//
//  BookStore.swift
//  Matterhorn
//
//  Created by Emma Plante on 2026-10-15.
//

import Combine
import SwiftUI
import Foundation
import ZIPFoundation

final class BookStore: ObservableObject {
    @Published private(set) var books: [Book] = []

    private let fm = FileManager.default
    private let booksDir: URL
    private let indexURL: URL

    private static let coverExtensions: Set<String> = ["jpg", "jpeg", "png"]

    init() {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        booksDir = docs.appendingPathComponent("Books", isDirectory: true)
        indexURL = support.appendingPathComponent("library.json")

        try? fm.createDirectory(at: booksDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: support, withIntermediateDirectories: true)
        load()
    }

    // MARK: - Import

    /// Imports book folders. Each folder must contain a cover image (jpg/jpeg/png)
    /// and a zip containing staticdata.json. Anything else is skipped.
    func importBooks(from urls: [URL]) {
        for url in urls {
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }

            // Only folders are supported
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            guard isDirectory else {
                print("Skipping \(url.lastPathComponent): not a folder")
                continue
            }

            let destination = uniqueDestination(for: url.lastPathComponent)

            // The coordinator also triggers the download if the folder is only in iCloud
            var coordinationError: NSError?
            var copied = false
            NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readURL in
                do {
                    try fm.copyItem(at: readURL, to: destination)
                    copied = true
                } catch {
                    print("Copy failed for \(url.lastPathComponent): \(error)")
                }
            }
            if let coordinationError {
                print("Coordination failed for \(url.lastPathComponent): \(coordinationError)")
            }
            guard copied else { continue }

            guard let book = importBookFolder(at: destination) else {
                // Don't leave a broken import behind
                try? fm.removeItem(at: destination)
                continue
            }
            books.append(book)
        }
        save()
    }

    /// Parses a copied book folder (cover image + zip containing staticdata.json).
    /// Returns nil if the folder is malformed.
    private func importBookFolder(at destination: URL) -> Book? {
        let children = (try? fm.contentsOfDirectory(
            at: destination,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        // Cover is required: any jpg/jpeg/png directly inside the folder
        guard let coverFile = children.first(where: { Self.coverExtensions.contains($0.pathExtension.lowercased()) }),
              let bookCover = relativeURL(for: coverFile)
        else {
            print("No cover image found in \(destination.lastPathComponent)")
            return nil
        }

        guard let zipURL = children.first(where: { $0.pathExtension.lowercased() == "zip" }) else {
            print("No zip found in \(destination.lastPathComponent)")
            return nil
        }

        let extractDir: URL
        do {
            extractDir = try FileUtils.unzip(from: zipURL, to: destination)
        } catch {
            print("Unzip failed for \(destination.lastPathComponent): \(error)")
            return nil
        }

        // Search recursively in case the zip wraps everything in a top-level folder
        guard let bookDataJson = fm.enumerator(at: extractDir, includingPropertiesForKeys: nil)?
            .compactMap({ $0 as? URL })
            .first(where: { $0.lastPathComponent == "staticdata.json" })
        else {
            print("staticdata.json not found in \(destination.lastPathComponent)")
            return nil
        }

        let bookData: BookData
        do {
            let jsonData = try Data(contentsOf: bookDataJson)
            bookData = try JSONDecoder().decode(BookData.self, from: jsonData)
        } catch {
            print("Failed to decode staticdata.json: \(error)")
            return nil
        }

        return Book(
            id: nextID(),
            fileName: destination.lastPathComponent,
            group: nil,
            cover: bookCover,
            data: bookData,
        )
    }

    private func nextID() -> Int {
        (books.map(\.id).max() ?? 0) + 1
    }

    // MARK: - Covers

    func coverImage(for book: Book) -> UIImage? {
        guard let cover = book.cover else { return nil }
        // Legacy entries saved an absolute file URL; new ones are relative to booksDir.
        let path = cover.isFileURL
            ? cover.path
            : booksDir.appendingPathComponent(cover.relativePath).path
        return UIImage(contentsOfFile: path)
    }

    /// Builds a container-independent URL like "My Book/cover.jpeg",
    /// so it survives app container path changes.
    private func relativeURL(for fileURL: URL) -> URL? {
        let folder = fileURL.deletingLastPathComponent().lastPathComponent
        let allowed = CharacterSet.urlPathAllowed
        guard let encodedFolder = folder.addingPercentEncoding(withAllowedCharacters: allowed),
              let encodedFile = fileURL.lastPathComponent.addingPercentEncoding(withAllowedCharacters: allowed)
        else { return nil }
        return URL(string: "\(encodedFolder)/\(encodedFile)")
    }

    // MARK: - Persistence

    private func uniqueDestination(for name: String) -> URL {
        var dest = booksDir.appendingPathComponent(name, isDirectory: true)
        var n = 2
        while fm.fileExists(atPath: dest.path) {
            dest = booksDir.appendingPathComponent("\(name) \(n)", isDirectory: true)
            n += 1
        }
        return dest
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let saved = try? JSONDecoder().decode([Book].self, from: data) else { return }
        books = saved
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(books) else { return }
        try? data.write(to: indexURL)
    }
}
