# POSTGRES

- select feed file

- add new row to `orderbooks` and save `id`

- load asks/bids to `tmp` (copy structure from `tmp_snap_exchange`)

- copy rows from `tmp` to `orderbook_snapshots` referencing `id`

- delete `tmp`

- load feed to `tmp` (copy structure from `tmp_exchange`)

- copy rows from `tmp` to `orderbook_feeds` referencing `id`
