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
  CourseType = GraphQL::ObjectType.define do
    name "Course"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id
    field :name, !types.String
    field :courseCode, types.String,
      "course short name",
      property: :course_code
    field :state, !CourseWorkflowState,
      property: :workflow_state

    connection :assignmentGroupsConnection, AssignmentGroupType.connection_type, property: :assignment_groups

    connection :assignmentsConnection do
      type AssignmentType.connection_type

      argument :filter, AssignmentFilterInputType

      resolve ->(course, args, ctx) {
        assignments = Assignments::ScopedToUser.new(course, ctx[:current_user]).scope

        assignments_resolver = ->(grading_period_id, has_grading_periods = nil) do
          if grading_period_id
            assignments.
              joins(:submissions).
              where(submissions: {grading_period_id: grading_period_id}).
              distinct
          elsif has_grading_periods
            # this is the case where a grading_period_id was not passed *and*
            # we are outside of any grading period (so we return nothing)
            []
          else
            assignments
          end
        end

        filter = args[:filter] || {}

        if filter.key?(:gradingPeriodId)
          assignments_resolver.call(filter[:gradingPeriodId])
        else
          Loaders::CurrentGradingPeriodLoader.load(course)
            .then do |gp, has_grading_periods|
            assignments_resolver.call(gp&.id, has_grading_periods)
          end
        end
      }
    end

    connection :sectionsConnection do
      type SectionType.connection_type
      resolve -> (course, _, ctx) {
        course.active_course_sections.
          order(CourseSection.best_unicode_collation_key('name'))
      }
    end

    connection :usersConnection do
      type UserType.connection_type

      argument :userIds, types[!types.ID], <<~DOC,
        Only include users with the given ids.

        **This field is deprecated, use `filter: {userIds}` instead.**
        DOC
        prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")

      argument :filter, CourseUsersFilterInputType

      resolve ->(course, args, ctx) {
        return nil unless course.grants_any_right?(
          ctx[:current_user], ctx[:session],
          :read_roster, :view_all_grades, :manage_grades
        )

        filter = args[:filter] || {}

        scope = UserSearch.scope_for(course, ctx[:current_user],
                                     include_inactive_enrollments: true,
                                     enrollment_state: filter[:enrollmentStates])

        user_ids = filter[:userIds] || args[:userIds]
        if user_ids.present?
          scope = scope.where(users: {id: user_ids})
        end

        scope
      }
    end

    connection :gradingPeriodsConnection, GradingPeriodType.connection_type do
      resolve ->(course, _, _) {
        GradingPeriod.for(course).order(:start_date)
      }
    end

    connection :submissionsConnection, SubmissionType.connection_type do
      description "all the submissions for assignments in this course"

      argument :studentIds, !types[!types.ID], "Only return submissions for the given students.",
        prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")
      argument :orderBy, types[SubmissionOrderInputType]
      argument :filter, SubmissionFilterInputType

      resolve ->(course, args, ctx) {
        current_user = ctx[:current_user]
        session = ctx[:session]
        user_ids = args[:studentIds].map(&:to_i)

        if course.grants_any_right?(current_user, session, :manage_grades, :view_all_grades)
          # TODO: make a preloader for this???
          allowed_user_ids = course.apply_enrollment_visibility(course.all_student_enrollments, current_user).pluck(:user_id)
          allowed_user_ids &= user_ids
        elsif course.grants_right?(current_user, session, :read_grades)
          allowed_user_ids = user_ids & [current_user.id]
        else
          allowed_user_ids = []
        end

        submissions = Submission.active.joins(:assignment).where(
          user_id: allowed_user_ids,
          assignment_id: course.assignments.published,
          workflow_state: (args[:filter] || {})[:states] || DEFAULT_SUBMISSION_STATES
        )

        (args[:orderBy] || []).each { |order|
          submissions = submissions.order("#{order[:field]} #{order[:direction]}")
        }

        submissions
      }
    end

    connection :groupsConnection, GroupType.connection_type, resolve: ->(course, _, ctx) {
      # TODO: share this with accounts when groups are added there
      if course.grants_right?(ctx[:current_user], nil, :read_roster)
        course.groups.active
          .order(GroupCategory::Bookmarker.order_by, Group::Bookmarker.order_by)
          .eager_load(:group_category)
      else
        nil
      end
    }

    field :permissions, CoursePermissionsType do
      description "returns permission information for the current user in this course"
      resolve ->(course, _, ctx) {
        Loaders::CoursePermissionsLoader.for(
          course,
          current_user: ctx[:current_user], session: ctx[:session]
        )
      }
    end
  end

  SubmissionOrderInputType = GraphQL::InputObjectType.define do
    name "SubmissionOrderCriteria"
    argument :field, !GraphQL::EnumType.define {
      name "SubmissionOrderField"
      value "_id", value: "id"
      value "gradedAt", value: "graded_at"
    }
    argument :direction, GraphQL::EnumType.define {
      name "OrderDirection"
      value "ascending", value: "ASC"
      value "descending", value: "DESC NULLS LAST"
    }
  end

  CourseWorkflowState = GraphQL::EnumType.define do
    name "CourseWorkflowState"
    description "States that Courses can be in"
    value "created"
    value "claimed"
    value "available"
    value "completed"
    value "deleted"
  end

  AssignmentFilterInputType = GraphQL::InputObjectType.define do
    name "AssignmentFilter"
    argument :gradingPeriodId, types.ID, <<-DESC
    only return assignments for the given grading period. Defaults to the
current grading period. Pass `null` to not filter by grading period.
    DESC
  end

  CourseUsersFilterInputType = GraphQL::InputObjectType.define do
    name "CourseUsersFilter"

    argument :userIds, types[!types.ID],
      "only include users with the given ids",
      prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")

    argument :enrollmentStates, types[!CourseFilterableEnrollmentWorkflowState], <<-DESC
      only return users with the given enrollment state. defaults
      to `invited`, `creation_pending`, `active`
    DESC
  end

  CourseFilterableEnrollmentWorkflowState = GraphQL::EnumType.define do
    name "CourseFilterableEnrollmentState"
    description "Users in a course can be returned based on these enrollment states"
    value "invited"
    value "creation_pending"
    value "active"
    value "rejected"
    value "completed"
    value "inactive"
  end
end
