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

### Permissions

In order to access the device's photos or media library, you will need to 
declare the permissions in the app's metadata.

On iOS this can be done by editing the `Darwin/AppName.xcconfig` file and adding the lines:

```
INFOPLIST_KEY_NSCameraUsageDescription = "This app needs to access the camera";
INFOPLIST_KEY_NSPhotoLibraryUsageDescription = "This app needs to access the photo library.";
```

On Android, the `app/src/main/AndroidManifest.xml` file will need to be edited to include 
camera permissions as well as a FileProvider implementation so the camera can share a Uri with the app. For example:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools">
    <!-- features and permissions needed in order to use the camera and read/write photos -->
    <uses-feature
        android:name="android.hardware.camera"
        android:required="false" />
    <uses-feature
        android:name="android.hardware.camera.autofocus"
        android:required="false" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <application
        android:label="${PRODUCT_NAME}"
        android:name=".AndroidAppMain"
        android:supportsRtl="true"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:configChanges="orientation|screenSize|screenLayout|keyboardHidden|mnc|colorMode|density|fontScale|fontWeightAdjustment|keyboard|layoutDirection|locale|mcc|navigation|smallestScreenSize|touchscreen|uiMode"
            android:theme="@style/Theme.AppCompat.DayNight.NoActionBar"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <!-- needed in order for the camera to be able to share the photo with the app -->
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
    </application>
</manifest>
```

In addition to editing the manifest, you must also manually create the `xml/file_paths` reference from the manifest's provider. This is done by creating the folder `Android/app/src/main/res/xml` in your Skip project and adding a file `file_paths.xml` with the following contents:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="my_images" path="." />
    <cache-path name="*" path="." />
</paths>
```

For an example of a properly configured project, see the Photo Chat sample application.

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
