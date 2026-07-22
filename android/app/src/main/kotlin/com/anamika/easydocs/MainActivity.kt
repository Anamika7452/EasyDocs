package com.anamika.easydocs

import android.content.Intent
import android.net.Uri
import com.anamika.easydocs.picker.DefaultFolders
import com.anamika.easydocs.picker.FolderInfo
import com.anamika.easydocs.picker.FolderPicker
import com.anamika.easydocs.picker.FolderStorage
import com.anamika.easydocs.permission.StoragePermission
import com.anamika.easydocs.scanner.TreeUriScanner
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// FlutterFragmentActivity (rather than FlutterActivity) is required so the
// activity is a FragmentActivity — a prerequisite for registerForActivityResult,
// which FolderPicker relies on to drive the SAF folder picker.
class MainActivity : FlutterFragmentActivity() {

    companion object {
        const val CHANNEL = "com.anamika.easydocs/documents"
    }

    private lateinit var folderPicker: FolderPicker
    private lateinit var folderStorage: FolderStorage
    private val scanner = FolderScanner()
    private var pendingDocument: Map<String, Any>? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        pendingDocument = extractPendingDocument(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        pendingDocument = extractPendingDocument(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        folderPicker = FolderPicker(this)
        folderStorage = FolderStorage(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "pickFolder" -> pickFolder(result)

                "hasStoragePermission" ->
                    result.success(StoragePermission.hasAccess())

                "requestStoragePermission" -> {
                    val intent = StoragePermission.requestIntent(this)
                    if (intent != null) startActivity(intent)
                    // Grant happens in Settings; the UI re-checks on resume.
                    result.success(StoragePermission.hasAccess())
                }

                "getSelectedFolders" -> result.success(selectedFolders())

                "removeFolder" -> {
                    val uri = call.argument<String>("uri")
                    when {
                        uri.isNullOrBlank() -> result.error(
                            "INVALID_ARGUMENT",
                            "A non-empty 'uri' is required to remove a folder.",
                            null
                        )
                        // Default folders are fixed and cannot be removed.
                        DefaultFolders.all.any { it.id == uri } -> result.error(
                            "CANNOT_REMOVE_DEFAULT",
                            "Default folders cannot be removed.",
                            null
                        )
                        else -> {
                            folderStorage.removeFolder(uri)
                            result.success(selectedFolders())
                        }
                    }
                }

                "getDocuments" -> {
                    // Scanning can touch the filesystem / content resolver, so
                    // run it off the platform thread and post the result back.
                    Thread {
                        val docs = runCatching { scanDocuments() }
                        runOnUiThread {
                            docs.fold(
                                onSuccess = { result.success(it) },
                                onFailure = {
                                    result.error(
                                        "SCAN_FAILED",
                                        it.message,
                                        null
                                    )
                                }
                            )
                        }
                    }.start()
                }

                "getPendingDocument" -> {
                    result.success(pendingDocument)
                }

                "getDocumentFilePath" -> {
                    val uri = call.argument<String>("uri")
                    val name = call.argument<String>("name")
                    val extension = call.argument<String>("extension")

                    when {
                        uri.isNullOrBlank() -> result.error(
                            "INVALID_ARGUMENT",
                            "A non-empty 'uri' is required to resolve the document.",
                            null
                        )
                        else -> {
                            val path = runCatching {
                                resolveDocumentPath(uri, name, extension)
                            }
                            path.fold(
                                onSuccess = { result.success(it) },
                                onFailure = {
                                    result.error(
                                        "DOCUMENT_ACCESS_FAILED",
                                        it.message,
                                        null
                                    )
                                }
                            )
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {

        folderPicker.pickFolder { uri ->

            if (uri == null) {
                result.success(null)
                return@pickFolder
            }

            val added = folderStorage.addFolder(uri.toString())

            if (!added) {
                result.success(null)
                return@pickFolder
            }

            result.success(selectedFolders())
        }
    }

    /** Default (always-on) folders first, then user-added custom folders. */
    private fun selectedFolders(): List<Map<String, Any>> {
        val defaults = DefaultFolders.toMaps()
        val custom = folderStorage.getFolders().map { uri ->
            FolderInfo.toMap(this, uri)
        }
        return defaults + custom
    }

    /**
     * Scans every enabled location and returns supported documents.
     *
     *  - Default folders (Download, Documents) are walked as files. This needs
     *    all-files access (MANAGE_EXTERNAL_STORAGE) to see documents other apps
     *    created; without it the walk simply returns nothing.
     *  - Custom folders are SAF tree URIs, walked via DocumentsContract, and do
     *    not require the all-files permission.
     *
     * Results are de-duplicated by uri so a document reachable through both a
     * default and an overlapping custom folder is only reported once.
     */
    private fun extractPendingDocument(intent: Intent?): Map<String, Any>? {
        if (intent == null) return null

        val action = intent.action ?: return null
        if (action != Intent.ACTION_VIEW) return null

        val uri = intent.data ?: return null
        val rawName = uri.lastPathSegment ?: intent.dataString?.substringAfterLast('/') ?: "shared_document"
        val name = rawName.substringAfterLast('/').takeIf { it.isNotBlank() } ?: "shared_document"
        val extension = inferExtension(name, intent.type, uri)

        return mapOf(
            "name" to name,
            "uri" to uri.toString(),
            "size" to 0,
            "extension" to extension
        )
    }

    private fun inferExtension(name: String, mimeType: String?, uri: Uri): String {
        val fromName = name.substringAfterLast('.', "").lowercase()
        if (fromName.isNotBlank()) return fromName

        return when (mimeType?.lowercase()) {
            "application/pdf" -> "pdf"
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" -> "docx"
            "text/plain" -> "txt"
            "application/json", "application/*+json" -> "json"
            else -> {
                val pathExt = uri.lastPathSegment?.substringAfterLast('.', "")?.lowercase()
                pathExt?.takeIf { it.isNotBlank() } ?: "bin"
            }
        }
    }

    private fun resolveDocumentPath(
        uri: String,
        name: String?,
        extension: String?
    ): String {
        val parsedUri = Uri.parse(uri)
        val fileName = when {
            !name.isNullOrBlank() -> name
            !extension.isNullOrBlank() -> "document.$extension"
            else -> "document"
        }

        val targetFile = File(cacheDir, "documents/$fileName")
        targetFile.parentFile?.mkdirs()

        return when (parsedUri.scheme) {
            "content" -> {
                contentResolver.openInputStream(parsedUri)?.use { input ->
                    targetFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                } ?: throw IllegalStateException("Unable to read the selected document.")
                targetFile.absolutePath
            }
            "file" -> {
                val sourceFile = File(parsedUri.path ?: uri)
                if (!sourceFile.exists()) {
                    throw IllegalStateException("The selected document could not be found.")
                }
                sourceFile.copyTo(targetFile, overwrite = true)
                targetFile.absolutePath
            }
            else -> {
                val sourceFile = File(uri)
                if (!sourceFile.exists()) {
                    throw IllegalStateException("The selected document could not be found.")
                }
                sourceFile.copyTo(targetFile, overwrite = true)
                targetFile.absolutePath
            }
        }
    }

    private fun scanDocuments(): List<Map<String, Any>> {

        val byUri = LinkedHashMap<String, Map<String, Any>>()

        // Default folders — filesystem walk (requires all-files access).
        val files = mutableListOf<File>()
        for (path in DefaultFolders.paths()) {
            scanner.scanFolder(File(path), files)
        }
        for (file in files) {
            byUri.putIfAbsent(
                file.absolutePath,
                mapOf(
                    "name" to file.name,
                    "uri" to file.absolutePath,
                    "size" to file.length(),
                    "extension" to file.extension.lowercase()
                )
            )
        }

        // Custom folders — SAF tree scan.
        for (uriString in folderStorage.getFolders()) {
            val docs = TreeUriScanner.scan(this, Uri.parse(uriString))
            for (doc in docs) {
                val key = doc["uri"] as String
                byUri.putIfAbsent(key, doc)
            }
        }

        return byUri.values.toList()
    }
}
