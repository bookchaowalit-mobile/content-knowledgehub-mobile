import XCTest
@testable import KnowledgehubCore

final class NotesTests: XCTestCase {
    func testExtractsWikiLinks() {
        let text = """
        See [[Swift]] and [[swift|the language]], also [[ Kotlin Multiplatform ]].
        `[[NotALink]]` in code
        ```
        [[AlsoNotALink]]
        ```
        Broken [[ and [[]] ignored, nested [[ junk [[Gradle]]
        """
        XCTAssertEqual(NoteParser.wikiLinks(in: text), ["Swift", "Kotlin Multiplatform", "Gradle"])
    }

    func testExtractsTags() {
        let text = "#iOS notes about #swift-ui and #ios\n## Heading\nhttps://x.io/#anchor #2024 #a/b"
        XCTAssertEqual(NoteParser.tags(in: text), ["a/b", "ios", "swift-ui"])
    }

    private var kb: KnowledgeBase {
        KnowledgeBase(notes: [
            Note(title: "Swift", body: "Language by Apple. #lang Related: [[SwiftUI]], [[Concurrency]]"),
            Note(title: "SwiftUI", body: "Declarative UI built on [[Swift]]. #ui"),
            Note(title: "Kotlin", body: "Also a #lang. Compare with [[swift]]. See [[Concurrency]] and [[Gradle]]."),
        ])
    }

    func testBacklinksAreCaseInsensitive() {
        XCTAssertEqual(kb.backlinks(to: "Swift"), ["Kotlin", "SwiftUI"])
        XCTAssertEqual(kb.backlinks(to: "Gradle"), ["Kotlin"])
        XCTAssertEqual(kb.backlinks(to: "Nothing"), [])
    }

    func testUnresolvedLinks() {
        let wanted = kb.unresolvedLinks()
        XCTAssertEqual(wanted.map { $0.title }, ["Concurrency", "Gradle"])
        XCTAssertEqual(wanted.map { $0.count }, [2, 1])
    }

    func testSearchRanking() {
        XCTAssertEqual(kb.search("swift").map(\.title), ["Swift", "SwiftUI", "Kotlin"])
        XCTAssertEqual(kb.search("#lang").map(\.title), ["Kotlin", "Swift"])
        XCTAssertTrue(kb.search(" ").isEmpty)
    }

    func testUpsertReplacesByTitleIgnoringCase() {
        var base = kb
        base.upsert(Note(title: "swift", body: "replaced"))
        XCTAssertEqual(base.notes.count, 3)
        XCTAssertEqual(base.note(titled: "SWIFT")?.body, "replaced")
    }
}
