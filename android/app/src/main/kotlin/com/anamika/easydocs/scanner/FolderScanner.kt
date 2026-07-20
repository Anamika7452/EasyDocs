package com.anamika.easydocs

import java.io.File

class FolderScanner {

    fun scanFolder(
        folder: File,
        documents: MutableList<File>
    ) {

        if (!folder.exists()) return

        if (!folder.isDirectory) return

        if (FileUtils.shouldSkipDirectory(folder)) return

        val files = folder.listFiles() ?: return

        for (file in files) {

            if (file.isDirectory) {

                scanFolder(file, documents)

            } else {

                if (FileUtils.isSupported(file)) {
                    documents.add(file)
                }

            }
        }
    }
}