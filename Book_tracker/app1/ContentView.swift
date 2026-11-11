import SwiftUI

struct Book: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var author: String
    var totalPages: Int
    var currentPage: Int

    init(id: UUID = UUID(), title: String, author: String, totalPages: Int, currentPage: Int = 0) {
        self.id = id
        self.title = title
        self.author = author
        self.totalPages = max(0, totalPages)
        self.currentPage = min(max(0, currentPage), self.totalPages)
    }

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }

    var remainingPages: Int { max(0, totalPages - currentPage) }

    mutating func updateCurrentPage(_ page: Int) {
        currentPage = min(max(0, page), totalPages)
    }
}

@Observable
final class LibraryStore {
    var books: [Book] = [
        Book(title: "데이터베이스 시스템", author: "김OO", totalPages: 650),
        Book(title: "기계학습 입문", author: "이OO", totalPages: 520),
        Book(title: "딥러닝 이론과 응용", author: "박OO", totalPages: 780),
        Book(title: "객체지향 프로그래밍", author: "최OO", totalPages: 430)
    ]

    func addBook(title: String, author: String, totalPages: Int) {
        let pages = max(0, totalPages)
        let book = Book(title: title, author: author, totalPages: pages)
        books.append(book)
    }

    func updateProgress(for book: Book, to page: Int) {
        guard let idx = books.firstIndex(of: book) else { return }
        var copy = books[idx]
        copy.updateCurrentPage(page)
        books[idx] = copy
    }
    
    func removeBook(_ book: Book) {
        books.removeAll { $0.id == book.id }
    }
}

struct ContentView: View {
    @State private var store = LibraryStore()
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if store.books.isEmpty {
                    ContentUnavailableView("등록된 서적이 없습니다", systemImage: "book", description: Text("우측 상단 + 버튼으로 추가하세요"))
                } else {
                    List {
                        Section(header: summaryHeader) {
                            ForEach(store.books) { book in
                                HStack(spacing: 0) {
                                    BookRow(book: binding(for: book))
                                    Spacer(minLength: 0)
                                    Button(role: .destructive) {
                                        store.removeBook(book)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .padding(.vertical, 18)
                                            .padding(.horizontal, 10)
                                    }
                                    .accessibilityLabel("도서 삭제")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("독서 기록기 앱")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("서적 추가")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddBookView { title, author, pages in
                    store.addBook(title: title, author: author, totalPages: pages)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var summaryHeader: some View {
        let totalPages = store.books.reduce(0) { $0 + $1.totalPages }
        let totalCurrent = store.books.reduce(0) { $0 + $1.currentPage }
        let overallProgress = totalPages > 0 ? Double(totalCurrent) / Double(totalPages) : 0
        return VStack(alignment: .leading, spacing: 8) {
            Text("전체 진행률")
                .font(.headline)
            ProgressView(value: overallProgress)
                .tint(.blue)
            HStack {
                Text("읽은 페이지: \(totalCurrent)")
                Spacer()
                Text("총 페이지: \(totalPages)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func binding(for book: Book) -> Binding<Book> {
        guard let idx = store.books.firstIndex(of: book) else {
            return .constant(book)
        }
        return $store.books[idx]
    }
}

struct BookRow: View {
    @Binding var book: Book
    @State private var inputPage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(book.title).font(.headline)
                    Text(book.author).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(book.currentPage)/\(book.totalPages)")
                    .monospacedDigit()
                    .font(.subheadline)
            }

            HStack(alignment: .center, spacing: 12) {
                ProgressView(value: book.progress) {
                    Text("")
                }
                .tint(.green)
                .frame(maxWidth: 150)
                Text("\(Int(book.progress * 100))% 완료")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
            }

            if book.totalPages == 0 {
                Text("총 페이지 수가 설정되지 않았습니다")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack(spacing: 8) {
                TextField("현재 페이지", text: $inputPage)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 80)

                Button("업데이트") {
                    let page = Int(inputPage) ?? book.currentPage
                    book.updateCurrentPage(page)
                    inputPage = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(book.totalPages == 0)

                Spacer()

                HStack(spacing: 0) {
                    Button {
                        book.updateCurrentPage(book.currentPage - 1)
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 32, height: 28)
                    }
                    .buttonStyle(.bordered)
                    .disabled(book.currentPage <= 0 || book.totalPages == 0)

                    Divider().frame(height: 20)

                    Button {
                        book.updateCurrentPage(book.currentPage + 1)
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 32, height: 28)
                    }
                    .buttonStyle(.bordered)
                    .disabled(book.currentPage >= book.totalPages || book.totalPages == 0)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .font(.caption)

            Text("남은 페이지: \(book.remainingPages)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .onAppear {
            inputPage = "\(book.currentPage)"
        }
    }
}

struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var author: String = ""
    @State private var pages: String = ""

    var onAdd: (String, String, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("서적 정보") {
                    TextField("제목", text: $title)
                    TextField("저자", text: $author)
                    TextField("총 페이지", text: $pages)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("서적 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let total = Int(pages) ?? 0
                        onAdd(title, author, max(0, total))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              Int(pages) ?? 0 <= 0)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

