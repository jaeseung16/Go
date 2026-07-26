//
//  FileLogHandler.swift
//  GoBoard
//
//  A minimal swift-log `LogHandler` that appends log records to a file.
//

import Foundation
import Logging

/// A `LogHandler` that writes formatted log lines to a file on disk.
///
/// swift-log ships only stdout/stderr handlers, so this fills the gap for
/// routing logs to a dedicated file while keeping the terminal output clean.
public struct FileLogHandler: LogHandler {
    let label: String
    private let fileHandle: FileHandle

    // Serializes writes so concurrent loggers don't interleave partial lines.
    private static let queue = DispatchQueue(label: "com.resonance.GoBotsSupport.FileLogHandler")

    public var logLevel: Logger.Level = .info
    public var metadata: Logger.Metadata = [:]

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    /// Opens (creating if needed) the file at `url` for appending.
    public init(label: String, fileURL url: URL) throws {
        self.label = label

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            fileManager.createFile(atPath: url.path, contents: nil)
        }

        self.fileHandle = try FileHandle(forWritingTo: url)
        try self.fileHandle.seekToEnd()
    }

    public func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        let merged = self.metadata.merging(metadata ?? [:]) { _, new in new }
        let metadataString = merged.isEmpty
            ? ""
            : " " + merged.map { "\($0)=\($1)" }.sorted().joined(separator: " ")

        let line = "[\(level)] \(label):\(metadataString) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        Self.queue.sync {
            self.fileHandle.write(data)
        }
    }
}
