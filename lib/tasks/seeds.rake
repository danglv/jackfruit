namespace :seeds do
  desc "seeding category and course name"
  task seed_category_and_course_name: :environment do
    csv_file_name = "db/seeding_data/"
    csv_file_name += "Category_sub-category_coursename"
    data = load_csv_file(csv_file_name) and true

    @category_name = @sub_category_name = ""

    data.each_with_index{|row, index|
      next if row[0] == 'STT'

      if !row[4].blank?
        @category_name = nomalize_string(row[4])
        category = Category.find_or_initialize_by(
          id: @category_name,
          name: row[4]
        )
        if category.save
          puts "Create category #{row[4]}"
        else
          binding.pry
        end
      else
        @sub_category_name = nomalize_string(row[5])
        category = Category.where(id: @category_name).first
        binding.pry if category.blank?

        sub_category = Category.find_or_initialize_by(
          id: "#{@category_name}/#{@sub_category_name}",
          name: row[5],
          parent_category_id: category.id.to_s
        )

        if sub_category.save
          puts "Create sub-category #{row[4]} of category #{@category_name}"
        else
          binding.pry
        end

        category.child_categories << sub_category
        category.save

        if !row[6].blank?
          course = Course.find_or_initialize_by(
            name: row[6],
            lang: "vi"
          )

          course.categories << category
          course.categories << sub_category

          if course.save
            puts "Create Course #{row[6]}"
          else
            binding.pry
          end
        end        
      end
    }
  end

  desc "seeding course by course name"
  task seed_course_by_course_name: :environment do
    csv_file_name = "db/seeding_data/course"
    csv_file_name += "1"
    data = load_csv_file(csv_file_name) and true

    @course_name = ""
    @curriculums = []
    @course = nil

    data.each_with_index{|row, index|
      next if row[0] == "Name"

      if !row[6].blank?
        @curriculums << [row[6], "chapter"]
      end

      if !row[7].blank?
        @curriculums << [row[7], "lecture"]
      end

      unless row[0].blank?
        if @course.blank?
          @course_name = row[0]
          @course = Course.where(name: @course_name).first

          binding.pry if @course.blank?

          @course.sub_title   = row[1]
          @course.description = row[2]
          @course.requirement = row[3]
          @course.benefit     = row[4]
          @course.audience    = row[5]
        else
          chapter_index = 0
          lecture_index = 0

          @curriculums.each_with_index {|curriculum, x|
            @course.curriculums.create(
              description: curriculum[0],
              order: x,
              chapter_index: chapter_index,
              lecture_index: lecture_index,
              type: curriculum[1]
            )

            chapter_index += 1 if curriculum[1] == "chapter"
            lecture_index += 1 if curriculum[1] == "lecture"
          }
        end
      else

      end
    }
  end
end

def load_csv_file(file_name)
  CSV.parse(File.read("#{file_name}.csv"))
end

def nomalize_string(unicode_string)
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

  ascii_string
end