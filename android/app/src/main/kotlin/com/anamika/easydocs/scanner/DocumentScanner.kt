package com.anamika.easydocs

import android.os.Environment
import java.io.File

class DocumentScanner {

    private val scanner = FolderScanner()

    fun getDocuments(): List<Map<String, Any>> {

        val files = mutableListOf<File>()

        scanner.scanFolder(
            Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            ),
            files
        )

        scanner.scanFolder(
            Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOCUMENTS
            ),
            files
        )

        return files.map {

            mapOf(
                "name" to it.name,
                "uri" to it.absolutePath,
                "size" to it.length(),
                "extension" to it.extension.lowercase()
            )

        }
    }

}