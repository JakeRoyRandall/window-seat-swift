# Window Seat

`Window Seat` is a small Swift CLI for imaginary 2020 stay-at-home travel. It creates a reproducible four-stop itinerary from a seed, gives each fictional place a postcard-sized story, assigns purely fictional route distances, and fits a small packing list into a configurable cozy-unit allowance.

Created September 2026 retrospectively. The project is fictional and 2020-inspired; it is not a historical work record. Destinations, stories, and distances are deliberate invented art and do not describe real travel.

Build and run:

```sh
swiftc -O main.swift -o window-seat
./window-seat --seed 42 --pack 6
./window-seat --seed 42 --avoid "Hotel Yesterday" --avoid "The Inland Sea"
./window-seat --seed 42 --save postcard.txt
./window-seat --self-test
```

Options are `--seed <whole number>`, `--pack <positive whole number>`, repeatable `--avoid <exact destination name>` (case-insensitive), `--save <path>`, and `--self-test`. `--help` lists valid destination names. Unknown exclusions and exclusions that leave fewer than four available destinations are rejected. No packages are required; the program uses Swift standard library and Foundation only. The self-test runs the real generator and renderer to check same-seed determinism, different-seed variation, packing bounds, Unicode option rejection, and invalid option handling.

Git author dates are deliberately assigned for contribution-calendar artwork. Committer timestamps record actual creation in September 2026.
