package com.dairy.corzin

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val exportChannelName = "com.dairy.corzin/report_export"
    private val folderPickerRequestCode = 8401

    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private var pendingFileName: String? = null
    private var pendingMimeType: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, exportChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "exportToPickedFolder" -> handleExportToPickedFolder(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleExportToPickedFolder(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("IN_PROGRESS", "An export request is already in progress.", null)
            return
        }

        val fileName = call.argument<String>("fileName")?.trim().orEmpty()
        val mimeType = call.argument<String>("mimeType")?.trim().orEmpty()
        val bytes = call.argument<ByteArray>("bytes")

        if (fileName.isEmpty() || mimeType.isEmpty() || bytes == null || bytes.isEmpty()) {
            result.error("INVALID_ARGS", "Invalid export payload.", null)
            return
        }

        pendingResult = result
        pendingBytes = bytes
        pendingFileName = fileName
        pendingMimeType = mimeType

        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                )
            }
            startActivityForResult(intent, folderPickerRequestCode)
        } catch (error: Exception) {
            val callback = pendingResult
            clearPending()
            callback?.error("PICKER_ERROR", error.message ?: "Folder picker failed.", null)
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != folderPickerRequestCode) return
        val treeUri = if (resultCode == Activity.RESULT_OK) data?.data else null
        onFolderPicked(treeUri)
    }

    private fun onFolderPicked(treeUri: Uri?) {
        val callback = pendingResult ?: return
        val fileName = pendingFileName
        val mimeType = pendingMimeType
        val bytes = pendingBytes

        if (treeUri == null) {
            clearPending()
            callback.error("CANCELLED", "Folder selection cancelled.", null)
            return
        }

        if (fileName.isNullOrBlank() || mimeType.isNullOrBlank() || bytes == null) {
            clearPending()
            callback.error("INVALID_ARGS", "Invalid pending export payload.", null)
            return
        }

        try {
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            contentResolver.takePersistableUriPermission(treeUri, flags)
        } catch (_: Exception) {
            // Persist may fail on some OEMs; one-time grant still works for current operation.
        }

        try {
            val parentDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
            val parentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, parentDocumentId)
            val createdUri = DocumentsContract.createDocument(
                contentResolver,
                parentUri,
                mimeType,
                fileName
            )

            if (createdUri == null) {
                clearPending()
                callback.error("CREATE_FAILED", "Unable to create file in selected folder.", null)
                return
            }

            contentResolver.openOutputStream(createdUri, "w")?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: run {
                clearPending()
                callback.error("WRITE_FAILED", "Unable to open output stream.", null)
                return
            }

            clearPending()
            callback.success(createdUri.toString())
        } catch (error: Exception) {
            clearPending()
            callback.error("WRITE_FAILED", error.message ?: "Failed to save file.", null)
        }
    }

    private fun clearPending() {
        pendingResult = null
        pendingBytes = null
        pendingFileName = null
        pendingMimeType = null
    }
}
