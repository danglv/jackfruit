class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
      user = User.current # guest user (not logged in)

      if user.role == "admin" 
        can :manage, :all
        can :access, :rails_admin # needed to access RailsAdmin
        can :dashboard            # dashboard access
        # includes
        can :history, :all
      else
      end
  end
end