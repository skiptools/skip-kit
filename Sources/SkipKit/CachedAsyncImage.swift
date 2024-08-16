// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation
import SwiftUI

/// A view that asynchronously loads, cache and displays an image.
///
/// This view uses a custom default
/// <doc://com.apple.documentation/documentation/Foundation/URLSession>
/// instance to load an image from the specified URL, and then display it.
/// For example, you can display an icon that's stored on a server:
///
///     CachedAsyncImage(url: URL(string: "https://example.com/icon.png"))
///         .frame(width: 200, height: 200)
///
/// Until the image loads, the view displays a standard placeholder that
/// fills the available space. After the load completes successfully, the view
/// updates to display the image. In the example above, the icon is smaller
/// than the frame, and so appears smaller than the placeholder.
///
/// ![A diagram that shows a grey box on the left, the SwiftUI icon on the
/// right, and an arrow pointing from the first to the second. The icon
/// is about half the size of the grey box.](AsyncImage-1)
///
/// You can specify a custom placeholder using
/// ``init(url:urlCache:scale:content:placeholder:)``. With this initializer, you can
/// also use the `content` parameter to manipulate the loaded image.
/// For example, you can add a modifier to make the loaded image resizable:
///
///     CachedAsyncImage(url: URL(string: "https://example.com/icon.png")) { image in
///         image.resizable()
///     } placeholder: {
///         ProgressView()
///     }
///     .frame(width: 50, height: 50)
///
/// For this example, SwiftUI shows a ``ProgressView`` first, and then the
/// image scaled to fit in the specified frame:
///
/// ![A diagram that shows a progress view on the left, the SwiftUI icon on the
/// right, and an arrow pointing from the first to the second.](AsyncImage-2)
///
/// > Important: You can't apply image-specific modifiers, like
/// ``Image/resizable(capInsets:resizingMode:)``, directly to a `CachedAsyncImage`.
/// Instead, apply them to the ``Image`` instance that your `content`
/// closure gets when defining the view's appearance.
///
/// To gain more control over the loading process, use the
/// ``init(url:urlCache:scale:transaction:content:)`` initializer, which takes a
/// `content` closure that receives an ``AsyncImagePhase`` to indicate
/// the state of the loading operation. Return a view that's appropriate
/// for the current phase:
///
///     CachedAsyncImage(url: URL(string: "https://example.com/icon.png")) { phase in
///         if let image = phase.image {
///             image // Displays the loaded image.
///         } else if phase.error != nil {
///             Color.red // Indicates an error.
///         } else {
///             Color.blue // Acts as a placeholder.
///         }
///     }
///
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CachedAsyncImage<Content>: View where Content: View {
    public var body: some View {
        EmptyView() // TODO
    }
}

