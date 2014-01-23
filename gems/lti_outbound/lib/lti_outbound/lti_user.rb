module LtiOutbound
  class LTIUser < LTIContext
    ACTIVE_STATE = 'active'
    INACTIVE_STATE = 'inactive'

    attr_accessor :avatar_url, :email, :login_id, :first_name, :last_name, :name,
                  :current_enrollments, :concluded_enrollments,
                  :sis_user_id

    add_variable_mapping '.login_id', :login_id
    add_variable_mapping '.enrollment_state', :enrollment_state
    add_variable_mapping '.concluded_roles', :concluded_roles
    add_variable_mapping '.full', :full_name
    add_variable_mapping '.family', :family_name
    add_variable_mapping '.given', :given_name
    add_variable_mapping '.timezone', :timezone

    def current_role_types
      roles = current_enrollments.map(&:type).join(',') if current_enrollments && current_enrollments.size > 0
      roles || LtiOutbound::LTIRole::NONE
    end

    def concluded_role_types
      roles = concluded_enrollments.map(&:type).join(',') if concluded_enrollments && concluded_enrollments.size > 0
      roles || LtiOutbound::LTIRole::NONE
    end

    def enrollment_state
      current_enrollments.any? { |e| e.active? } ? LtiOutbound::LTIUser::ACTIVE_STATE : LtiOutbound::LTIUser::INACTIVE_STATE
    end

    def learner?
      current_enrollments.any? { |e| e.type == LtiOutbound::LTIRole::LEARNER }
    end
  end
end