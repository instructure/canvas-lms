module Lti
  class LtiRolesCreator
    ENROLLMENT_MAP = {
        StudentEnrollment => LtiOutbound::LTIRole::LEARNER,
        TeacherEnrollment => LtiOutbound::LTIRole::INSTRUCTOR,
        TaEnrollment => LtiOutbound::LTIRole::TEACHING_ASSISTANT,
        DesignerEnrollment => LtiOutbound::LTIRole::CONTENT_DEVELOPER,
        ObserverEnrollment => LtiOutbound::LTIRole::OBSERVER,
        AccountUser => LtiOutbound::LTIRole::ADMIN,
        StudentViewEnrollment => LtiOutbound::LTIRole::LEARNER
    }

    def initialize(canvas_user, canvas_context)
      @canvas_user = canvas_user
      @canvas_context = canvas_context

    end

    def current_roles
      map_enrollments_to_roles(current_course_enrollments + current_account_enrollments)
    end

    def currently_active_in_course?
      current_course_enrollments.any?{|membership| membership.state_based_on_date == :active}
    end

    def concluded_roles
      map_enrollments_to_roles(concluded_course_enrollments)
    end

    private
    def map_enrollments_to_roles(enrollments)
      enrollments.map { |enrollment| ENROLLMENT_MAP[enrollment.class] }.uniq
    end

    def current_course_enrollments
      return [] unless @canvas_context.is_a?(Course)

      @current_course_enrollments ||= @canvas_user.current_enrollments.find_all_by_course_id(@canvas_context.id)
    end

    def current_account_enrollments
      unless @current_account_enrollments
        if @canvas_context.respond_to?(:account_chain) && !@canvas_context.account_chain_ids.empty?
          @current_account_enrollments = @canvas_user.account_users.find_all_by_account_id(@canvas_context.account_chain_ids).uniq
        else
          @current_account_enrollments = []
        end
      end
      @current_account_enrollments
    end

    def concluded_course_enrollments
      @concluded_course_enrollments ||=
          @canvas_context.is_a?(Course) ? @canvas_user.concluded_enrollments.find_all_by_course_id(@canvas_context.id) : []
    end
  end
end
