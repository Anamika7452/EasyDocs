package com.anamika.easydocs

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.nio.file.Files

class FolderScannerTest {

    @Test
    fun scanFolderFindsSupportedFilesAndSkipsUnsupported() {
        val tempDir = Files.createTempDirectory("easydocs-test").toFile()
        try {
            val supportedText = File(tempDir, "notes.txt")
            supportedText.writeText("hello")

            val supportedHtml = File(tempDir, "index.html")
            supportedHtml.writeText("<html></html>")

            val nestedDir = File(tempDir, "nested")
            nestedDir.mkdirs()
            val supportedPdf = File(nestedDir, "guide.pdf")
            supportedPdf.writeText("pdf")

            val supportedXls = File(tempDir, "sheet.xls")
            supportedXls.writeText("xls")

            val supportedXlsx = File(tempDir, "workbook.xlsx")
            supportedXlsx.writeText("xlsx")

            val supportedPpt = File(tempDir, "presentation.ppt")
            supportedPpt.writeText("ppt")

            val supportedOdp = File(tempDir, "slides.odp")
            supportedOdp.writeText("odp")

            val supportedImage = File(tempDir, "photo.png")
            supportedImage.writeText("png")

            val supportedVideo = File(tempDir, "clip.mp4")
            supportedVideo.writeText("mp4")

            val unsupportedBinary = File(tempDir, "program.exe")
            unsupportedBinary.writeText("exe")

            val scanner = FolderScanner()
            val documents = mutableListOf<File>()
            scanner.scanFolder(tempDir, documents)

            val names = documents.map { it.name }

            assertTrue(names.contains("notes.txt"))
            assertTrue(names.contains("index.html"))
            assertTrue(names.contains("guide.pdf"))
            assertTrue(names.contains("photo.png"))
            assertTrue(names.contains("clip.mp4"))
            assertFalse(names.contains("program.exe"))
        } finally {
            tempDir.deleteRecursively()
        }
    }
}
