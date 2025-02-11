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

    render json: { errors: }
  end

  private

  def map_to_error_object(id, name, errors)
    { id:, name:, errors: errors.group_by_attribute }
  end

  def validate_entites(entities, validator, errors, error_key)
    entities.each do |entity|
      validator.validate(entity)
      next if entity.errors.empty?

      name = entity.respond_to?(:title) ? entity.title : entity.name
      errors[error_key] ||= []
      errors[error_key] << map_to_error_object(entity.id, name, entity.errors)
    end
  end
end
