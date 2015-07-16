module Constants
  module  CurriculumTypes
    CHAPTER = "chapter"
    LECTURE = "lecture"
  end

  module CourseLang
    EN = "en"
    VI = "vi"
  end

  module UserLang
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

  module ContentTypes
    JSON = "json"
    HTML = "html"
  end

  module BudgetTypes
    FREE = "free"
    PAID = "paid"
  end

  module CourseLevel
    All          = "all"
    BEGINNER     = "beginner"
    INTERMEDIATE = "intermediate"
    EXPERT       = "expert"
  end

  module Ordering
    RATING    = "ratings"
    NEWEST    = "newest"
    PRICE_ASC = "price-low-to-high"
    PRICE_DESC= "price-high-to-low"
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