# Window Seat

`Window Seat` is a small Swift CLI for imaginary 2020 stay-at-home travel. It creates a reproducible itinerary of four stops by default (or a bounded number selected with `--stops`), gives each fictional place a postcard-sized story, assigns purely fictional route distances, and fits a small packing list into a configurable cozy-unit allowance.

Created September 2026 retrospectively. The project is fictional and 2020-inspired; it is not a historical work record. Destinations, stories, and distances are deliberate invented art and do not describe real travel.

Build and run:

```sh
cd app
swiftc -O main.swift -o window-seat
./window-seat --seed 42 --pack 6
./window-seat --seed 42 --stops 2
./window-seat --seed 42 --start "The Inland Sea" --stops 1
./window-seat --seed 42 --no-pack pencil --format json
./window-seat --catalog --format json
./window-seat --seed 42 --reverse --format json
./window-seat --seed 42 --only "Marmalade Moon" --stops 1
./window-seat --seed 42 --packing-list --format json
./window-seat --seed 42 --avoid "Hotel Yesterday" --avoid "The Inland Sea"
./window-seat --seed 42 --save postcard.txt
./window-seat --seed 42 --format html --save postcard.html
./window-seat --seed 42 --save postcard.txt --force
./window-seat --seed 42 --format json --stops 2
./window-seat --self-test
```

Options are `--catalog`, `--packing-list`, `--seed <whole number>`, `--pack <positive whole number>`, `--stops <1-6>` (four by default), `--start <exact destination name>` (case-insensitive), repeatable `--only <exact destination name>` (case-insensitive), repeatable `--avoid <exact destination name>` (case-insensitive), repeatable `--no-pack <known packing item>` (case-insensitive), `--reverse`, `--format text|html|json`, `--save <path>`, optional `--force`, and `--self-test`. Saves refuse to overwrite an existing file unless `--force` is supplied; `--force` requires `--save`. `--catalog` is a standalone catalog of all six fictional destinations and accepts only `--format` and `--save`; route options are rejected. `--packing-list` reports aggregated item names and unit counts for the selected route, in text or JSON; HTML is rejected. `--reverse` reverses the selected stop order after seeded selection while retaining each stop's generated fictional leg distance and packing; it cannot be combined with `--start`, so a pinned start always remains first. `--only` restricts the destination pool; repeated names are harmless, and the pool must contain at least the requested number of stops. `--start` pins the first stop and counts toward `--stops`; it cannot name an avoided destination or fall outside an `--only` pool. `--no-pack` removes selected items from the greedy packing pass; repeated names are harmless. Avoided destinations must leave at least the requested number of stops available, and cannot overlap `--only`. Text is the default; HTML is a standalone printable postcard with inline CSS and no external assets. JSON has schema 1 with seed, packing totals, total distance, and each stop's name, tagline, story, distance, and packed items. Catalog JSON has schema 1 with the destination mood, story, and packing items, without generated route distances. JSON uses Foundation's UTF-8 serializer with sorted keys. Save confirmations go to stderr so saved JSON stdout remains machine-readable. `--help` lists valid destination names and valid packing item names. No packages are required; the program uses Swift standard library and Foundation only. The self-test runs the real generator and all renderers to check same-seed determinism, different-seed variation, stop-count bounds, packing bounds, no-pack filtering, reverse ordering, packing-list aggregation, HTML escaping, JSON parsing, Unicode option rejection, and invalid option handling.

`--packing-catalog` is a standalone read-only catalogue of all fixed packing item names and unit costs. It accepts `--format text|json` (schema 1 JSON has an `items` array), plus optional save output, and rejects itinerary options such as `--seed`, `--pack`, and `--stops`.
