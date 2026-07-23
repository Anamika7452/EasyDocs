package com.anamika.easydocs

import java.io.File

object FileUtils {

    private val supportedExtensions = setOf(
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