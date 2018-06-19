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
  AssignmentType = GraphQL::ObjectType.define do
    name "Assignment"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id

    field :name, types.String

    field :position, types.Int,
      "determines the order this assignment is displayed in in its assignment group"
    field :description, types.String

    field :pointsPossible, types.Float,
      "the assignment is out of this many points",
      property: :points_possible

    field :dueAt, DateTimeType,
      "when this assignment is due",
      property: :due_at
    field :lockAt, DateTimeType, property: :lock_at
    field :unlockAt, DateTimeType, property: :unlock_at

    field :muted, types.Boolean, property: :muted?

    field :state, !AssignmentState, property: :workflow_state

    field :assignmentGroup, AssignmentGroupType, resolve: ->(assignment, _, _) {
      Loaders::AssociationLoader.for(Assignment, :assignment_group)
        .load(assignment)
        .then { assignment.assignment_group }
    }

    field :quiz, Types::QuizType, resolve: -> (assignment, _, _) {
      Loaders::AssociationLoader.for(Assignment, :quiz)
        .load(assignment)
        .then { assignment.quiz }
    }

    field :discussion, Types::DiscussionType, resolve: -> (assignment, _, _) {
      Loaders::AssociationLoader.for(Assignment, :discussion_topic)
        .load(assignment)
        .then { assignment.discussion_topic }
    }

    field :htmlUrl, UrlType, resolve: ->(assignment, _, ctx) {
      Rails.application.routes.url_helpers.course_assignment_url(
        course_id: assignment.context_id,
        id: assignment.id,
        host: ctx[:request].host_with_port
      )
    }

    field :needsGradingCount, types.Int do
      # NOTE: this query (as it exists right now) is not batch-able.
      # make this really expensive cost-wise?
      resolve ->(assignment, _, ctx) do
        Assignments::NeedsGradingCountQuery.new(
          assignment,
          ctx[:current_user]
          # TODO course proxy stuff
          # (actually for some reason not passing along a course proxy doesn't
          # seem to matter)
        ).count
      end
    end

    field :gradingType, AssignmentGradingType, resolve: ->(assignment, _, _) {
      GRADING_TYPES[assignment.grading_type]
    }

    field :submissionTypes, types[!AssignmentSubmissionType],
      resolve: ->(assignment, _, _) {
        # there's some weird data in the db so we'll just ignore anything that
        # doesn't match a value that is expected
        (SUBMISSION_TYPES & assignment.submission_types_array).to_a
      }

    field :course, Types::CourseType, resolve: -> (assignment, _, _) {
      # course is polymorphicly associated with assignment through :context
      # it could also be queried by assignment.assignment_group.course
      Loaders::AssociationLoader.for(Assignment, :context)
        .load(assignment)
        .then { assignment.context }
    }

    field :assignmentGroup, AssignmentGroupType, resolve: ->(assignment, _, _) {
      Loaders::AssociationLoader.for(Assignment, :assignment_group)
        .load(assignment)
        .then { assignment.assignment_group }
    }

    field :onlyVisibleToOverrides, types.Boolean,
      "specifies that this assignment is only assigned to students for whom an
       `AssignmentOverride` applies.",
      property: :only_visible_to_overrides

    connection :assignmentOverrides, AssignmentOverrideType.connection_type, resolve:
      ->(assignment, _, ctx) {
        # this is the assignment overrides index method of loading
        # overrides... there's also the totally different method found in
        # assignment_overrides_json. they may not return the same results?
        # ¯\_(ツ)_/¯
        AssignmentOverrideApplicator.overrides_for_assignment_and_user(assignment, ctx[:current_user])
      }

    connection :submissionsConnection, SubmissionType.connection_type do
      description "submissions for this assignment"
      argument :filter, SubmissionFilterInputType

      resolve ->(assignment, args, ctx) {
        current_user = ctx[:current_user]
        session = ctx[:session]
        course = assignment.course

        submissions = assignment.submissions.where(
          workflow_state: (args[:filter] || {})[:states] || DEFAULT_SUBMISSION_STATES
        )

        if course.grants_any_right?(current_user, session, :manage_grades, :view_all_grades)
          submissions
        elsif course.grants_right?(current_user, session, :read_grades)
          # a user can see their own submission
          submissions.where(user_id: current_user.id)
        end
      }
    end
  end

  AssignmentState = GraphQL::EnumType.define do
    name "AssignmentState"
    description "States that an Assignment can be in"
    value "unpublished"
    value "published"
    value "deleted"
  end

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

  GRADING_TYPES = Hash[
    Assignment::ALLOWED_GRADING_TYPES.zip(Assignment::ALLOWED_GRADING_TYPES)
  ]

  AssignmentSubmissionType = GraphQL::EnumType.define do
    name "SubmissionType"
    description "Types of submissions an assignment accepts"
    SUBMISSION_TYPES.each { |submission_type|
      value(submission_type)
    }
  end

  AssignmentGradingType = GraphQL::EnumType.define do
    name "GradingType"
    Assignment::ALLOWED_GRADING_TYPES.each { |type| value(type) }
  end
end
