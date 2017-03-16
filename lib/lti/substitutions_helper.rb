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
        'observer' => LtiOutbound::LTIRoles::Context::OBSERVER,
        AccountUser => LtiOutbound::LTIRoles::Institution::ADMIN,

        StudentEnrollment => LtiOutbound::LTIRoles::Context::LEARNER,
        TeacherEnrollment => LtiOutbound::LTIRoles::Context::INSTRUCTOR,
        TaEnrollment => LtiOutbound::LTIRoles::Context::TEACHING_ASSISTANT,
        DesignerEnrollment => LtiOutbound::LTIRoles::Context::CONTENT_DEVELOPER,
        ObserverEnrollment => LtiOutbound::LTIRoles::Context::OBSERVER,
        StudentViewEnrollment => LtiOutbound::LTIRoles::Context::LEARNER
    }

    LIS_V2_ROLE_MAP = {
      'user' => 'http://purl.imsglobal.org/vocab/lis/v2/system/person#User',
      'siteadmin' => 'http://purl.imsglobal.org/vocab/lis/v2/system/person#SysAdmin',

      'teacher' => 'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Instructor',
      'student' => 'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student',
      'admin' => 'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator',
      AccountUser => 'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator',
      TaEnrollment => ['http://purl.imsglobal.org/vocab/lis/v2/membership/instructor#TeachingAssistant', 'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'],
      StudentEnrollment => 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner',
      TeacherEnrollment => 'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor',
      DesignerEnrollment => 'http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper',
      ObserverEnrollment => 'http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor',
      StudentViewEnrollment => 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'
    }

    LIS_V2_ROLE_NONE = 'http://purl.imsglobal.org/vocab/lis/v2/person#None'

    def initialize(context, root_account, user, tool = nil)
      @context = context
      @root_account = root_account
      @user = user
      @tool = tool
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

    def all_roles(version = 'lis1')
      case version
        when 'lis2'
          role_map = LIS_V2_ROLE_MAP
          role_none = LIS_V2_ROLE_NONE
        else
          role_map = LIS_ROLE_MAP
          role_none = LtiOutbound::LTIRoles::System::NONE
      end

      if @user
        context_roles = course_enrollments.each_with_object(Set.new) { |role, set| set.add([*role_map[role.class]].join(",")) }

        institution_roles = @user.roles(@root_account).map { |role| role_map[role] }
        if Account.site_admin.account_users_for(@user).present?
          institution_roles << role_map['siteadmin']
        end
        (context_roles + institution_roles).to_a.compact.uniq.sort.join(',')
      else
        [role_none]
      end
    end

    def course_enrollments
      return [] unless @context.is_a?(Course) && @user
      @current_course_enrollments ||= @context.current_enrollments.where(user_id: @user.id)
    end

    def course_sections
      return [] unless @context.is_a?(Course) && @user
      @current_course_sections ||= @context.course_sections.where(id: course_enrollments.map(&:course_section_id)).select("id, sis_source_id")
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
          @context.is_a?(Course) && @user ? @user.enrollments.concluded.where(course_id: @context.id).shard(@context.shard) : []
    end

    def concluded_lis_roles
      concluded_course_enrollments.size > 0 ? enrollments_to_lis_roles(concluded_course_enrollments).join(',') : LtiOutbound::LTIRoles::System::NONE
    end

    def current_canvas_roles
      roles = (course_enrollments + account_enrollments).map(&:role).map(&:name).uniq
      roles = roles.map{|role| role == "AccountAdmin" ? "Account Admin" : role} # to maintain backwards compatibility
      roles.join(',')
    end

    def enrollment_state
      enrollments = @user ? @context.enrollments.where(user_id: @user.id).preload(:enrollment_state) : []
      return '' if enrollments.size == 0
      enrollments.any? { |membership| membership.state_based_on_date == :active } ? LtiOutbound::LTIUser::ACTIVE_STATE : LtiOutbound::LTIUser::INACTIVE_STATE
    end

    def previous_lti_context_ids
      previous_course_ids_and_context_ids.map(&:lti_context_id).compact.join(',')
    end

    def previous_course_ids
      previous_course_ids_and_context_ids.map(&:id).sort.join(',')
    end

    def section_ids
      course_enrollments.map(&:course_section_id).uniq.sort.join(',')
    end

    def section_sis_ids
      course_sections.map(&:sis_source_id).compact.uniq.sort.join(',')
    end

    def sis_email
      if @user&.pseudonym&.sis_user_id
        tablename = Pseudonym.quoted_table_name
        query = "INNER JOIN #{tablename} ON communication_channels.id=pseudonyms.sis_communication_channel_id"
        @user.communication_channels.joins(query).limit(1).pluck(:path).first
      end
    end

    def email
      # we are using sis_email for lti2 tools, or if the 'prefer_sis_email' extension is set for LTI 1
      e = if !lti1? || @tool&.extension_setting(nil, :prefer_sis_email)&.downcase == "true"
            sis_email
          end
      e || @user.email
    end

    private

    def lti1?
      @tool&.respond_to?(:extension_setting)
    end

    def previous_course_ids_and_context_ids
      return [] unless @context.is_a?(Course)
      @previous_ids ||= Course.where(
        "EXISTS (?)", ContentMigration.where(context_id: @context.id, workflow_state: :imported).where("content_migrations.source_course_id = courses.id")
      ).select("id, lti_context_id")
    end

  end
end
