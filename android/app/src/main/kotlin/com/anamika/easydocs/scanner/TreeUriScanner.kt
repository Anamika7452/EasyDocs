package com.anamika.easydocs.scanner

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import com.anamika.easydocs.FileUtils
import java.io.File

/**
 * Recursively scans a SAF tree URI (a user-picked custom folder) for
 * supported documents using [DocumentsContract]. Custom folders are
 * content:// trees, so they cannot be walked as java.io.File — this is the
 * SAF equivalent of [FolderScanner].
 */
object TreeUriScanner {

    private val SUPPORTED = setOf(
        "pdf",
        "doc",
        "docx",
        "xls",
        "xlsx",
        "ppt",
        "pptx",
        "odp",
        "txt",
        "html",
        "htm",
        "md",
        "rtf",
        "json",
        "xml",
        "csv",
        "log",
        "yaml",
        "yml",
        "properties",
        "ini",
        "toml",
        "jpg",
        "jpeg",
        "png",
        "gif",
        "bmp",
        "webp",
        "heic",
        "heif",
        "mp3",
        "wav",
        "aac",
        "ogg",
        "m4a",
        "amr",
        "mp4",
        "mkv",
        "mov",
        "avi",
        "flv",
        "wmv",
        "webm",
        "3gp"
    )

    fun scan(context: Context, treeUri: Uri): List<Map<String, Any>> {

        val results = mutableListOf<Map<String, Any>>()

        val rootDocId = runCatching {
            DocumentsContract.getTreeDocumentId(treeUri)
        }.getOrNull() ?: return results

        walk(context, treeUri, rootDocId, results)

        return results
    }

    private fun walk(
        context: Context,
        treeUri: Uri,
        parentDocId: String,
        out: MutableList<Map<String, Any>>
    ) {

        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            parentDocId
        )

        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE
        )

        val cursor = runCatching {
            context.contentResolver.query(childrenUri, projection, null, null, null)
        }.getOrNull() ?: return

        cursor.use { c ->
            while (c.moveToNext()) {

                val docId = c.getString(0)
                val name = c.getString(1) ?: continue
                val mime = c.getString(2)
                val size = if (c.isNull(3)) 0L else c.getLong(3)

                if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                    // Recurse into subdirectories.
                    walk(context, treeUri, docId, out)
                } else {
                    val ext = name.substringAfterLast('.', "").lowercase()
                    if (ext in SUPPORTED || FileUtils.isSupported(File(name))) {
                        val fileUri = DocumentsContract.buildDocumentUriUsingTree(
                            treeUri,
                            docId
                        )
                        out.add(
                            mapOf(
                                "name" to name,
                                "uri" to fileUri.toString(),
                                "size" to size,
                                "extension" to ext
                            )
                        )
                    }
                }
            }
        }
    }
}
