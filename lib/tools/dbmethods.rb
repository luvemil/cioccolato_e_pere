$LOAD_PATH << "."

require 'files'

module BTCData
  module DB
    def self.create_snap_table conn, file_match
      exchange = file_match[:exchange]
      if exchange == "bitfinex"
        base_table = "tmp_snap_bfx"
      elsif exchange == "bitmex"
        base_table = "tmp_snap_bmx"
      else
        p "Error"
        return 0
      end

      conn.exec("CREATE TABLE tmp AS SELECT * FROM #{base_table} WHERE false;")
    end

    def self._load_snap_single conn, csvpath, attr
      filename = File.basename csvpath
      filedir = File.dirname csvpath
      target = File.join(filedir,BTCData::Files.change_attr(filename, attr))
      m = BTCData::Files.patt.match filename
      if m[:exchange] == "bitfinex"
        data_list = "(price, count_i, amount)"
      elsif m[:exchange] == "bitmex"
        data_list = "(price, amount)"
      else
        p "Error"
        return 0
      end
      conn.exec("COPY tmp #{data_list} FROM '#{target}' WITH (FORMAT csv);")
    end

    def self._move_tmp_to_snap conn, csvpath, attr, orderbook_id
      filename = File.basename csvpath
      m = BTCData::Files.patt.match filename
      if m[:exchange] == "bitfinex"
        values = "price, amount, count_i"
      elsif m[:exchange] == "bitmex"
        values = "price, amount"
      else
        p "Error"
        return 0
      end
      conn.exec("INSERT INTO orderbook_snapshots
                (#{values}, type, snapshot_id)
                SELECT #{values},
                  '#{attr.upcase}' AS type,
                  #{orderbook_id} AS snapshot_id
                  FROM tmp;")
    end

    def self.add_orderbook conn, csvpath
      filename = File.basename csvpath
      m = BTCData::Files.patt.match filename
      if m[:exchange] == "bitfinex"
        price_currency = "USD"
        amount_currency = "BTC"
      elsif m[:exchange] == "bitmex"
        price_currency = "USD"
        amount_currency = "USD"
      else
        p "Error"
        return 0
      end

      timestring = DateTime.parse(m[:timestamp]).to_s

      conn.exec("INSERT INTO orderbooks (exchange, symbol, time, price_currency, amount_currency) VALUES (
                '#{m[:exchange].downcase}',
                '#{m[:symbol].downcase}',
                '#{timestring}',
                '#{price_currency}',
                '#{amount_currency}'
                )")

      res = conn.exec("SELECT lastval();")
      # Returns the orderbook id
      res[0][0]
    end

    def self.delete_tmp_table conn
      conn.exec("DROP TABLE tmp;")
    end
  end
end
