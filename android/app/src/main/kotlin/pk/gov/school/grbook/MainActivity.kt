package pk.gov.school.grbook

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "pk.gov.school.grbook/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveImageToGallery") {
                val bytes = call.argument<ByteArray>("bytes")
                val fileName = call.argument<String>("fileName") ?: "GR_Book_${System.currentTimeMillis()}.png"
                if (bytes == null) {
                    result.error("INVALID_ARGS", "Bytes cannot be null", null)
                    return@setMethodCallHandler
                }

                try {
                    val success = saveToGallery(bytes, fileName)
                    result.success(success)
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveToGallery(bytes: ByteArray, fileName: String): Boolean {
        val resolver = applicationContext.contentResolver
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg")) "image/jpeg" else "image/png")
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + File.separator + "GR_Book")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues) ?: return false
            resolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            }

            contentValues.clear()
            contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, contentValues, null, null)
            return true
        } else {
            val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            val grBookDir = File(picturesDir, "GR_Book")
            if (!grBookDir.exists()) grBookDir.mkdirs()
            val file = File(grBookDir, fileName)
            FileOutputStream(file).use { out ->
                out.write(bytes)
                out.flush()
            }
            android.media.MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(file.absolutePath),
                arrayOf(if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg")) "image/jpeg" else "image/png"),
                null
            )
            return true
        }
    }
}
