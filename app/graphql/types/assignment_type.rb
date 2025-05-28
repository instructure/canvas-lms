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

    def self.overridden_field(field_name, description)
      field field_name, DateTimeType, description, null: true do
        argument :apply_overrides, Boolean, <<~MD, required: false, default_value: true
          When true, return the overridden dates.

          Not all roles have permission to view un-overridden dates (in which
          case the overridden dates will be returned)
        MD
      end

      define_method(field_name) do |apply_overrides:|
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
          method: :graded_submissions_exist?,
          null: true
    field :has_multiple_due_dates, Boolean, method: :multiple_distinct_due_dates?, null: true
    field :has_submitted_submissions,
          Boolean,
          "If true, the assignment has been submitted to by at least one student",
          method: :has_submitted_submissions?,
          null: true
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

    field :originality_report_visibility, String, null: true
    def originality_report_visibility
      return nil if object.turnitin_settings.empty?

      object.turnitin_settings[:originality_report_visibility]
    end

    field :rubric, RubricType, null: true
    def rubric
      load_association(:rubric)
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

    field :post_manually, Boolean, null: true
    def post_manually
      assignment.post_manually?
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

    field :assignment_overrides, AssignmentOverrideType.connection_type, null: true
    def assignment_overrides
      # this is the assignment overrides index method of loading
      # overrides... there's also the totally different method found in
      # assignment_overrides_json. they may not return the same results?
      # ¯\_(ツ)_/¯
      AssignmentOverrideApplicator.overrides_for_assignment_and_user(assignment, current_user)
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

    field :my_sub_assignment_submissions_connection, SubmissionType.connection_type, null: true
    def my_sub_assignment_submissions_connection
      return nil if current_user.nil?

      load_association(:sub_assignment_submissions).then do |submissions|
        submissions.active.where(user_id: current_user)
      end
    end

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
        # In the future we may need this for students, but for now
        # this is safest
        if course.root_account.feature_enabled?(:lti_asset_processor) && course.grants_right?(current_user, :manage_grades)
          load_association(:lti_asset_processors)
        end
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

    field :has_sub_assignments, Boolean, null: false

    field :checkpoints, [CheckpointType], null: true
    def checkpoints
      load_association(:context).then do |course|
        if course.discussion_checkpoints_enabled?
          load_association(:sub_assignments)
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

    field :auto_grade_assignment_errors, [String], null: false, description: "Issues related to the assignment"
    def auto_grade_assignment_errors
      GraphQLHelpers::AutoGradeEligibilityHelper.validate_assignment(assignment:)
    end

    field :is_new_quiz, Boolean, null: false, description: "Assignment is connected to a New Quiz"
    def is_new_quiz
      assignment.quiz_lti?
    end
  end
end
