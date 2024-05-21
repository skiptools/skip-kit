# SkipKit

This Skip module enhances the `SkipUI` package with commonly-used features.

## Camera and Media selection

The `View.withMediaPicker(type:isPresented:selectedImageURL:)` extension function
can be used to enable the acquisition of an image from either the system camera 
or the user's media library. 

On iOS, this camera selector will be presented in a `fullScreenCover` view, 
whereas the media library browser will be presented in a `sheet`. In both cases,
a standad `UIImagePickerController` will be used to acquire the media.

On Android, the camera and library browser will be activated through 
an Intent after querying for the necessary permissions.

Following is an example of implementing a media selection button that 
will bring up the system user interface.

```swift
import SkipKit

/// A button that enables the selection of media from the library or the taking of a photo.
///
/// The selected/captured image will be communicated through the `selectedImageURL` binding,
/// which can be observed with `onChange` to perform an action when the media URL is acquired.
struct MediaButton : View {
    let type: MediaPickerType // either .camera or .library
    @Binding var selectedImageURL: URL?
    @State private var showPicker = false

    var body: some View {
        Button(type == .camera ? "Take Photo" : "Select Media") {
            showPicker = true // activate the media picker
        }
        .withMediaPicker(type: .camera, isPresented: $showPicker, selectedImageURL: $selectedImageURL)
    }
}
```


## Building

This project is a free Swift Package Manager module that uses the
[Skip](https://skip.tools) plugin to transpile Swift into Kotlin.

Building the module requires that Skip be installed using 
[Homebrew](https://brew.sh) with `brew install skiptools/skip/skip`.
This will also install the necessary build prerequisites:
Kotlin, Gradle, and the Android build tools.

## Testing

The module can be tested using the standard `swift test` command
or by running the test target for the macOS destination in Xcode,
which will run the Swift tests as well as the transpiled
Kotlin JUnit tests in the Robolectric Android simulation environment.

Parity testing can be performed with `skip test`,
which will output a table of the test results for both platforms.
