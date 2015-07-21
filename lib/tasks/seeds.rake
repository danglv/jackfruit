namespace :seeds do
  desc "seeding category and course name"
  task seed_category_and_course_name: :environment do
    csv_file_name = "db/seeding_data/"
    csv_file_name += "Tên category và sub-category chuẩn - premium"
    data = load_csv_file(csv_file_name) and true

    @category_name = @sub_category_name = ""

    data.each_with_index{|row, index|
      next if row[0] == 'Category'

      if !row[0].blank?
        @category_name = nomalize_string(row[0])
        category = Category.find_or_initialize_by(
          id: @category_name,
        )
        category.name =  row[0]

        if category.save
          puts "Create category #{row[0]}"
        else
          binding.pry
        end
      elsif !row[1].blank?
        @sub_category_name = nomalize_string(row[1])
        category = Category.where(id: @category_name).first
        binding.pry if category.blank?

        sub_category = Category.find_or_initialize_by(
          id: "#{@category_name}_#{@sub_category_name}",
        )
        sub_category.name = row[1]
        sub_category.parent_category_id = category.id.to_s

        if sub_category.save
          puts "Create sub-category #{row[0]} of category #{@category_name}"
        else
          binding.pry
        end

        category.child_categories << sub_category
        category.save

        if !row[2].blank?
          course = Course.find_or_initialize_by(
            name: row[2],
            lang: "vi"
          )

          course.categories << category
          course.categories << sub_category
          course.price = 1990000
          if course.save
            puts "Create Course #{row[2]}"
          else
            binding.pry
          end
        end        
      end
    }
  end
  
  desc "seeding course by course name"
  task seed_course_by_course_name: :environment do

    categorys = Category.where(:parent_category_id.in => [nil, '', []])
    # File.exist?(file_path)
    @count = 0
    categorys.each {|category|
      csv_file_name = "db/seeding_data/course/paid/"
      csv_file_name += "#{category.id}/"
      @category_count = 0

      category.child_categories.each {|sub_category|
        if !File.exist?("#{csv_file_name}#{category.name} - #{sub_category.name}.csv")
          # puts "#{csv_file_name}#{category.name} - #{sub_category.name}.csv"
          next
        else
          @category_count += 1
          @count += 1
          puts "---#{category.name} - #{sub_category.name}.csv"
          data = load_csv_file("#{csv_file_name}#{category.name} - #{sub_category.name}") and true

          @course_name = ""
          @curriculums = []
          @course = nil
         
          data.each_with_index{|row, index|
            next if (row[0] == "" || row[0] == "name" || row[0] == "Name")
            if index == 0
              course = Course.where(name: row[0]).first

              next if course.blank?
            end

            if !row[6].blank?
              @curriculums << [row[6], "chapter", row[9], row[8], row[10]]
            end

            if !row[7].blank?
              @curriculums << [row[7], "lecture", row[9], row[8], row[10]]
            end

            if (!row[0].blank? || (index == data.count - 1))
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
                  course_curriculum = @course.curriculums.find_or_initialize_by(
                    title: curriculum[0],
                    description: curriculum[3],
                    order: x,
                    chapter_index: chapter_index,
                    lecture_index: lecture_index,
                    type: curriculum[1],
                    asset_type: curriculum[2],
                    url: curriculum[4]
                  )
                  course_curriculum.asset_type = "text" if !Constants.CurriculumAssetTypesValues.include?(course_curriculum.asset_type)
                  chapter_index += 1 if curriculum[1] == "chapter"
                  lecture_index += 1 if curriculum[1] == "lecture"
                }
                
                @course.save
              end
            end
          }
        end
      }
      puts "#{category.name}: #{@category_count}"
    }
    puts "so luong : #{@count}"
  end

  desc "rename images for courses"
  task rename_images_for_course: :environment do
    images = Dir["db/seeding_data/images/*"]
    file_name = "db/seeding_data/course_name/course name map"
    data = load_csv_file(file_name) and true

    # chuẩn hóa tên file & ten course
    images_name = []
    images.each{|image|
      image.gsub!("db/seeding_data/images/", "")
      image.gsub!("x-.", "")
      image.gsub!("x-", "")
      image.gsub!("\u0096", "")
      image.gsub!("---", "-")
      image.gsub!("--", "-")
      image.gsub!(" .", ".")
      image.gsub!("..", ".")
      image.gsub!(".png", "")
      images_name << nomalize_string(image)
    }

    results = []
    data.each{|row|
      if (!row[2].blank? && !row[7].blank?)
        row[2].gsub!("x-.", "")
        row[2].gsub!("x-", "")
        row[2].gsub!("\u0096", "")
        row[2].gsub!("---", "-")
        row[2].gsub!("--", "-")
        row[2].gsub!("\"", "")
        row[2] = nomalize_string(row[2])
        results << [row[2], row[7]] 
      end
    }

    CSV.open("db/seeding_data/export.csv", "w") do |csv|
      results.each{|result|
        csv << [result[0], nomalize_string(result[1])]
      }
    end
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
    "ửûüūŭůűųùúủũụưừứủữựÙÚỦŨỤƯỪỨỬỮỰ" => 'u',
    "ỳýỷỹỵỲÝỶỸỴ" => 'y',
    " " => '-',
    "/" => "-",
    "----" => "-",
    "---" => "-",
    "--" => "-"
  }.each {|pattern, replacement|
    ascii_string.gsub!(/[#{pattern}]/, replacement)
  }

  ascii_string
end