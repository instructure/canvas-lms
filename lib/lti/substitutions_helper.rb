#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Lti
  class SubstitutionsHelper
    LIS_ROLE_MAP = {
        'user' => LtiOutbound::LTIRoles::System::USER,
        'siteadmin' => LtiOutbound::LTIRoles::System::SYS_ADMIN,

        'teacher' => LtiOutbound::LTIRoles::Institution::INSTRUCTOR,
        'student' => LtiOutbound::LTIRoles::Institution::STUDENT,
        'admin' => LtiOutbound::LTIRoles::Institution::ADMIN,
        AccountUser => LtiOutbound::LTIRoles::Institution::ADMIN,

        StudentEnrollment => LtiOutbound::LTIRoles::Context::LEARNER,
        TeacherEnrollment => LtiOutbound::LTIRoles::Context::INSTRUCTOR,
        TaEnrollment => LtiOutbound::LTIRoles::Context::TEACHING_ASSISTANT,
        DesignerEnrollment => LtiOutbound::LTIRoles::Context::CONTENT_DEVELOPER,
        ObserverEnrollment => LtiOutbound::LTIRoles::Context::OBSERVER,
        StudentViewEnrollment => LtiOutbound::LTIRoles::Context::LEARNER
    }

    def initialize(context, root_account, user)
      @context = context
      @root_account = root_account
      @user = user
    end

    def account
      @account ||=
          case @context
            when Account
              @context
            when Course
              @context.account
            else
              @root_account
          end
    end

    def enrollments_to_lis_roles(enrollments)
      enrollments.map { |enrollment| Lti::LtiUserCreator::ENROLLMENT_MAP[enrollment.class] }.uniq
    end

    def all_roles
      if @user
        context_roles = course_enrollments.map { |enrollment| LIS_ROLE_MAP[enrollment.class] }
        institution_roles = @user.roles.map { |role| LIS_ROLE_MAP[role] }
        if Account.site_admin.account_users_for(@user).present?
          institution_roles << LIS_ROLE_MAP['siteadmin']
        end
        (context_roles + institution_roles).uniq.sort.join(',')
      else
        [LtiOutbound::LTIRoles::System::NONE]
      end
    end

    def course_enrollments
      return [] unless @context.is_a?(Course)
      @current_course_enrollments ||= @context.current_enrollments.where(user_id: @user.id)
    end

    def account_enrollments
      unless @current_account_enrollments
        @current_account_enrollments = []
        if @user && @context.respond_to?(:account_chain) && !@context.account_chain.empty?
          @current_account_enrollments = AccountUser.where(user_id: @user, account_id: @context.account_chain).shard(@context.shard)
        end
      end
      @current_account_enrollments
    end

    def current_lis_roles
      enrollments = course_enrollments + account_enrollments
      enrollments.size > 0 ? enrollments_to_lis_roles(enrollments).join(',') : LtiOutbound::LTIRoles::System::NONE
    end

    def concluded_course_enrollments
      @concluded_course_enrollments ||=
          @context.is_a?(Course) ? @user.concluded_enrollments.where(course_id: @context.id).shard(@context.shard) : []
    end

    def concluded_lis_roles
      concluded_course_enrollments.size > 0 ? enrollments_to_lis_roles(concluded_course_enrollments).join(',') : LtiOutbound::LTIRoles::System::NONE
    end

    def current_canvas_roles
      (course_enrollments.map(&:role) + account_enrollments.map(&:readable_type)).uniq.join(',')
    end

    def enrollment_state
      enrollments = @context.enrollments.where(user_id: @user.id)
      return '' if enrollments.size == 0
      enrollments.any? { |membership| membership.state_based_on_date == :active } ? LtiOutbound::LTIUser::ACTIVE_STATE : LtiOutbound::LTIUser::INACTIVE_STATE
    end
  end
end
