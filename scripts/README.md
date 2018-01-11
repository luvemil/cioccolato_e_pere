# BitMEX

## Preliminaries

- Ensure that your system has the GNU version of `date`. If you are on Mac, this usually involves installing the package `coreutils` from MacPorts or HomeBrew.

- If you want to get the data in JSON format, install `jq` from [the GitHub repo](https://github.com/stedolan/jq)

## Run

`getohlc.sh` uses the following syntax:

```bash
./getohlc.sh [OPTIONS] start_date [end_date]

Output is written to csv by default, unless --json is given. If end_date is
not given, it will default to current time.

Accepted options are:

  -d, --density DENSITY
    x is one of 1m, 5m, 1h, 1d.

  -o, --output filename
    Write the result to filename.csv or filename.json depending on the chosen
    format.

  -s, --symbol SYMBOL
    Specify a symbol, as accepted by Bitmex API.

  --json
    Write to JSON instead of CSV.
```
