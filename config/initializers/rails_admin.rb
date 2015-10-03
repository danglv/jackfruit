module RailsAdmin
  module Config
    module Fields
      module Types
        class Datetime < RailsAdmin::Config::Fields::Base
          def value
            @format = :short
            value_in_default_time_zone = bindings[:object].send(name)
            return nil if value_in_default_time_zone.nil?
            pacific_time_zone = ActiveSupport::TimeZone.new('Hanoi')
            value_in_default_time_zone.in_time_zone(pacific_time_zone)
          end
        end
      end
    end

    module Actions
      class Delete < RailsAdmin::Config::Actions::Base
        register_instance_option :visible? do
          if bindings[:object].class.to_s != 'Payment'
            true
          else
            false
          end
        end
      end

      class Edit < RailsAdmin::Config::Actions::Base
        register_instance_option :visible? do
          if bindings[:object].class.to_s != 'Payment'
            true
          elsif bindings[:object].status == 'pending'
            true
          else
            false
          end
        end
      end
    end
  end
end

RailsAdmin.config do |config|
  config.main_app_name = ["PEDIA", "Pedia"]
  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  ## == Cancan ==
  config.authorize_with :cancan

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    history_index
    history_show
  end

  config.model 'Payment' do
    list do
      field :created_at, :datetime
      field :updated_at
      field :user
      field :course
      field :method
      field :status
      field :money
      field :coupons
    end

    show do
      field :status
      field :cod_code
      field :user
      field :course
      field :email
      field :mobile
      field :method
      field :address
      field :city
      field :district
      field :coupons
      field :money
    end

    edit do
      field :status
      field :cod_code do
        visible do
          bindings[:object].status == Constants::PaymentMethod::COD
        end
      end
      field :user
      field :course
      field :email
      field :mobile
      field :method
      field :address
      field :city
      field :district
      field :cod_code
    end
  end

  config.model 'User' do
    list do
      field :created_at
      field :name
      field :email
      field :role
    end

    create do
      field :name
      field :email
      field :password
      field :password_confirmation
      field :role
      field :lang
      field :labels
      field :instructor_profile
      field :courses
      field :avatar
    end 

    show do
      field :created_at
      field :name
      field :email
      field :role
      field :avatar do
        pretty_value do
          unless bindings[:object].avatar.blank?
            html = bindings[:view].tag(:img, { :src => bindings[:object].avatar }).html_safe
            bindings[:view].content_tag(:a, html, href: bindings[:object].avatar)
          else
            bindings[:view].content_tag(:span, "-")
          end
        end
      end
    end

    edit do
      field :name
      field :email
      field :password
      field :password_confirmation
      field :role
      field :lang
      field :labels
      field :instructor_profile
      field :courses
      field :avatar
    end
  end

  config.model 'UserGetCourseLog' do
    list do
      field :created_at
      field :user
      field :course
    end
  end

  config.model 'LevelLog' do
    list do
      field :created_at
      field :user
      field :level_before_up
      field :level_after_up
    end
  end

  config.model 'Feedback' do
    list do
      field :created_at
      field :name
      field :email
      field :content
    end
  end

  config.model 'Course' do
    list do
      field :created_at
      field :alias_name
      field :name
      field :lang
      field :price
      field :user
    end

    # edit do
    #   exclude_fields :reviews
    # end
  end

  config.model 'Banner' do
    list do
      field :created_at
      field :enabled
      field :location
      field :url
    end

    show do
      field :location
      field :target
      field :layout
      field :type
      field :opened_users
      field :banner_image do
        pretty_value do
          unless bindings[:object].banner_image.blank?
            html = bindings[:view].tag(:img, { :src => bindings[:object].banner_image }).html_safe
            bindings[:view].content_tag(:a, html, href: bindings[:object].banner_image)
          else
            bindings[:view].content_tag(:span, "-")
          end
        end
      end
    end

    edit do
    end
  end
end