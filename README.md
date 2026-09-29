# LexiLens ⚖️

An iOS application that reads a contract, strips personal data from it on the device, and returns a structured risk report — summary, threats, and critical dates — for people who do not speak legal language.

## 📌 Executive Summary

LexiLens was built around a trust problem rather than a parsing problem. Analysing a contract well requires a large language model; handing a contract to a third-party API means handing over names, national ID numbers, bank accounts and phone numbers along with it. The application resolves this by placing a redaction stage **before** the network boundary: the document is ingested through one of four input paths, personal data is detected and replaced on the device, the user reviews and corrects the redaction by hand, and only then does the text leave the phone. The model never receives what it does not need. The report that comes back is constrained to a fixed schema, persisted locally with Core Data, and exportable as a PDF.

## 🛠 Technical Architecture & Core Competencies

**Four Independent Ingestion Paths:** A contract can enter the application through `VNDocumentCameraViewController` (multi-page document scanning), `VNRecognizeTextRequest` OCR over a photo from the library, `PDFKit` page-by-page text extraction, or direct paste. All four converge on a single string, so every downstream stage — redaction, analysis, storage, export — is written once rather than per input type. OCR runs on a background quality-of-service queue with Turkish and English recognition enabled.

**Two-Layer On-Device Redaction:** The privacy stage combines two complementary detectors. `NSRegularExpression` handles structurally predictable data — email addresses, URLs, IBANs, payment card numbers, identification numbers and phone numbers — with patterns built over UTF-16 ranges so that emoji and multi-byte characters cannot crash or misalign the scan. Apple's `NaturalLanguage` framework then runs named-entity recognition through `NLTagger` to catch what regular expressions structurally cannot: person and organisation names. Replacements are applied **in reverse order**, from the end of the string backwards, because rewriting an earlier range invalidates every index that follows it.

**Human-in-the-Loop Correction:** Automatic detection is treated as a first pass, not a guarantee. The review screen replaces the system predictive bar with a custom `inputAccessoryView` — a horizontally scrollable toolbar inside a `UIScrollView` and `UIStackView` — offering one-tap `[SECRET]`, `[PERSON]`, `[ORGANIZATION]` and `[ID NUMBER]` masks for any selected text. The design assumption is that a redaction tool which cannot be corrected by the user is a redaction tool that will eventually be wrong silently.

**Schema-Locked Model Output:** A language model returns prose by default, which is unusable as an application data source. The system prompt binds the response to a fixed JSON contract — `riskLevel`, `summary`, `threats`, `keyDates` — and explicitly instructs the model to treat redaction placeholders as intentional rather than as contract deficiencies. Parsing is defensive: the response is decoded through a typed `Codable` layer, markdown code fences are stripped if the model emits them anyway, and any failure surfaces as a typed error instead of a blank screen. HTTP status codes are mapped to distinct messages, so an invalid key, a rate limit and a server outage are not reported as the same failure.

**Local Persistence:** Reports are stored with Core Data through a `HistoryManager` singleton. The variable-length `threats` and `keyDates` arrays are encoded to JSON `Data` rather than modelled as separate entities, keeping the schema flat for a list that is only ever read as a whole. The history screen colours entries by risk level, supports swipe-to-delete, and renders a dedicated empty state.

**Programmatic Report UI and PDF Export:** The results screen is built entirely in code — cards, constraints and risk-level colouring — with no storyboard layout. Export composes an HTML document from the report and renders it through `UIMarkupTextPrintFormatter` and `UIPrintPageRenderer` into a paginated PDF written with `UIGraphicsBeginPDFContextToData`, then hands it to `UIActivityViewController` for sharing.

### Project Structure

```
LexiLens/
├── Controller/   Dashboard, Scanner, Text, PrivacyReview, Processing, Results, History
├── Model/        ReportManager (Claude API), ReportData, HistoryManager (Core Data), PDFGenerator
├── View/         Main.storyboard
└── Secrets.swift (untracked — see Setup)
```

Architecture is MVC with the delegate pattern carrying network results back to the presenting controller; the delegate protocol is constrained to `AnyObject` and held weakly so the controller and the networking layer do not retain each other.

## 👨‍💻 Developer Insight

The hardest decision in this project was not technical but architectural: **where to draw the privacy boundary.** Redacting after the response arrives would have been far simpler to implement and completely worthless — the data would already have left the device. Placing redaction before the network call meant accepting that detection happens without any server-side model, using only what the phone can run, and that it will therefore be imperfect. That trade-off is why the manual masking toolbar exists. The system is designed around the assumption that automatic detection will miss things, rather than around the hope that it will not.

The second problem was making a probabilistic system behave like an API. A language model asked for a contract analysis will happily return a friendly paragraph, a markdown-wrapped JSON block, or a JSON object with fields it invented — none of which a `Codable` struct can decode. The solution was to treat the prompt as an interface definition rather than a request: a fixed schema, an explicit prohibition on markdown fences and greetings, and an instruction that redaction placeholders are expected input rather than missing data. The parser then assumes the contract will occasionally be broken anyway and strips code fences before decoding. Treating the model's output as untrusted, exactly like any other external response, turned out to be the difference between a demo and something that could survive real use.

## Setup

Create `LexiLens/Secrets.swift` with your Anthropic API key:

```swift
import Foundation

enum Secrets {
    static let anthropicAPIKey = "sk-ant-..."
}
```

This file is listed in `.gitignore` and is not part of the repository.
