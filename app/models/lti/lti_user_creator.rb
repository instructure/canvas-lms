module Lti
  class LtiUserCreator
    # deprecated mapping
    ENROLLMENT_MAP = {
        StudentEnrollment => LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER,
        TeacherEnrollment => LtiOutbound::LTIRoles::ContextNotNamespaced::INSTRUCTOR,
        TaEnrollment => LtiOutbound::LTIRoles::ContextNotNamespaced::TEACHING_ASSISTANT,
        DesignerEnrollment => LtiOutbound::LTIRoles::ContextNotNamespaced::CONTENT_DEVELOPER,
        ObserverEnrollment => LtiOutbound::LTIRoles::ContextNotNamespaced::OBSERVER,
        AccountUser => LtiOutbound::LTIRoles::Institution::ADMIN,
        StudentViewEnrollment => LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER
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

      lti_helper = Lti::SubstitutionsHelper.new(@canvas_context, @canvas_root_account, @canvas_user)
      user.current_roles = lti_helper.current_lis_roles.split(',')

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

      @current_course_enrollments ||= @canvas_user.current_enrollments.where(course_id: @canvas_context).to_a
    end

    def current_account_enrollments()
      unless @current_account_enrollments
        if @canvas_context.respond_to?(:account_chain) && !@canvas_context.account_chain.empty?
          @current_account_enrollments = @canvas_user.account_users.where(account_id: @canvas_context.account_chain).uniq.to_a
        else
          @current_account_enrollments = []
        end
      end
      @current_account_enrollments
    end

    def concluded_course_enrollments
      @concluded_course_enrollments ||=
          @canvas_context.is_a?(Course) ? @canvas_user.concluded_enrollments.where(course_id: @canvas_context).to_a : []
    end
  end
end
