#!/bin/bash

# Remove shit

clear() {
  pushd ../live_feed
  ls bitfinex_btcusd* | head -n -20 | xargs -I {} rm {}
  ls bitfinex_ethusd* | head -n -20 | xargs -I {} rm {}
  ls bitmex_btcusd* | head -n -20 | xargs -I {} rm {}
  popd
}

while true; do
  read -p "Do you to remove all data except for the last 20? (this operation is not reversible) [yN]" yn
  case $yn in
    [Yy]* )
      clear
      break
      ;;
    * )
      echo "Leaving everything untouched"
      exit
      ;;
  esac
done
