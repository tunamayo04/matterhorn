//
//  ReaderView.swift
//  Matterhorn
//
//  Created by Emma Plante on 2026-10-17.
//

import Foundation
import SwiftUI
import WebKit

struct ReaderView: View {
    @State private var page = WebPage()
    @State private var showBars = false
    @Environment(\.dismiss) private var dismiss
    let book: Book

    init(book: Book = .sample) {
        self.book = book
    }

    var body: some View {
        WebView(page)
            .overlay(alignment: .top) {
                // Invisible tap zone at the top of the screen
                Color.clear
                    .frame(height: 100)
                    .contentShape(Rectangle())
                    .ignoresSafeArea(edges: .top)
                    .onTapGesture {
                        withAnimation { showBars.toggle() }
                    }
            }
            .navigationTitle(book.data.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(showBars ? .visible : .hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .statusBarHidden(!showBars)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .task {
                let html = """
                <!DOCTYPE html>
                <html>
                <head>
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style></style>
                </head>
                <body>\(book.data.elementHtml)</body>
                </html>
                """

                page.load(html: html)
            }
    }
}

extension Book {
    static let sample = Book(
        id: 1, fileName: "test", group: nil, cover: nil,
        data: BookData(
            title: "ReZero",
            styleSheet: "",
            elementHtml: "<p><ruby><rb>縋</rb><rt>すが</rt></ruby>りつくようなスバルの確信は…</p>"
        )
    )
}

#Preview {
    ReaderView()
}
