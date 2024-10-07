// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation
import SwiftUI

#if SKIP
import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.contract.ActivityResultContracts.GetContent
import androidx.activity.result.contract.ActivityResultContracts.TakePicture
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat.startActivity
#endif

public enum MediaPickerType {
    case camera, library
}

extension View {
    /// Enables a media picker interface for the camera or photo library can be activated through the `isPresented` binding, and which returns the selected image through the `selectedImageURL` binding.
    ///
    /// On iOS, this camera selector will be presented in a `fullScreenCover` view, whereas the media library browser will be presented in a `sheet`.
    /// On Android, the camera and library browser will be activated through Intents after querying for the necessary permissions.
    @ViewBuilder public func withMediaPicker(type: MediaPickerType, isPresented: Binding<Bool>, selectedImageURL: Binding<URL?>) -> some View {
        switch type {
        case .library:
            #if !SKIP
            #if os(iOS)
            sheet(isPresented: isPresented) {
                PhotoLibraryPicker(sourceType: .photoLibrary, selectedImageURL: selectedImageURL)
                    .presentationDetents([.medium])
            }
            #endif
            #else
            let pickImageLauncher = rememberLauncherForActivityResult(contract: ActivityResultContracts.GetContent()) { uri in
                // uri e.g.: content://media/picker/0/com.android.providers.media.photopicker/media/1000000025
                isPresented.wrappedValue = false // clear the presented bit
                logger.log("pickImageLauncher: \(uri)")
                if let uri = uri {
                    selectedImageURL.wrappedValue = URL(platformValue: java.net.URI.create(uri.toString()))
                }
            }

            return onChange(of: isPresented.wrappedValue) { presented in
                if presented == true {
                    pickImageLauncher.launch("image/*")
                }
            }
            #endif

        case .camera:
            #if !SKIP
            #if os(iOS)
            fullScreenCover(isPresented: isPresented) {
                PhotoLibraryPicker(sourceType: .camera, selectedImageURL: selectedImageURL)
            }
            #endif
            #else
            var imageURL: android.net.Uri? = nil

            // alternatively, we could use TakePicturePreview, which returns a Bitmap
            let takePictureLauncher = rememberLauncherForActivityResult(contract: ActivityResultContracts.TakePicture()) { success in
                // uri e.g.: content://media/picker/0/com.android.providers.media.photopicker/media/1000000025
                isPresented.wrappedValue = false // clear the presented bit
                logger.log("takePictureLauncher: success: \(success) from \(imageURL)")
                if success == true, let imageURL = imageURL {
                    selectedImageURL.wrappedValue = URL(string: imageURL.toString())
                }
            }

            // FIXME: 05-20 20:29:41.435  8964  8964 E AndroidRuntime: java.lang.SecurityException: Permission Denial: starting Intent { act=android.media.action.IMAGE_CAPTURE flg=0x3 cmp=com.android.camera2/com.android.camera.CaptureActivity clip={text/uri-list hasLabel(0) {}} (has extras) } from ProcessRecord{c5fb1f 8964:skip.photo.chat/u0a190} (pid=8964, uid=10190) with revoked permission android.permission.CAMERA

            let context = LocalContext.current

            let PERM_REQUEST_CAMERA = 642

            return onChange(of: isPresented.wrappedValue) { presented in
                if presented == true {
                    var perms = listOf(Manifest.permission.CAMERA).toTypedArray()
                    if ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED {
                        logger.log("takePictureLauncher: requesting Manifest.permission.CAMERA permission")
                        ActivityCompat.requestPermissions(context as Activity, perms, PERM_REQUEST_CAMERA)
                    } else {
                        let storageDir = context.getExternalFilesDir(android.os.Environment.DIRECTORY_PICTURES)
                        let ext = ".jpg"
                        let tmpFile = java.io.File.createTempFile("SkipKit_\(UUID().uuidString)", ext, storageDir)
                        logger.log("takePictureLauncher: create tmpFile: \(tmpFile)")

                        imageURL = androidx.core.content.FileProvider.getUriForFile(context as Activity, context.getPackageName() + ".fileprovider", tmpFile)
                        logger.log("takePictureLauncher: takePictureLauncher.launch: \(imageURL)")

                        takePictureLauncher.launch(android.net.Uri.parse(imageURL.kotlin().toString()))
                    }
                }
            }
            #endif
        }
    }
}


#if !SKIP
#if os(iOS)
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImageURL: URL?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.sourceType = sourceType
        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: PhotoLibraryPicker

        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            logger.info("didFinishPickingMediaWithInfo: \(info)")

            if let imageURL = info[.imageURL] as? URL {
                // for the media picker, it provided direct access to the image URL
                logger.info("imagePickerController: selected imageURL: \(imageURL)")
                parent.selectedImageURL = imageURL
            } else if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
                logger.info("imagePickerController: selected editedImage: \(image)")
                // need to save to a temporary URLso it can be loaded
                if let imageData = image.pngData() {
                    let imageURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
                    logger.info("imagePickerController: saving image to: \(imageURL.path)")
                    do {
                        try imageData.write(to: imageURL)
                        parent.selectedImageURL = imageURL
                    } catch {
                        logger.warning("imagePickerController: error writing image to \(imageURL.path): \(error)")
                    }
                } else {
                    logger.warning("imagePickerController: error extracting PNG data from image: \(image)")
                }
            } else {
                logger.info("imagePickerController: no image found in keys: \(info.keys)")
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            logger.info("imagePickerControllerDidCancel")
            parent.dismiss()
        }
    }
}
#endif
#endif
