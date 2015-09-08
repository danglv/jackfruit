namespace :seeds do
  desc "seeding category and course name premium"
  task seed_category_and_course_name_paid: :environment do
    csv_file_name = "db/seeding_data/version1.0.3/category/"
    csv_file_name += "Alias - Premium"
    data = load_csv_file(csv_file_name) and true

    @category_alias_name = @sub_category_alias_name = ""

    data.each_with_index{|row, index|
      next if ( row[0] == 'Category' || row[0] == 'category')

      if !row[0].blank?
        @category_alias_name = row[1] #nomalize_string(row[0])
        category = Category.find_or_initialize_by(
          id: @category_alias_name,
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
          @sub_category_alias_name = row[3] #nomalize_string(row[1])
          category = Category.where(id: @category_alias_name).first
          binding.pry if category.blank?

          sub_category = Category.find_or_initialize_by(
            id: "#{@category_alias_name}_#{@sub_category_alias_name}",
          )
          sub_category.name = row[2]
          sub_category.alias_name = row[3]
          sub_category.parent_category_id = category.id.to_s

          if sub_category.save
            puts "Create sub-category #{row[2]} of category #{@category_alias_name}"
          else
            binding.pry
          end

          category.child_categories << sub_category
          category.save
        end

        if !row[4].blank?
          course = Course.find_or_initialize_by(
            alias_name: row[5],
            lang: "vi"
          )

          course.name = row[4]
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
    csv_file_name = "db/seeding_data/version1.0.3/category/"
    csv_file_name += "Alias - Free"
    data = load_csv_file(csv_file_name) and true

    @category_alias_name = @sub_category_alias_name = ""

    data.each_with_index{|row, index|
      next if ( row[0] == 'Category' || row[0] == 'category')

      if !row[0].blank?
        @category_alias_name = row[1] #nomalize_string(row[0])
        category = Category.find_or_initialize_by(
          id: @category_alias_name,
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
          @sub_category_alias_name = row[3] #nomalize_string(row[1])
          category = Category.where(id: @category_alias_name).first
          binding.pry if category.blank?

          sub_category = Category.find_or_initialize_by(
            id: "#{@category_alias_name}_#{@sub_category_alias_name}",
          )
          sub_category.name = row[2]
          sub_category.alias_name = row[3]
          sub_category.parent_category_id = category.id.to_s

          if sub_category.save
            puts "Create sub-category #{row[2]} of category #{@category_alias_name}"
          else
            binding.pry
          end

          category.child_categories << sub_category
          category.save
        end
        if !row[4].blank?
          course = Course.find_or_initialize_by(
            alias_name: row[5],
            lang: "vi"
          )

          course.name = row[4]
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
      csv_file_name = "db/seeding_data/version1.0.3/paid/"
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
              if !@course.blank?
                chapter_index = 0
                lecture_index = 0
            
                @curriculums.each_with_index {|curriculum, x|
                  course_curriculum = @course.curriculums.find_or_initialize_by(
                    order: x,
                  )
                  course_curriculum.title = curriculum[0]
                  course_curriculum.description = curriculum[2]
                  course_curriculum.chapter_index = chapter_index
                  course_curriculum.lecture_index = lecture_index
                  course_curriculum.type = curriculum[1]
                  course_curriculum.asset_type = curriculum[3]
                  course_curriculum.url = curriculum[4]
                  course_curriculum.asset_type = "Text" if !Constants.CurriculumAssetTypesValues.include?(curriculum[3])
                  chapter_index += 1 if curriculum[1] == "chapter"
                  lecture_index += 1 if curriculum[1] == "lecture"
                }
                
                @course.description = @description
                @course.requirement = @requirement
                @course.benefit     = @benefit
                @course.audience    = @audience

                binding.pry unless @course.save
                
                @course = nil
                @curriculums = []
                @description = []
                @requirement = []
                @benefit = []
                @audience = []
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

              end

              break if (index == data.count - 1)
              @course_name = row[0]
              @course = Course.where(alias_name: @course_name).first

              binding.pry if @course.blank?
              @course.sub_title  = row[2]
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
      csv_file_name = "db/seeding_data/version1.0.3/free/"
      csv_file_name += "#{category.id}"
      @category_count = 0

      category.child_categories.each {|sub_category|
        if !File.exist?("#{csv_file_name} - #{sub_category.alias_name}.csv")
          # puts "#{csv_file_name} - #{sub_category.alias_name}.csv"
          next
        else
          @category_count += 1
          # @count += 1
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
                    order: x,
                  )
                  course_curriculum.title = curriculum[0]
                  course_curriculum.description = curriculum[2]
                  course_curriculum.chapter_index = chapter_index
                  course_curriculum.lecture_index = lecture_index
                  course_curriculum.type = curriculum[1]
                  course_curriculum.asset_type = curriculum[3]
                  course_curriculum.url = curriculum[4]
                  course_curriculum.asset_type = "Text" if !Constants.CurriculumAssetTypesValues.include?(curriculum[3])
                  chapter_index += 1 if curriculum[1] == "chapter"
                  lecture_index += 1 if curriculum[1] == "lecture"
                }
                
                @course.description = @description
                @course.requirement = @requirement
                @course.benefit     = @benefit
                @course.audience    = @audience

                binding.pry unless @course.save
                @count += 1
                @course = nil
                @curriculums = []
                @description = []
                @requirement = []
                @benefit = []
                @audience = []
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

              end

              break if (index == data.count - 1)
              @course_name = row[0]
              @course = Course.where(alias_name: @course_name).first

              binding.pry if @course.blank?
              @course.sub_title  = row[2]
              @course.intro_link = row[3]
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
    images = Dir["db/seeding_data/version1.0.3/mapping_image_course/images_detail/*"]
    file_name =  "db/seeding_data/version1.0.3/mapping_image_course/name_mapping"
    data = load_csv_file(file_name) and true

    # chuẩn hóa tên file & ten course
    images_name = []
    
    images.each{|image|
      old_name = image.gsub("db/seeding_data/version1.0.3/mapping_image_course/images_detail/", "")
      image.gsub!("db/seeding_data/version1.0.3/mapping_image_course/images_detail/", "")
      # image.gsub!("x-.", "")
      # image.gsub!("x-", "")
      image.gsub!("_", "-")
      image.gsub!("\u0096", "")
      image.gsub!("----", "-")
      image.gsub!("---", "-")
      image.gsub!("--", "-")
      image.gsub!(" .", ".")
      image.gsub!("..", ".")
      image.gsub!(".png", "")
      images_name << [nomalize_string(image), old_name]
    }

    images_name.each {|image_name|
      image_name[0].gsub!("----", "-")
      image_name[0].gsub!("---", "-")
      image_name[0].gsub!("--", "-")
      image_name[0].gsub!(" .", ".")
      image_name[0].gsub!("..", ".")
    }

    results = []
    data.each{|row|
      if (!row[0].blank? && !row[1].blank?)
        row[0].gsub!(":", "")
        row[0].gsub!("\"", "")
        row[0] = nomalize_string(row[0])
        row[0].gsub!("---", "-")
        row[0].gsub!("--", "-")
        row[0].gsub!(" .", ".")
        results << [row[0], row[1]] 
      end
    }

    course_name = results.map(&:first)
    all_course = []
    images_name.each {|image_name|
      if course_name.include?(image_name[0])

        results.select {|k|
          all_course << [image_name[1], k[1]] if k[0] == image_name[0]
        }
      end
    }
    # results.each {|result|
    #   result[0] = 
    # }
  end

  desc "seeding images_url for course"
  task seed_images_url_course: :environment do
    url = '/uploads/images/'
    Course.all.each {|c|
      c.image = url + "#{c.alias_name}.png"
      c.save
    }
  end

  desc "seeding images_url for course"
  task seed_images_detail_url_course: :environment do
    url = '/uploads/images/detail/'
    Course.where(:price.gt => 0).each {|c|
      c.intro_image = url + "#{c.alias_name}.png"
      c.save
    }
  end

  desc "refine data user::course"
  task refine_data_user_course: :environment do
    User.all.each {|u|
      if u.courses.count > 0
        u.courses.each {|c|
          binding.pry if c.course.blank?
          if c.course.price == 0
            c.payment_status = Constants::PaymentStatus::SUCCESS
          else
            c.payment_status = Constants::PaymentStatus::PENDING
          end
        }
        binding if u.save
      end
    }
  end

  desc "seeds one course"
  task seed_one_course_paid: :environment do
    csv_file_name = "public/08-09-2015/REV03 - Dev.Upload - Sheet1"
    data = load_csv_file(csv_file_name) and true
    @curriculums = []
    @description = []
    @requirement = []
    @benefit = []
    @audience = []
    @course = Course.find_or_initialize_by(alias_name: data[1][0])
    @course.name = data[1][1]
    @course.sub_title = data[1][2]
    @username = data[1][12]
    @intro_link = data[1][13]
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
    }
    chapter_index = 0
    lecture_index = 0
    @curriculums.each_with_index {|curriculum, x|
      course_curriculum = @course.curriculums.find_or_initialize_by(
        order: x,
      )
      course_curriculum.title = curriculum[0]
      course_curriculum.description = curriculum[2]
      course_curriculum.chapter_index = chapter_index
      course_curriculum.lecture_index = lecture_index
      course_curriculum.type = curriculum[1]
      course_curriculum.asset_type = curriculum[3]
      course_curriculum.url = curriculum[4]
      course_curriculum.asset_type = "Text" if !Constants.CurriculumAssetTypesValues.include?(curriculum[3])
      chapter_index += 1 if curriculum[1] == "chapter"
      lecture_index += 1 if curriculum[1] == "lecture"
    }
    
    @course.description = @description
    @course.requirement = @requirement
    @course.benefit     = @benefit
    @course.audience    = @audience
    @course.intro_link = @intro_link
    @user = User.where(name: @username).first

    binding.pry if @user.blank?
    unless @user
      @user = User.new(name: @username, password:"12345678", email: "#{@username}@tudemy.vn")
      @user.instructor_profile = User::InstructorProfile.new()
      @user.save      
    end

    @course.enabled = true
    @course.version = "public"
    @course.user = @user
    binding.pry unless @course.save
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