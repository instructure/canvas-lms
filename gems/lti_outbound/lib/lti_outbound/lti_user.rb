module LtiOutbound
  class LTIUser < LTIContext
    ACTIVE_STATE = 'active'
    INACTIVE_STATE = 'inactive'

    proc_accessor :avatar_url, :concluded_roles, :currently_active_in_course,
                  :current_roles, :first_name, :email, :last_name, :login_id,
                  :name, :timezone

    def current_role_types
      roles = current_roles.join(',') if current_roles && current_roles.size > 0
      roles || LtiOutbound::LTIRole::NONE
    end

    def concluded_role_types
      roles = concluded_roles.join(',') if concluded_roles && concluded_roles.size > 0
      roles || LtiOutbound::LTIRole::NONE
    end

    def enrollment_state
      {
          true => LtiOutbound::LTIUser::ACTIVE_STATE,
          false => LtiOutbound::LTIUser::INACTIVE_STATE,
          nil => nil
      }[currently_active_in_course]
    end

    def learner?
      current_roles.any? { |e| e == LtiOutbound::LTIRole::LEARNER }
    end

  end
end