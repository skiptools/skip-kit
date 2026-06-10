// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
import Foundation
import SwiftUI

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
#endif

extension View {
    /// Allow to present a Document picker interface activated by the `isPresented` binding. It will return the selected file URL through the `selectedDocumentURL` binding.
    ///
    /// On iOS uses the `fileImporter` with allowed content types of `text`, `pdf` and `images`.
    /// On Android it will user the intet action  ACTION_OPEN_DOCUMENT  to present the system picker for `pdf` and `images`.
    /// It optionally also returns the real `filename` and `mimeType` through the corresponding bindings, since on this platform the document pickers returns an obfuscated url. Also, on Android, in order for the url to be accessible outside the scope of this call a copy of the file is made in the cache directory, and the copied file url is returned
    /// - Parameters:
    ///   - isPresented: binding for presentation
    ///   - selectedDocumentURL: the URL of the selected file
    ///   - filename: the filename of the selected file
    ///   - mimeType: the mimeType of the selected file
    @ViewBuilder public func withDocumentPicker(isPresented: Binding<Bool>, allowedContentTypes: [UTType], selectedDocumentURL: Binding<URL?>, selectedFilename: Binding<String?>, selectedFileMimeType: Binding<String?> ) -> some View {
        #if SKIP
        let context = LocalContext.current
        
        let pickDocumentLauncher = rememberLauncherForActivityResult(contract: ActivityResultContracts.OpenDocument()) { uri in
            isPresented.wrappedValue = false
            logger.log(message: "selected document uri: \(uri)")
            if let uri = uri {
                let resolver = context.contentResolver
                var resolvedName: String? = nil
                var resolvedMime: String? = nil

                if let query = resolver.query(uri, nil, nil, nil, nil) {
                    if query.moveToFirst() {
                        // Downloads provider omits these columns; tolerate -1.
                        let nameIndex = query.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                        if nameIndex >= 0 {
                            resolvedName = query.getString(nameIndex)
                        }
                        let mimeIndex = query.getColumnIndex(android.provider.DocumentsContract.Document.COLUMN_MIME_TYPE)
                        if mimeIndex >= 0 {
                            resolvedMime = query.getString(mimeIndex)
                        }
                    }
                    query.close()
                }

                if resolvedMime == nil {
                    resolvedMime = resolver.getType(uri)
                }

                let safeName: String = resolvedName ?? "import-\(java.util.UUID.randomUUID().toString())"

                selectedFilename.wrappedValue = safeName
                selectedFileMimeType.wrappedValue = resolvedMime

                // java.io.File path avoids Skip URL.appendingPathComponent NPE.
                if let cacheDir = context.cacheDir {
                    let destinationFile = java.io.File(cacheDir, safeName)
                    if destinationFile.exists() {
                        destinationFile.delete()
                    }
                    if let inputStream = resolver.openInputStream(uri) {
                        let outputStream = java.io.FileOutputStream(destinationFile)
                        inputStream.copyTo(outputStream)
                        outputStream.close()
                        inputStream.close()
                        // File.toURI() percent-encodes; raw path would crash java.net.URI.
                        selectedDocumentURL.wrappedValue = URL(platformValue: destinationFile.toURI())
                    } else {
                        selectedDocumentURL.wrappedValue = URL(platformValue: java.net.URI.create(uri.toString()))
                    }
                } else {
                    selectedDocumentURL.wrappedValue = URL(platformValue: java.net.URI.create(uri.toString()))
                }
            }
        }
        
        return onChange(of: isPresented.wrappedValue) { oldValue, presented in
            if presented == true {
                let parsedMimeTypes: [String] = allowedContentTypes.map({ $0.preferredMIMEType ?? ""})
                var types = kotlin.arrayOf("")
                for type in parsedMimeTypes {
                    types += type
                }
                let mimeTypes = types //kotlin.arrayOf("application/pdf", "image/*")
                pickDocumentLauncher.launch(mimeTypes)
            }
        }

        #else // !SKIP

        fileImporter(isPresented: isPresented, allowedContentTypes: allowedContentTypes) { result in
            switch result {
            case .success(let file):
                // gain access to the directory
                let gotAccess = file.startAccessingSecurityScopedResource()
                if !gotAccess { return }
                // access the directory URL
                // (read templates in the directory, make a bookmark, etc.)
                selectedDocumentURL.wrappedValue = file
                isPresented.wrappedValue = false
                // release access
                file.stopAccessingSecurityScopedResource()
            case .failure(let error):
                // handle error
                print(error)
                isPresented.wrappedValue = false
            }
        }
        #endif
    }
}
#endif
