package com.anamika.easydocs.picker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.FragmentActivity

class FolderPicker(
    private val activity: FragmentActivity
) {

    private var onFolderPicked: ((Uri?) -> Unit)? = null

    private val launcher: ActivityResultLauncher<Intent> =
        activity.registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { result ->

            if (result.resultCode != Activity.RESULT_OK) {
                onFolderPicked?.invoke(null)
                return@registerForActivityResult
            }

            val uri = result.data?.data

            if (uri != null) {

                activity.contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            }

            onFolderPicked?.invoke(uri)
        }

    fun pickFolder(
        callback: (Uri?) -> Unit
    ) {

        onFolderPicked = callback

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {

            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }

        launcher.launch(intent)
    }
}