module Constants
  module  CurriculumTypes
    CHAPTER = "chapter"
    LECTURE = "lecture"
  end

  module CourseLang
    EN = "en"
    VI = "vi"
  end

  module Labels
    NEW    = "new"
    STUDENT= "student"
  end

  module OwnedCourseTypes
    LEARNING = "learning"
    TEACHING = "teaching"
    WISHLIST = "wishlist"
  end

  module SortTypes
    DEFAULT   = 1
    RATING    = 2
    NEWEST    = 3
    PRICE_ASC = 4
    PRICE_DESC= 5
  end

  class << self
    Constants.constants.each {|module_name|
      sub_module = Constants.const_get(module_name)
      next unless sub_module.is_a?(Module)

      define_method(module_name.to_s + "Values") {
        sub_module.constants.collect {|const_name| sub_module.const_get(const_name)}
      }
    }
  end
end