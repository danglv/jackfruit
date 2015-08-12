module Utils
  def self.indented_log(log, indent = 0, index = -1, total = -1)
    prefix = if index >= 0 && total > 0
      "[#{index}/#{total}] "
    else
      ""
    end

    puts "\s"*2*indent + prefix + log
  end

  def self.nomalize_string(unicode_string)
    unicode_string = unicode_string.strip
    ascii_string = unicode_string.downcase

    {
      "äåāąàáảãạăắằẳẵặâầấẩẫậÀÁẢÃẠĂẮẰẲẴẶÂẦẤẨẪẬ" => 'a',
      "çćĉċč" => 'c',
      "ðďđĐ" => 'd',
      "ëēĕėęěèéẻẽẹêềếểễệÈÉẺẼẸÊỀẾỂỄỆ" => 'e',
      "ĝğġģ" => 'g',
      "ĥħ" => 'h',
      "îïīĭįıìíỉĩịÌÍỈĨỊ" => 'i',
      "ĵ" => 'j',
      "ķĸ" => 'k',
      "ĺĻļľŀł" => 'l',
      "ñńņňŉŊŋ" => 'n',
      "öøōŏőòóỏõọôồốổỗộơờớởỡợÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ" => 'o',
      "ŕŗř" => 'r',
      "śŝşšſ" => 's',
      "ţťŧ" => 't',
      "ûüūŭůűųùúủũụưừứủữựÙÚỦŨỤƯỪỨỬỮỰ" => 'u',
      "ỳýỷỹỵỲÝỶỸỴ" => 'y',
      " " => '-',
      "---" => '-',
      "--" => '-'
    }.each {|pattern, replacement|
      ascii_string.gsub!(/[#{pattern}]/, replacement)
    }

    ascii_string
  end
end