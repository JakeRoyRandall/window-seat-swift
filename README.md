# Window Seat

`Window Seat` is a small Swift CLI for imaginary 2020 stay-at-home travel. It creates a reproducible itinerary of four stops by default (or a bounded number selected with `--stops`), gives each fictional place a postcard-sized story, assigns purely fictional route distances, and fits a small packing list into a configurable cozy-unit allowance.

Created September 2026 retrospectively. The project is fictional and 2020-inspired; it is not a historical work record. Destinations, stories, and distances are deliberate invented art and do not describe real travel.

Build and run:

```sh
swiftc -O main.swift -o window-seat
./window-seat --seed 42 --pack 6
./window-seat --seed 42 --stops 2
./window-seat --seed 42 --avoid "Hotel Yesterday" --avoid "The Inland Sea"
./window-seat --seed 42 --save postcard.txt
./window-seat --seed 42 --format html --save postcard.html
./window-seat --self-test
```

Options are `--seed <whole number>`, `--pack <positive whole number>`, `--stops <1-6>` (four by default), repeatable `--avoid <exact destination name>` (case-insensitive), `--format text|html`, `--save <path>`, and `--self-test`. Avoided destinations must leave at least the requested number of stops available. Text is the default; HTML is a standalone printable postcard with inline CSS and no external assets. `--help` lists valid destination names. No packages are required; the program uses Swift standard library and Foundation only. The self-test runs the real generator and both renderers to check same-seed determinism, different-seed variation, stop-count bounds, packing bounds, HTML escaping, Unicode option rejection, and invalid option handling.
