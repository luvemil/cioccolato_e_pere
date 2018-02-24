#!/usr/bin/env bash

# Check if running Mac, else assume Linux
if [ "$(uname)" == "Darwin" ]
then
  if ! hash gdate 2>/dev/null
  then
    >&2 echo "Missing command gdate, please install package 'coreutils' from MacPorts or HomeBrew"
    exit 2
  fi
fi

gnudate() {
  if hash gdate 2>/dev/null
  then
    gdate "$@"
  else
    date "$@"
  fi
}

JSON_OUTPUT=false

POSITIONAL=()
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
    -d|--density) # in [1m,5m,15m,30m,1h,3h,6h,12h,1D,7D,14D,1M]
      DENSITY="$2"
      shift
      shift
      ;;
    -o|--output)
      OUTPUT="$2"
      shift
      shift
      ;;
    -s|--symbol)
      SYMBOL="$2"
      shift
      shift
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift;;
  esac
done

set -- "${POSITIONAL[@]}"

if [ -z ${DENSITY+x} ]
then
  DENSITY=1D
fi

if [ -z ${SYMBOL+x} ]
then
  SYMBOL=tBTCUSD
fi

>&2 echo DENSITY  = "${DENSITY}"
>&2 echo SYMBOL   = "${SYMBOL}"

BASEURL="https://api.bitfinex.com/v2"
ENDPOINT="/candles/trade"

BASEQUERY="${BASEURL}${ENDPOINT}:${DENSITY}:${SYMBOL}/hist"
BASEQUERT=$BASEQUERY"&limit=720&sort=1"


>&2 echo "Using basequery = $BASEQUERY"


if [ $# -lt 1 ]
then
  >&2 echo "Error: not enough arguments given, expecting 1 or 2"
  exit 1
fi

CURL_OPTIONS=""

SDATE=$1
if [ $# -gt 1 ]
then
  EDATE=$2
else
  EDATE=$(gnudate -u "+%F %T")
fi

rm -rf tmp_files

COUNT=1
SMALLCOUNT=0

while [ $(gnudate -d"$SDATE" +%s) -lt $(gnudate -d"$EDATE" +%s)  ]
do
  FILE_EXT=.json
  FILENAME=$(gnudate -d"$SDATE" +%s)$FILE_EXT
  STARTOPT=$(gnudate --date "$SDATE" +%s3N)
  ENDOPT=$(gnudate --date "$EDATE" +%s3N)
  curl --create-dirs -o tmp_files/$FILENAME \
    $CURL_OPTIONS -G -X GET --header 'Accept: application/json' \
    --data-urlencode "start=$STARTOPT" \
    --data-urlencode "end=$ENDOPT" \
    "${BASEQUERY}"
  if [ $( wc -l <  tmp_files/$FILENAME ) -le 15 ]
    # TODO: do a better check for ratelimits
  then
    SMALLCOUNT=0
    case $DENSITY in
      1m)
        SDATE=$(gnudate --date="$SDATE 720 minutes" "+%F %T")
        ;;
      5m)
        SDATE=$(gnudate --date="$SDATE 3600 minutes" "+%F %T")
        ;;
      1h)
        SDATE=$(gnudate --date="$SDATE 720 hours" "+%F %T")
        ;;
      1D)
        SDATE=$(gnudate --date="$SDATE 720 days" "+%F %T")
        ;;
    esac
  else
    SMALLCOUNT=$(( $SMALLCOUNT + 1 ))
    sleep 5
  fi
  if [ $SMALLCOUNT -ge 15 ]
  then
    >&2 echo "Error downloading $SYMBOL"
    exit 2
  fi
  if (($COUNT % 270 == 0))
  then
    sleep 30
  fi
  COUNT=$(($COUNT + 1))
done

#jq -s 'reduce .[] as $item ({}; . * $item)' json_files/*

#convert from json to csv
# jq '.[]|@csv' < $INPUT | xargs -I {} echo {} > $OUTPUT

if [ -z ${OUTPUT+x} ]
then
  OUTPUT=bitfinex_${SYMBOL}_${DENSITY}_$(gnudate -d"$1" "+%FT%H-%M-%S")_$(gnudate -d"$EDATE" "+%FT%H-%M-%S")
  >&2 echo "Using filename = ${OUTPUT}"
fi

mkdir -p json_files
jq -s '.|add' tmp_files/*.json > json_files/$OUTPUT.json
if ! $JSON_OUTPUT
then
  mkdir -p csv_files
  # TODO: add a header
  jq '.[]|@csv' < json_files/$OUTPUT.json | xargs -I {} echo {} > csv_files/$OUTPUT.csv
fi

mv tmp_files ${SYMBOL}_files
