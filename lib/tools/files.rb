require 're'

module BTCData
  module Files
    @@patt = /(?<exchange>[^_]+)_(?<symbol>[^_]+)_(?<timestamp>[^_]+)_(?<function>[^_]+)_(?<attr>[^_]+)\.csv/
    def self.patt
      @@patt
    end

    @@time_format = '%Y%m%d%H%M%S'
    def self.time_format
      @@time_format
    end

    @@attr_pattern = /_[^_]+\./
    def self.change_attr filename, attr
      filename.sub @@attr_pattern, "_#{attr}."
    end
  end

end
