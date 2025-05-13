# SkipKit

This [Skip Lite](https://skip.tools) module enhances the `SkipUI` package with commonly-used features,
such as a permission checker and a picker for photos and other media.

## PermissionManager

The `PermissionManager` provides the ability to request device permissions.

For example:

```swift
import SkipKit
import SkipDevice

let locationProvider = LocationProvider()

if await PermissionManager.requestPermission(.ACCESS_FINE_LOCATION) == true {
    let location = try await locationProvider.fetchCurrentLocation()
}
```

In addition to symbolic constants, there are also functions for requesting
specific permissions with various parameters:

```swift
static func queryLocationPermission(precise: Bool, always: Bool) -> PermissionAuthorization
static func requestLocationPermission(precise: Bool, always: Bool) async -> PermissionAuthorization

static func queryPostNotificationPermission() async -> PermissionAuthorization
static func requestPostNotificationPermission(alert: Bool = true, sound: Bool = true, badge: Bool = true) async throws -> PermissionAuthorization

static func queryCameraPermission() -> PermissionAuthorization
static func requestCameraPermission() async -> PermissionAuthorization

static func queryRecordAudioPermission() -> PermissionAuthorization
static func requestRecordAudioPermission() async -> PermissionAuthorization

static func queryContactsPermission(readWrite: Bool) -> PermissionAuthorization
static func requestContactsPermission(readWrite: Bool) async throws -> PermissionAuthorization

static func queryCalendarPermission(readWrite: Bool) -> PermissionAuthorization
static func requestCalendarPermission(readWrite: Bool) async throws -> PermissionAuthorization

static func queryReminderPermission(readWrite: Bool) -> PermissionAuthorization
static func requestReminderPermission(readWrite: Bool) async throws -> PermissionAuthorization

static func queryPhotoLibraryPermission(readWrite: Bool) -> PermissionAuthorization
static func requestPhotoLibraryPermission(readWrite: Bool) async -> PermissionAuthorization
```

To request an arbitrary Android permission for which there may be no
iOS equivalent, you can pass the string literal. For a list of common permission literals, see
[https://developer.android.com/reference/android/Manifest.permission](https://developer.android.com/reference/android/Manifest.permission).

For example, to request the SMS sending permission:

```swift
let granted = await PermissionManager.requestPermission("android.permission.SEND_SMS")
```

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

### Camera and Media Permissions

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

## Contributing

We welcome contributions to this package in the form of enhancements and bug fixes.

The general flow for contributing to this and any other Skip package is:

1. Fork this repository and enable actions from the "Actions" tab
2. Check out your fork locally
3. When developing alongside a Skip app, add the package to a [shared workspace](https://skip.tools/docs/contributing) to see your changes incorporated in the app
4. Push your changes to your fork and ensure the CI checks all pass in the Actions tab
5. Add your name to the Skip [Contributor Agreement](https://github.com/skiptools/clabot-config)
6. Open a Pull Request from your fork with a description of your changes

## License

This software is licensed under the
[GNU Lesser General Public License v3.0](https://spdx.org/licenses/LGPL-3.0-only.html),
with the following
[linking exception](https://spdx.org/licenses/LGPL-3.0-linking-exception.html)
to clarify that distribution to restricted environments (e.g., app stores)
is permitted:

> This software is licensed under the LGPL3, included below.
> As a special exception to the GNU Lesser General Public License version 3
> ("LGPL3"), the copyright holders of this Library give you permission to
> convey to a third party a Combined Work that links statically or dynamically
> to this Library without providing any Minimal Corresponding Source or
> Minimal Application Code as set out in 4d or providing the installation
> information set out in section 4e, provided that you comply with the other
> provisions of LGPL3 and provided that you meet, for the Application the
> terms and conditions of the license(s) which apply to the Application.
> Except as stated in this special exception, the provisions of LGPL3 will
> continue to comply in full to this Library. If you modify this Library, you
> may apply this exception to your version of this Library, but you are not
> obliged to do so. If you do not wish to do so, delete this exception
> statement from your version. This exception does not (and cannot) modify any
> license terms which apply to the Application, with which you must still
> comply.

