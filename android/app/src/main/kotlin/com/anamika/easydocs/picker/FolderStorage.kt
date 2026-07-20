package com.anamika.easydocs.picker

import android.content.Context

/**
 * Persists the set of folder tree-URIs that EasyDocs is allowed to scan.
 *
 * URIs are stored as an ordered list (newest last) so the UI can display
 * folders in a stable order. Persistable URI read permissions are taken
 * separately by [FolderPicker]; this class only owns the string bookkeeping.
 */
class FolderStorage(
    context: Context
) {

    companion object {
        private const val PREF_NAME = "easydocs_preferences"
        private const val KEY_FOLDERS = "selected_folders"
        // Newline can never appear inside a content:// URI, so it is a safe separator.
        private const val SEPARATOR = "\n"
    }

    private val preferences =
        context.getSharedPreferences(
            PREF_NAME,
            Context.MODE_PRIVATE
        )

    fun getFolders(): List<String> {

        val raw = preferences.getString(KEY_FOLDERS, "") ?: ""

        if (raw.isEmpty()) return emptyList()

        return raw.split(SEPARATOR).filter { it.isNotBlank() }
    }

    /**
     * Adds [uri] to the persisted list. Duplicates are ignored so a folder is
     * never scanned twice. Returns true if the folder was newly added.
     */
    fun addFolder(uri: String): Boolean {

        val folders = getFolders().toMutableList()

        if (folders.contains(uri)) return false

        folders.add(uri)

        persist(folders)

        return true
    }

    fun removeFolder(uri: String) {

        val folders = getFolders().toMutableList()

        folders.remove(uri)

        persist(folders)
    }

    fun clearFolders() {

        preferences.edit()
            .remove(KEY_FOLDERS)
            .apply()
    }

    private fun persist(folders: List<String>) {

        preferences.edit()
            .putString(KEY_FOLDERS, folders.joinToString(SEPARATOR))
            .apply()
    }
}
