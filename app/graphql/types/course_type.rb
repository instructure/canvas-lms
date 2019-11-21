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

    argument :field, SubmissionOrderFieldType, required: true
    argument :direction, OrderDirectionType, required: false
  end

  class CourseType < ApplicationObjectType
    graphql_name "Course"

    alias :course :object

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

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

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

    field :account, AccountType, null: true
    def account
      load_association(:account)
    end

    field :sections_connection, SectionType.connection_type, null: true
    def sections_connection
      course.active_course_sections.
        order(CourseSection.best_unicode_collation_key('name'))
    end

    field :modules_connection, ModuleType.connection_type, null: true
    def modules_connection
      course.modules_visible_to(current_user).
        order('name')
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
        required: false
      argument :order_by, [SubmissionOrderInputType], required: false
      argument :filter, SubmissionFilterInputType, required: false
    end
    def submissions_connection(student_ids: nil, order_by: [], filter: {})
      if course.grants_any_right?(current_user, session, :manage_grades, :view_all_grades)
        # TODO: make a preloader for this???
        allowed_user_ids = course.apply_enrollment_visibility(course.all_student_enrollments, current_user).pluck(:user_id)
      elsif course.grants_right?(current_user, session, :read_grades)
        allowed_user_ids = [current_user.id]
      else
        allowed_user_ids = []
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

      (order_by || []).each { |order|
        direction = order[:direction] == 'descending' ? "DESC NULLS LAST" : "ASC"
        submissions = submissions.order("#{order[:field]} #{direction}")
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

    field :group_sets_connection, GroupSetType.connection_type, <<~DOC, null: true
      Project group sets for this course.
    DOC
    def group_sets_connection
      if course.grants_right? current_user, :manage_groups
        course.group_categories.where(role: nil)
      end
    end

    field :external_tools_connection, ExternalToolType.connection_type, null: true do
      argument :filter, ExternalToolFilterInputType, required: false, default_value: {}
    end
    def external_tools_connection(filter:)
      scope = ContextExternalTool.all_tools_for(course, {placements: filter.placement})
      filter.state.nil? ? scope : scope.where(workflow_state: filter.state)
    end

    field :term, TermType, null: true
    def term
      load_association(:enrollment_term)
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

    field :post_policy, PostPolicyType, "A course-specific post policy", null: true
    def post_policy
      return nil unless course.grants_right?(current_user, :manage_grades)
      load_association(:default_post_policy)
    end

    field :assignment_post_policies, PostPolicyType.connection_type,
      <<~DOC,
        PostPolicies for assignments within a course
      DOC
      null: true
    def assignment_post_policies
      return nil unless course.grants_right?(current_user, :manage_grades)
      course.assignment_post_policies
    end

    field :image_url, UrlType, <<~DOC, null: true
      Returns a URL for the course image (this is the image used on dashboard
      course cards)
    DOC
    def image_url
      return nil unless course.feature_enabled?('course_card_images')

      if course.image_url
        course.image_url
      elsif course.image_id.present?
        Loaders::IDLoader.for(Attachment.active).load(
          # if `course.image` was a proper AR association, we wouldn't have to
          # do this shard-id stuff
          course.shard.global_id_for(Integer(course.image_id))
        ).then { |attachment|
          attachment&.public_download_url(1.week)
        }
      end
    end
  end
end
