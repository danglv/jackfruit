module Constants
  module AppVersion
    VER_1 = "ver_1"
  end

  module TrackingTypes
    PAYMENT = "payment"
  end

  module  CurriculumTypes
    CHAPTER = "chapter"
    LECTURE = "lecture"
  end

  module CourseLang
    EN = "en"
    VI = "vi"
  end

  module PreviewMode
    TIME = 1.minutes
  end

  PROFILE_LINK_PREFIX = {
    :website => "http://",
    :facebook => "http://facebook.com/",
    :google => "http://plus.google.com/",
    :twitter => "http://twitter.com/",
    :linkedin => "http://linkedin.com/",
    :youtube => "http://youtube.com/"
  }

  USER_LANG_MAPPING = {
    "vi" => "Tiếng Việt",
    "en" => "Tiếng Anh",
    "fr" => "Tiếng Pháp"
  }

  module UserLang
    EN = "en"
    VI = "vi"
  end

  module Labels
    FEATURED = "featured"
    TOP_PAID = "top_paid"
    TOP_FREE = "top_free"
  end

  module PaymentStatus
    RESERVE = "reserve" # Not created yet, but expect to be created, apply for a preview course ...
    CREATED = "created" # Created and waiting for further processing
    PENDING = "pending" # Being pending, waiting for next processing
    PROCESS = "process" # Being processing, waiting for result
    SUCCESS = "success" # Success
    CANCEL  = "cancel"  # Canceled
  end

  module OwnedCourseTypes
    LEARNING = "learning"
    TEACHING = "teaching"
    WISHLIST = "wishlist"
    PREVIEW  = "preview"
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
    BLANK = "_blank"
    SELF  = "_self"
  end

  module BannerTypes
    IMAGE = "image"
    POPUP = "popup"
  end

  module BannerLocation
    HEADER = "header"
  end

  module PaymentMethod
    NONE = 'none'
    COD = "cod"
    TRANSER = "transfer"
    ONLINE_PAYMENT = "online_payment"
    CARD = "card"
    DELIVERY = "delivery"
  end

  module CourseVersions
    TEST = "test"
    PUBLIC = "public"
  end

  module Seller
    TOPICA = "topica"
    INSTRUCTOR = "instructor"
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