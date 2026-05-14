//
//  ExportService.swift
//  MyRecaLLM
//

import Foundation

// MARK: - Envelope

enum RecallExportKind: String, Codable {
    case category
    case topic
    case subTopic
}

struct RecallExportEnvelope<T: Codable>: Codable {
    var version: Int
    var exportedAt: Date
    var kind: RecallExportKind
    var item: T
}

// MARK: - Export service

enum ExportService {
    static let envelopeVersion = 1

    static func encode(category: Category) throws -> Data {
        let envelope = RecallExportEnvelope(
            version: envelopeVersion,
            exportedAt: Date(),
            kind: .category,
            item: category
        )
        return try makeEncoder().encode(envelope)
    }

    static func encode(topic: Topic) throws -> Data {
        let envelope = RecallExportEnvelope(
            version: envelopeVersion,
            exportedAt: Date(),
            kind: .topic,
            item: topic
        )
        return try makeEncoder().encode(envelope)
    }

    static func encode(subTopic: SubTopic) throws -> Data {
        let envelope = RecallExportEnvelope(
            version: envelopeVersion,
            exportedAt: Date(),
            kind: .subTopic,
            item: subTopic
        )
        return try makeEncoder().encode(envelope)
    }

    static func defaultFilename(kind: RecallExportKind, title: String) -> String {
        let dateString = isoDateFormatter.string(from: Date())
        let slug = slugify(title)
        return "MyRecaLLM-\(kind.rawValue)-\(slug)-\(dateString).json"
    }

    // MARK: - Shared decoder (used by tests and by the future importer)

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - Private helpers

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter
    }()

    private static func slugify(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Untitled" }
        let allowed = CharacterSet.alphanumerics
        var result = ""
        var lastWasDash = false
        for scalar in trimmed.unicodeScalars {
            if allowed.contains(scalar) {
                result.unicodeScalars.append(scalar)
                lastWasDash = false
            } else if !lastWasDash {
                result.append("-")
                lastWasDash = true
            }
        }
        let cleaned = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return cleaned.isEmpty ? "Untitled" : cleaned
    }
}

// MARK: - File store

enum RecallFileStore {
    enum StoreError: LocalizedError {
        case noDocumentsDirectory

        var errorDescription: String? {
            switch self {
            case .noDocumentsDirectory: "Could not locate the Documents directory."
            }
        }
    }

    static let directoryName = "MyRecaLLM"

    /// Returns `~/Documents/MyRecaLLM/`, creating it if missing.
    static func exportDirectory() throws -> URL {
        let fileManager = FileManager.default
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw StoreError.noDocumentsDirectory
        }
        let directory = documents.appending(path: directoryName, directoryHint: .isDirectory)
        if !fileManager.fileExists(atPath: directory.path()) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        print(directory.path())
        return directory
    }

    /// Writes `data` atomically to the export directory. If a file with the same
    /// name already exists, appends ` (2)`, ` (3)`, … before the extension.
    @discardableResult
    static func write(_ data: Data, filename: String) throws -> URL {
        let directory = try exportDirectory()
        let target = uniqueURL(in: directory, filename: filename)
        try data.write(to: target, options: .atomic)
        return target
    }

    /// Lists every `.json` file currently in the export directory.
    static func listExportedFiles() throws -> [URL] {
        let directory = try exportDirectory()
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        return contents
            .filter { $0.pathExtension.lowercased() == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func uniqueURL(in directory: URL, filename: String) -> URL {
        let initial = directory.appending(path: filename)
        guard FileManager.default.fileExists(atPath: initial.path()) else { return initial }

        let nsName = filename as NSString
        let base = nsName.deletingPathExtension
        let ext = nsName.pathExtension

        var counter = 2
        while true {
            let candidateName: String
            if ext.isEmpty {
                candidateName = "\(base) (\(counter))"
            } else {
                candidateName = "\(base) (\(counter)).\(ext)"
            }
            let candidate = directory.appending(path: candidateName)
            if !FileManager.default.fileExists(atPath: candidate.path()) {
                return candidate
            }
            counter += 1
        }
    }
}
