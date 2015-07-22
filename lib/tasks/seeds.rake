namespace :seeds do
  desc "seeding category and course name premium"
  task seed_category_and_course_name_paid: :environment do
    csv_file_name = "db/seeding_data/version1.0.2/category/"
    csv_file_name += "Alias - Premium"
    data = load_csv_file(csv_file_name) and true

    @category_name = @sub_category_name = ""

    data.each_with_index{|row, index|
      next if ( row[0] == 'Category' || row[0] == 'category')

      if !row[0].blank?
        @category_name = row[1] #nomalize_string(row[0])
        category = Category.find_or_initialize_by(
          id: @category_name,
        )
        category.name =  row[0]
        category.alias_name = row[1]

        if category.save
          puts "Create category #{row[0]}"
        else
          binding.pry
        end
      elsif !row[4].blank?
        if !row[2].blank?
          @sub_category_name = row[3] #nomalize_string(row[1])
          category = Category.where(id: @category_name).first
          binding.pry if category.blank?

          sub_category = Category.find_or_initialize_by(
            id: "#{@category_name}_#{@sub_category_name}",
          )
          sub_category.name = row[2]
          sub_category.alias_name = row[3]
          sub_category.parent_category_id = category.id.to_s

          if sub_category.save
            puts "Create sub-category #{row[2]} of category #{@category_name}"
          else
            binding.pry
          end

          category.child_categories << sub_category
          category.save
        end

        if !row[4].blank?
          course = Course.find_or_initialize_by(
            name: row[4],
            alias_name: row[5],
            lang: "vi"
          )

          course.categories << category
          course.categories << sub_category
          course.price = 990000
          if course.save
            puts "Create Course #{row[4]}"
          else
            binding.pry
          end
        end        
      end
    }
  end
  
  desc "seeding category and course name free"
  task seed_category_and_course_name_free: :environment do
    csv_file_name = "db/seeding_data/version1.0.2/category/"
    csv_file_name += "Alias - Free"
    data = load_csv_file(csv_file_name) and true

    @category_name = @sub_category_name = ""

    data.each_with_index{|row, index|
      next if ( row[0] == 'Category' || row[0] == 'category')

      if !row[0].blank?
        @category_name = row[1] #nomalize_string(row[0])
        category = Category.find_or_initialize_by(
          id: @category_name,
        )
        category.name =  row[0]
        category.alias_name = row[1]

        if category.save
          puts "Create category #{row[0]}"
        else
          binding.pry
        end
      elsif !row[4].blank?
        if !row[2].blank?
          @sub_category_name = row[3] #nomalize_string(row[1])
          category = Category.where(id: @category_name).first
          binding.pry if category.blank?

          sub_category = Category.find_or_initialize_by(
            id: "#{@category_name}_#{@sub_category_name}",
          )
          sub_category.name = row[2]
          sub_category.alias_name = row[3]
          sub_category.parent_category_id = category.id.to_s

          if sub_category.save
            puts "Create sub-category #{row[2]} of category #{@category_name}"
          else
            binding.pry
          end

          category.child_categories << sub_category
          category.save
        end
        if !row[4].blank?
          course = Course.find_or_initialize_by(
            name: row[4],
            alias_name: row[5],
            lang: "vi"
          )

          course.categories << category
          course.categories << sub_category
          if course.save
            puts "Create Course #{row[4]}"
          else
            binding.pry
          end
        end        
      end
    }
  end

  desc "seeding course by course name premium"
  task seed_course_by_course_name_paid: :environment do

    categories = Category.where(:parent_category_id.in => [nil, '', []])
    # File.exist?(file_path)
    @count = 0
    categories.each {|category|
      csv_file_name = "db/seeding_data/version1.0.2/paid/"
      csv_file_name += "#{category.id}"
      @category_count = 0

      category.child_categories.each {|sub_category|
        if !File.exist?("#{csv_file_name} - #{sub_category.alias_name}.csv")
          # puts "#{csv_file_name} - #{sub_category_alias}.csv"
          next
        else
          @category_count += 1
          @count += 1
          puts "---#{csv_file_name} - #{sub_category.alias_name}.csv"
          data = load_csv_file("#{csv_file_name} - #{sub_category.alias_name}") and true

          @course_name = ""
          @curriculums = []
          @description = []
          @requirement = []
          @benefit = []
          @audience = []
          @course = nil
         
          data.each_with_index{|row, index|
            if index == 0
              next if (row[0] == "" || row[0] == "alias" || row[0] == "Alias")
              course = Course.where(alias_name: row[0]).first

              next if course.blank?
            end

            if !row[7].blank?
              @curriculums << [row[7], "chapter", row[9], row[10], row[11]]
            end
        
            if !row[8].blank?
              @curriculums << [row[8], "lecture", row[9], row[10], row[11]]
            end
        
            if !row[3].blank?
              @description << row[3]
            end

            if !row[4].blank?
              @requirement << row[4]
            end

            if !row[5].blank?
              @benefit << row[5]
            end

            if !row[6].blank?
              @audience << row[6]
            end

            if (!row[0].blank? || (index == data.count - 1))
              if @course.blank?
                @course_name = row[0]
                @course = Course.where(alias_name: @course_name).first
                binding.pry if @course.blank?
                @course.sub_title   = row[2]
              else
                chapter_index = 0
                lecture_index = 0
            
                @curriculums.each_with_index {|curriculum, x|
                  course_curriculum = @course.curriculums.find_or_initialize_by(
                    title: curriculum[0],
                    description: curriculum[2],
                    order: x,
                    chapter_index: chapter_index,
                    lecture_index: lecture_index,
                    type: curriculum[1],
                    asset_type: curriculum[3],
                    url: curriculum[4]
                  )
                  course_curriculum.asset_type = "text" if !Constants.CurriculumAssetTypesValues.include?(curriculum[3])
                  chapter_index += 1 if curriculum[1] == "chapter"
                  lecture_index += 1 if curriculum[1] == "lecture"
                }

                
                @course.description = @description
                @course.requirement = @requirement
                @course.benefit     = @benefit
                @course.audience    = @audience
                
                @course.save
                @course = nil

                @curriculums = []
                @description = []
                @requirement = []
                @benefit = []
                @audience = []
              end
            end
        
          }
        end
      }
      puts "#{category.name}: #{@category_count}"
    }
    puts "so luong : #{@count}"
  end

  desc "seeding course by course name free"
  task seed_course_by_course_name_free: :environment do

    categories = Category.where(:parent_category_id.in => [nil, '', []])
    # File.exist?(file_path)
    @count = 0
    categories.each {|category|
      csv_file_name = "db/seeding_data/version1.0.2/free/"
      csv_file_name += "#{category.id}"
      @category_count = 0

      category.child_categories.each {|sub_category|
        if !File.exist?("#{csv_file_name} - #{sub_category.alias_name}.csv")
          # puts "#{csv_file_name} - #{sub_category_alias}.csv"
          next
        else
          @category_count += 1
          @count += 1
          puts "---#{csv_file_name} - #{sub_category.alias_name}.csv"
          data = load_csv_file("#{csv_file_name} - #{sub_category.alias_name}") and true

          @course_name = ""
          @curriculums = []
          @description = []
          @requirement = []
          @benefit = []
          @audience = []
          @course = nil
         
          data.each_with_index{|row, index|
            if index == 0
              next if (row[0] == "" || row[0] == "alias" || row[0] == "Alias")
              course = Course.where(alias_name: row[0]).first

              next if course.blank?
            end

            if !row[8].blank?
              @curriculums << [row[8], "chapter", row[10], row[11], row[12]]
            end
        
            if !row[9].blank?
              @curriculums << [row[9], "lecture", row[10], row[11], row[12]]
            end
        
            if !row[4].blank?
              @description << row[4]
            end

            if !row[5].blank?
              @requirement << row[5]
            end

            if !row[6].blank?
              @benefit << row[6]
            end

            if !row[7].blank?
              @audience << row[7]
            end

            # binding.pry if ((index == data.count - 1) && (sub_category.alias_name == "ngon-ngu-lap-trinh"))
            if (!row[0].blank? || (index == data.count - 1))
              if !@course.blank?
                chapter_index = 0
                lecture_index = 0
            
                @curriculums.each_with_index {|curriculum, x|
                  course_curriculum = @course.curriculums.find_or_initialize_by(
                    title: curriculum[0],
                    description: curriculum[2],
                    order: x,
                    chapter_index: chapter_index,
                    lecture_index: lecture_index,
                    type: curriculum[1],
                    asset_type: curriculum[3],
                    url: curriculum[4]
                  )
                  course_curriculum.asset_type = "text" if !Constants.CurriculumAssetTypesValues.include?(curriculum[3])
                  chapter_index += 1 if curriculum[1] == "chapter"
                  lecture_index += 1 if curriculum[1] == "lecture"
                }
                
                @course.description = @description
                @course.requirement = @requirement
                @course.benefit     = @benefit
                @course.audience    = @audience

                @course.save
                
                @course = nil
                @curriculums = []
                @description = []
                @requirement = []
                @benefit = []
                @audience = []
              end

              break if (index == data.count - 1)
              @course_name = row[0]
              @course = Course.where(alias_name: @course_name).first

              binding.pry if @course.blank?
              @course.sub_title   = row[2]
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