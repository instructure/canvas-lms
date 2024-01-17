# frozen_string_literal: true

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
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Lti
  class SubstitutionsHelper
    LIS_ROLE_MAP = {
      "user" => LtiOutbound::LTIRoles::System::USER,
      "siteadmin" => LtiOutbound::LTIRoles::System::SYS_ADMIN,

      "teacher" => LtiOutbound::LTIRoles::Institution::INSTRUCTOR,
      "student" => LtiOutbound::LTIRoles::Institution::STUDENT,
      "admin" => LtiOutbound::LTIRoles::Institution::ADMIN,
      "observer" => LtiOutbound::LTIRoles::Context::OBSERVER,
      AccountUser => LtiOutbound::LTIRoles::Institution::ADMIN,

      StudentEnrollment => LtiOutbound::LTIRoles::Context::LEARNER,
      TeacherEnrollment => LtiOutbound::LTIRoles::Context::INSTRUCTOR,
      TaEnrollment => LtiOutbound::LTIRoles::Context::TEACHING_ASSISTANT,
      DesignerEnrollment => LtiOutbound::LTIRoles::Context::CONTENT_DEVELOPER,
      ObserverEnrollment => LtiOutbound::LTIRoles::Context::OBSERVER,
      StudentViewEnrollment => LtiOutbound::LTIRoles::Context::LEARNER
    }.freeze

    LIS_V2_ROLE_MAP = {
      "user" => "http://purl.imsglobal.org/vocab/lis/v2/system/person#User",
      "siteadmin" => "http://purl.imsglobal.org/vocab/lis/v2/system/person#SysAdmin",

      "teacher" => "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Instructor",
      "student" => "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student",
      "admin" => "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator",
      AccountUser => "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator",
      TaEnrollment => ["http://purl.imsglobal.org/vocab/lis/v2/membership/instructor#TeachingAssistant", "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor"],
      StudentEnrollment => "http://purl.imsglobal.org/vocab/lis/v2/membership#Learner",
      TeacherEnrollment => "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor",
      DesignerEnrollment => "http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper",
      ObserverEnrollment => "http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor",
      StudentViewEnrollment => "http://purl.imsglobal.org/vocab/lis/v2/membership#Learner",
      Course => "http://purl.imsglobal.org/vocab/lis/v2/course#CourseOffering",
      Group => "http://purl.imsglobal.org/vocab/lis/v2/course#Group"
    }.freeze

    LIS_V2_ROLE_NONE = "http://purl.imsglobal.org/vocab/lis/v2/person#None"

    # Nearly identical to LIS_V2_ROLE_MAP except:
    #   1. Corrects typo in first TaEnrollment URI ('instructor'->'Instructor')
    #   2. Values uniformly (frozen) Arrays
    #   3. Has Group roles
    #   4. Has no Course role
    LIS_V2_LTI_ADVANTAGE_ROLE_MAP = {
      "user" => ["http://purl.imsglobal.org/vocab/lis/v2/system/person#User"].freeze,
      "siteadmin" => ["http://purl.imsglobal.org/vocab/lis/v2/system/person#SysAdmin"].freeze,
      "fake_student" => ["http://purl.imsglobal.org/vocab/lti/system/person#TestUser"].freeze,

      "teacher" => ["http://purl.imsglobal.org/vocab/lis/v2/institution/person#Instructor"].freeze,
      "student" => ["http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student"].freeze,
      "admin" => ["http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator"].freeze,
      AccountUser => ["http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator"].freeze,
      TaEnrollment => [
        "http://purl.imsglobal.org/vocab/lis/v2/membership/Instructor#TeachingAssistant",
        "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor"
      ].freeze,
      StudentEnrollment => ["http://purl.imsglobal.org/vocab/lis/v2/membership#Learner"].freeze,
      TeacherEnrollment => ["http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor"].freeze,
      DesignerEnrollment => ["http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper"].freeze,
      ObserverEnrollment => ["http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor"].freeze,
      StudentViewEnrollment => [
        "http://purl.imsglobal.org/vocab/lis/v2/membership#Learner",
        "http://purl.imsglobal.org/vocab/lti/system/person#TestUser",
      ].freeze,
      :group_member => ["http://purl.imsglobal.org/vocab/lis/v2/membership#Member"].freeze,
      :group_leader => [
        "http://purl.imsglobal.org/vocab/lis/v2/membership#Member",
        "http://purl.imsglobal.org/vocab/lis/v2/membership#Manager"
      ].freeze
    }.freeze

    # Inversion of LIS_V2_LTI_ADVANTAGE_ROLE_MAP, i.e.:
    #
    #   {
    #     '<lis-url>' => [<enrollment-class>, <logical-sys-or-insitution-role-name-string>, <enrollment-class>],
    #     '<lis-url>' => [<group-membership-type-symbol>, <group-membership-type-symbol>],
    #     ...
    #   }
    #
    # (Extra copy at the end is to undo the default value ([]))
    INVERTED_LIS_V2_LTI_ADVANTAGE_ROLE_MAP = LIS_V2_LTI_ADVANTAGE_ROLE_MAP.each_with_object(Hash.new([])) do |(key, values), memo|
      values.each { |value| memo[value] += [key] }
    end.reverse_merge({}).freeze

    LIS_V2_LTI_ADVANTAGE_ROLE_NONE = "http://purl.imsglobal.org/vocab/lis/v2/system/person#None"

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

    def all_roles(version = "lis1")
      case version
      when "lis2"
        role_map = LIS_V2_ROLE_MAP
        role_none = LIS_V2_ROLE_NONE
      when "lti1_3"
        role_map = LIS_V2_LTI_ADVANTAGE_ROLE_MAP
        role_none = LIS_V2_LTI_ADVANTAGE_ROLE_NONE
      else
        role_map = LIS_ROLE_MAP
        role_none = LtiOutbound::LTIRoles::System::NONE
      end

      if @user
        context_roles = course_enrollments.flat_map { |e| role_map[e.class] }
        institution_roles = @user.roles(@root_account, true).flat_map { |role| role_map[role] }
        if Account.site_admin.account_users_for(@user).present?
          institution_roles.push(*role_map["siteadmin"])
        end
        (context_roles + institution_roles).to_a.compact.uniq.sort.join(",")
      else
        role_none
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
        has_federated_parent = !@root_account.primary_settings_root_account?
        account_chain = @context.respond_to?(:account_chain) ? @context.account_chain(include_federated_parent: has_federated_parent) : []
        if @user && !account_chain.empty?
          @current_account_enrollments = Shard.partition_by_shard(account_chain) do |accounts_by_shard|
            AccountUser.active.where(user_id: @user, account_id: accounts_by_shard)
          end.flatten
        end
      end
      @current_account_enrollments
    end

    def current_lis_roles
      roles = enrollments_to_lis_roles(course_enrollments + account_enrollments)
      roles.push(*LIS_ROLE_MAP["siteadmin"]) if Account.site_admin.account_users_for(@user).present?
      roles.join(",").presence || LtiOutbound::LTIRoles::System::NONE
    end

    def concluded_course_enrollments
      @concluded_course_enrollments ||=
        (@context.is_a?(Course) && @user) ? @user.enrollments.concluded.where(course_id: @context.id).shard(@context.shard) : []
    end

    def concluded_lis_roles
      concluded_course_enrollments.empty? ? LtiOutbound::LTIRoles::System::NONE : enrollments_to_lis_roles(concluded_course_enrollments).join(",")
    end

    def granted_permissions(permissions_to_check)
      permissions_to_check.select { |p| @context.grants_right?(@user, p.to_sym) }.join(",")
    end

    def current_canvas_roles
      roles = (course_enrollments + account_enrollments).map { |e| e.role.name }.uniq
      roles = roles.map { |role| (role == "AccountAdmin") ? "Account Admin" : role } # to maintain backwards compatibility
      roles.join(",")
    end

    def current_canvas_roles_lis_v2(version = "lis2")
      roles = (course_enrollments + account_enrollments).map(&:class).uniq
      role_map = (version == "lti1_3") ? LIS_V2_LTI_ADVANTAGE_ROLE_MAP : LIS_V2_ROLE_MAP
      roles.map { |r| role_map[r] }.join(",")
    end

    def enrollment_state
      enrollments = @user ? @context.enrollments.where(user_id: @user.id).preload(:enrollment_state) : []
      return "" if enrollments.empty?

      (enrollments.any? { |membership| membership.state_based_on_date == :active }) ? LtiOutbound::LTIUser::ACTIVE_STATE : LtiOutbound::LTIUser::INACTIVE_STATE
    end

    def previous_lti_context_ids
      previous_course_ids_and_context_ids.filter_map(&:last).join(",")
    end

    def previous_course_ids
      previous_course_ids_and_context_ids.map(&:first).sort.join(",")
    end

    def section_ids
      course_enrollments.map(&:course_section_id).uniq.sort.join(",")
    end

    def section_restricted
      @context.is_a?(Course) && @user && @context.visibility_limited_to_course_sections?(@user)
    end

    def section_sis_ids
      course_sections.filter_map(&:sis_source_id).uniq.sort.join(",")
    end

    def sis_email
      sis_ps = SisPseudonym.for(@user, @context, type: :trusted, require_sis: true)
      sis_ps.sis_communication_channel&.path || sis_ps.communication_channels.ordered.active.first&.path if sis_ps
    end

    def tag_from_resource_link(resource_link)
      ContentTag.find_by(associated_asset: resource_link) if resource_link
    end

    def email
      # we are using sis_email for lti2 tools, or if the 'prefer_sis_email' extension is set for LTI 1
      # accept the setting as a boolean or string for backwards-compatibility
      e = if !lti1? ||
             @tool&.extension_setting(nil, :prefer_sis_email)&.to_s&.downcase == "true" ||
             @tool&.extension_setting(:tool_configuration, :prefer_sis_email)&.to_s&.downcase == "true"
            sis_email
          end
      e || @user.email
    end

    def adminable_account_ids_recursive_truncated(limit_chars: 40_000)
      full_list = @user.adminable_account_ids_recursive(starting_root_account: @root_account).join(",")

      # Some browsers break when the POST param field value is too long, as
      # seen in 95fad766f / INTEROP-6390. It's unclear what the limit is, but from
      # that, 40000 (1000 * course.lti_context_id.length) seems to be safe.
      if full_list.length <= limit_chars
        full_list
      else
        warning_str = ",truncated"
        # Get the index of the last "," before the limit (minus room for the warning string)
        # The maximum possible for truncate_after would be (limit_chars - warning_str.length),
        # in which case adding warning_str puts us exactly at limit_chars chars.
        truncate_after = full_list.rindex(",", limit_chars - warning_str.length)
        full_list[0...truncate_after] + warning_str
      end
    end

    def recursively_fetch_previous_lti_context_ids(limit: 1000)
      return "" unless @context.is_a?(Course)

      # now find all parents for locked folders
      last_migration_id = @context.content_migrations.where(workflow_state: :imported).order(id: :desc).limit(1).pluck(:id).first
      return "" unless last_migration_id

      use_alternate_settings = @root_account.feature_enabled?(:tune_lti_context_id_history_query)

      # we can cache on the last migration because even if copies are done elsewhere they won't affect anything
      # until a new copy is made to _this_ course
      Rails.cache.fetch(["recursive_copied_course_lti_context_ids", @context.global_id, last_migration_id, use_alternate_settings].cache_key) do
        # Finds content migrations for this course and recursively, all content
        # migrations for the source course of the migration -- that is, all
        # content migrations that directly or indirectly provided content to
        # this course. From there we get the unique list of courses, ordering by
        # which has the migration with the latest timestamp.
        results = Course.transaction do
          Course.connection.statement_timeout = 30 # seconds
          Course.connection.set("cpu_tuple_cost", 0.2, local: true) if use_alternate_settings
          Course.from(<<~SQL.squish)
            (WITH RECURSIVE all_contexts AS (
              SELECT context_id, source_course_id
              FROM #{ContentMigration.quoted_table_name}
              WHERE context_id=#{@context.id}
              UNION
              SELECT content_migrations.context_id, content_migrations.source_course_id
              FROM #{ContentMigration.quoted_table_name}
                INNER JOIN all_contexts t ON content_migrations.context_id = t.source_course_id
            )
            SELECT DISTINCT ON (courses.lti_context_id) courses.id, ct.finished_at, courses.lti_context_id
            FROM #{Course.quoted_table_name}
            INNER JOIN #{ContentMigration.quoted_table_name} ct
            ON ct.source_course_id = courses.id
            AND ct.workflow_state = 'imported'
            AND (ct.context_id IN (
              SELECT x.context_id
              FROM all_contexts x))
            ORDER BY courses.lti_context_id, ct.finished_at DESC
            ) as courses
          SQL
                .where.not(lti_context_id: nil).order(finished_at: :desc).limit(limit + 1).pluck(:lti_context_id)
        end

        # We discovered that at around 3000 lti_context_ids, the form data gets too
        # big and breaks the LTI launch. We decided to truncate after 1000 and note
        # it in the launch as "truncated"
        results = results.first(limit) << "truncated" if results.length > limit
        results.join(",")
      rescue ActiveRecord::QueryCanceled
        "timed out"
      end
    end

    private

    def lti1?
      @tool&.respond_to?(:extension_setting)
    end

    def previous_course_ids_and_context_ids
      return [] unless @context.is_a?(Course)

      @previous_ids ||= Course.where(
        ContentMigration.where(context_id: @context.id, workflow_state: :imported).where("content_migrations.source_course_id = courses.id").arel.exists
      ).pluck(:id, :lti_context_id)
    end
  end
end
