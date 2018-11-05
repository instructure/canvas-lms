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
    graphql_name "Query"

    field :node, field: GraphQL::Relay::Node.field

    field :legacy_node, GraphQL::Types::Relay::Node, null: true do
      description "Fetches an object given its type and legacy ID"
      argument :_id, ID, required: true
      argument :type, LegacyNodeType, required: true
    end
    def legacy_node(type:, _id:)
      GraphQLNodeLoader.load(type, _id, context)
    end

    field :course, Types::CourseType, null: true do
      argument :id, ID, "a graphql or legacy id", required: true,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
    end
    def course(id:)
      GraphQLNodeLoader.load("Course", id, context)
    end

    field :assignment, Types::AssignmentType, null: true do
      argument :id, ID, "a graphql or legacy id", required: true,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")
    end
    def assignment(id:)
      GraphQLNodeLoader.load("Assignment", id, context)
    end

    field :assignment_group, Types::AssignmentGroupType, null: true do
      argument :id, ID, "a graphql or legacy id", required: true,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("AssignmentGroup")
    end
    def assignment_group(id:)
      GraphQLNodeLoader.load("AssignmentGroup", id, context)
    end

    field :all_courses, [CourseType],
      "All courses viewable by the current user",
      null: true
    def all_courses
        # TODO: really need a way to share similar logic like this
        # with controllers in api/v1
        current_user&.cached_current_enrollments(preload_courses: true).
          index_by(&:course_id).values.
          sort_by! { |enrollment|
            Canvas::ICU.collation_key(enrollment.course.nickname_for(current_user))
          }.map(&:course)
    end
  end
end
