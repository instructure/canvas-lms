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

    field :_id, ID, null: false
    field :alignments_count, Integer, null: false
    field :assignment_content_type, String, null: true
    field :assignment_workflow_state, String, null: true
    field :content_id, ID, null: false
    field :content_type, String, null: false
    field :context_id, ID, null: false
    field :context_type, String, null: false
    field :learning_outcome_id, ID, null: false
    field :module_id, String, null: true
    field :module_name, String, null: true
    field :module_url, String, null: true
    field :module_workflow_state, String, null: true
    field :quiz_items, [Types::QuizItemType], null: true
    field :title, String, null: false
    field :url, String, null: false
  end
end
