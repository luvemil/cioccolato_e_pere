require 'csv'

module BTCData
  def BTCData.save_csv data_t, csv_file
    # Save an array of the form [[a_11,...,a_1n],[a_21,...,a_2n],...] to csv
    CSV.open(csv_file,'w') do |csv_object|
      data_t.each do |row_array|
        csv_object << row_array
      end
    end
  end

  def BTCData.append_csv data_t, csv_file
    CSV.open(csv_file, 'a') do |csv_object|
      data_t.each do |row_array|
        csv_object << row_array
      end
    end
  end


  def BTCData.date_prefix
    return Time.new.getgm.strftime('%Y%m%d%H%M%S')
  end

  def BTCData._date_to_string time
    return time.strftime('%Y%m%d%H%M%S')
  end

  def BTCData.parse_filename path
    # Return match objects with data spects to put in a Slice object
    split = [ File.dirname(path), File.basename(path) ]
    filename = split[1]
    mask = /(?<market>[^_]+)_(?<pair>[^_]+)_(?<date>[^_]+)_(?<function>[^_]+)(_(?<args>[^\.]+)|)\.csv/
    m = mask.match filename
  end

  def BTCData.convert_date_string date_string
    # Return Time object from string
    year = date_string.slice(0,4)
    month = date_string.slice(4,2)
    day = date_string.slice(6,2)
    hour = date_string.slice(8,2)
    minutes = date_string.slice(10,2)
    seconds = date_string.slice(12,2)
    return Time.gm year, month, day, hour, minutes, seconds
  end
end
