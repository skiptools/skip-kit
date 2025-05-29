// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
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
    // SKIP @nobridge
    @ViewBuilder public func withDocumentPicker(isPresented: Binding<Bool>, allowedContentTypes: [UTType], selectedDocumentURL: Binding<URL?>, selectedFilename: Binding<String?>, selectedFileMimeType: Binding<String?> ) -> some View {
#if SKIP
        let context = LocalContext.current
        
        let pickDocumentLauncher = rememberLauncherForActivityResult(contract: ActivityResultContracts.OpenDocument()) { uri in
            isPresented.wrappedValue = false
            logger.log(message: "selected document uri: \(uri)")
            if let uri = uri {
                let resolver = context.contentResolver
                                            
                if let query = resolver.query(uri, nil, nil, nil, nil) {
                    let nameIndex = query.getColumnIndexOrThrow(android.provider.OpenableColumns.DISPLAY_NAME)
                    let mimetypeIndex = query.getColumnIndexOrThrow(android.provider.DocumentsContract.Document.COLUMN_MIME_TYPE)
                    query.moveToFirst()
                    let name = query.getString(nameIndex)
                    let type = query.getString(mimetypeIndex)
                    
                    selectedFilename.wrappedValue = name
                    selectedFileMimeType.wrappedValue = type
                    
                    // To be able to access the file from another part of the app it needs to be copied in tha cached directory:
                    if let storageDir = context.cacheDir, let url = URL(string: storageDir.path) {
                        let filemanager = FileManager.default
                        let destinationFileURL = url.appendingPathComponent(selectedFilename.wrappedValue!)
                        
                        if filemanager.fileExists(atPath: destinationFileURL.path) {
                            try? filemanager.removeItem(at: destinationFileURL)
                        }
                                                
                        let inputStream = resolver.openInputStream(uri)!
                        let outputFile = java.io.File(destinationFileURL.path)
                        let outputStream = java.io.FileOutputStream(outputFile)
                        inputStream.copyTo(outputStream)
                        
                        outputStream.close()
                        inputStream.close()
                        
                        selectedDocumentURL.wrappedValue = destinationFileURL
                    } else {
                        selectedDocumentURL.wrappedValue = URL(platformValue: java.net.URI.create(uri.toString()))
                    }
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
#else
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
