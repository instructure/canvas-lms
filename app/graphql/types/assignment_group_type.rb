# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Types
  class AssignmentGroupType < ApplicationObjectType
    graphql_name "AssignmentGroup"

    alias_method :assignment_group, :object

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    class AssignmentGroupState < BaseEnum
      graphql_name "AssignmentGroupState"
      description "States that Assignment Group can be in"
      value "available"
      value "deleted"
    end

    class GradesEnrollmentFilterInputType < Types::BaseInputObject
      graphql_name "GradesEnrollmentFilter"

      argument :enrollment_ids,
               [ID],
               "only include users with the given enrollment ids",
               prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Enrollment"),
               required: false
    end

    global_id_field :id
    field :name, String, null: true
    field :rules, AssignmentGroupRulesType, method: :rules_hash, null: true
    field :group_weight, Float, null: true
    field :position, Int, null: true
    field :state, AssignmentGroupState, method: :workflow_state, null: false

    implements Interfaces::AssignmentsConnectionInterface
    def assignments_connection(filter: {})
      load_association(:context).then do |course|
        super(course:, filter:)
      end
    end

    field :grades_connection, GradesType.connection_type, null: true do
      description "grades for this assignment group"
      argument :filter, GradesEnrollmentFilterInputType, required: false
    end
    def grades_connection(filter: {})
      load_association(:context).then do |course|
        enrollments = course.all_student_enrollments
        if filter[:enrollment_ids]
          enrollments = enrollments.where(id: filter[:enrollment_ids])
        end
        visible_enrollments = course.apply_enrollment_visibility(enrollments, current_user)

        # slim the scope down further because while students can see other student enrollments, they should not be able to see other student grades
        unless course.grants_any_right?(current_user, :manage_grades, :read_as_admin)
          visible_enrollments = visible_enrollments.where(enrollments: { user_id: current_user[:id] })
        end
        assignment_group.scores.where(enrollment_id: visible_enrollments)
      end
    end

    field :sis_id, String, null: true
    def sis_id
      load_association(:context).then do |course|
        assignment_group.sis_source_id if course.grants_any_right?(current_user, :read_sis, :manage_sis)
      end
    end

    def assignments_scope(*args)
      super(*args).where(assignment_group_id: object.id)
    end
    private :assignments_scope
  end
end
