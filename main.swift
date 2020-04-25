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

func itinerary(seed: Int, packLimit: Int, excluded: Set<Int> = []) -> [Stop] {
    var rng = LCG(seed: seed); var indexes: [Int] = []
    while indexes.count < 4 { let index = rng.next(destinations.count); if !excluded.contains(index) && !indexes.contains(index) { indexes.append(index) } }
    var used = 0
    return indexes.map { index in
        let destination = destinations[index]
        var packed: [(String, Int)] = []
        for item in destination.packing where used + item.1 <= packLimit { packed.append(item); used += item.1 }
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

func parse(arguments: [String]) throws -> (seed: Int, pack: Int, save: String?, avoids: [String], format: String, selfTest: Bool, help: Bool) {
    var seed = 2020, pack = 6, save: String?, avoids: [String] = [], format = "text", selfTest = false, help = false; var index = 0
    while index < arguments.count {
        switch arguments[index] {
        case "--seed": index += 1; guard index < arguments.count, let value = Int(arguments[index]) else { throw NSError(domain: "WindowSeat", code: 1, userInfo: [NSLocalizedDescriptionKey: "--seed needs a whole number"]) }; seed = value
        case "--pack": index += 1; guard index < arguments.count, let value = Int(arguments[index]), value > 0 else { throw NSError(domain: "WindowSeat", code: 2, userInfo: [NSLocalizedDescriptionKey: "--pack needs a positive whole number"]) }; pack = value
        case "--save": index += 1; guard index < arguments.count, !arguments[index].isEmpty else { throw NSError(domain: "WindowSeat", code: 3, userInfo: [NSLocalizedDescriptionKey: "--save needs a file path"]) }; save = arguments[index]
        case "--avoid": index += 1; guard index < arguments.count, !arguments[index].isEmpty else { throw NSError(domain: "WindowSeat", code: 5, userInfo: [NSLocalizedDescriptionKey: "--avoid needs a destination name"]) }; avoids.append(arguments[index])
        case "--format": index += 1; guard index < arguments.count, arguments[index] == "text" || arguments[index] == "html" else { throw NSError(domain: "WindowSeat", code: 8, userInfo: [NSLocalizedDescriptionKey: "--format must be text or html"]) }; format = arguments[index]
        case "--self-test": selfTest = true
        case "--help": help = true
        default: throw NSError(domain: "WindowSeat", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown option: \(arguments[index])"])
        }
        index += 1
    }
    return (seed, pack, save, avoids, format, selfTest, help)
}

func resolveAvoids(_ names: [String]) throws -> Set<Int> {
    var indexes: Set<Int> = []
    for name in names {
        guard let index = destinations.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            throw NSError(domain: "WindowSeat", code: 6, userInfo: [NSLocalizedDescriptionKey: "Unknown destination for --avoid: \(name)"])
        }
        indexes.insert(index)
    }
    guard destinations.count - indexes.count >= 4 else {
        throw NSError(domain: "WindowSeat", code: 7, userInfo: [NSLocalizedDescriptionKey: "Keep at least four destinations available"])
    }
    return indexes
}

func runSelfTests() -> Bool {
    let first = render(seed: 42, packLimit: 6, stops: itinerary(seed: 42, packLimit: 6))
    let second = render(seed: 42, packLimit: 6, stops: itinerary(seed: 42, packLimit: 6))
    let other = render(seed: 43, packLimit: 6, stops: itinerary(seed: 43, packLimit: 6))
    guard first == second, first != other else { return false }
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
    do { let help = try parse(arguments: ["--help"]); guard help.help else { return false } } catch { return false }
    do { let avoided = try resolveAvoids(["mArMaLaDe MoOn", "The Inland Sea", "the inland sea"]); guard avoided.count == 2 else { return false } } catch { return false }
    do { let avoided = try resolveAvoids(["Hotel Yesterday"]); let a = render(seed: 9, packLimit: 4, stops: itinerary(seed: 9, packLimit: 4, excluded: avoided)); let b = render(seed: 9, packLimit: 4, stops: itinerary(seed: 9, packLimit: 4, excluded: avoided)); guard a == b, !a.contains("Hotel Yesterday") else { return false } } catch { return false }
    do { _ = try resolveAvoids(["Not A Place"]); return false } catch { }
    do { _ = try resolveAvoids(destinations.prefix(3).map(\.name)); return false } catch { }
    guard htmlEscape("<tag attr=\"x\">&'") == "&lt;tag attr=&quot;x&quot;&gt;&amp;&#39;" else { return false }
    let html = renderHTML(seed: 42, packLimit: 6, stops: itinerary(seed: 42, packLimit: 6))
    guard html.contains("<!doctype html>"), html.contains("@media print"), !html.contains("<tag") else { return false }
    return first.contains("Marmalade") || first.contains("Junction") || first.contains("Sea") || first.contains("Heights")
}

do {
    let options = try parse(arguments: Array(CommandLine.arguments.dropFirst()))
    if options.help { print("Usage: window-seat [--seed N] [--pack N] [--avoid NAME]... [--format text|html] [--save PATH] [--self-test]"); print("Valid destinations: \(destinations.map(\.name).joined(separator: ", "))"); exit(0) }
    if options.selfTest { let passed = runSelfTests(); print(passed ? "self-tests passed: deterministic seeds, unique stops, packing bounds, Unicode and option errors" : "self-tests failed"); exit(passed ? 0 : 1) }
    let excluded = try resolveAvoids(options.avoids)
    let stops = itinerary(seed: options.seed, packLimit: options.pack, excluded: excluded)
    let output = options.format == "html" ? renderHTML(seed: options.seed, packLimit: options.pack, stops: stops) : render(seed: options.seed, packLimit: options.pack, stops: stops)
    print(output, terminator: "")
    if let path = options.save { do { try output.write(toFile: path, atomically: true, encoding: .utf8); print("Saved postcard to \(path).") } catch { fputs("Could not save itinerary: \(error.localizedDescription)\n", stderr); exit(5) } }
} catch { fputs("Window Seat: \(error.localizedDescription)\n", stderr); exit(2) }
