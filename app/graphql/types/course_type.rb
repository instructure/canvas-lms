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
  class SubmissionOrderFieldType < BaseEnum
    graphql_name "SubmissionOrderField"
    value :_id, value: :id
    value :gradedAt, value: :graded_at
  end

  class SubmissionOrderInputType < BaseInputObject
    graphql_name "SubmissionOrderCriteria"

    argument :direction, OrderDirectionType, required: false
    argument :field, SubmissionOrderFieldType, required: true
  end

  class CourseType < ApplicationObjectType
    graphql_name "Course"

    implements Interfaces::AssetStringInterface

    alias_method :course, :object

    class CourseWorkflowState < BaseEnum
      graphql_name "CourseWorkflowState"
      description "States that Courses can be in"
      value "created"
      value "claimed"
      value "available"
      value "completed"
      value "deleted"
    end

    class CourseFilterableEnrollmentWorkflowState < BaseEnum
      graphql_name "CourseFilterableEnrollmentState"
      description "Users in a course can be returned based on these enrollment states"
      value "invited"
      value "creation_pending"
      value "active"
      value "rejected"
      value "completed"
      value "inactive"
    end

    class CourseFilterableEnrollmentType < BaseEnum
      graphql_name "CourseFilterableEnrollmentType"
      description "Users in a course can be returned based on these enrollment types"
      value "StudentEnrollment"
      value "TeacherEnrollment"
      value "TaEnrollment"
      value "ObserverEnrollment"
      value "DesignerEnrollment"
      value "StudentViewEnrollment"
    end

    class CourseGradeStatus < BaseEnum
      description "Grade statuses that can be applied to submissions in a course"
      value "late"
      value "missing"
      value "none"
      value "excused"
      value "extended"
    end

    class CourseUsersFilterInputType < Types::BaseInputObject
      graphql_name "CourseUsersFilter"

      argument :enrollment_role_ids,
               [ID],
               "Only return users with the specified enrollment role ids",
               required: false
      argument :enrollment_states,
               [CourseFilterableEnrollmentWorkflowState],
               <<~MD,
                 only return users with the given enrollment state. defaults
                 to `invited`, `creation_pending`, `active`
               MD
               required: false
      argument :enrollment_types,
               [CourseFilterableEnrollmentType],
               "Only return users with the specified enrollment types",
               required: false
      argument :exclude_test_students,
               Boolean,
               "Exclude test students from results",
               required: false
      argument :search_term,
               String,
               <<~MD,
                 Only return users that match the given search term. The search
                 term is matched against the user's name and depending on current
                 user permissions against the user's login id, email and sisid
               MD
               required: false,
               prepare: :prepare_search_term
      argument :user_ids,
               [ID],
               "only include users with the given ids",
               prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User"),
               required: false

      def prepare_search_term(term)
        if term.presence && term.length < SearchTermHelper::MIN_SEARCH_TERM_LENGTH
          raise GraphQL::ExecutionError, "search term must be at least #{SearchTermHelper::MIN_SEARCH_TERM_LENGTH} characters"
        end

        term
      end
    end

    class CourseSectionsFilterInputType < Types::BaseInputObject
      graphql_name "CourseSectionsFilter"

      argument :assignment_id,
               ID,
               "Only include sections associated with users assigned to this assignment",
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment"),
               required: false
    end

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :course_code, String, "course short name", null: true
    field :horizon_course, Boolean, null: true
    field :name, String, null: false
    field :state, CourseWorkflowState, method: :workflow_state, null: false
    field :syllabus_body, String, null: true

    field :assignment_groups_connection,
          AssignmentGroupType.connection_type,
          method: :assignment_groups,
          null: true

    def assignment_groups_connection
      assignment_groups = object.assignment_groups
      assignment_groups.where(workflow_state: "available")
    end

    field :assignment_groups,
          [AssignmentGroupType],
          null: true

    def assignment_groups
      assignment_groups = object.assignment_groups
      assignment_groups.where(workflow_state: "available")
    end

    field :apply_group_weights, Boolean, null: true
    def apply_group_weights
      object.apply_group_weights?
    end

    implements Interfaces::AssignmentsConnectionInterface
    def assignments_connection(filter: {})
      super(filter:, course:)
    end

    implements Interfaces::QuizzesConnectionInterface
    def quizzes_connection(filter: {})
      super(filter:, course:)
    end

    implements Interfaces::FilesConnectionInterface
    def files_connection(filter: {})
      super(filter:, course:)
    end

    implements Interfaces::PagesConnectionInterface
    def pages_connection(filter: {})
      super(filter:, course:)
    end

    implements Interfaces::DiscussionsConnectionInterface
    def discussions_connection(filter: {})
      super(filter:, course:)
    end

    field :account, AccountType, null: true
    def account
      load_association(:account)
    end

    field :outcome_proficiency, OutcomeProficiencyType, null: true
    def outcome_proficiency
      # This does a recursive lookup of parent accounts, not sure how we could
      # batch load it in a reasonable way.
      course.resolved_outcome_proficiency
    end

    # field :proficiency_ratings_connection, ProficiencyRatingType.connection_type, null: true
    # def proficiency_ratings_connection
    #   # This does a recursive lookup of parent accounts, not sure how we could
    #   # batch load it in a reasonable way.
    #   outcome_proficiency&.outcome_proficiency_ratings
    # end

    field :outcome_calculation_method, OutcomeCalculationMethodType, null: true
    def outcome_calculation_method
      # This does a recursive lookup of parent accounts, not sure how we could
      # batch load it in a reasonable way.
      course.resolved_outcome_calculation_method
    end

    field :outcome_alignment_stats, CourseOutcomeAlignmentStatsType, null: true
    def outcome_alignment_stats
      Loaders::CourseOutcomeAlignmentStatsLoader.load(course) if course&.grants_right?(current_user, session, :manage_outcomes)
    end

    field :sections_connection, SectionType.connection_type, null: true do
      argument :filter, CourseSectionsFilterInputType, required: false
    end

    def sections_connection(filter: {})
      scope = course.active_course_sections

      if filter[:assignment_id]
        assignment = course.assignments.active.find(filter[:assignment_id])
        scope = scope.where(id: assignment.sections_for_assigned_students) if assignment.only_visible_to_overrides?
      end

      scope.order(CourseSection.best_unicode_collation_key("name"))
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "assignment not found"
    end

    field :modules_connection, ModuleType.connection_type, null: true
    def modules_connection
      course.modules_visible_to(current_user)
            .order("name")
    end

    field :rubrics_connection, RubricType.connection_type, null: true
    def rubrics_connection
      rubric_associations = course.rubric_associations
                                  .bookmarked
                                  .include_rubric
                                  .joins(:rubric)
                                  .where.not(rubrics: { workflow_state: "deleted" })
                                  .to_a
      rubric_associations = Canvas::ICU.collate_by(rubric_associations.select(&:rubric_id).uniq(&:rubric_id)) { |r| r.rubric.title }
      rubric_associations.map(&:rubric)
    end

    field :users_connection, UserType.connection_type, null: true do
      argument :user_ids,
               [ID],
               <<~MD,
                 Only include users with the given ids.

                 **This field is deprecated, use `filter: {userIds}` instead.**
               MD
               prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User"),
               required: false

      argument :filter, CourseUsersFilterInputType, required: false
      argument :sort, CourseUsersSortInputType, required: false
    end
    def users_connection(user_ids: nil, filter: {}, sort: {})
      return nil unless course.grants_any_right?(
        current_user,
        session,
        :read_roster,
        :view_all_grades,
        :manage_grades
      )

      context.scoped_merge!(course:)

      options = {
        enrollment_state: filter[:enrollment_states],
        enrollment_type: filter[:enrollment_types],
        enrollment_role_id: filter[:enrollment_role_ids],
        include_inactive_enrollments: true,
        sort: sort[:field],
        order: sort[:direction]
      }

      search_term = filter[:search_term].presence

      scope = if search_term
                UserSearch.for_user_in_context(search_term, course, current_user, session, options)
              else
                UserSearch.scope_for(course, current_user, options)
              end

      user_ids = filter[:user_ids] || user_ids
      if user_ids.present?
        scope = scope.where(users: { id: user_ids })
      end

      scope = scope.not_fake_student if filter[:exclude_test_students]

      scope
    end

    field :users_connection_count, Integer, null: true do
      argument :filter, CourseUsersFilterInputType, required: false
      argument :sort, CourseUsersSortInputType, required: false
      argument :user_ids,
               [ID],
               <<~MD,
                 Only include users with the given ids.

                 **This field is deprecated, use `filter: {userIds}` instead.**
               MD
               prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User"),
               required: false
    end
    def users_connection_count(user_ids: nil, filter: {}, sort: {})
      users_connection(user_ids:, filter:, sort:).size
    end

    field :course_nickname, String, null: true
    def course_nickname
      current_user.course_nickname(course)
    end

    field :custom_grade_statuses_connection, CustomGradeStatusType.connection_type, null: true
    def custom_grade_statuses_connection
      return unless Account.site_admin.feature_enabled?(:custom_gradebook_statuses)
      return unless course.grants_any_right?(current_user, session, :manage_grades, :view_all_grades)

      course.custom_grade_statuses.active.order(:id)
    end

    field :enrollments_connection, EnrollmentType.connection_type, null: true do
      argument :filter, EnrollmentFilterInputType, required: false
    end

    def enrollments_connection(filter: {})
      return nil unless course.grants_any_right?(
        current_user,
        session,
        :read_roster,
        :view_all_grades,
        :manage_grades
      )

      context.scoped_merge!(course:)
      scope = course.apply_enrollment_visibility(course.all_enrollments, current_user)
      scope = filter[:states].present? ? scope.where(workflow_state: filter[:states]) : scope.active
      scope = scope.where(associated_user_id: filter[:associated_user_ids]) if filter[:associated_user_ids].present?
      scope = scope.where(user_id: filter[:user_ids]) if filter[:user_ids].present?
      scope = scope.where(type: filter[:types]) if filter[:types].present?
      scope
    end

    field :grading_periods_connection, GradingPeriodType.connection_type, null: true
    def grading_periods_connection
      GradingPeriod.for(course).order(:start_date)
    end

    field :relevant_grading_period_group, GradingPeriodGroupType, null: true
    delegate :relevant_grading_period_group, to: :object

    field :grading_standard, GradingStandardType, null: true
    def grading_standard
      object.grading_standard_or_default
    end

    field :submissions_connection, SubmissionType.connection_type, null: true do
      description "all the submissions for assignments in this course"

      argument :filter, SubmissionFilterInputType, required: false
      argument :order_by, [SubmissionOrderInputType], required: false
      argument :student_ids,
               [ID],
               "Only return submissions for the given students.",
               prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User"),
               required: false
    end
    def submissions_connection(student_ids: nil, order_by: [], filter: {})
      allowed_user_ids = if course.grants_any_right?(current_user, session, :manage_grades, :view_all_grades)
                           # TODO: make a preloader for this???
                           course.apply_enrollment_visibility(course.all_student_enrollments, current_user).pluck(:user_id)
                         elsif course.grants_right?(current_user, session, :read_grades)
                           [current_user.id]
                         else
                           []
                         end

      if student_ids.present?
        allowed_user_ids &= student_ids.map(&:to_i)
      end

      filter ||= {}

      submissions = Submission.active.joins(:assignment).where(
        user_id: allowed_user_ids,
        assignment_id: course.assignments.published,
        workflow_state: filter[:states] || DEFAULT_SUBMISSION_STATES
      )

      if filter[:submitted_since]
        submissions = submissions.where("submitted_at > ?", filter[:submitted_since])
      end
      if filter[:graded_since]
        submissions = submissions.where("graded_at > ?", filter[:graded_since])
      end
      if filter[:updated_since]
        submissions = submissions.where("submissions.updated_at > ?", filter[:updated_since])
      end
      if (due_between = filter[:due_between])
        submissions = submissions.where(cached_due_date: (due_between[:start])..(due_between[:end]))
      end

      (order_by || []).each do |order|
        direction = (order[:direction] == "descending") ? "DESC NULLS LAST" : "ASC"
        submissions = submissions.order("#{order[:field]} #{direction}")
      end

      submissions
    end

    field :groups_connection, GroupType.connection_type, null: true do
      argument :include_non_collaborative, Boolean, required: false, default_value: false
    end
    def groups_connection(include_non_collaborative: false)
      show_non_collaborative = include_non_collaborative && course&.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS)
      groups_scope = show_non_collaborative ? course.combined_groups_and_differentiation_tags.active : course.active_groups

      # TODO: share this with accounts when groups are added there
      if course.grants_right?(current_user, session, :read_roster)
        groups_scope
          .order(GroupCategory::Bookmarker.order_by, Group::Bookmarker.order_by)
          .eager_load(:group_category)
      else
        nil
      end
    end

    def get_group_sets(course, include_non_collaborative: false)
      return [] unless course

      # Check user permissions
      can_manage_groups = course&.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_GROUPS_PERMISSIONS)
      can_manage_tags   = course&.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS)

      # Only return group sets if the user has permission to manage groups or tags
      return [] unless can_manage_groups || can_manage_tags

      # If a user only has permission to see tags but doesn't want them included, return early
      return [] if can_manage_tags && !can_manage_groups && !include_non_collaborative

      # Get all GroupCategory models for the context, this includes Tags AND Group Sets
      group_sets = GroupCategory.where(context: course, role: nil).active

      if can_manage_groups && can_manage_tags
        group_sets = group_sets.collaborative unless include_non_collaborative
      elsif can_manage_groups
        group_sets = group_sets.collaborative
      elsif can_manage_tags
        group_sets = group_sets.non_collaborative
      end

      group_sets
    end

    field :group_sets_connection, GroupSetType.connection_type, null: true do
      description "Project group sets for this course."
      argument :include_non_collaborative, Boolean, required: false, default_value: false
    end
    def group_sets_connection(include_non_collaborative: false)
      get_group_sets(course, include_non_collaborative:)
    end

    # TODO: this is only temporary until the group_sets_connection gets paginated
    field :group_sets, [GroupSetType], null: true do
      description "Project group sets for this course."
      argument :include_non_collaborative, Boolean, required: false, default_value: false
    end
    def group_sets(include_non_collaborative: false)
      get_group_sets(course, include_non_collaborative:)
    end

    field :folders_connection, FolderType.connection_type, null: true do
      description "Folders for this course."
    end
    def folders_connection
      return nil unless course.grants_right?(current_user, :read)

      course.active_folders
    end

    field :external_tools_connection, ExternalToolType.connection_type, null: true do
      argument :filter, ExternalToolFilterInputType, required: false, default_value: {}
    end
    def external_tools_connection(filter:)
      scope = Lti::ContextToolFinder.all_tools_for(course, placements: filter.placement)
      filter.state.nil? ? scope : scope.where(workflow_state: filter.state)
    end

    field :term, TermType, null: true
    def term
      load_association(:enrollment_term)
    end

    field :permissions,
          CoursePermissionsType,
          "returns permission information for the current user in this course",
          null: true
    def permissions
      Loaders::PermissionsLoader.for(
        course,
        current_user:,
        session:
      )
    end

    field :post_policy, PostPolicyType, "A course-specific post policy", null: true
    def post_policy
      return nil unless course.grants_right?(current_user, :manage_grades)

      load_association(:default_post_policy)
    end

    field :assignment_post_policies,
          PostPolicyType.connection_type,
          <<~MD,
            PostPolicies for assignments within a course
          MD
          null: true
    def assignment_post_policies
      return nil unless course.grants_right?(current_user, :manage_grades)

      course.assignment_post_policies
    end

    field :image_url, UrlType, <<~MD, null: true
      Returns a URL for the course image (this is the image used on dashboard
      course cards)
    MD
    def image_url
      if course.image_url.present?
        course.image_url
      elsif course.image_id.present?
        Loaders::IDLoader.for(Attachment.active).load(
          # if `course.image` was a proper AR association, we wouldn't have to
          # do this shard-id stuff
          course.shard.global_id_for(Integer(course.image_id))
        ).then do |attachment|
          attachment&.public_download_url(1.week)
        end
      end
    end

    field :sis_id, String, null: true
    def sis_id
      return nil unless course.grants_any_right?(current_user, :read_sis, :manage_sis)

      course.sis_course_id
    end

    field :submission_statistics, SubmissionStatisticsType, "Returns submission-related statistics for the current user", null: true
    def submission_statistics
      return nil unless course.grants_right?(current_user, :read)

      course
    end

    field :allow_final_grade_override, Boolean, null: true
    def allow_final_grade_override
      course.allow_final_grade_override?
    end

    field :root_outcome_group, LearningOutcomeGroupType, null: false

    field :grade_statuses, [CourseGradeStatus], null: false

    field :dashboard_card, CourseDashboardCardType, "returns dashboard card information for this course", null: true
    def dashboard_card
      object
    end

    field :activity_stream, ActivityStreamType, null: true
    def activity_stream
      context.scoped_set!(:context_type, "Course")
      object
    end

    field :available_moderators, UserType.connection_type, null: true
    def available_moderators
      return unless course.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)

      course.moderators
    end

    field :available_moderators_count, Integer, null: true
    def available_moderators_count
      return unless course.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)

      course.moderators.size
    end

    field :settings, CourseSettingsType, "Settings for the course", null: true
    def settings
      return nil unless course.grants_right?(current_user, :read)

      course
    end
  end
end
