// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
import Foundation
import SwiftUI

#if SKIP
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.FileProvider
#else
#if os(iOS)
import MessageUI
#endif
#endif

// MARK: - MailComposerOptions

/// Options for composing an email message.
public struct MailComposerOptions {
    /// The primary recipient email addresses.
    public var recipients: [String]
    /// Carbon copy recipients.
    public var ccRecipients: [String]
    /// Blind carbon copy recipients.
    public var bccRecipients: [String]
    /// The email subject line.
    public var subject: String?
    /// The email body text.
    public var body: String?
    /// Whether the body is HTML formatted.
    public var isHTML: Bool
    /// File attachments. Each attachment specifies a URL, MIME type, and filename.
    public var attachments: [MailAttachment]

    public init(
        recipients: [String] = [],
        ccRecipients: [String] = [],
        bccRecipients: [String] = [],
        subject: String? = nil,
        body: String? = nil,
        isHTML: Bool = false,
        attachments: [MailAttachment] = []
    ) {
        self.recipients = recipients
        self.ccRecipients = ccRecipients
        self.bccRecipients = bccRecipients
        self.subject = subject
        self.body = body
        self.isHTML = isHTML
        self.attachments = attachments
    }
}

// MARK: - MailAttachment

/// A file attachment for an email.
public struct MailAttachment: Sendable {
    /// The file URL of the attachment.
    public var url: URL
    /// The MIME type (e.g. `"image/png"`, `"application/pdf"`).
    public var mimeType: String
    /// The filename to display to the recipient.
    public var filename: String

    public init(url: URL, mimeType: String, filename: String) {
        self.url = url
        self.mimeType = mimeType
        self.filename = filename
    }
}

// MARK: - MailComposerResult

/// The result of a mail composition attempt.
public enum MailComposerResult: String, Sendable {
    /// The email was sent successfully.
    case sent
    /// The email was saved as a draft.
    case saved
    /// The user cancelled the composition.
    case cancelled
    /// The composition failed.
    case failed
    /// The result is unknown (Android always returns this since the intent doesn't report back).
    case unknown
}

// MARK: - MailComposer Availability

/// Utility for checking mail composition availability.
public enum MailComposer {
    /// Whether the device can send email.
    ///
    /// On iOS, this checks `MFMailComposeViewController.canSendMail()`.
    /// On Android, this checks whether an app can handle `ACTION_SENDTO` with a `mailto:` URI.
    public static func canSendMail() -> Bool {
        #if SKIP
        let context = ProcessInfo.processInfo.androidContext
        let intent = Intent(Intent.ACTION_SENDTO)
        intent.setData(Uri.parse("mailto:"))
        return intent.resolveActivity(context.getPackageManager()) != nil
        #elseif os(iOS)
        return MFMailComposeViewController.canSendMail()
        #else
        return false
        #endif
    }
}

// MARK: - View Extension

extension View {
    /// Present an email composition interface.
    ///
    /// On iOS, this presents an `MFMailComposeViewController` in a sheet.
    /// On Android, this launches an `ACTION_SENDTO` intent to the user's email app.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls whether the composer is shown.
    ///   - options: The email composition options (recipients, subject, body, attachments).
    ///   - onComplete: Called when the composition finishes, with the result status.
    @ViewBuilder public func withMailComposer(
        isPresented: Binding<Bool>,
        options: MailComposerOptions = MailComposerOptions(),
        onComplete: ((MailComposerResult) -> Void)? = nil
    ) -> some View {
        #if SKIP
        let context = LocalContext.current

        return onChange(of: isPresented.wrappedValue) { oldValue, presented in
            if presented == true {
                isPresented.wrappedValue = false
                launchMailIntent(context: context, options: options)
                onComplete?(.unknown)
            }
        }
        #else // !SKIP
        #if os(iOS)
        sheet(isPresented: isPresented) {
            MailComposerRepresentable(
                options: options,
                isPresented: isPresented,
                onComplete: onComplete
            )
        }
        #else
        self
        #endif
        #endif
    }
}

// MARK: - Android Intent

#if SKIP
private func launchMailIntent(context: Context, options: MailComposerOptions) {
    if options.attachments.isEmpty {
        // Simple mailto: intent for text-only emails
        var uriString = "mailto:"
        if !options.recipients.isEmpty {
            uriString += options.recipients.joined(separator: ",")
        }
        var params: [String] = []
        if let subject = options.subject {
            params.append("subject=" + Uri.encode(subject))
        }
        if let body = options.body {
            params.append("body=" + Uri.encode(body))
        }
        if !options.ccRecipients.isEmpty {
            params.append("cc=" + options.ccRecipients.joined(separator: ","))
        }
        if !options.bccRecipients.isEmpty {
            params.append("bcc=" + options.bccRecipients.joined(separator: ","))
        }
        if !params.isEmpty {
            uriString += "?" + params.joined(separator: "&")
        }

        let intent = Intent(Intent.ACTION_SENDTO)
        intent.setData(Uri.parse(uriString))
        context.startActivity(intent)
    } else {
        // ACTION_SEND or ACTION_SEND_MULTIPLE for attachments
        let intent: Intent
        if options.attachments.count == 1 {
            intent = Intent(Intent.ACTION_SEND)
            intent.setType(options.attachments[0].mimeType)
            let fileUri = Uri.parse(options.attachments[0].url.absoluteString)
            intent.putExtra(Intent.EXTRA_STREAM, fileUri)
        } else {
            intent = Intent(Intent.ACTION_SEND_MULTIPLE)
            intent.setType("message/rfc822")
            // SKIP INSERT: val uris = ArrayList<Uri>()
            for attachment in options.attachments {
                let fileUri = Uri.parse(attachment.url.absoluteString)
                uris.add(fileUri)
            }
            intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
        }

        if !options.recipients.isEmpty {
            intent.putExtra(Intent.EXTRA_EMAIL, options.recipients.toList().toTypedArray())
        }
        if !options.ccRecipients.isEmpty {
            intent.putExtra(Intent.EXTRA_CC, options.ccRecipients.toList().toTypedArray())
        }
        if !options.bccRecipients.isEmpty {
            intent.putExtra(Intent.EXTRA_BCC, options.bccRecipients.toList().toTypedArray())
        }
        if let subject = options.subject {
            intent.putExtra(Intent.EXTRA_SUBJECT, subject)
        }
        if let body = options.body {
            if options.isHTML {
                intent.putExtra(Intent.EXTRA_TEXT, android.text.Html.fromHtml(body, android.text.Html.FROM_HTML_MODE_COMPACT))
            } else {
                intent.putExtra(Intent.EXTRA_TEXT, body)
            }
        }

        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        context.startActivity(Intent.createChooser(intent, "Send Email"))
    }
}
#endif

// MARK: - iOS MFMailComposeViewController

#if !SKIP
#if os(iOS)

struct MailComposerRepresentable: UIViewControllerRepresentable {
    let options: MailComposerOptions
    @Binding var isPresented: Bool
    let onComplete: ((MailComposerResult) -> Void)?

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator

        if !options.recipients.isEmpty {
            vc.setToRecipients(options.recipients)
        }
        if !options.ccRecipients.isEmpty {
            vc.setCcRecipients(options.ccRecipients)
        }
        if !options.bccRecipients.isEmpty {
            vc.setBccRecipients(options.bccRecipients)
        }
        if let subject = options.subject {
            vc.setSubject(subject)
        }
        if let body = options.body {
            vc.setMessageBody(body, isHTML: options.isHTML)
        }

        for attachment in options.attachments {
            if let data = try? Data(contentsOf: attachment.url) {
                vc.addAttachmentData(data, mimeType: attachment.mimeType, fileName: attachment.filename)
            }
        }

        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        let parent: MailComposerRepresentable

        init(parent: MailComposerRepresentable) {
            self.parent = parent
        }

        @MainActor func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            let mapped: MailComposerResult
            switch result {
            case .sent: mapped = .sent
            case .saved: mapped = .saved
            case .cancelled: mapped = .cancelled
            case .failed: mapped = .failed
            @unknown default: mapped = .unknown
            }
            parent.onComplete?(mapped)
            parent.isPresented = false
        }
    }
}

#endif
#endif

#endif
