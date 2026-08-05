// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
import Foundation
import SwiftUI

#if SKIP
import android.Manifest
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

    /// Allows presenting a document picker interface activated by the `isPresented` binding.
    ///
    /// On iOS, this uses `fileImporter` with the supplied content types. On Android, this uses the
    /// `ACTION_OPEN_DOCUMENT` intent. Android returns an obfuscated URL, so the selected document is
    /// copied into the app cache and the copied file URL is returned together with its filename and MIME type.
    ///
    /// - Parameters:
    ///   - isPresented: Binding for presentation.
    ///   - allowedContentTypes: The content types that can be selected.
    ///   - selectedDocumentURL: The URL of the selected file.
    ///   - selectedFilename: The filename of the selected file.
    ///   - selectedFileMimeType: The MIME type of the selected file.
    @ViewBuilder public func withDocumentPicker(
        isPresented: Binding<Bool>,
        allowedContentTypes: [UTType],
        selectedDocumentURL: Binding<URL?>,
        selectedFilename: Binding<String?>,
        selectedFileMimeType: Binding<String?>
    ) -> some View {

        self.withDocumentPicker(
            isPresented: isPresented,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: false,
            selectedDocumentURLs: Binding(
                get: {
                    if let value = selectedDocumentURL.wrappedValue {
                        return [value]
                    }
                    return []
                },
                set: { selectedDocumentURL.wrappedValue = $0.first }
            ),
            selectedFilenames: Binding(
                get: {
                    if let value = selectedFilename.wrappedValue {
                        return [value]
                    }
                    return []
                },
                set: { selectedFilename.wrappedValue = $0.first }
            ),
            selectedFileMimeTypes: Binding(
                get: {
                    if let value = selectedFileMimeType.wrappedValue {
                        return [value]
                    }
                    return []
                },
                set: { selectedFileMimeType.wrappedValue = $0.first }
            )
        )
    }

    /// Allows presenting a document picker interface activated by the `isPresented` binding.
    ///
    /// On iOS, this uses `fileImporter` with the supplied content types. On Android, this uses the
    /// `ACTION_OPEN_DOCUMENT` intent. Android returns obfuscated URLs, so selected documents are
    /// copied into the app cache and the copied file URLs are returned together with their filenames and MIME types.
    ///
    /// - Parameters:
    ///   - isPresented: Binding for presentation.
    ///   - allowedContentTypes: The content types that can be selected.
    ///   - allowsMultipleSelection: Whether multiple documents can be selected.
    ///   - selectedDocumentURLs: The URLs of the selected files.
    ///   - selectedFilenames: The filenames of the selected files.
    ///   - selectedFileMimeTypes: The MIME types of the selected files.
    @ViewBuilder public func withDocumentPicker(
        isPresented: Binding<Bool>,
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool,
        selectedDocumentURLs: Binding<[URL]>,
        selectedFilenames: Binding<[String]>,
        selectedFileMimeTypes: Binding<[String]>
    ) -> some View {

        #if SKIP
        let context = LocalContext.current

        let pickDocumentLauncher = rememberLauncherForActivityResult(contract: ActivityResultContracts.OpenDocument()) { uri in
            isPresented.wrappedValue = false
            logger.log(message: "selected document uri: \(uri)")
            if let uri = uri {
                let result = resolvePickedDocument(uri: uri, context: context)
                selectedFilenames.wrappedValue = [result.filename]
                selectedFileMimeTypes.wrappedValue = [result.mimeType ?? ""]
                if let url = result.url {
                    selectedDocumentURLs.wrappedValue = [url]
                } else {
                    selectedDocumentURLs.wrappedValue = []
                }
            }
        }

        let pickDocumentsLauncher = rememberLauncherForActivityResult(contract: ActivityResultContracts.OpenMultipleDocuments()) { uris in
            isPresented.wrappedValue = false
            var urls = [URL]()
            var filenames = [String]()
            var mimeTypes = [String]()

            for uri in uris {
                let result = resolvePickedDocument(uri: uri, context: context, uniqueDestinationName: true)
                if let url = result.url {
                    urls.append(url)
                    filenames.append(result.filename)
                    mimeTypes.append(result.mimeType ?? "")
                }
            }

            selectedDocumentURLs.wrappedValue = urls
            selectedFilenames.wrappedValue = filenames
            selectedFileMimeTypes.wrappedValue = mimeTypes
        }

        return onChange(of: isPresented.wrappedValue) { oldValue, presented in
            if presented == true {
                let parsedMimeTypes: [String] = allowedContentTypes.map { $0.preferredMIMEType ?? "" }
                var types = kotlin.arrayOf("*/*")
                for type in parsedMimeTypes {
                    if type.isEmpty == false {
                        types += type
                    }
                }
                let mimeTypes = types
                isPresented.wrappedValue = false
                if allowsMultipleSelection {
                    pickDocumentsLauncher.launch(mimeTypes)
                } else {
                    pickDocumentLauncher.launch(mimeTypes)
                }
            }
        }

        #else // !SKIP

        fileImporter(
            isPresented: isPresented,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: allowsMultipleSelection
        ) { result in
            switch result {
            case .success(let files):
                var selectedFiles = [URL]()
                for file in files {
                    let gotAccess = file.startAccessingSecurityScopedResource()
                    if !gotAccess { continue }
                    selectedFiles.append(file)
                    file.stopAccessingSecurityScopedResource()
                }
                selectedDocumentURLs.wrappedValue = selectedFiles
                selectedFilenames.wrappedValue = selectedFiles.map { $0.lastPathComponent }
                selectedFileMimeTypes.wrappedValue = Array(repeating: "", count: selectedFiles.count)
                isPresented.wrappedValue = false
            case .failure(let error):
                print(error)
                isPresented.wrappedValue = false
            }
        }
        #endif
    }

    /// Allows presenting a document exporter interface activated by the `isPresented` binding.
    ///
    /// On iOS, this uses `fileExporter` to present the system export dialog. On Android, this uses the
    /// `ACTION_CREATE_DOCUMENT` intent and copies the file to the selected location.
    ///
    /// - Parameters:
    ///   - isPresented: Binding for presentation.
    ///   - contentType: The content type of the exported file.
    ///   - documentURL: The URL of the file to export.
    ///   - onCompletion: Called when the export finishes or fails.
    @ViewBuilder public func withDocumentExporter(
        isPresented: Binding<Bool>,
        contentType: UTType,
        documentURL: URL?,
        onCompletion: ((Result<URL, any Error>) -> Void)? = nil
    ) -> some View {

        #if SKIP
        let context = LocalContext.current
        let mimeType = contentType.preferredMIMEType ?? "*/*"

        let exportDocumentLauncher = rememberLauncherForActivityResult(contract: ActivityResultContracts.CreateDocument(mimeType)) { uri in
            isPresented.wrappedValue = false
            guard let uri = uri, let documentURL = documentURL
            else {
                return
            }

            do {
                guard let outputStream = context.contentResolver.openOutputStream(uri) else {
                    throw CocoaError.error(CocoaError.fileWriteUnknown)
                }

                let inputStream = java.io.FileInputStream(java.io.File(documentURL.path))
                inputStream.copyTo(outputStream)
                inputStream.close()
                outputStream.close()
                onCompletion?(.success(URL(platformValue: java.net.URI.create(uri.toString()))))
            } catch {
                onCompletion?(.failure(error))
            }
        }

        return onChange(of: isPresented.wrappedValue) { oldValue, presented in
            if presented == true {
                isPresented.wrappedValue = false
                exportDocumentLauncher.launch(documentURL?.lastPathComponent ?? "Document")
            }
        }

        #else // !SKIP

        fileExporter(
            isPresented: isPresented,
            document: ExportedDocument(url: documentURL),
            contentType: contentType,
            defaultFilename: documentURL?.lastPathComponent,
            onCompletion: { result in
                onCompletion?(result)
            }
        )
        #endif
    }
}

#if SKIP
private func resolvePickedDocument(
    uri: android.net.Uri,
    context: Context,
    uniqueDestinationName: Bool = false
) -> (url: URL?, filename: String, mimeType: String?) {

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
    let destinationName: String = uniqueDestinationName ? "\(java.util.UUID.randomUUID().toString())-\(safeName)" : safeName

    // java.io.File path avoids Skip URL.appendingPathComponent NPE.
    if let cacheDir = context.cacheDir {
        let destinationFile = java.io.File(cacheDir, destinationName)
        if destinationFile.exists() {
            destinationFile.delete()
        }
        if let inputStream = resolver.openInputStream(uri) {
            let outputStream = java.io.FileOutputStream(destinationFile)
            inputStream.copyTo(outputStream)
            outputStream.close()
            inputStream.close()
            // File.toURI() percent-encodes; raw path would crash java.net.URI.
            return (URL(platformValue: destinationFile.toURI()), safeName, resolvedMime)
        } else {
            return (URL(platformValue: java.net.URI.create(uri.toString())), safeName, resolvedMime)
        }
    } else {
        return (URL(platformValue: java.net.URI.create(uri.toString())), safeName, resolvedMime)
    }
}
#endif

#if !SKIP
private struct ExportedDocument: FileDocument {
    static var readableContentTypes: [UTType] { Self.writableContentTypes }
    static var writableContentTypes: [UTType] { [.data, .plainText, .commaSeparatedText] }

    let url: URL?

    init(url: URL?) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url else {
            return FileWrapper(regularFileWithContents: Data())
        }

        return FileWrapper(regularFileWithContents: try Data(contentsOf: url))
    }
}
#endif
#endif
