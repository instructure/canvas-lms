module Lti
  class LtiUserCreator
    ENROLLMENT_MAP = {
        StudentEnrollment => LtiOutbound::LTIRole::LEARNER,
        TeacherEnrollment => LtiOutbound::LTIRole::INSTRUCTOR,
        TaEnrollment => LtiOutbound::LTIRole::TEACHING_ASSISTANT,
        DesignerEnrollment => LtiOutbound::LTIRole::CONTENT_DEVELOPER,
        ObserverEnrollment => LtiOutbound::LTIRole::OBSERVER,
        AccountUser => LtiOutbound::LTIRole::ADMIN,
        StudentViewEnrollment => LtiOutbound::LTIRole::LEARNER
    }

    def initialize(canvas_user, canvas_root_account, canvas_tool, canvas_context, variable_substitutor = nil)
      @canvas_user = canvas_user
      @canvas_root_account = canvas_root_account
      @canvas_context = canvas_context
      @opaque_identifier = canvas_tool.opaque_identifier_for(@canvas_user)
      @variable_substitutor = variable_substitutor
      @pseudonym = false
    end

    def convert
      user = ::LtiOutbound::LTIUser.new

      user.id = @canvas_user.id
      user.avatar_url = @canvas_user.avatar_url
      user.email = @canvas_user.email
      user.first_name = @canvas_user.first_name
      user.last_name = @canvas_user.last_name
      user.name = @canvas_user.name
      user.opaque_identifier = @opaque_identifier
      user.timezone = Time.zone.tzinfo.name
      user.current_roles = -> { current_roles() }
      user.currently_active_in_course = -> { currently_active_in_course?() }
      user.concluded_roles = -> { concluded_roles() }
      user.login_id = -> { pseudonym ? pseudonym.unique_id : nil }
      user.sis_source_id = -> { pseudonym ? pseudonym.sis_user_id : nil }

      if @variable_substitutor
        @variable_substitutor.add_substitution('$Canvas.user.id', user.id)
        @variable_substitutor.add_substitution('$Canvas.user.sisSourceId', -> { user.sis_source_id })
        @variable_substitutor.add_substitution('$Canvas.user.loginId', -> { user.login_id })
        @variable_substitutor.add_substitution('$Canvas.enrollment.enrollmentState', -> { user.enrollment_state })
        @variable_substitutor.add_substitution('$Canvas.membership.concludedRoles', -> { user.concluded_role_types })
        @variable_substitutor.add_substitution('$Canvas.membership.roles', -> {
          (current_course_enrollments.map(&:role) + current_account_enrollments.map(&:readable_type)).uniq.join(',')
        })
      end

      user
    end

    private
    def pseudonym
      if @pseudonym === false
        @pseudonym ||= @canvas_user.find_pseudonym_for_account(@canvas_root_account)
      end
      @pseudonym
    end

    def current_roles
      map_enrollments_to_roles(current_course_enrollments + current_account_enrollments)
    end

    def currently_active_in_course?
      current_course_enrollments.any? { |membership| membership.state_based_on_date == :active } if @canvas_context.is_a?(Course)
    end

    def concluded_roles
      map_enrollments_to_roles(concluded_course_enrollments)
    end

    def map_enrollments_to_roles(enrollments)
      enrollments.map { |enrollment| ENROLLMENT_MAP[enrollment.class] }.uniq
    end

    def current_course_enrollments
      return [] unless @canvas_context.is_a?(Course)

      @current_course_enrollments ||= @canvas_user.current_enrollments.find_all_by_course_id(@canvas_context.id)
    end

    def current_account_enrollments()
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