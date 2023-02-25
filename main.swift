import Foundation

struct Destination {
    let name: String
    let mood: String
    let postcard: String
    let packing: [(String, Int)]
}

struct LCG {
    private var state: UInt64
    init(seed: Int) { state = UInt64(bitPattern: Int64(seed)) &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next(_ upperBound: Int) -> Int {
        state = state &* 2862933555777941757 &+ 3037000493
        return Int((state >> 33) % UInt64(upperBound))
    }
}

let destinations = [
    Destination(name: "Marmalade Moon", mood: "orange skies and zero meetings", postcard: "The moon is technically cheese here, but nobody has filed paperwork.", packing: [("soft socks", 1), ("citrus notebook", 1)]),
    Destination(name: "The Quiet Archipelago", mood: "islands that whisper back", postcard: "A ferry waved. You waved. This counted as the evening's big event.", packing: [("earplugs", 1), ("tiny binoculars", 2)]),
    Destination(name: "Pajama Junction", mood: "platforms, naps, perfect announcements", postcard: "Your train arrived precisely when you stopped checking the clock.", packing: [("sleep mask", 1), ("emergency cocoa", 2)]),
    Destination(name: "Cloudberry Heights", mood: "high altitude, low expectations", postcard: "You mailed yourself a postcard and admired the efficiency.", packing: [("wool scarf", 2), ("pencil", 1)]),
    Destination(name: "Hotel Yesterday", mood: "retro wallpaper and tomorrow's breakfast", postcard: "The lobby clock is wrong in a reassuring way.", packing: [("paper map", 1), ("comfy cardigan", 2)]),
    Destination(name: "The Inland Sea", mood: "salt air, no airport queues", postcard: "Every wave arrived with a small administrative sigh.", packing: [("tea tin", 2), ("sun hat", 1)])
]

struct Stop { let destination: Destination; let distance: Int; let packed: [(String, Int)] }

func itinerary(seed: Int, packLimit: Int, excluded: Set<Int> = [], stopCount: Int = 4, startingIndex: Int? = nil, excludedPacking: Set<String> = [], allowed: Set<Int>? = nil) -> [Stop] {
    var rng = LCG(seed: seed); var indexes: [Int] = []
    if let startingIndex { indexes.append(startingIndex) }
    if let allowed {
        let candidates = destinations.indices.filter { !excluded.contains($0) && allowed.contains($0) }
        while indexes.count < stopCount { let index = candidates[rng.next(candidates.count)]; if !indexes.contains(index) { indexes.append(index) } }
    } else {
        while indexes.count < stopCount { let index = rng.next(destinations.count); if !excluded.contains(index) && !indexes.contains(index) { indexes.append(index) } }
    }
    var used = 0
    return indexes.map { index in
        let destination = destinations[index]
        var packed: [(String, Int)] = []
        for item in destination.packing where !excludedPacking.contains(item.0.lowercased()) && used + item.1 <= packLimit { packed.append(item); used += item.1 }
        return Stop(destination: destination, distance: 120 + rng.next(721), packed: packed)
    }
}

func render(seed: Int, packLimit: Int, stops: [Stop]) -> String {
    let totalDistance = stops.reduce(0) { $0 + $1.distance }
    let packed = stops.flatMap(\.packed)
    var output = "WINDOW SEAT / FICTIONAL STAY-AT-HOME TRAVEL\n"
    output += "Seed: \(seed)  |  Packing allowance: \(packLimit) cozy units\n"
    output += "Route total: \(totalDistance) imaginary miles\n\n"
    for (offset, stop) in stops.enumerated() {
        output += "STOP \(offset + 1) · \(stop.destination.name)\n"
        output += "  Mood: \(stop.destination.mood)\n"
        output += "  Route: \(stop.distance) fictional miles from the last window\n"
        output += "  Postcard: \(stop.destination.postcard)\n"
        output += "  Packed: \(stop.packed.isEmpty ? "just optimism" : stop.packed.map(\.0).joined(separator: ", "))\n\n"
    }
    output += "PACKING CHECK · \(packed.reduce(0) { $0 + $1.1 }) / \(packLimit) units used\n"
    output += "All places, distances, and stories are invented. Stay home, look out the window.\n"
    return output
}

func renderJSON(seed: Int, packLimit: Int, stops: [Stop]) throws -> String {
    let packed = stops.flatMap(\.packed)
    let object: [String: Any] = [
        "schema": 1,
        "seed": seed,
        "packing_allowance": packLimit,
        "packing_used": packed.reduce(0) { $0 + $1.1 },
        "total_distance": stops.reduce(0) { $0 + $1.distance },
        "stops": stops.map { stop in
            [
                "name": stop.destination.name,
                "tagline": stop.destination.mood,
                "story": stop.destination.postcard,
                "distance": stop.distance,
                "packed_items": stop.packed.map { ["name": $0.0, "units": $0.1] }
            ] as [String: Any]
        }
    ]
    let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    guard let json = String(data: data, encoding: .utf8) else { throw NSError(domain: "WindowSeat", code: 10, userInfo: [NSLocalizedDescriptionKey: "Could not encode JSON as UTF-8"]) }
    return json + "\n"
}

func renderCatalog() -> String {
    var output = "WINDOW SEAT DESTINATION CATALOG\n\n"
    for destination in destinations {
        let items = destination.packing.map { $0.0 + " (" + String($0.1) + ")" }.joined(separator: ", ")
        output += destination.name + "\n  Mood: " + destination.mood + "\n  Story: " + destination.postcard + "\n  Packing: " + items + "\n\n"
    }
    output += "All destinations and stories are invented."
    return output + "\n"
}

func renderCatalogJSON() throws -> String {
    let object: [String: Any] = [
        "schema": 1,
        "destinations": destinations.map { destination in
            ["name": destination.name, "mood": destination.mood, "story": destination.postcard,
             "packing_items": destination.packing.map { ["name": $0.0, "units": $0.1] }] as [String: Any]
        }
    ]
    let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    guard let json = String(data: data, encoding: .utf8) else { throw NSError(domain: "WindowSeat", code: 14, userInfo: [NSLocalizedDescriptionKey: "Could not encode catalog as UTF-8"]) }
    return json + "\n"
}

func renderCatalogHTML() -> String {
    let cards = destinations.map { destination in
        let items = destination.packing.map { "\(htmlEscape($0.0)) (\($0.1) units)" }.joined(separator: ", ")
        return "<article><h2>\(htmlEscape(destination.name))</h2><p><b>MOOD</b> \(htmlEscape(destination.mood))</p><p>\(htmlEscape(destination.postcard))</p><p><b>PACKING</b> \(items)</p></article>"
    }.joined(separator: "\n")
    return "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>Window Seat · catalog</title><style>body{max-width:820px;margin:40px auto;padding:0 24px;background:#f5f0e6;color:#1e2b2b;font-family:Georgia,serif}article{border-top:2px solid;padding:18px 0}h1{font-size:48px}h2{color:#e85d3f}p{line-height:1.5}b{font:700 11px monospace}</style></head><body><h1>Window Seat destinations</h1><p>A fictional stay-at-home travel catalog.</p>\(cards)<footer>All destinations and stories are invented. Created retrospectively in September 2026.</footer></body></html>"
}

func packingTotals(_ stops: [Stop]) -> [String: Int] {
    var totals: [String: Int] = [:]
    for item in stops.flatMap(\.packed) { totals[item.0, default: 0] += item.1 }
    return totals
}

func renderPackingList(_ stops: [Stop]) -> String {
    let totals = packingTotals(stops)
    var output = "WINDOW SEAT PACKING LIST\n"
    if totals.isEmpty { return output + "Nothing packed: just optimism.\n" }
    for name in totals.keys.sorted() { output += "- \(name): \(totals[name]!) unit(s)\n" }
    output += "Total packed units: \(totals.values.reduce(0, +))\n"
    return output
}

func renderPackingListJSON(_ stops: [Stop]) throws -> String {
    let totals = packingTotals(stops)
    let object: [String: Any] = ["schema": 1, "items": totals.keys.sorted().map { ["name": $0, "units": totals[$0]!] }]
    let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    guard let json = String(data: data, encoding: .utf8) else { throw NSError(domain: "WindowSeat", code: 22, userInfo: [NSLocalizedDescriptionKey: "Could not encode packing list as UTF-8"]) }
    return json + "\n"
}

func saveOutput(_ output: String, path: String, force: Bool, label: String) throws {
    let data = Data(output.utf8)
    do {
        try data.write(to: URL(fileURLWithPath: path), options: force ? [.atomic] : [.withoutOverwriting])
    } catch let error as NSError {
        if !force && error.domain == NSCocoaErrorDomain && error.code == NSFileWriteFileExistsError {
            throw NSError(domain: "WindowSeat", code: 24, userInfo: [NSLocalizedDescriptionKey: "Refusing to overwrite existing file; use --force"])
        }
        throw error
    }
    fputs("Saved \(label) to \(path).\n", stderr)
}

func htmlEscape(_ value: String) -> String {
    value.replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}

func renderHTML(seed: Int, packLimit: Int, stops: [Stop]) -> String {
    let totalDistance = stops.reduce(0) { $0 + $1.distance }
    let packed = stops.flatMap(\.packed).reduce(0) { $0 + $1.1 }
    let cards = stops.enumerated().map { offset, stop in
        let items = stop.packed.isEmpty ? "just optimism" : stop.packed.map { htmlEscape($0.0) }.joined(separator: ", ")
        return """
        <article class="stop"><div class="number">0\(offset + 1)</div><div><p class="eyebrow">WINDOW \(offset + 1) · \(htmlEscape(stop.destination.mood))</p><h2>\(htmlEscape(stop.destination.name))</h2><p class="route">\(stop.distance) fictional miles</p><p>\(htmlEscape(stop.destination.postcard))</p><p class="packed"><b>PACKED</b> \(items)</p></div></article>
        """
    }.joined(separator: "\n")
    return """
    <!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Window Seat · \(htmlEscape(String(seed)))</title><style>
    :root{--ink:#1e2b2b;--cream:#f5f0e6;--orange:#e85d3f;--teal:#9ac8bd;--blue:#d9e8e9}*{box-sizing:border-box}body{margin:0;background:var(--cream);color:var(--ink);font-family:Georgia,serif;background-image:radial-gradient(#1e2b2b16 1px,transparent 1px);background-size:14px 14px}.page{max-width:880px;margin:0 auto;padding:52px 34px}.mast{display:flex;justify-content:space-between;align-items:start;border-bottom:3px solid var(--ink);padding-bottom:18px}.eyebrow{font:700 11px/1.4 "Courier New",monospace;letter-spacing:.14em;text-transform:uppercase;color:var(--orange);margin:0 0 10px}h1{font-size:clamp(46px,9vw,92px);line-height:.85;margin:18px 0 16px;letter-spacing:-.06em}h1 span{color:var(--orange);font-style:italic}.ticket{border:2px solid var(--ink);padding:10px 12px;transform:rotate(3deg);font:700 11px/1.5 "Courier New",monospace;white-space:nowrap}.dek{font-size:18px;max-width:580px;line-height:1.45}.meta{display:flex;gap:12px;flex-wrap:wrap;margin:26px 0}.meta span{background:var(--teal);border:2px solid var(--ink);padding:10px 14px;font:700 12px "Courier New",monospace;box-shadow:3px 3px 0 var(--ink)}.stop{display:grid;grid-template-columns:82px 1fr;gap:20px;padding:24px 0;border-top:2px solid var(--ink)}.number{font:700 42px "Courier New",monospace;color:var(--orange)}h2{font-size:34px;margin:0 0 2px}.route{font:700 12px "Courier New",monospace;color:var(--orange)}.stop p{line-height:1.5}.packed{background:var(--blue);border-left:5px solid var(--orange);padding:10px 12px;font-size:14px}.packed b{font:700 10px "Courier New",monospace;letter-spacing:.12em;margin-right:8px}.foot{border-top:3px solid var(--ink);padding-top:16px;margin-top:12px;font:11px/1.5 "Courier New",monospace}@media print{body{background:white}.page{padding:20px}.stop{break-inside:avoid}}@media(max-width:600px){.page{padding:28px 18px}.mast{display:block}.ticket{display:inline-block;margin-top:18px}.stop{grid-template-columns:48px 1fr;gap:12px}h2{font-size:27px}}
    </style></head><body><main class="page"><header class="mast"><div><p class="eyebrow">Window Seat · fictional itinerary</p><h1>Stay home.<br><span>Go somewhere.</span></h1><p class="dek">A printable postcard route for a year when the most daring journey was to the other side of the sofa.</p></div><div class="ticket">SEAT 2020<br>ROW ∞<br>NO BOARDING</div></header><div class="meta"><span>SEED \(htmlEscape(String(seed)))</span><span>\(totalDistance) IMAGINARY MILES</span><span>PACKED \(packed)/\(packLimit)</span></div><section>\(cards)</section><footer class="foot">All destinations, distances, and stories are invented. Created retrospectively in September 2026 as a fictional 2020-inspired art project.</footer></main></body></html>
    """
}

func parse(arguments: [String]) throws -> (seed: Int, pack: Int, save: String?, force: Bool, avoids: [String], only: [String], format: String, stops: Int, start: String?, noPack: [String], reverse: Bool, packingList: Bool, catalog: Bool, routeOptionUsed: Bool, selfTest: Bool, help: Bool) {
    var seed = 2020, pack = 6, save: String?, force = false, avoids: [String] = [], only: [String] = [], format = "text", stops = 4, start: String?, noPack: [String] = [], reverse = false, packingList = false, catalog = false, routeOptionUsed = false, selfTest = false, help = false; var index = 0
    while index < arguments.count {
        switch arguments[index] {
        case "--seed": routeOptionUsed = true; index += 1; guard index < arguments.count, let value = Int(arguments[index]) else { throw NSError(domain: "WindowSeat", code: 1, userInfo: [NSLocalizedDescriptionKey: "--seed needs a whole number"]) }; seed = value
        case "--pack": routeOptionUsed = true; index += 1; guard index < arguments.count, let value = Int(arguments[index]), value > 0 else { throw NSError(domain: "WindowSeat", code: 2, userInfo: [NSLocalizedDescriptionKey: "--pack needs a positive whole number"]) }; pack = value
        case "--save": index += 1; guard index < arguments.count, !arguments[index].isEmpty else { throw NSError(domain: "WindowSeat", code: 3, userInfo: [NSLocalizedDescriptionKey: "--save needs a file path"]) }; save = arguments[index]
        case "--force": force = true
        case "--avoid": routeOptionUsed = true; index += 1; guard index < arguments.count, !arguments[index].isEmpty else { throw NSError(domain: "WindowSeat", code: 5, userInfo: [NSLocalizedDescriptionKey: "--avoid needs a destination name"]) }; avoids.append(arguments[index])
        case "--only": routeOptionUsed = true; index += 1; guard index < arguments.count, !arguments[index].isEmpty else { throw NSError(domain: "WindowSeat", code: 17, userInfo: [NSLocalizedDescriptionKey: "--only needs a destination name"]) }; only.append(arguments[index])
        case "--stops": routeOptionUsed = true; index += 1; guard index < arguments.count, let value = Int(arguments[index]), (1...destinations.count).contains(value) else { throw NSError(domain: "WindowSeat", code: 9, userInfo: [NSLocalizedDescriptionKey: "--stops must be a whole number from 1 to \(destinations.count)"]) }; stops = value
        case "--start": routeOptionUsed = true; index += 1; guard index < arguments.count, !arguments[index].isEmpty else { throw NSError(domain: "WindowSeat", code: 10, userInfo: [NSLocalizedDescriptionKey: "--start needs a destination name"]) }; start = arguments[index]
        case "--no-pack": routeOptionUsed = true; index += 1; guard index < arguments.count, !arguments[index].isEmpty else { throw NSError(domain: "WindowSeat", code: 12, userInfo: [NSLocalizedDescriptionKey: "--no-pack needs an item name"]) }; noPack.append(arguments[index])
        case "--reverse": routeOptionUsed = true; reverse = true
        case "--packing-list": packingList = true
        case "--catalog": catalog = true
        case "--format": index += 1; guard index < arguments.count, ["text", "html", "json"].contains(arguments[index]) else { throw NSError(domain: "WindowSeat", code: 8, userInfo: [NSLocalizedDescriptionKey: "--format must be text, html, or json"]) }; format = arguments[index]
        case "--self-test": selfTest = true
        case "--help": help = true
        default: throw NSError(domain: "WindowSeat", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown option: \(arguments[index])"])
        }
        index += 1
    }
    return (seed, pack, save, force, avoids, only, format, stops, start, noPack, reverse, packingList, catalog, routeOptionUsed, selfTest, help)
}

func resolveDestination(_ name: String) throws -> Int {
    guard let index = destinations.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
        throw NSError(domain: "WindowSeat", code: 11, userInfo: [NSLocalizedDescriptionKey: "Unknown destination for --start: \(name)"])
    }
    return index
}

func resolvePackingExclusions(_ names: [String]) throws -> Set<String> {
    let known = Set(destinations.flatMap { $0.packing.map { $0.0.lowercased() } })
    var result: Set<String> = []
    for name in names {
        let normalized = name.lowercased()
        guard known.contains(normalized) else {
            throw NSError(domain: "WindowSeat", code: 13, userInfo: [NSLocalizedDescriptionKey: "Unknown packing item for --no-pack: \(name)"])
        }
        result.insert(normalized)
    }
    return result
}

func resolveOnly(_ names: [String]) throws -> Set<Int>? {
    if names.isEmpty { return nil }
    var indexes: Set<Int> = []
    for name in names {
        guard let index = destinations.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { throw NSError(domain: "WindowSeat", code: 18, userInfo: [NSLocalizedDescriptionKey: "Unknown destination for --only: \(name)"]) }
        indexes.insert(index)
    }
    return indexes
}

func resolveAvoids(_ names: [String], requiredStops: Int = 4) throws -> Set<Int> {
    var indexes: Set<Int> = []
    for name in names {
        guard let index = destinations.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            throw NSError(domain: "WindowSeat", code: 6, userInfo: [NSLocalizedDescriptionKey: "Unknown destination for --avoid: \(name)"])
        }
        indexes.insert(index)
    }
    guard destinations.count - indexes.count >= requiredStops else {
        throw NSError(domain: "WindowSeat", code: 7, userInfo: [NSLocalizedDescriptionKey: "Keep at least \(requiredStops) destinations available"])
    }
    return indexes
}

func runSelfTests() -> Bool {
    let first = render(seed: 42, packLimit: 6, stops: itinerary(seed: 42, packLimit: 6))
    let second = render(seed: 42, packLimit: 6, stops: itinerary(seed: 42, packLimit: 6))
    let other = render(seed: 43, packLimit: 6, stops: itinerary(seed: 43, packLimit: 6))
    guard first == second, first != other else { return false }
    let forwardStops = itinerary(seed: 42, packLimit: 6)
    var reverseStops = forwardStops
    reverseStops.reverse()
    guard render(seed: 42, packLimit: 6, stops: reverseStops).contains("STOP 1 · \(forwardStops.last!.destination.name)") else { return false }
    for seed in 0...200 { for limit in 0...12 {
        let stops = itinerary(seed: seed, packLimit: limit)
        guard stops.count == 4, Set(stops.map { $0.destination.name }).count == 4 else { return false }
        guard stops.flatMap(\.packed).reduce(0, { $0 + $1.1 }) <= limit else { return false }
    }}
    do { _ = try parse(arguments: ["--pack", "0"]); return false } catch { }
    do { _ = try parse(arguments: ["--seed", "🪟"]); return false } catch { }
    do { _ = try parse(arguments: ["--pack"]); return false } catch { }
    do { _ = try parse(arguments: ["--save"]); return false } catch { }
    do { _ = try parse(arguments: ["--format", "pdf"]); return false } catch { }
    do { _ = try parse(arguments: ["--stops", "0"]); return false } catch { }
    do { _ = try parse(arguments: ["--stops", "7"]); return false } catch { }
    do { let one = try parse(arguments: ["--stops", "1"]); guard one.stops == 1 else { return false } } catch { return false }
    do { let parsed = try parse(arguments: ["--start", "mArMaLaDe Moon"]); guard parsed.start == "mArMaLaDe Moon", try resolveDestination(parsed.start!) == 0 else { return false } } catch { return false }
    do { let parsed = try parse(arguments: ["--no-pack", "PENCIL", "--no-pack", "pencil"]); guard parsed.noPack.count == 2, try resolvePackingExclusions(parsed.noPack) == ["pencil"] else { return false } } catch { return false }
    do { let parsed = try parse(arguments: ["--reverse"]); guard parsed.reverse else { return false } } catch { return false }
    do { let parsed = try parse(arguments: ["--only", "Marmalade Moon", "--only", "The Inland Sea"]); guard parsed.only.count == 2 else { return false } } catch { return false }
    do { let parsed = try parse(arguments: ["--packing-list", "--format", "json"]); guard parsed.packingList, parsed.format == "json" else { return false } } catch { return false }
    do { let parsed = try parse(arguments: ["--force", "--save", "out.txt"]); guard parsed.force, parsed.save == "out.txt" else { return false } } catch { return false }
    do { let help = try parse(arguments: ["--help"]); guard help.help else { return false } } catch { return false }
    do { let avoided = try resolveAvoids(["mArMaLaDe MoOn", "The Inland Sea", "the inland sea"]); guard avoided.count == 2 else { return false } } catch { return false }
    do { let avoided = try resolveAvoids(["Hotel Yesterday"]); let a = render(seed: 9, packLimit: 4, stops: itinerary(seed: 9, packLimit: 4, excluded: avoided)); let b = render(seed: 9, packLimit: 4, stops: itinerary(seed: 9, packLimit: 4, excluded: avoided)); guard a == b, !a.contains("Hotel Yesterday") else { return false } } catch { return false }
    do { let pin = try resolveDestination("The Inland Sea"); let a = try renderJSON(seed: 17, packLimit: 6, stops: itinerary(seed: 17, packLimit: 6, startingIndex: pin)); let b = try renderJSON(seed: 17, packLimit: 6, stops: itinerary(seed: 17, packLimit: 6, startingIndex: pin)); guard a == b, a.contains("The Inland Sea") else { return false } } catch { return false }
    do { let avoided = try resolveAvoids(["Hotel Yesterday", "The Inland Sea", "Pajama Junction", "Cloudberry Heights", "The Quiet Archipelago"], requiredStops: 1); let one = itinerary(seed: 9, packLimit: 4, excluded: avoided, stopCount: 1); guard one.count == 1 else { return false } } catch { return false }
    do { let pin = try resolveDestination("the inland sea"); let one = itinerary(seed: 9, packLimit: 4, stopCount: 1, startingIndex: pin); guard one.first?.destination.name == "The Inland Sea" else { return false } } catch { return false }
    do { let noPencil = try resolvePackingExclusions(["pencil"]); let packed = itinerary(seed: 9, packLimit: 12, excludedPacking: noPencil).flatMap(\.packed); guard !packed.contains(where: { $0.0 == "pencil" }) else { return false } } catch { return false }
    do { _ = try resolvePackingExclusions(["stapler"]); return false } catch { }
    let six = itinerary(seed: 9, packLimit: 4, stopCount: destinations.count)
    guard six.count == destinations.count else { return false }
    do { _ = try resolveAvoids(["Not A Place"]); return false } catch { }
    do { _ = try resolveAvoids(destinations.prefix(3).map(\.name)); return false } catch { }
    guard htmlEscape("<tag attr=\"x\">&'") == "&lt;tag attr=&quot;x&quot;&gt;&amp;&#39;" else { return false }
    let html = renderHTML(seed: 42, packLimit: 6, stops: itinerary(seed: 42, packLimit: 6))
    guard html.contains("<!doctype html>"), html.contains("@media print"), !html.contains("<tag") else { return false }
    do {
        let json = try renderJSON(seed: 42, packLimit: 6, stops: itinerary(seed: 42, packLimit: 6))
        guard let data = json.data(using: .utf8), let object = try JSONSerialization.jsonObject(with: data) as? [String: Any], let jsonStops = object["stops"] as? [[String: Any]], jsonStops.count == 4, object["schema"] as? Int == 1, object["total_distance"] is Int else { return false }
        guard json.contains("Marmalade Moon") else { return false }
    } catch { return false }
    do {
        let json = try renderJSON(seed: 42, packLimit: 6, stops: reverseStops)
        guard let data = json.data(using: .utf8), let object = try JSONSerialization.jsonObject(with: data) as? [String: Any], let entries = object["stops"] as? [[String: Any]], entries.first?["name"] as? String == forwardStops.last!.destination.name else { return false }
    } catch { return false }
    do {
        let catalog = try renderCatalogJSON()
        guard let data = catalog.data(using: .utf8), let object = try JSONSerialization.jsonObject(with: data) as? [String: Any], let entries = object["destinations"] as? [[String: Any]], entries.count == destinations.count, entries.first?["name"] as? String == destinations[0].name else { return false }
        guard renderCatalog().contains("WINDOW SEAT DESTINATION CATALOG"), renderCatalogHTML().contains("<article>") else { return false }
    } catch { return false }
    do {
        let list = try renderPackingListJSON(forwardStops)
        guard let data = list.data(using: .utf8), let object = try JSONSerialization.jsonObject(with: data) as? [String: Any], object["schema"] as? Int == 1, object["items"] is [[String: Any]] else { return false }
        guard renderPackingList(forwardStops).contains("WINDOW SEAT PACKING LIST") else { return false }
    } catch { return false }
    return first.contains("Marmalade") || first.contains("Junction") || first.contains("Sea") || first.contains("Heights")
}

do {
    let options = try parse(arguments: Array(CommandLine.arguments.dropFirst()))
    if options.force && options.save == nil { throw NSError(domain: "WindowSeat", code: 25, userInfo: [NSLocalizedDescriptionKey: "--force requires --save"]) }
    if options.catalog && (options.routeOptionUsed || options.packingList || options.selfTest) { throw NSError(domain: "WindowSeat", code: 15, userInfo: [NSLocalizedDescriptionKey: "--catalog cannot be combined with route options or --self-test"]) }
    if options.packingList && options.format == "html" { throw NSError(domain: "WindowSeat", code: 23, userInfo: [NSLocalizedDescriptionKey: "--packing-list supports text or json, not html"]) }
    if options.reverse && options.start != nil { throw NSError(domain: "WindowSeat", code: 16, userInfo: [NSLocalizedDescriptionKey: "--reverse cannot be combined with --start"]) }
    if options.help {
        print("Usage: window-seat [--catalog | --packing-list] [--seed N] [--pack N] [--stops N] [--start NAME] [--only NAME]... [--avoid NAME]... [--no-pack ITEM]... [--reverse] [--format text|html|json] [--save PATH] [--force] [--self-test]")
        print("Valid destinations: \(destinations.map(\.name).joined(separator: ", "))")
        let validPackingItems = Set(destinations.flatMap { $0.packing.map { $0.0 } }).sorted()
        print("Valid packing items: \(validPackingItems.joined(separator: ", "))")
        exit(0)
    }
    if options.selfTest { let passed = runSelfTests(); print(passed ? "self-tests passed: deterministic seeds, unique stops, packing bounds, Unicode and option errors" : "self-tests failed"); exit(passed ? 0 : 1) }
    if options.catalog {
        let output: String
        if options.format == "html" { output = renderCatalogHTML() }
        else if options.format == "json" { output = try renderCatalogJSON() }
        else { output = renderCatalog() }
        if let path = options.save { do { try saveOutput(output, path: path, force: options.force, label: "catalog") } catch { fputs("Could not save catalog: \(error.localizedDescription)\n", stderr); exit(5) } }
        print(output, terminator: "")
        exit(0)
    }
    let allowed = try resolveOnly(options.only)
    if let allowed, allowed.count < options.stops { throw NSError(domain: "WindowSeat", code: 19, userInfo: [NSLocalizedDescriptionKey: "--only must include at least \(options.stops) destinations"]) }
    let excluded = try resolveAvoids(options.avoids, requiredStops: options.stops)
    if let allowed {
        for name in options.avoids {
            let index = try resolveDestination(name)
            if allowed.contains(index) { throw NSError(domain: "WindowSeat", code: 20, userInfo: [NSLocalizedDescriptionKey: "--only and --avoid cannot overlap"]) }
        }
    }
    let startingIndex = try options.start.map(resolveDestination)
    if let startingIndex, excluded.contains(startingIndex) { throw NSError(domain: "WindowSeat", code: 12, userInfo: [NSLocalizedDescriptionKey: "--start destination is excluded by --avoid"]) }
    if let startingIndex, let allowed, !allowed.contains(startingIndex) { throw NSError(domain: "WindowSeat", code: 21, userInfo: [NSLocalizedDescriptionKey: "--start destination must be included by --only"]) }
    let excludedPacking = try resolvePackingExclusions(options.noPack)
    var stops = itinerary(seed: options.seed, packLimit: options.pack, excluded: excluded, stopCount: options.stops, startingIndex: startingIndex, excludedPacking: excludedPacking, allowed: allowed)
    if options.reverse { stops.reverse() }
    let output: String
    if options.packingList && options.format == "json" {
        output = try renderPackingListJSON(stops)
    } else if options.packingList {
        output = renderPackingList(stops)
    } else if options.format == "html" {
        output = renderHTML(seed: options.seed, packLimit: options.pack, stops: stops)
    } else if options.format == "json" {
        output = try renderJSON(seed: options.seed, packLimit: options.pack, stops: stops)
    } else {
        output = render(seed: options.seed, packLimit: options.pack, stops: stops)
    }
    if let path = options.save { do { try saveOutput(output, path: path, force: options.force, label: options.packingList ? "packing list" : "postcard") } catch { fputs("Could not save itinerary: \(error.localizedDescription)\n", stderr); exit(5) } }
    print(output, terminator: "")
} catch { fputs("Window Seat: \(error.localizedDescription)\n", stderr); exit(2) }
