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
  class QueryType < ApplicationObjectType
    graphql_name "Query"

    add_field GraphQL::Types::Relay::NodeField

    field :legacy_node, GraphQL::Types::Relay::Node, null: true do
      description "Fetches an object given its type and legacy ID"
      argument :_id, ID, required: true
      argument :type, LegacyNodeType, required: true
    end
    def legacy_node(type:, _id:)
      GraphQLNodeLoader.load(type, _id, context)
    end

    field :account, Types::AccountType, null: true do
      argument :id, ID, "a graphql or legacy id", required: false,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Account")
      argument :sis_id, String, "a id from the original SIS system", required: false
    end
    def account(id: nil, sis_id: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of id or sisId" if (id && sis_id) || !(id || sis_id)
      return GraphQLNodeLoader.load("Account", id, context) if id
      return GraphQLNodeLoader.load("AccountBySis", sis_id, context) if sis_id
    end

    field :course, Types::CourseType, null: true do
      argument :id, ID, "a graphql or legacy id, preference for search is given to this id", required: false,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
      argument :sis_id, String, "a id from the original SIS system", required: false
    end
    def course(id: nil, sis_id: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of id or sisId" if (id && sis_id) || !(id || sis_id)
      return GraphQLNodeLoader.load("Course", id, context) if id
      return GraphQLNodeLoader.load("CourseBySis", sis_id, context) if sis_id
    end

    field :assignment, Types::AssignmentType, null: true do
      argument :id, ID, "a graphql or legacy id", required: false,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")
      argument :sis_id, String, "an id from the original SIS system", required: false
    end
    def assignment(id: nil, sis_id: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of id or sisId" if (id && sis_id) || !(id || sis_id)
      return GraphQLNodeLoader.load("Assignment", id, context) if id
      return GraphQLNodeLoader.load("AssignmentBySis", sis_id, context) if sis_id
    end

    field :assignment_group, Types::AssignmentGroupType, null: true do
      argument :id, ID, "a graphql or legacy id", required: false,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("AssignmentGroup")
      argument :sis_id, String, "an id from the original SIS system", required: false
    end
    def assignment_group(id: nil, sis_id: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of id or sisId" if (id && sis_id) || !(id || sis_id)
      return GraphQLNodeLoader.load("AssignmentGroup", id, context) if id
      return GraphQLNodeLoader.load("AssignmentGroupBySis", sis_id, context) if sis_id
    end

    field :submission, Types::SubmissionType, null: true do
      argument :id, ID, "a graphql or legacy id", required: true,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Submission")
    end
    def submission(id:)
      GraphQLNodeLoader.load("Submission", id, context)
    end

    field :term, Types::TermType, null: true do
      argument :id, ID, "a graphql or legacy id", required: false,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Term")
      argument :sis_id, String, "an id from the original SIS system", required: false
    end
    def term(id: nil, sis_id: nil)
      raise GraphQL::ExecutionError, "Must specify exactly one of id or sisId" if (id && sis_id) || !(id || sis_id)
      return GraphQLNodeLoader.load("Term", id, context) if id
      return GraphQLNodeLoader.load("TermBySis", sis_id, context) if sis_id
    end

    field :all_courses, [CourseType],
      "All courses viewable by the current user",
      null: true
    def all_courses
        # TODO: really need a way to share similar logic like this
        # with controllers in api/v1
        current_user&.cached_currentish_enrollments(preload_courses: true).
          index_by(&:course_id).values.
          sort_by! { |enrollment|
            Canvas::ICU.collation_key(enrollment.course.nickname_for(current_user))
          }.map(&:course)
    end

    field :module_item, Types::ModuleItemType, null: true do
      description "ModuleItem"
      argument :id, ID, "a graphql or legacy id", required: true,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("ModuleItem")
    end
    def module_item(id:)
      GraphQLNodeLoader.load("ModuleItem", id, context)
    end

    field :audit_logs, Types::AuditLogsType, null: true
    def audit_logs
      Canvas::DynamoDB::DatabaseBuilder.from_config(:auditors)
    end

    field :outcome_calculation_method, Types::OutcomeCalculationMethodType, null: true do
      description "OutcomeCalculationMethod"
      argument :id, ID, "a graphql or legacy id", required: true,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("OutcomeCalculationMethod")
    end
    def outcome_calculation_method(id:)
      GraphQLNodeLoader.load("OutcomeCalculationMethod", id, context)
    end

    field :outcome_proficiency, Types::OutcomeProficiencyType, null: true do
      description "OutcomeProficiency"
      argument :id, ID, "a graphql or legacy id", required: true,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("OutcomeProficiency")
    end
    def outcome_proficiency(id:)
      GraphQLNodeLoader.load("OutcomeProficiency", id, context)
    end
  end
end
