package com.anamika.easydocs.picker

import android.os.Environment

/**
 * Well-known folders EasyDocs always scans (via MediaStore, later).
 *
 * These are surfaced in the Scan Locations sheet as fixed, always-on rows.
 * They are NOT pickable through SAF — Android blocks taking tree access to
 * Download / shared-storage roots — so they are represented here directly
 * rather than as content:// tree URIs. Their [id]s are synthetic and stable
 * so Flutter can distinguish them from user-added custom folders.
 */
object DefaultFolders {

    data class DefaultFolder(
        val id: String,
        val name: String,
        val path: String
    )

    val all: List<DefaultFolder> = listOf(
        DefaultFolder(
            id = "default:download",
            name = "Download",
            path = "Internal storage/Download"
        ),
        DefaultFolder(
            id = "default:documents",
            name = "Documents",
            path = "Internal storage/Documents"
        )
    )

    /** Display-ready maps for the Flutter UI. */
    fun toMaps(): List<Map<String, Any>> = all.map {
        mapOf(
            "uri" to it.id,          // synthetic id; not a real content URI
            "name" to it.name,
            "path" to it.path,
            "isDefault" to true
        )
    }

    /** The absolute filesystem paths these defaults refer to (for future scanning). */
    fun paths(): List<String> = listOf(
        Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        ).absolutePath,
        Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOCUMENTS
        ).absolutePath
    )
}
