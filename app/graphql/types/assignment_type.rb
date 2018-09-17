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

    implements GraphQL::Relay::Node.interface
    implements Interfaces::TimestampInterface

    alias :assignment :object

    class AssignmentStateType < Types::BaseEnum
      graphql_name "AssignmentState"
      description "States that an Assignment can be in"
      value "unpublished"
      value "published"
      value "deleted"
    end

    GRADING_TYPES = Hash[
      Assignment::ALLOWED_GRADING_TYPES.zip(Assignment::ALLOWED_GRADING_TYPES)
    ]

    SUBMISSION_TYPES = %w[
      attendance
      discussion_topic
      external_tool
      media_recording
      none
      not_graded
      on_paper
      online_quiz
      online_text_entry
      online_upload
      online_url
      wiki_page
    ].to_set

    class AssignmentSubmissionType < Types::BaseEnum
      graphql_name "SubmissionType"
      description "Types of submissions an assignment accepts"
      SUBMISSION_TYPES.each { |submission_type|
        value(submission_type)
      }
    end

    class AssignmentGradingType < Types::BaseEnum
      graphql_name "GradingType"
      Assignment::ALLOWED_GRADING_TYPES.each { |type| value(type) }
    end

    global_id_field :id
    field :_id, ID, "legacy canvas id", null: false, method: :id

    field :name, String, null: true

    field :position, Int,
      "determines the order this assignment is displayed in in its assignment group",
      null: true
    field :description, String, null: true

    field :points_possible, Float, "the assignment is out of this many points",
      null: true

    field :due_at, DateTimeType,
      "when this assignment is due",
      null: true
    field :lock_at, DateTimeType, null: true
    field :unlock_at, DateTimeType, null: true

    field :lock_info, LockInfoType, null: true

    def lock_info
      Loaders::AssociationLoader.for(
        Assignment,
        %i[context discussion_topic quiz wiki_page]
      ).load(assignment).then {
        assignment.low_level_locked_for?(current_user,
                                         check_policies: true,
                                         context: assignment.context)
      }
    end

    field :muted, Boolean, method: :muted?, null: false

    field :state, AssignmentStateType, method: :workflow_state, null: false

    field :assignment_group, AssignmentGroupType, null: true
    def assignment_group
      # TODO: conditionally load context_module_tags (see locked_for impl.)
      load_association(:assignment_group)
    end

    field :quiz, Types::QuizType, null: true
    def quiz
      load_association(:quiz)
    end

    field :discussion, Types::DiscussionType, null: true
    def discussion
      load_association(:discussion_topic)
    end

    field :html_url, UrlType, null: true
    def html_url
      Rails.application.routes.url_helpers.course_assignment_url(
        course_id: assignment.context_id,
        id: assignment.id,
        host: context[:request].host_with_port
      )
    end

    field :needs_grading_count, Int, null: true
    def needs_grading_count
      # NOTE: this query (as it exists right now) is not batch-able.
      # make this really expensive cost-wise?
      Assignments::NeedsGradingCountQuery.new(
        assignment,
        current_user
        # TODO course proxy stuff
        # (actually for some reason not passing along a course proxy doesn't
        # seem to matter)
      ).count
    end

    field :grading_type, AssignmentGradingType, null: true
    def grading_type
      GRADING_TYPES[assignment.grading_type]
    end

    field :submission_types, [AssignmentSubmissionType],
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

    field :assignment_group, AssignmentGroupType, null: true
    def assignment_group
      load_association(:assignment_group)
    end

    field :only_visible_to_overrides, Boolean,
      "specifies that this assignment is only assigned to students for whom an
       `AssignmentOverride` applies.",
      null: false

    field :assignment_overrides, AssignmentOverrideType.connection_type,
      null: true
    def assignment_overrides
        # this is the assignment overrides index method of loading
        # overrides... there's also the totally different method found in
        # assignment_overrides_json. they may not return the same results?
        # ¯\_(ツ)_/¯
        AssignmentOverrideApplicator.overrides_for_assignment_and_user(assignment, current_user)
    end

    field :submissions_connection, SubmissionType.connection_type, null: true do
      description "submissions for this assignment"
      argument :filter, SubmissionFilterInputType, required: false
    end
    def submissions_connection(filter: nil)
      course = assignment.context

      submissions = assignment.submissions.where(
        workflow_state: (filter || {})[:states] || DEFAULT_SUBMISSION_STATES
      )

      if course.grants_any_right?(current_user, session, :manage_grades, :view_all_grades)
        submissions
      elsif course.grants_right?(current_user, session, :read_grades)
        # a user can see their own submission
        submissions.where(user_id: current_user.id)
      end
    end
  end
end
