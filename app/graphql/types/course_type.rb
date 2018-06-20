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

  class CourseType < ApplicationObjectType
    graphql_name "Course"

    alias :course :object

    CourseWorkflowState = GraphQL::EnumType.define do
      name "CourseWorkflowState"
      description "States that Courses can be in"
      value "created"
      value "claimed"
      value "available"
      value "completed"
      value "deleted"
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

    class CourseUsersFilterInputType < Types::BaseInputObject
      graphql_name "CourseUsersFilter"

      argument :user_ids, [ID],
        "only include users with the given ids",
        prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User"),
        required: false

      argument :enrollment_states, [CourseFilterableEnrollmentWorkflowState],
        <<~DESC,
          only return users with the given enrollment state. defaults
          to `invited`, `creation_pending`, `active`
        DESC
        required: false
    end

    implements GraphQL::Relay::Node.interface
    implements Interfaces::TimestampInterface

    field :_id, ID, "legacy canvas id", method: :id, null: false
    global_id_field :id
    field :name, String, null: false
    field :course_code, String, "course short name", null: true
    field :state, CourseWorkflowState, method: :workflow_state, null: false

    field :assignment_groups_connection, AssignmentGroupType.connection_type,
      method: :assignment_groups,
      null: true

    implements Interfaces::AssignmentsConnectionInterface
    def assignments_connection(filter: {})
      super(filter: filter, course: course)
    end

    field :sections_connection, SectionType.connection_type, null: true
    def sections_connection
      course.active_course_sections.
        order(CourseSection.best_unicode_collation_key('name'))
    end

    field :users_connection, UserType.connection_type, null: true do
      argument :user_ids, [ID], <<~DOC,
        Only include users with the given ids.

        **This field is deprecated, use `filter: {userIds}` instead.**
        DOC
        prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User"),
        required: false

      argument :filter, CourseUsersFilterInputType, required: false
    end
    def users_connection(user_ids: nil, filter: {})
      return nil unless course.grants_any_right?(
        current_user, session,
        :read_roster, :view_all_grades, :manage_grades
      )

      scope = UserSearch.scope_for(course, current_user,
                                   include_inactive_enrollments: true,
                                   enrollment_state: filter[:enrollment_states])

      user_ids = filter[:user_ids] || user_ids
      if user_ids.present?
        scope = scope.where(users: {id: user_ids})
      end

      scope
    end

    field :grading_periods_connection, GradingPeriodType.connection_type, null: true
    def grading_periods_connection
      GradingPeriod.for(course).order(:start_date)
    end

    field :submissions_connection, SubmissionType.connection_type, null: true do
      description "all the submissions for assignments in this course"

      argument :student_ids, [ID], "Only return submissions for the given students.",
        prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User"),
        required: true
      argument :order_by, [SubmissionOrderInputType], required: false
      argument :filter, SubmissionFilterInputType, required: false
    end
    def submissions_connection(student_ids:, order_by: [], filter: {})
      user_ids = student_ids.map(&:to_i)
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
        workflow_state: (filter || {})[:states] || DEFAULT_SUBMISSION_STATES
      )

      (order_by || []).each { |order|
        submissions = submissions.order("#{order[:field]} #{order[:direction]}")
      }

      submissions
    end

    field :groups_connection, GroupType.connection_type, null: true
    def groups_connection
      # TODO: share this with accounts when groups are added there
      if course.grants_right?(current_user, session, :read_roster)
        course.groups.active
          .order(GroupCategory::Bookmarker.order_by, Group::Bookmarker.order_by)
          .eager_load(:group_category)
      else
        nil
      end
    end

    field :permissions, CoursePermissionsType,
      "returns permission information for the current user in this course",
      null: true

    def permissions
      Loaders::CoursePermissionsLoader.for(
        course,
        current_user: current_user, session: session
      )
    end
  end
end

