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
    FEATURED = "featured"
    TOP_FREE = "top_free"
    TOP_PAID = "top_paid"
  end

  module OwnedCourseStatus
    FREE = "free"
    PENDING = "pending"
    CONFIRMED = "confirmed"
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

  module CurriculumAssetTypes
    VIDEO    = "Video"
    TEXT     = "Text"
    SLIDE    = "Slide"
    QUIZ     = "Quiz"
    DOCUMENT = "Document"
    AUDIO    = "Audio"
  end

  module UserLevel
    U1  = "u1"
    U2  = "u2"
    U5A = "u5a"
    U5B = "u5b"
    U6A = "u6a"
    U6B = "u6b"
    U7A = "u7a"
    U7B = "u7b"
    U8  = "u8"
    U9  = "u9"
  end

  module LabelTypes
    CATEGORY = "category"
    COURSE   = "course"
    USER     = "user"
  end
  
  module BannerTargetTypes
    BLANK = "blank"
    SELF  = "self"
  end

  module BannerTypes
    IMAGE = "image"
    POPUP = "popup"
  end

  module BannerLocation
    HEADER = "header"
  end

  module PaymentMethod
    DELIVERY = "delivery"
    BANK = "bank"
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