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

func parse(arguments: [String]) throws -> (seed: Int, pack: Int, save: String?, avoids: [String], selfTest: Bool, help: Bool) {
    var seed = 2020, pack = 6, save: String?, avoids: [String] = [], selfTest = false, help = false; var index = 0
    while index < arguments.count {
        switch arguments[index] {
        case "--seed": index += 1; guard index < arguments.count, let value = Int(arguments[index]) else { throw NSError(domain: "WindowSeat", code: 1, userInfo: [NSLocalizedDescriptionKey: "--seed needs a whole number"]) }; seed = value
        case "--pack": index += 1; guard index < arguments.count, let value = Int(arguments[index]), value > 0 else { throw NSError(domain: "WindowSeat", code: 2, userInfo: [NSLocalizedDescriptionKey: "--pack needs a positive whole number"]) }; pack = value
        case "--save": index += 1; guard index < arguments.count, !arguments[index].isEmpty else { throw NSError(domain: "WindowSeat", code: 3, userInfo: [NSLocalizedDescriptionKey: "--save needs a file path"]) }; save = arguments[index]
        case "--avoid": index += 1; guard index < arguments.count, !arguments[index].isEmpty else { throw NSError(domain: "WindowSeat", code: 5, userInfo: [NSLocalizedDescriptionKey: "--avoid needs a destination name"]) }; avoids.append(arguments[index])
        case "--self-test": selfTest = true
        case "--help": help = true
        default: throw NSError(domain: "WindowSeat", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown option: \(arguments[index])"])
        }
        index += 1
    }
    return (seed, pack, save, avoids, selfTest, help)
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
    do { let help = try parse(arguments: ["--help"]); guard help.help else { return false } } catch { return false }
    do { let avoided = try resolveAvoids(["mArMaLaDe MoOn", "The Inland Sea", "the inland sea"]); guard avoided.count == 2 else { return false } } catch { return false }
    do { let avoided = try resolveAvoids(["Hotel Yesterday"]); let a = render(seed: 9, packLimit: 4, stops: itinerary(seed: 9, packLimit: 4, excluded: avoided)); let b = render(seed: 9, packLimit: 4, stops: itinerary(seed: 9, packLimit: 4, excluded: avoided)); guard a == b, !a.contains("Hotel Yesterday") else { return false } } catch { return false }
    do { _ = try resolveAvoids(["Not A Place"]); return false } catch { }
    do { _ = try resolveAvoids(destinations.prefix(3).map(\.name)); return false } catch { }
    return first.contains("Marmalade") || first.contains("Junction") || first.contains("Sea") || first.contains("Heights")
}

do {
    let options = try parse(arguments: Array(CommandLine.arguments.dropFirst()))
    if options.help { print("Usage: window-seat [--seed N] [--pack N] [--avoid NAME]... [--save PATH] [--self-test]"); print("Valid destinations: \(destinations.map(\.name).joined(separator: ", "))"); exit(0) }
    if options.selfTest { let passed = runSelfTests(); print(passed ? "self-tests passed: deterministic seeds, unique stops, packing bounds, Unicode and option errors" : "self-tests failed"); exit(passed ? 0 : 1) }
    let excluded = try resolveAvoids(options.avoids)
    let text = render(seed: options.seed, packLimit: options.pack, stops: itinerary(seed: options.seed, packLimit: options.pack, excluded: excluded))
    print(text, terminator: "")
    if let path = options.save { do { try text.write(toFile: path, atomically: true, encoding: .utf8); print("Saved postcard to \(path).") } catch { fputs("Could not save itinerary: \(error.localizedDescription)\n", stderr); exit(5) } }
} catch { fputs("Window Seat: \(error.localizedDescription)\n", stderr); exit(2) }
