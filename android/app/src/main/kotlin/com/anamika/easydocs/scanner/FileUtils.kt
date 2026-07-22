package com.anamika.easydocs

import java.io.File

object FileUtils {

    private val supportedExtensions = setOf(
        "pdf",
        "docx",
        "txt",
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
        "toml"
    )

    fun isSupported(file: File): Boolean {
        return supportedExtensions.contains(
            file.extension.lowercase()
        )
    }

    fun shouldSkipDirectory(directory: File): Boolean {

        val name = directory.name.lowercase()

        return name == "android" ||
                name == ".thumbnails" ||
                name == "cache" ||
                name == ".cache"
    }

}