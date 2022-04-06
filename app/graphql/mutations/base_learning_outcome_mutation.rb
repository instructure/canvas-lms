# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module Mutations
  class BaseLearningOutcomeMutation < BaseMutation
    # input arguments
    argument :title, String, required: true
    argument :description, String, required: false
    argument :display_name, String, required: false
    argument :vendor_guid, String, required: false
    argument :calculation_method, String, required: false
    argument :calculation_int, Integer, required: false
    argument :mastery_points, Float, required: false
    argument :ratings, [Types::ProficiencyRatingInputType], required: false

    field :learning_outcome, Types::LearningOutcomeType, null: true

    protected

    def attrs(input, context)
      outcome_input = input.to_h.slice(:title, :display_name, :description, :vendor_guid)

      outcome_input.merge ratings_attrs(input, context)
    end

    def ratings_attrs(input, context)
      ratings_input = input.to_h.slice(:calculation_method, :calculation_int, :mastery_points, :ratings)

      return {} unless ratings_input.count.positive? && context

      raise GraphQL::ExecutionError, I18n.t("individual ratings data input with acount_level_mastery_scale FF enabled") if context.root_account.feature_enabled?(:account_level_mastery_scales)

      updated_ratings_attrs = {}
      rubric_criterion = {}
      rubric_criterion[:mastery_points] = ratings_input[:mastery_points] if ratings_input[:mastery_points]
      rubric_criterion[:ratings] = ratings_input[:ratings] if ratings_input[:ratings]
      updated_ratings_attrs[:calculation_method] = ratings_input[:calculation_method] if ratings_input[:calculation_method]
      updated_ratings_attrs[:calculation_int] = ratings_input[:calculation_int] if ratings_input[:calculation_int]
      updated_ratings_attrs[:rubric_criterion] = rubric_criterion if rubric_criterion.present?

      updated_ratings_attrs
    end
  end
end
