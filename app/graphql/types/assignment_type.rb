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
  class AssignmentType < ApplicationObjectType
    graphql_name "Assignment"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::ModuleItemInterface
    implements Interfaces::LegacyIDInterface
    implements Interfaces::AssignedDatesInterface

    alias_method :assignment, :object

    class AssignmentStateType < Types::BaseEnum
      graphql_name "AssignmentState"
      description "States that an Assignment can be in"
      value "unpublished"
      value "published"
      value "deleted"
      value "duplicating"
      value "failed_to_duplicate"
      value "importing"
      value "fail_to_import"
      value "migrating"
      value "failed_to_migrate"
      value "outcome_alignment_cloning"
      value "failed_to_clone_outcome_alignment"
    end

    class AssignmentGradingType < Types::BaseEnum
      graphql_name "GradingType"
      Assignment::ALLOWED_GRADING_TYPES.each { |type| value(type) }
    end

    class GradingRole < Types::BaseEnum
      description "The grading role of the current user for this assignment"
      value "moderator", "User is a moderator for the assignment"
      value "provisional_grader", "User is a provisional grader for the assignment"
      value "grader", "User is a standard grader for the assignment"
    end

    class AssignmentPeerReviews < ApplicationObjectType
      graphql_name "PeerReviews"
      description "Settings for Peer Reviews on an Assignment"

      field :anonymous_reviews,
            Boolean,
            "Boolean representing whether or not peer reviews are anonymous",
            method: :anonymous_peer_reviews,
            null: true
      field :automatic_reviews,
            Boolean,
            "Boolean indicating peer reviews are assigned automatically. If false, the teacher is expected to manually assign peer reviews.",
            method: :automatic_peer_reviews,
            null: true
      field :count,
            Int,
            "Integer representing the amount of reviews each user is assigned.",
            method: :peer_review_count,
            null: true
      field :due_at,
            DateTimeType,
            "Date and Time representing when the peer reviews are due",
            method: :peer_reviews_due_at,
            null: true
      field :enabled,
            Boolean,
            "Boolean indicating if peer reviews are required for this assignment",
            method: :peer_reviews,
            null: true
      field :intra_reviews,
            Boolean,
            "Boolean representing whether or not members from within the same group on a group assignment can be assigned to peer review their own group's work",
            method: :intra_group_peer_reviews,
            null: true
      field :submission_required,
            Boolean,
            "Boolean indicating if students must submit their assignment before they can do peer reviews",
            null: true
      def submission_required
        return nil unless object.context.feature_enabled?(:peer_review_allocation_and_grading)

        object.peer_review_submission_required
      end
      field :across_sections,
            Boolean,
            "Boolean indicating if peer reviews can be assigned across different sections",
            null: true
      def across_sections
        return nil unless object.context.feature_enabled?(:peer_review_allocation_and_grading)

        object.peer_review_across_sections
      end
    end

    class AssignmentModeratedGrading < ApplicationObjectType
      graphql_name "ModeratedGrading"
      description "Settings for Moderated Grading on an Assignment"

      field :enabled,
            Boolean,
            "Boolean indicating if the assignment is moderated.",
            method: :moderated_grading,
            null: true
      field :grader_comments_visible_to_graders,
            Boolean,
            "Boolean indicating if provisional graders' comments are visible to other provisional graders.",
            null: true
      field :grader_count,
            Int,
            "The maximum number of provisional graders who may issue grades for this assignment.",
            null: true
      field :grader_names_visible_to_final_grader,
            Boolean,
            "Boolean indicating if provisional graders' identities are hidden from other provisional graders.",
            null: true
      field :graders_anonymous_to_graders,
            Boolean,
            "Boolean indicating if provisional grader identities are visible to the final grader.",
            null: true

      field :final_grader,
            UserType,
            "The user of the grader responsible for choosing final grades for this assignment.",
            null: true
      def final_grader
        Loaders::IDLoader.for(User).load(object.final_grader_id)
      end

      field :final_grader_anonymous_id, String, "The anonymous ID of the final grader", null: true
      def final_grader_anonymous_id
        Loaders::AssignmentLoaders::FinalGraderAnonymousIdLoader.load(object.id)
      end
    end

    class AssignmentRubricAssessmentType < ApplicationObjectType
      description "RubricAssessments on an Assignment"

      field :assessments_count,
            Int,
            "The count of RubricAssessments on an Assignment.",
            null: true

      def assessments_count
        Loaders::AssignmentRubricAssessmentsCountLoader.load(object)
      end
    end

    class AssignmentScoreStatisticType < ApplicationObjectType
      graphql_name "AssignmentScoreStatistic"
      description "Statistics for an Assignment"

      field :count,
            Int,
            "The number of scores for the assignment",
            null: true
      field :lower_q,
            Float,
            "The lower quartile score for the assignment",
            null: true
      field :maximum,
            Float,
            "The maximum score for the assignment",
            null: true
      field :mean,
            Float,
            "The mean score for the assignment",
            null: true
      field :median,
            Float,
            "The median score for the assignment",
            null: true
      field :minimum,
            Float,
            "The minimum score for the assignment",
            null: true
      field :upper_q,
            Float,
            "The upper quartile score for the assignment",
            null: true
    end

    class AnonymousStudentIdentityType < ApplicationObjectType
      description "An anonymous student identity"

      field :anonymous_id, ID, null: false
      field :name, String, null: false
      field :position, Int, null: false
    end

    class AssignedStudentsFilterInputType < Types::BaseInputObject
      graphql_name "AssignedStudentsFilter"

      argument :search_term,
               String,
               required: false,
               prepare: :prepare_search_term

      def prepare_search_term(term)
        if term.presence && term.length < SearchTermHelper::MIN_SEARCH_TERM_LENGTH
          raise GraphQL::ExecutionError, "search term must be at least #{SearchTermHelper::MIN_SEARCH_TERM_LENGTH} characters"
        end

        term
      end
    end

    class AllocationRulesFilterInputType < Types::BaseInputObject
      argument :search_term,
               String,
               required: false,
               prepare: :prepare_search_term

      def prepare_search_term(term)
        if term.presence && term.length < SearchTermHelper::MIN_SEARCH_TERM_LENGTH
          raise GraphQL::ExecutionError, "search term must be at least #{SearchTermHelper::MIN_SEARCH_TERM_LENGTH} characters"
        end

        term
      end
    end

    class AssignmentAllocationRules < ApplicationObjectType
      description "Allocation rules for peer review assignments"

      field :rules_connection, AllocationRuleType.connection_type, null: true do
        description "Paginated list of allocation rules"
        argument :filter, AllocationRulesFilterInputType, required: false
      end
      def rules_connection(filter: {})
        apply_search_filter(filter).then { |scope| scope.order(:id) }
      end

      field :count, Int, null: true do
        description "Total count of allocation rules (filtered if search is applied)"
        argument :filter, AllocationRulesFilterInputType, required: false
      end
      def count(filter: {})
        apply_search_filter(filter).then(&:count)
      end

      private

      def apply_search_filter(filter)
        load_association(:allocation_rules).then do |rules|
          scope = rules.active

          search_term = filter[:search_term].presence
          if search_term
            scope = scope.joins(
              "JOIN #{User.quoted_table_name} AS assessor_users ON allocation_rules.assessor_id = assessor_users.id"
            ).joins(
              "JOIN #{User.quoted_table_name} AS assessee_users ON allocation_rules.assessee_id = assessee_users.id"
            ).where(
              "assessor_users.name ILIKE ? OR assessee_users.name ILIKE ?",
              "%#{search_term}%",
              "%#{search_term}%"
            )
          end

          scope
        end
      end
    end

    global_id_field :id

    field :name, String, null: true

    field :points_possible,
          Float,
          "the assignment is out of this many points",
          null: true
    field :position,
          Int,
          "determines the order this assignment is displayed in in its assignment group",
          null: true

    field :restrict_quantitative_data, Boolean, "Is the current user restricted from viewing quantitative data", null: true do
      argument :check_extra_permissions, Boolean, "Check extra permissions in RQD method", required: false
    end
    def restrict_quantitative_data(check_extra_permissions: false)
      assignment.restrict_quantitative_data?(current_user, check_extra_permissions)
    end

    field :provisional_grading_locked, Boolean, "Indicates if the user is locked out of provisional grading for this assignment.", null: false
    def provisional_grading_locked
      return false unless assignment.moderated_grader_limit_reached?
      return false unless assignment.context.grants_any_right?(current_user, :manage_grades, :view_all_grades)
      return false if assignment.grades_published?
      return false if assignment.permits_moderation?(current_user)
      return false if assignment.provisional_moderation_graders.where(user: current_user).exists?

      true
    end

    field :grading_role, GradingRole, "The grading role of the current user for this assignment. Returns null if the user does not have sufficient grading permissions.", null: true
    def grading_role
      unless assignment.context.grants_any_right?(current_user, :manage_grades, :view_all_grades)
        return nil
      end

      role = assignment.grading_role(current_user)
      role&.to_s
    end

    def self.overridden_field(field_name, description)
      field field_name, DateTimeType, description, null: true do
        argument :apply_overrides, Boolean, <<~MD, required: false, default_value: true
          When true, return the overridden dates.

          Not all roles have permission to view un-overridden dates (in which
          case the overridden dates will be returned)
        MD
      end

      define_method(field_name) do |apply_overrides: true|
        load_association(:context).then do |course|
          if !apply_overrides && course.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)
            assignment.send(field_name)
          else
            Loaders::OverrideAssignmentLoader.for(current_user).load(assignment).then(&field_name)
          end
        end
      end
    end

    overridden_field :due_at, "when this assignment is due"
    overridden_field :lock_at, "the lock date (assignment is locked after this date)"
    overridden_field :unlock_at, "the unlock date (assignment is unlocked after this date)"

    field :lock_info, LockInfoType, null: true

    # needed for instructure.atlassian.net/browse/PFS-23713
    field :suppress_assignment,
          Boolean,
          "internal use",
          null: false

    field :post_to_sis,
          Boolean,
          "present if Sync Grades to SIS feature is enabled",
          null: true

    field :peer_reviews, AssignmentPeerReviews, null: true
    def peer_reviews
      assignment
    end

    field :assessment_requests_for_current_user, [AssessmentRequestType], null: true
    def assessment_requests_for_current_user
      Loaders::AssessmentRequestLoader.for(current_user:).load(assignment)
    end

    field :peer_review_sub_assignment, AssignmentType, null: true
    def peer_review_sub_assignment
      return nil unless assignment.grants_right?(current_user, session, :grade)
      return nil unless assignment.context.feature_enabled?(:peer_review_allocation_and_grading)
      return nil unless assignment.peer_reviews

      load_association(:peer_review_sub_assignment)
    end

    field :assessment_requests_for_user, [AssessmentRequestType], null: true do
      description "Assessment requests for a specific user where they are the assessor (peer reviewer)"
      argument :user_id,
               ID,
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("User")
    end
    def assessment_requests_for_user(user_id:)
      return nil unless assignment.grants_right?(current_user, session, :grade)

      Loaders::IDLoader.for(User).load(user_id).then do |assessor|
        next nil unless assessor

        Loaders::AssessmentRequestLoader.for(current_user: assessor).load(assignment)
      end
    end

    field :moderated_grading, AssignmentModeratedGrading, null: true
    def moderated_grading
      assignment
    end

    field :rubric_assessment, AssignmentRubricAssessmentType, null: true
    def rubric_assessment
      assignment
    end

    field :anonymous_grading,
          Boolean,
          null: true
    field :anonymous_instructor_annotations, Boolean, null: true
    field :can_duplicate, Boolean, method: :can_duplicate?, null: true
    field :graded_submissions_exist,
          Boolean,
          "If true, the assignment has at least one graded submission",
          null: true
    def graded_submissions_exist
      Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(assignment.id)
    end
    field :has_multiple_due_dates, Boolean, method: :multiple_distinct_due_dates?, null: true
    field :has_submitted_submissions,
          Boolean,
          "If true, the assignment has been submitted to by at least one student",
          null: true
    def has_submitted_submissions
      Loaders::AssignmentHasSubmissionsLoader.for.load(assignment.id).then do |has_submissions|
        # Set cache for both methods that check submission existence
        assignment.instance_variable_set(:@has_student_submissions, has_submissions)
        assignment.instance_variable_set(:@has_submitted_submissions, has_submissions)
        assignment.has_student_submissions?
      end
    end
    field :omit_from_final_grade,
          Boolean,
          "If true, the assignment will be omitted from the student's final grade",
          null: true

    field :grade_group_students_individually,
          Boolean,
          "If this is a group assignment, boolean flag indicating whether or not students will be graded individually.",
          null: true
    field :group_category_id, Int, null: true

    field :allow_google_docs_submission, Boolean, method: :allow_google_docs_submission?, null: true
    field :anonymize_students, Boolean, method: :anonymize_students?, null: true
    field :new_quizzes_anonymous_participants, Boolean, method: :new_quizzes_anonymous_participants?, null: true
    field :expects_external_submission, Boolean, method: :expects_external_submission?, null: true
    field :expects_submission, Boolean, method: :expects_submission?, null: true
    field :grades_published_at, String, null: true
    field :important_dates, Boolean, null: true
    field :in_closed_grading_period, Boolean, method: :in_closed_grading_period?, null: true
    field :non_digital_submission, Boolean, method: :non_digital_submission?, null: true
    field :submissions_downloads, Int, null: true
    field :time_zone_edited, String, null: true

    field :can_unpublish, Boolean, method: :can_unpublish?, null: true
    field :due_date_required, Boolean, method: :due_date_required?, null: true

    field :has_rubric, Boolean, null: false
    def has_rubric
      Loaders::AssignmentLoaders::HasRubricLoader.load(object.id)
    end

    field :has_plagiarism_tool, Boolean, "Indicates if the assignment has LTI 2.0 plagiarism detection tool configured", null: false
    def has_plagiarism_tool
      assignment.assignment_configuration_tool_lookup_ids.present?
    end

    field :muted, Boolean, null: true

    field :assignment_visibility, [ID], null: true do
      description "Returns empty array if visible to everyone"
    end
    def assignment_visibility
      return unless object.course.grants_any_right?(current_user, :read_as_admin, :manage_grades, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)

      Loaders::AssignmentVisibilityLoader.load(object.id)
    end

    field :originality_report_visibility, String, null: true
    def originality_report_visibility
      return nil if object.turnitin_settings.empty?

      object.turnitin_settings[:originality_report_visibility]
    end

    field :rubric, RubricType, null: true
    def rubric
      assignment.active_rubric_association? ? load_association(:rubric) : nil
    end

    field :rubric_association, RubricAssociationType, null: true
    def rubric_association
      assignment.active_rubric_association? ? load_association(:rubric_association) : nil
    end

    field :rubric_update_url, String, null: true
    def rubric_update_url
      return nil unless assignment.active_rubric_association?

      "/courses/#{assignment.context_id}/rubric_associations/#{assignment.rubric_association.id}/assessments" if assignment.rubric_association
    end

    def lock_info
      load_locked_for { |lock_info| lock_info || {} }
    end

    def load_locked_for
      Promise.all([
                    load_association(:context),
                    load_association(:discussion_topic),
                    load_association(:quiz),
                    load_association(:wiki_page),
                  ]).then do
        yield assignment.low_level_locked_for?(current_user,
                                               check_policies: true,
                                               context: assignment.context)
      end
    end

    field :allowed_attempts,
          Int,
          "The number of submission attempts a student can make for this assignment. null implies unlimited.",
          null: true

    def allowed_attempts
      return nil if assignment.allowed_attempts.nil? || assignment.allowed_attempts <= 0

      assignment.allowed_attempts
    end

    field :allowed_extensions,
          [String],
          "permitted uploaded file extensions (e.g. ['doc', 'xls', 'txt'])",
          null: true

    field :state, AssignmentStateType, method: :workflow_state, null: false

    field :quiz, Types::QuizType, null: true
    def quiz
      load_association(:quiz)
    end

    field :supports_grade_by_question, Boolean, null: false
    def supports_grade_by_question
      Promise.all([load_association(:quiz), load_association(:external_tool_tag)]).then do
        assignment.supports_grade_by_question?
      end
    end

    field :grade_by_question_enabled, Boolean, null: false
    def grade_by_question_enabled
      supports_grade_by_question.then do |supported|
        supported && current_user.present? && current_user.grade_by_question_in_speedgrader?
      end
    end

    field :discussion, Types::DiscussionType, null: true
    def discussion
      load_association(:discussion_topic)
    end

    field :html_url, UrlType, null: true
    def html_url
      GraphQLHelpers::UrlHelpers.course_assignment_url(
        course_id: assignment.context_id,
        id: assignment.id,
        host: context[:request].host_with_port
      )
    end

    field :description, String, null: true
    def description
      return nil if assignment.description.blank?

      load_locked_for do |lock_info|
        # some (but not all) locked assignments allow viewing the description
        next nil if lock_info && !assignment.include_description?(current_user, lock_info)

        Loaders::ApiContentAttachmentLoader.for(assignment.context).load(assignment.description).then do |preloaded_attachments|
          GraphQLHelpers::UserContent.process(assignment.description,
                                              request: context[:request],
                                              context: assignment.context,
                                              user: current_user,
                                              in_app: context[:in_app],
                                              preloaded_attachments:,
                                              options: {
                                                domain_root_account: context[:domain_root_account],
                                              },
                                              location: assignment.asset_string)
        end
      end
    end

    field :needs_grading_count, Int, null: true
    def needs_grading_count
      return unless assignment.context.grants_right?(current_user, :manage_grades)

      # NOTE: this query (as it exists right now) is not batch-able.
      # make this really expensive cost-wise?
      Assignments::NeedsGradingCountQuery.new(
        assignment,
        current_user
        # TODO: course proxy stuff
        # (actually for some reason not passing along a course proxy doesn't
        # seem to matter)
      ).count
    end

    field :grading_type, AssignmentGradingType, null: true
    def grading_type
      return nil unless Assignment::ALLOWED_GRADING_TYPES.include?(assignment.grading_type)

      assignment.grading_type
    end

    field :grading_period_id, String, null: true
    def grading_period_id
      load_association(:submissions).then do |submissions|
        submissions.pluck(:grading_period_id).uniq.first
      end
    end

    field :submission_types,
          [Types::AssignmentSubmissionType],
          null: true
    def submission_types
      # there's some weird data in the db so we'll just ignore anything that
      # doesn't match a value that is expected
      (SUBMISSION_TYPES & assignment.submission_types_array).to_a
    end

    field :course, Types::CourseType, null: true
    def course
      load_association(:context)
    end

    field :course_id, ID, null: true
    def course_id
      assignment.context_id
    end

    field :grades_published, Boolean, null: true
    def grades_published
      assignment.grades_published?
    end

    field :moderated_grading_enabled, Boolean, null: true
    def moderated_grading_enabled
      assignment.moderated_grading?
    end

    field :allow_provisional_grading, Types::AllowProvisionalGradingType, null: false, description: "Whether the current user can provide a provisional grade for this assignment"
    def allow_provisional_grading
      return "not_applicable" unless assignment.moderated_grading?
      # Once grades are published, moderation is over - treat as normal assignment
      return "not_applicable" if assignment.grades_published_at.present?

      can_grade = assignment.can_be_moderated_grader?(current_user)
      can_grade ? "allowed" : "not_allowed"
    end

    field :post_manually, Boolean, null: true
    def post_manually
      Loaders::AssignmentLoaders::PostManuallyLoader.load(object.id)
    end

    field :published, Boolean, null: true
    def published
      assignment.published?
    end

    field :assignment_group, AssignmentGroupType, null: true
    def assignment_group
      load_association(:assignment_group)
    end

    field :assignment_group_id, ID, null: true

    field :only_visible_to_overrides,
          Boolean,
          "specifies that this assignment is only assigned to students for whom an
       `AssignmentOverride` applies.",
          null: false
    field :visible_to_everyone,
          Boolean,
          "specifies all other variables that can determine visiblity.",
          null: false
    def visible_to_everyone
      Loaders::DatesOverridableLoader.for.load(assignment).then(&:visible_to_everyone)
    end

    field :assignment_overrides, AssignmentOverrideType.connection_type, null: true
    def assignment_overrides
      # this is the assignment overrides index method of loading
      # overrides... there's also the totally different method found in
      # assignment_overrides_json. they may not return the same results?
      # ¯\_(ツ)_/¯
      Loaders::DatesOverridableLoader.for.load(assignment).then do |preloaded_assignment|
        AssignmentOverrideApplicator.overrides_for_assignment_and_user(preloaded_assignment, current_user)
      end
    end

    field :has_group_category,
          Boolean,
          "specifies that this assignment is a group assignment",
          method: :has_group_category?,
          null: false

    field :grade_as_group,
          Boolean,
          "specifies that students are being graded as a group (as opposed to being graded individually).",
          method: :grade_as_group?,
          null: false

    field :rubric_self_assessment_enabled,
          Boolean,
          "specifies that students can self-assess using the assignment rubric.",
          null: true

    field :can_update_rubric_self_assessment,
          Boolean,
          "specifies that the current user can update the rubric self-assessment.",
          null: true
    def can_update_rubric_self_assessment
      assignment.can_update_rubric_self_assessment?
    end

    field :group_set, GroupSetType, null: true
    def group_set
      load_association(:group_category)
    end

    field :submissions_connection, SubmissionType.connection_type, null: true do
      description "submissions for this assignment"
      argument :filter, SubmissionSearchFilterInputType, required: false
      argument :order_by, [SubmissionSearchOrderInputType], required: false
    end
    def submissions_connection(filter: nil, order_by: nil)
      return nil if current_user.nil?

      filter = filter.to_h
      order_by ||= []
      filter[:states] ||= DEFAULT_SUBMISSION_STATES
      filter[:states] = filter[:states] + ["unsubmitted"].freeze if filter[:include_unsubmitted]
      filter[:order_by] = order_by.map(&:to_h)
      SubmissionSearch.new(assignment, current_user, session, filter).search
    end

    field :my_sub_assignment_submissions_connection, SubmissionType.connection_type, null: true do
      description "submissions for sub-assignments belonging to the current user"
    end
    def my_sub_assignment_submissions_connection
      return nil if current_user.nil?

      load_association(:sub_assignment_submissions).then do |submissions|
        submissions.active.where(user_id: current_user)
      end
    end

    field :grading_standard_id, ID, null: true

    field :grading_standard, GradingStandardType, null: true
    def grading_standard
      load_association(:grading_standard)
    end

    field :group_submissions_connection, SubmissionType.connection_type, null: true do
      description "returns submissions grouped to one submission object per group"
      argument :filter, SubmissionSearchFilterInputType, required: false
      argument :order_by, [SubmissionSearchOrderInputType], required: false
    end
    def group_submissions_connection(filter: nil, order_by: nil)
      return nil if assignment.group_category_id.nil?

      scope = submissions_connection(filter:, order_by:)
      Promise.all([
                    Loaders::AssociationLoader.for(Assignment, :submissions).load(assignment),
                    Loaders::AssociationLoader.for(Assignment, :context).load(assignment)
                  ]).then do
        students = assignment.representatives(user: current_user)
        scope.where(user_id: students)
      end
    end

    field :lti_asset_processors_connection, LtiAssetProcessorType.connection_type, null: true
    def lti_asset_processors_connection
      load_association(:context).then do |course|
        next unless course.root_account.feature_enabled?(:lti_asset_processor)

        load_association(:lti_asset_processors)
      end
    end

    field :post_policy, PostPolicyType, null: true
    def post_policy
      load_association(:context).then do |course|
        if course.grants_right?(current_user, :manage_grades)
          load_association(:post_policy)
        end
      end
    end

    field :scheduled_post, ScheduledPostType, null: true
    def scheduled_post
      load_association(:context).then do |course|
        if course.grants_right?(current_user, :manage_grades)
          load_association(:scheduled_post)
        end
      end
    end

    field :score_statistic, AssignmentScoreStatisticType, null: true
    def score_statistic
      load_association(:context).then do |course|
        if course.grants_right?(current_user, :read_as_admin)
          object.score_statistic if object.can_view_score_statistics?(current_user)
        elsif object.can_view_score_statistics?(current_user) && object.submissions.first.eligible_for_showing_score_statistics?
          object.score_statistic
        end
      end
    end

    field :sis_id, String, null: true
    def sis_id
      load_association(:context).then do |course|
        assignment.sis_source_id if course.grants_any_right?(current_user, :read_sis, :manage_sis)
      end
    end

    field :has_sub_assignments, Boolean, "Boolean: returns true if the assignment is checkpointed. A checkpointed assignment has checkpoints ( also known as sub_assignments)", null: false

    field :checkpoints, [CheckpointType], "A list of checkpoints (also known as sub_assignments) that are associated with this assignment", null: true
    def checkpoints
      load_association(:context).then do |course|
        if course.discussion_checkpoints_enabled?
          load_association(:ordered_sub_assignments)
        end
      end
    end

    field :total_submissions, Int, null: true
    def total_submissions
      load_association(:context).then do |context|
        if context.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)
          load_association(:submissions).then do |submissions|
            submissions.where.not(workflow_state: "unsubmitted").count
          end
        end
      end
    end

    field :total_graded_submissions, Int, null: true
    def total_graded_submissions
      load_association(:context).then do |context|
        if context.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)
          load_association(:submissions).then do |submissions|
            submissions.graded.count
          end
        end
      end
    end

    field :assignment_target_connection, AssignmentOverrideType.connection_type, null: true do
      argument :order_by, AssignmentTargetSortOrderInputType, required: false
    end
    def assignment_target_connection(order_by: nil)
      load_association(:context).then do |context|
        return unless context.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)

        scope = assignment.all_assignment_overrides.active

        if order_by.present?
          field = order_by[:field]
          direction = (order_by[:direction] == "descending") ? "DESC NULLS LAST" : "ASC"

          raise "Sort by field '#{field}' is not supported" unless %w[title due_at lock_at unlock_at].include?(field)

          scope = scope.order(Arel.sql("assignment_overrides.#{field} #{direction}"))
        end

        scope
      end
    end

    field :anonymous_student_identities, [AnonymousStudentIdentityType], null: true
    def anonymous_student_identities
      return nil unless assignment.context.grants_right?(current_user, :manage_grades)

      assignment.anonymous_student_identities.values
    end

    field :auto_grade_assignment_issues, Types::EligibilityIssueType, null: true, description: "Issues related to the assignment"
    def auto_grade_assignment_issues
      load_association(:context).then do |course|
        next nil unless course.feature_enabled?(:project_lhotse)

        GraphQLHelpers::AutoGradeEligibilityHelper.validate_assignment(assignment:)
      end
    end

    field :auto_grade_assignment_errors, [String], null: false, description: "Errors related to the assignment"
    def auto_grade_assignment_errors
      load_association(:context).then do |course|
        next [] unless course.feature_enabled?(:project_lhotse)

        issues = GraphQLHelpers::AutoGradeEligibilityHelper.validate_assignment(assignment:)
        issues ? [issues[:message]] : []
      end
    end

    field :is_new_quiz, Boolean, null: false, description: "Assignment is connected to a New Quiz"
    def is_new_quiz
      assignment.quiz_lti?
    end

    field :module_items, [Types::ModuleItemType], null: true
    def module_items
      case object.submission_types
      when "online_quiz"
        load_association(:quiz).then do |quiz|
          next unless quiz

          Loaders::AssociationLoader.for(QuizType, :context_module_tags).load(quiz)
        end

      when "discussion_topic"
        load_association(:discussion_topic).then do |discussion|
          next unless discussion

          Loaders::AssociationLoader.for(DiscussionType, :context_module_tags).load(discussion)
        end
      else
        load_association(:context_module_tags)
      end
    end

    field :assigned_students, UserType.connection_type, null: true do
      argument :filter, AssignedStudentsFilterInputType, required: false
    end
    def assigned_students(filter: {})
      return nil unless assignment.context.grants_right?(current_user, :manage_grades)

      base_scope = assignment.context.participating_students_by_date.not_fake_student
      visible_students_subquery = assignment.context.apply_enrollment_visibility(base_scope, current_user)
                                            .select("users.*")

      scope = User.from("(#{visible_students_subquery.to_sql}) AS users")
      scope = assignment.students_with_visibility(scope)

      if (search_term = filter[:search_term].presence)
        scope = scope.name_like(search_term, "peer_review")
      end

      context.scoped_set!(:assignment_id, assignment.id)
      scope
    end

    field :grader_identities_connection, GraderIdentityType.connection_type, null: true do
      description "Grader identities if moderated assignment"
    end
    def grader_identities_connection
      return nil unless object.moderated_grading? &&
                        # The current user is an admin, moderator
                        (object.permits_moderation?(current_user) ||
                        # or provisional grader
                        object.moderation_graders.where(user: current_user).exists?)

      Loaders::AssignmentLoaders::OrderedModerationGradersWithSlotTakenLoader.load(object.id).then do |graders|
        AbstractAssignment.build_grader_identities(graders, anonymize: !object.can_view_other_grader_identities?(current_user))
      end
    end

    field :allocation_rules, AssignmentAllocationRules, null: true do
      description "Allocation rules if peer review is enabled"
    end
    def allocation_rules
      return nil unless assignment.grants_right?(current_user, :grade) &&
                        assignment.context.feature_enabled?(:peer_review_allocation_and_grading) &&
                        assignment.peer_reviews

      context.scoped_set!(:assignment_id, assignment.id)
      assignment
    end
  end
end
