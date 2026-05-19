# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
  class AiGradeCriterionResultType < ApplicationObjectType
    graphql_name "AIGradeCriterionResult"

    field :comments, String, null: true, hash_key: "comments"
    field :description, String, null: false, hash_key: "description"
    field :id, ID, null: false, hash_key: "id"
    field :rating, AiGradeRatingType, null: false, hash_key: "rating"
    field :response_id, String, null: true, hash_key: "responseId"
  end
end
