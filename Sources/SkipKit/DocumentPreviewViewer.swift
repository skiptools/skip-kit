// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
//
//  SwiftUIView.swift
//  skip-kit
//
//  Created by Simone Figlie' on 23/05/25.
//

import SwiftUI
import Foundation

#if SKIP
import android.Manifest
import android.app.Activity
import android.content.Context
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
import android.content.ContentResolver
#endif

extension View {
    /// Dispay a preview for the selected file. On iOS uses a `QLPreviewController` while on Android it opens a new intent for choosing the appropriate viewer by the `ACTION_VIEW` intent parameter.
    /// On Android is mandatory to use a FileProvider to expose the url to the exteranl app. The file must be in the App Cache foder, otherwise the file provider can't give read access to the receiving app.
    /// If it's used wiith the provided `DocumentPicker` of this library there's no need to move the file since the document provider already creates a copy of the selected file in the cache folder.
    /// - Parameters:
    ///   - isPresented: binding della variabile di stato che indica se il compoemente è visualizzato o meno
    ///   - documentURL: URL del file che si intente visualizzare
    /// - Returns: su iOS un QLPreviewController mentre su Android viene lanciato in Intent ACTION_VIEW per la scelta dell'App da utilizzare.
    // SKIP @nobridge
    @ViewBuilder public func withDocumentPreview(isPresented: Binding<Bool>, documentURL: URL?, filename: String? = nil, type: String? = nil) -> some View {
        #if !SKIP
        #if os(iOS)
        fullScreenCover(isPresented: isPresented) {
            PreviewController(url: documentURL!, isPresented: isPresented)
                .ignoresSafeArea()
        }
        #endif
        #else
        let context = LocalContext.current
        return onChange(of: isPresented.wrappedValue) { presented in
            if presented == true {
                
                let file = java.io.File.init(documentURL!.absoluteString)
                let uri = androidx.core.content.FileProvider.getUriForFile(context.asActivity(), context.getPackageName() + ".fileprovider", file)
                
                var mimeType: String
                                
                if type == nil {
                    let fileExtension = android.webkit.MimeTypeMap.getFileExtensionFromUrl(uri.toString()) ?? ""
                    mimeType = android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(fileExtension) ?? ""
                } else {
                    mimeType = type
                }
                                
                if mimeType.isEmpty {
                    // Try to use a content provider to get the mime type
                    let contentResolver: android.content.ContentResolver = context.contentResolver
                    mimeType = contentResolver.getType(uri) ?? ""
                }
                
                let intent = android.content.Intent()
                intent.action = android.content.Intent.ACTION_VIEW
                intent.setDataAndType(uri, mimeType)
                intent.setFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
                
                let chooser = android.content.Intent.createChooser(intent, "Open with")
                context.startActivity(chooser)
                
                isPresented.wrappedValue = false
            }
        }
        #endif
    }
}
