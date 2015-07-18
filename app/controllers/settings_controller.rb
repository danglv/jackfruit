class SettingsController < ApplicationController
  def alias
    unicode_string = params[:name]
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
      " " => '-'
    }.each {|pattern, replacement|
      ascii_string.gsub!(/[#{pattern}]/, replacement)
    }

    # ascii_string
    render :text => ascii_string
  end
end