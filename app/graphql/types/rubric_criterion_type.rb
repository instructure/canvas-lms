# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
  class RubricCriterionType < ApplicationObjectType
    description "Individual criteria for a rubric"

    def initialize(object, context)
      @rubric_id = context[:rubric_id]
      super(object, context)
    end

    implements Interfaces::LegacyIDInterface

    field :criterion_use_range, Boolean, null: false
    def criterion_use_range
      !!object[:criterion_use_range]
    end

    field :description, String, null: true

    field :ignore_for_scoring, Boolean, null: false
    def ignore_for_scoring
      !!object[:ignore_for_scoring]
    end

    field :outcome, LearningOutcomeType, null: true
    def outcome
      return nil unless object[:learning_outcome_id]

      Loaders::IDLoader.for(LearningOutcome).load(object[:learning_outcome_id])
    end

    field :learning_outcome_id, ID, null: true
    field :long_description, String, null: true
    field :mastery_points, Float, null: true
    field :points, Float, null: true
    field :ratings, [RubricRatingType], <<~MD, null: true
      The possible ratings available for this criterion
    MD
    def ratings
      context[:rubric_id] = @rubric_id
      object[:ratings]
    end
  end
end
