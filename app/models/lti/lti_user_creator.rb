#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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

    def initialize(canvas_user, canvas_root_account, canvas_tool, canvas_context)
      @canvas_user = canvas_user
      @canvas_root_account = canvas_root_account
      @canvas_tool = canvas_tool
      @canvas_context = canvas_context
      @opaque_identifier = @canvas_tool.opaque_identifier_for(@canvas_user)
    end

    def convert
      lti_helper = Lti::SubstitutionsHelper.new(@canvas_context, @canvas_root_account, @canvas_user, @canvas_tool)
      user = ::LtiOutbound::LTIUser.new
      user.id = @canvas_user.id
      user.avatar_url = @canvas_user.avatar_url
      user.email = lti_helper.email
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
      user.current_observee_ids = -> { current_course_observee_lti_context_ids() }
      user.current_roles = lti_helper.current_lis_roles.split(',')

      user
    end

    private
    def pseudonym
      unless instance_variable_defined?(:@pseudonym)
        @pseudonym = SisPseudonym.for(@canvas_user, @canvas_root_account, type: :trusted, require_sis: false)
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

      @current_course_enrollments ||= @canvas_user.enrollments.current.where(course_id: @canvas_context).preload(:enrollment_state).to_a
    end

    def current_course_observee_lti_context_ids
      return [] unless @canvas_context.is_a?(Course)

      @current_course_observee_lti_context_ids ||= @canvas_user.observer_enrollments
                                                               .current
                                                               .where(course_id: @canvas_context)
                                                               .preload(:associated_user)
                                                               .map { |e| e.try(:associated_user).try(:lti_context_id) }.compact
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
          @canvas_context.is_a?(Course) ? @canvas_user.enrollments.concluded.where(course_id: @canvas_context).to_a : []
    end
  end
end
