//
//  BookStore.swift
//  Matterhorn
//
//  Created by Emma Plante on 2026-10-15.
//

import Combine
import SwiftUI
import PDFKit

final class BookStore: ObservableObject {
    @Published private(set) var books: [Book] = []

    private let fm = FileManager.default
    private let booksDir: URL
    private let coversDir: URL
    private let indexURL: URL

    init() {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        booksDir = docs.appendingPathComponent("Books", isDirectory: true)
        coversDir = support.appendingPathComponent("Covers", isDirectory: true)
        indexURL = support.appendingPathComponent("library.json")

        try? fm.createDirectory(at: booksDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: coversDir, withIntermediateDirectories: true)
        load()
    }

    // MARK: - Import

    func importBooks(from urls: [URL]) {
        for url in urls {
            // Needed for files outside the app's sandbox (iCloud, Files, etc.)
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }

            let destination = uniqueDestination(for: url.lastPathComponent)

            // The coordinator also triggers the download if the file is only in iCloud
            var coordinationError: NSError?
            var copied = false
            NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readURL in
                copied = (try? fm.copyItem(at: readURL, to: destination)) != nil
            }
            guard copied else { continue }

            let book = Book(
                id: (books.map(\.id).max() ?? 0) + 1,
                title: url.deletingPathExtension().lastPathComponent,
                fileName: destination.lastPathComponent,
                group: nil
            )
            makeCover(for: book)
            books.append(book)
        }
        save()
    }

    // MARK: - Covers

    func coverImage(for book: Book) -> UIImage? {
        UIImage(contentsOfFile: coverURL(for: book).path)
    }

    private func coverURL(for book: Book) -> URL {
        coversDir.appendingPathComponent("\(book.id).png")
    }

    private func makeCover(for book: Book) {
        let fileURL = booksDir.appendingPathComponent(book.fileName)
        guard fileURL.pathExtension.lowercased() == "pdf",
              let page = PDFDocument(url: fileURL)?.page(at: 0) else { return }

        let image = page.thumbnail(of: CGSize(width: 400, height: 600), for: .mediaBox)
        try? image.pngData()?.write(to: coverURL(for: book))
    }

    // MARK: - Persistence

    private func uniqueDestination(for name: String) -> URL {
        var dest = booksDir.appendingPathComponent(name)
        let base = dest.deletingPathExtension().lastPathComponent
        let ext = dest.pathExtension
        var n = 2
        while fm.fileExists(atPath: dest.path) {
            dest = booksDir.appendingPathComponent("\(base) \(n)").appendingPathExtension(ext)
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
