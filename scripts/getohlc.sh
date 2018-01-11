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
    -d|--density)
      DENSITY="$2"
      shift
      shift
      ;;
    -o|--output)
      OUTPUT="$2"
      shift
      shift
      ;;
    -t|--symbol)
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
  DENSITY=1d
fi

if [ -z ${SYMBOL+x} ]
then
  SYMBOL=XBTUSD
fi

>&2 echo DENSITY  = "${DENSITY}"
>&2 echo SYMBOL   = "${SYMBOL}"

BASEURL="https://www.bitmex.com/api/v1"
ENDPOINT="/trade/bucketed"

BASEQUERY="${BASEURL}${ENDPOINT}?partial=false&symbol=${SYMBOL}&binSize=${DENSITY}"

if ! $JSON_OUTPUT
then
  >&2 echo "Downloading CSV"
  BASEQUERY=$BASEQUERY"&_format=csv"
else
  >&2 echo "Downloading JSON"
fi

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

while [ $(gnudate -d"$SDATE" +%s) -lt $(gnudate -d"$EDATE" +%s)  ]
do
  if $JSON_OUTPUT
  then
    FILE_EXT=.json
  else
    FILE_EXT=.csv
  fi
  curl --create-dirs -o tmp_files/$(gnudate -d"$SDATE" +%s)$FILE_EXT \
    $CURL_OPTIONS -G -X GET --header 'Accept: application/json' \
    --data-urlencode "startTime=$SDATE" \
    --data-urlencode "endTime=$EDATE" \
    "${BASEQUERY}"
  case $DENSITY in
    1m)
      SDATE=$(gnudate --date="$SDATE 100 minutes" "+%F %T")
      ;;
    5m)
      SDATE=$(gnudate --date="$SDATE 500 minutes" "+%F %T")
      ;;
    1h)
      SDATE=$(gnudate --date="$SDATE 100 hours" "+%F %T")
      ;;
    1d)
      SDATE=$(gnudate --date="$SDATE 100 days" "+%F %T")
      ;;
  esac
done

#jq -s 'reduce .[] as $item ({}; . * $item)' json_files/*

if [ -z ${OUTPUT+x} ]
then
  OUTPUT=${SYMBOL}_${DENSITY}_$(gnudate -d"$1" "+%FT%H-%M-%S")_$(gnudate -d"$2" "+%FT%H-%M-%S")
  >&2 echo "Using filename = ${OUTPUT}"
fi

if $JSON_OUTPUT
then
  mkdir -p json_files
  jq -s '.|add' tmp_files/*.json > json_files/$OUTPUT.json
else
  mkdir -p csv_files
  i=0
  for filename in tmp_files/*.csv
  do
    if [[ $i -eq 0 ]]
    then
      head -1 $filename > csv_files/$OUTPUT.csv
    fi
    tail -n +2 $filename >> csv_files/$OUTPUT.csv
    i=$(( $i + 1))
  done
fi

rm -r tmp_files
