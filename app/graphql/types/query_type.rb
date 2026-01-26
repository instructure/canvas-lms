# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Types
  class QueryType < ApplicationObjectType
    include GraphQL::Types::Relay::HasNodeField

    ALLOWED_INSTRUCTOR_TYPES = ["TeacherEnrollment", "TaEnrollment"].freeze

    field :legacy_node, GraphQL::Types::Relay::Node, null: true do
      description "Fetches an object given its type and legacy ID"
      argument :_id, ID, required: true
      argument :type, LegacyNodeType, required: true
    end
    def legacy_node(type:, _id:) # rubocop:disable Lint/UnderscorePrefixedVariableName -- named for DSL reasons
      GraphQLNodeLoader.load(type, _id, context)
    end

    field :account, Types::AccountType, null: true do
      argument :id,
               ID,
               "a graphql or legacy id",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Account")
      argument :sis_id, String, "a id from the original SIS system", required: false
    end
    def account(id: nil, sis_id: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of id or sisId" if (id && sis_id) || !(id || sis_id)
      return GraphQLNodeLoader.load("Account", id, context) if id

      GraphQLNodeLoader.load("AccountBySis", sis_id, context) if sis_id
    end

    field :course, Types::CourseType, null: true do
      argument :id,
               ID,
               "a graphql or legacy id, preference for search is given to this id",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
      argument :sis_id, String, "a id from the original SIS system", required: false
    end
    def course(id: nil, sis_id: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of id or sisId" if (id && sis_id) || !(id || sis_id)
      return GraphQLNodeLoader.load("Course", id, context) if id

      GraphQLNodeLoader.load("CourseBySis", sis_id, context) if sis_id
    end

    field :assignment, Types::AssignmentType, null: true do
      argument :id,
               ID,
               "a graphql or legacy id",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")
      argument :include_types,
               [Types::AssignmentTypeEnum],
               "Types of assignments to include. Defaults to [ASSIGNMENT] for backward compatibility. " \
               "Note: This parameter is ignored when using sisId lookup.",
               required: false,
               default_value: ["Assignment"]
      argument :sis_id, String, "an id from the original SIS system", required: false
    end
    def assignment(id: nil, sis_id: nil, include_types: ["Assignment"])
      raise GraphQL::ExecutionError, "Must specify exactly one of id or sisId" if (id && sis_id) || !(id || sis_id)

      if id
        GraphQLNodeLoader.load("AbstractAssignment", { id:, include_types: }, context)
      elsif sis_id
        GraphQLNodeLoader.load("AssignmentBySis", sis_id, context)
      end
    end

    field :peer_review_sub_assignment, Types::PeerReviewSubAssignmentType, null: true do
      argument :id,
               ID,
               "a graphql or legacy id",
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("PeerReviewSubAssignment")
    end
    def peer_review_sub_assignment(id:)
      GraphQLNodeLoader.load("PeerReviewSubAssignment", id, context)
    end

    field :assignment_group, Types::AssignmentGroupType, null: true do
      argument :id,
               ID,
               "a graphql or legacy id",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("AssignmentGroup")
      argument :sis_id, String, "an id from the original SIS system", required: false
    end
    def assignment_group(id: nil, sis_id: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of id or sisId" if (id && sis_id) || !(id || sis_id)
      return GraphQLNodeLoader.load("AssignmentGroup", id, context) if id

      GraphQLNodeLoader.load("AssignmentGroupBySis", sis_id, context) if sis_id
    end

    field :submission, Types::SubmissionType, null: true do
      argument :id,
               ID,
               "a graphql or legacy id",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Submission")

      argument :assignment_id,
               ID,
               "a graphql or legacy assignment id",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")

      argument :user_id,
               ID,
               "a graphql or legacy user id",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("User")

      argument :anonymous_id,
               ID,
               "an anonymous id in use when grading anonymously",
               required: false
    end

    def submission(id: nil, assignment_id: nil, user_id: nil, anonymous_id: nil)
      if id && !assignment_id && !user_id && !anonymous_id
        GraphQLNodeLoader.load("Submission", id, context)
      elsif !id && assignment_id && user_id
        GraphQLNodeLoader.load("SubmissionByAssignmentAndUser", { assignment_id:, user_id: }, context)
      elsif !id && assignment_id && anonymous_id
        GraphQLNodeLoader.load("SubmissionByAssignmentAndAnonymousId", { assignment_id:, anonymous_id: }, context)
      else
        raise GraphQL::ExecutionError, "Must specify an id or an assignment_id and user_id or an assignment_id and an anonymous_id"
      end
    end

    field :term, Types::TermType, null: true do
      argument :id,
               ID,
               "a graphql or legacy id",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Term")
      argument :sis_id, String, "an id from the original SIS system", required: false
    end
    def term(id: nil, sis_id: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of id or sisId" if (id && sis_id) || !(id || sis_id)
      return GraphQLNodeLoader.load("Term", id, context) if id

      GraphQLNodeLoader.load("TermBySis", sis_id, context) if sis_id
    end

    field :all_courses,
          [CourseType],
          "All courses viewable by the current user",
          null: true
    def all_courses
      # TODO: really need a way to share similar logic like this
      # with controllers in api/v1
      current_user&.cached_currentish_enrollments(preload_courses: true)
                  &.index_by(&:course_id)
                  &.values
                  &.sort_by! do |enrollment|
                    Canvas::ICU.collation_key(enrollment.course.nickname_for(current_user))
                  end&.map(&:course)
    end

    field :course_instructors_connection, EnrollmentType.connection_type, null: true do
      description "Paginated instructor enrollments across multiple courses"
      argument :course_ids,
               [ID],
               "Course IDs to get instructors for",
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Course")
      argument :enrollment_types, [String], "Filter by enrollment types (TeacherEnrollment, TaEnrollment)", required: false
      argument :observed_user_id, ID, "ID of the observed user", required: false
    end
    def course_instructors_connection(course_ids:, observed_user_id: nil, enrollment_types: nil, **_args)
      return Enrollment.none unless current_user

      user_course_ids = if observed_user_id.present?
                          observed_user = User.find_by(id: observed_user_id)
                          return Enrollment.none unless observed_user

                          current_user.cached_course_ids_for_observed_user(observed_user).map(&:to_s)
                        else
                          current_user.enrollments.active_by_date.pluck(:course_id).uniq.map(&:to_s)
                        end

      course_ids = if course_ids.blank?
                     user_course_ids
                   else
                     course_ids & user_course_ids
                   end

      # Optimized approach: use a subquery for deduplication, then sort for display
      # This eliminates one level of joins compared to the previous double-subquery approach
      types_to_filter = if enrollment_types.present?
                          enrollment_types & ALLOWED_INSTRUCTOR_TYPES
                        else
                          ALLOWED_INSTRUCTOR_TYPES
                        end
      types_to_filter = ALLOWED_INSTRUCTOR_TYPES if types_to_filter.empty?
      deduplicated_ids = Enrollment
                         .joins(:enrollment_state)
                         .current
                         .where(course_id: course_ids)
                         .where(type: types_to_filter)
                         .where(enrollment_states: { restricted_access: false, state: "active" })
                         .where(courses: { workflow_state: "available" })
                         .where("courses.conclude_at IS NULL OR courses.conclude_at > ?", Time.now.utc)
                         .select("DISTINCT ON (enrollments.course_id, enrollments.user_id) enrollments.id")
                         .order(
                           Arel.sql("enrollments.course_id"),
                           Arel.sql("enrollments.user_id"),
                           Enrollment.state_by_date_rank_sql,
                           Arel.sql("enrollments.id")
                         )

      # Now join to users and courses only once for the final result set
      Enrollment.where(id: deduplicated_ids)
                .joins(:user, :course)
                .order("courses.name ASC, users.sortable_name ASC")
    end

    field :courses,
          [Types::CourseType],
          "Courses by IDs that are viewable by the current user",
          null: true do
      argument :ids, [ID], "graphql or legacy course IDs", required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Course")
      argument :sis_ids, [String], "ids from the original SIS system", required: false
    end
    def courses(ids: nil, sis_ids: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of ids or sisIds" if (ids && sis_ids) || !(ids || sis_ids)

      course_ids = ids || sis_ids
      raise GraphQL::ExecutionError, "Cannot request more than 100 courses at once" if course_ids&.length.to_i > 100

      courses = if ids
                  current_user&.accessible_courses_by_ids(ids, preload_courses: true)
                elsif sis_ids
                  current_user&.accessible_courses_by_sis_ids(sis_ids, preload_courses: true)
                end

      courses&.index_by(&:id)
             &.values
             &.sort_by! do |course|
               Canvas::ICU.collation_key(course.nickname_for(current_user))
             end
    end

    field :module_item, Types::ModuleItemType, null: true do
      description "ModuleItem"
      argument :id,
               ID,
               "a graphql or legacy id",
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("ModuleItem")
    end
    def module_item(id:)
      GraphQLNodeLoader.load("ModuleItem", id, context)
    end

    field :audit_logs, Types::AuditLogsType, null: true
    def audit_logs
      Canvas::DynamoDB::DatabaseBuilder.from_config(:auditors)
    end

    field :outcome_calculation_method, Types::OutcomeCalculationMethodType, null: true do
      description "OutcomeCalculationMethod"
      argument :id,
               ID,
               "a graphql or legacy id",
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("OutcomeCalculationMethod")
    end
    def outcome_calculation_method(id:)
      GraphQLNodeLoader.load("OutcomeCalculationMethod", id, context)
    end

    field :outcome_proficiency, Types::OutcomeProficiencyType, null: true do
      description "OutcomeProficiency"
      argument :id,
               ID,
               "a graphql or legacy id",
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("OutcomeProficiency")
    end
    def outcome_proficiency(id:)
      GraphQLNodeLoader.load("OutcomeProficiency", id, context)
    end

    field :learning_outcome_group, Types::LearningOutcomeGroupType, null: true do
      description "LearningOutcomeGroup"
      argument :id,
               ID,
               "a graphql or legacy id",
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("LearningOutcomeGroup")
    end
    def learning_outcome_group(id:)
      GraphQLNodeLoader.load("LearningOutcomeGroup", id, context)
    end

    field :learning_outcome, Types::LearningOutcomeType, null: true do
      description "LearningOutcome"
      argument :id,
               ID,
               "a graphql or legacy id",
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("LearningOutcome")
    end
    def learning_outcome(id:)
      GraphQLNodeLoader.load("LearningOutcome", id, context)
    end

    field :internal_setting, Types::InternalSettingType, null: true do
      description "Retrieves a single internal setting by its ID or name"
      argument :id,
               ID,
               "a graphql or legacy id",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("InternalSetting")
      argument :name, String, "the name of the Setting", required: false
    end
    def internal_setting(id: nil, name: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of id or name" if (id && name) || !(id || name)

      return GraphQLNodeLoader.load("InternalSetting", id, context) if id

      GraphQLNodeLoader.load("InternalSettingByName", name, context) if name
    end

    field :internal_settings, [Types::InternalSettingType], null: true do
      description "All internal settings"
    end
    def internal_settings
      return [] unless Account.site_admin.grants_right?(context[:current_user], context[:session], :manage_internal_settings)

      Setting.all
    end

    field :account_notifications, [Types::AccountNotificationType], null: false do
      description "Account notifications for the current user"
      argument :account_id, ID, "Account ID to fetch notifications for", required: false
    end
    def account_notifications(account_id: nil)
      return [] unless context[:current_user]

      account = if account_id
                  Account.find_by(id: account_id)
                else
                  # Use root account from domain
                  context[:domain_root_account]
                end

      return [] unless account

      AccountNotification.for_user_and_account(context[:current_user], account)
    end

    field :enrollment_invitations, [Types::EnrollmentType], null: false do
      description "Pending enrollment invitations for the current user"
      argument :include_enrollment_uuid, String, required: false
    end
    def enrollment_invitations(include_enrollment_uuid: nil)
      return [] unless context[:current_user]

      context[:current_user].cached_invitations(
        include_enrollment_uuid:,
        preload_course: true
      )
    end

    field :rubric, Types::RubricType, null: true do
      description "Rubric"
      argument :id,
               ID,
               "a graphql or legacy id",
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Rubric")
    end
    def rubric(id:)
      GraphQLNodeLoader.load("Rubric", id, context)
    end

    field :folder, Types::FolderType, null: true do
      description "Folder"
      argument :id,
               ID,
               "a graphql or legacy id",
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Folder")
    end
    def folder(id:)
      GraphQLNodeLoader.load("Folder", id, context)
    end

    field :my_inbox_settings, Types::InboxSettingsType, null: true
    def my_inbox_settings
      GraphQLNodeLoader.load("MyInboxSettings", context[:current_user].id.to_s, context) if context[:current_user]
    end
  end
end
