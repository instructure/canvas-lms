# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
  class OutcomeAlignmentType < ApplicationObjectType
    graphql_name "OutcomeAlignment"

    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :title, String, null: false
    field :content_id, ID, null: false
    field :content_type, String, null: false
    field :context_id, ID, null: false
    field :context_type, String, null: false
    field :learning_outcome_id, ID, null: false
    field :url, String, null: false
    def url
      [base_context_url.to_s, "outcomes", object.learning_outcome_id, "alignments", object.id].join("/")
    end
    field :module_id, String, null: true
    field :module_name, String, null: true
    field :module_url, String, null: true
    def module_url
      [base_context_url.to_s, "modules", object.module_id].join("/") if object.module_id
    end
    field :module_workflow_state, String, null: true
    field :assignment_content_type, String, null: true
    def assignment_content_type
      return "quiz" unless object.quizzes_id.nil?
      return "discussion" unless object.discussion_id.nil?
      return "assignment" unless object.assignment_id.nil?
    end

    private

    def base_context_url
      ["/#{object.context_type.downcase.pluralize}", object.context_id].join("/")
    end
  end
end
