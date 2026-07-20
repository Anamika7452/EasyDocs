package com.anamika.easydocs.permission

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings

/**
 * Manages "All files access" (MANAGE_EXTERNAL_STORAGE), which is required to
 * read documents (PDF/DOCX) that other apps created in shared storage — these
 * are hidden from MediaStore under scoped storage.
 *
 * The permission cannot be granted via a normal runtime dialog; the user must
 * toggle it in system Settings, so [requestIntent] opens that screen.
 */
object StoragePermission {

    fun hasAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            // Pre-R relies on the legacy READ_EXTERNAL_STORAGE runtime permission,
            // which is declared in the manifest and granted the usual way.
            true
        }
    }

    /**
     * Intent that takes the user to the "All files access" settings screen for
     * this app. Returns null on versions where the permission does not exist.
     */
    fun requestIntent(context: Context): Intent? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null

        return Intent(
            Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
            Uri.parse("package:${context.packageName}")
        ).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
}
