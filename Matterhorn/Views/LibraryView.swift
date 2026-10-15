import SwiftUI
import UniformTypeIdentifiers

enum BookSort: String, CaseIterable, Identifiable {
    case title = "Title"
    case bookID = "ID"

    var id: String { rawValue }
}

struct LibraryView: View {
    @EnvironmentObject private var store: BookStore

    @State private var searchText = ""
    @State private var showingImporter = false
    @State private var selectedGroup = "All Books"
    @State private var sortOption: BookSort = .title

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 16)
    ]

    private let groupOptions = ["All Books"] + Book.sampleGroups

    private var filteredBooks: [Book] {
        var books = store.books

        if selectedGroup != "All Books" {
            books = books.filter { $0.group == selectedGroup }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            books = books.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }

        switch sortOption {
        case .title:
            books.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .bookID:
            books.sort { $0.id < $1.id }
        }

        return books
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                if store.books.isEmpty {
                    emptyMessage("No books yet. Tap + to import some.")
                } else if filteredBooks.isEmpty {
                    emptyMessage("No books found")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredBooks) { book in
                                BookCell(book: book, cover: store.coverImage(for: book))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                };
                ToolbarItem(placement:
                    .navigationBarLeading) {
                    Button {
                        showingImporter = true
                    } label : {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always)
            )
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.pdf, .epub],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    store.importBooks(from: urls)
                }
            }
        }
    }

    private func emptyMessage(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var filterBar: some View {
        HStack {
            Menu {
                Picker("Group", selection: $selectedGroup) {
                    ForEach(groupOptions, id: \.self) { group in
                        Text(group).tag(group)
                    }
                }
            } label: {
                filterLabel(selectedGroup)
            }

            Spacer()

            Menu {
                Picker("Order by", selection: $sortOption) {
                    ForEach(BookSort.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                filterLabel("Order by: \(sortOption.rawValue)")
            }
        }
    }

    private func filterLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}

struct BookCell: View {
    let book: Book
    let cover: UIImage?

    private static let palette: [Color] = [
        .blue, .green, .red, .indigo, .orange, .teal, .purple, .brown
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(2 / 3, contentMode: .fit)
                .overlay { coverContent }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 3, y: 2)

            Text(book.title)
                .font(.subheadline)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var coverContent: some View {
        if let cover {
            Image(uiImage: cover)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Self.palette[book.id % Self.palette.count]
                Image(systemName: "book.closed")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(BookStore())
}
