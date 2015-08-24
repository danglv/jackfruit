class Ability
  include CanCan::Ability

  def initialize(admin)
    # Define abilities for the passed in user here. For example:
    #
      # user = User.current # guest user (not logged in)

      # if user.role == "admin" 
      #   can :manage, :all
      #   can :access, :rails_admin # needed to access RailsAdmin
      #   can :dashboard            # dashboard access
      # else
      # end
      can :access, :rails_admin
      return unless admin

      admin = Admin.current

      # if admin.role == "sysop" 
        can :manage, :all
        can :access, :rails_admin # needed to access RailsAdmin
        can :dashboard
      # else
      # end
  end
end
