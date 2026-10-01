import Foundation

public struct Note: Identifiable, Equatable {
    public var id: String { title.lowercased() }
    public var title: String
    public var body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}

public enum NoteParser {
    /// `[[Target]]` and `[[Target|alias]]` links, in order of appearance, de-duplicated
    /// case-insensitively. Links inside fenced code blocks and inline code are ignored.
    public static func wikiLinks(in text: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for line in proseLines(text) {
            var rest = Substring(line)
            while let first = rest.range(of: "[["), let close = rest.range(of: "]]", range: first.upperBound..<rest.endIndex) {
                // Use the "[[" closest to "]]" so "[[ broken [[Link]]" yields "Link".
                let open = rest.range(of: "[[", options: .backwards, range: first.lowerBound..<close.lowerBound) ?? first
                let inner = rest[open.upperBound..<close.lowerBound]
                let target = (inner.split(separator: "|", maxSplits: 1).first.map(String.init) ?? "")
                    .trimmingCharacters(in: .whitespaces)
                if !target.isEmpty, seen.insert(target.lowercased()).inserted { result.append(target) }
                rest = rest[close.upperBound...]
            }
        }
        return result
    }

    /// `#tags` (letters, digits, `-`, `_`, `/`), lower-cased and sorted. A tag must
    /// start after whitespace or at line start, so URLs with fragments and `##` headings are skipped.
    public static func tags(in text: String) -> [String] {
        var found = Set<String>()
        for line in proseLines(text) {
            let chars = Array(line)
            var i = 0
            while i < chars.count {
                let atBoundary = i == 0 || chars[i - 1].isWhitespace
                if chars[i] == "#", atBoundary, i + 1 < chars.count, chars[i + 1].isLetter {
                    var j = i + 1
                    while j < chars.count, chars[j].isLetter || chars[j].isNumber || "-_/".contains(chars[j]) { j += 1 }
                    found.insert(String(chars[(i + 1)..<j]).lowercased())
                    i = j
                } else {
                    i += 1
                }
            }
        }
        return found.sorted()
    }

    /// Lines outside ``` fences, with `inline code` spans blanked out.
    static func proseLines(_ text: String) -> [String] {
        var inFence = false
        var lines: [String] = []
        for raw in text.components(separatedBy: "\n") {
            if raw.trimmingCharacters(in: .whitespaces).hasPrefix("```") { inFence.toggle(); continue }
            if inFence { continue }
            var line = ""
            var inCode = false
            for ch in raw {
                if ch == "`" { inCode.toggle(); line.append(" "); continue }
                line.append(inCode ? " " : ch)
            }
            lines.append(line)
        }
        return lines
    }
}

public struct KnowledgeBase {
    public private(set) var notes: [String: Note] = [:]

    public init(notes: [Note] = []) {
        for n in notes { upsert(n) }
    }

    public mutating func upsert(_ note: Note) { notes[note.id] = note }

    public func note(titled title: String) -> Note? { notes[title.lowercased()] }

    /// Titles of notes that link to `title`, sorted.
    public func backlinks(to title: String) -> [String] {
        let key = title.lowercased()
        return notes.values
            .filter { note in
                note.id != key && NoteParser.wikiLinks(in: note.body).contains { link in link.lowercased() == key }
            }
            .map(\.title)
            .sorted()
    }

    /// Link targets that have no note yet ("wanted pages"), with how often they are referenced.
    public func unresolvedLinks() -> [(title: String, count: Int)] {
        var counts: [String: (title: String, count: Int)] = [:]
        for note in notes.values {
            for link in NoteParser.wikiLinks(in: note.body) where self.note(titled: link) == nil {
                let k = link.lowercased()
                counts[k] = (counts[k]?.title ?? link, (counts[k]?.count ?? 0) + 1)
            }
        }
        return counts.values.sorted { $0.count != $1.count ? $0.count > $1.count : $0.title < $1.title }
    }

    /// Search ranked by: title match (3) + tag match (2) + body match (1).
    public func search(_ query: String) -> [Note] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        let tag = q.hasPrefix("#") ? String(q.dropFirst()) : q
        let scored: [(Note, Int)] = notes.values.map { n in
            var s = 0
            if n.title.lowercased().contains(q) { s += 3 }
            if NoteParser.tags(in: n.body).contains(tag) { s += 2 }
            if n.body.lowercased().contains(q) { s += 1 }
            return (n, s)
        }
        return scored.filter { $0.1 > 0 }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.title < $1.0.title }
            .map { $0.0 }
    }
}
