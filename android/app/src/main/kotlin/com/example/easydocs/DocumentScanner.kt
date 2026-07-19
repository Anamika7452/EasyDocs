package com.anamika.easydocs

import android.content.ContentUris
import android.content.Context
import android.provider.MediaStore
import android.util.Log

class DocumentScanner(
    private val context: Context
) {

    private val supportedExtensions = setOf(
        "pdf",
        "docx"
    )

    fun getDocuments(): List<Map<String, Any>> {

        val documents = mutableListOf<Map<String, Any>>()

        val collection = MediaStore.Files.getContentUri("external")

        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.MIME_TYPE
        )

        Log.d("EasyDocs", "Starting MediaStore scan")

        val cursor = context.contentResolver.query(
            collection,
            projection,
            null,
            null,
            "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
        )

        Log.d(
            "EasyDocs",
            "Cursor count: ${cursor?.count}"
        )

        cursor?.use {

            val idColumn =
                it.getColumnIndexOrThrow(
                    MediaStore.Files.FileColumns._ID
                )

            val nameColumn =
                it.getColumnIndexOrThrow(
                    MediaStore.Files.FileColumns.DISPLAY_NAME
                )

            val sizeColumn =
                it.getColumnIndexOrThrow(
                    MediaStore.Files.FileColumns.SIZE
                )


            while (it.moveToNext()) {

                val id = it.getLong(idColumn)

                val name =
                    it.getString(nameColumn)
                        ?: continue

                val size =
                    it.getLong(sizeColumn)


                val extension =
                    name.substringAfterLast(
                        ".",
                        ""
                    ).lowercase()


                if (!supportedExtensions.contains(extension)) {
                    continue
                }


                val uri =
                    ContentUris.withAppendedId(
                        collection,
                        id
                    )


                Log.d(
                    "EasyDocs",
                    "Found: $name"
                )


                documents.add(
                    mapOf(
                        "name" to name,
                        "uri" to uri.toString(),
                        "size" to size,
                        "extension" to extension
                    )
                )
            }
        }


        Log.d(
            "EasyDocs",
            "Total documents: ${documents.size}"
        )


        return documents
    }
}