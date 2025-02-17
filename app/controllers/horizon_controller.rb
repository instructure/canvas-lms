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

class HorizonController < ApplicationController
  before_action :require_user
  before_action :require_context

  def validate_course
    return unless authorized_action(@context, @current_user, :manage_courses_admin)

    errors = {}

    # check assignments
    assignment_validator = HorizonValidators::AssignmentValidator.new
    validate_entites(@context.assignments, assignment_validator, errors, "assignments")

    # check groups
    group_validator = HorizonValidators::GroupValidator.new
    validate_entites(@context.groups, group_validator, errors, "groups")

    # check discussions
    discussions_validator = HorizonValidators::DiscussionsValidator.new
    validate_entites(@context.discussion_topics, discussions_validator, errors, "discussions")

    # check quizzes
    quizzes_validator = HorizonValidators::QuizzesValidator.new
    validate_entites(@context.quizzes, quizzes_validator, errors, "quizzes")

    # check collaborations
    collaborations_validator = HorizonValidators::CollaborationsValidator.new
    validate_entites(@context.collaborations, collaborations_validator, errors, "collaborations")

    # check outcomes
    outcomes_validator = HorizonValidators::OutcomesValidator.new
    validate_entites(@context.learning_outcomes, outcomes_validator, errors, "outcomes")

    render json: { errors: }
  end

  private

  def map_to_error_object(id, name, link, errors)
    { id:, name:, link:, errors: errors.group_by_attribute }
  end

  def validate_entites(entities, validator, errors, error_key)
    entities.active.each do |entity|
      validator.validate(entity)
      next if entity.errors.empty?

      name = entity.respond_to?(:title) ? entity.title : entity.name
      link = case error_key
             when "assignments"
               named_context_url(@context, :context_assignment_url, entity.id)
             when "discussions"
               named_context_url(@context, :context_discussion_topic_url, entity.id)
             when "quizzes"
               named_context_url(@context, :context_quiz_url, entity.id)
             when "groups"
               group_url(entity.id)
             when "collaborations"
               named_context_url(@context, :context_collaboration_url, entity.id)
             when "outcomes"
               named_context_url(@context, :context_outcome_url, entity.id)
             else
               nil
             end
      errors[error_key] ||= []
      errors[error_key] << map_to_error_object(entity.id, name, link, entity.errors)
    end
  end
end
