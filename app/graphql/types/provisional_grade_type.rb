# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
  class ProvisionalGradeType < ApplicationObjectType
    implements Interfaces::LegacyIDInterface

    field :grade, String, null: true
    field :score, Float, null: true

    field :final, Boolean, null: false
    field :selected, Boolean, null: false
    def selected
      load_association(:selection).then do
        object.selection.present?
      end
    end

    field :scorer_anonymous_id, ID, null: true
    def scorer_anonymous_id
      # Most often, we are requesting submissions that belong to the same assignment,
      # so we fetch the moderation graders only once for that assignment and filter in memory
      load_association(:submission).then do |submission|
        Loaders::AssociationLoader.for(Submission, :assignment).load(submission).then do |assignment|
          Loaders::AssociationLoader.for(AbstractAssignment, :moderation_graders).load(assignment).then do |graders|
            graders.find { |grader| grader.user_id == object.scorer_id }&.anonymous_id
          end
        end
      end
    end
  end
end
