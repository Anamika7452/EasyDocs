package com.anamika.easydocs.picker

import android.content.Context
import android.net.Uri
import androidx.documentfile.provider.DocumentFile

/**
 * Turns an opaque SAF tree-URI into a small map the Flutter UI can render:
 * a human-friendly folder [name] and a readable [path]. The original [uri]
 * is preserved so Flutter can round-trip it back for removal.
 */
object FolderInfo {

    fun toMap(context: Context, uriString: String): Map<String, Any> {

        val uri = Uri.parse(uriString)

        return mapOf(
            "uri" to uriString,
            "name" to resolveName(context, uri),
            "path" to resolvePath(uri),
            "isDefault" to false
        )
    }

    private fun resolveName(context: Context, uri: Uri): String {

        // DocumentFile gives us the true display name of the picked tree.
        val fromDoc = runCatching {
            DocumentFile.fromTreeUri(context, uri)?.name
        }.getOrNull()

        if (!fromDoc.isNullOrBlank()) return fromDoc

        // Fallback: derive the last path segment from the tree document id.
        return lastSegment(uri) ?: "Selected folder"
    }

    /**
     * Produces a friendly, non-authoritative path like "Internal storage/Download"
     * from a tree document id such as "primary:Download".
     */
    private fun resolvePath(uri: Uri): String {

        val documentId = runCatching {
            android.provider.DocumentsContract.getTreeDocumentId(uri)
        }.getOrNull() ?: return uri.toString()

        val parts = documentId.split(":", limit = 2)

        val volume = when (parts.getOrNull(0)) {
            "primary" -> "Internal storage"
            else -> parts.getOrNull(0)?.ifBlank { "Storage" } ?: "Storage"
        }

        val relative = parts.getOrNull(1)?.trim('/').orEmpty()

        return if (relative.isEmpty()) volume else "$volume/$relative"
    }

    private fun lastSegment(uri: Uri): String? {

        val documentId = runCatching {
            android.provider.DocumentsContract.getTreeDocumentId(uri)
        }.getOrNull() ?: return null

        val afterColon = documentId.substringAfter(":", documentId)

        return afterColon.trim('/').substringAfterLast('/').ifBlank { null }
    }
}
