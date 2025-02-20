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
module Courses
  class HorizonService < ApplicationService
    class << self
      def validate_course_contents(context, link_transformer)
        errors = {}

        # check assignments
        assignment_validator = HorizonValidators::AssignmentValidator.new
        validate_entities(context, context.assignments, assignment_validator, errors, link_transformer, :assignments)

        # check groups
        group_validator = HorizonValidators::GroupValidator.new
        validate_entities(context, context.groups, group_validator, errors, link_transformer, :groups)

        # check discussions
        discussions_validator = HorizonValidators::DiscussionsValidator.new
        validate_entities(context, context.discussion_topics, discussions_validator, errors, link_transformer, :discussions)

        # check quizzes
        quizzes_validator = HorizonValidators::QuizzesValidator.new
        validate_entities(context, context.quizzes, quizzes_validator, errors, link_transformer, :quizzes)

        # check collaborations
        collaborations_validator = HorizonValidators::CollaborationsValidator.new
        validate_entities(context, context.collaborations, collaborations_validator, errors, link_transformer, :collaborations)

        # check outcomes
        outcomes_validator = HorizonValidators::OutcomesValidator.new
        validate_entities(context, context.learning_outcomes, outcomes_validator, errors, link_transformer, :outcomes)

        errors
      end

      def convert_course_to_horizon(progress = nil, context:, errors:)
        error_size = errors.size
        progress&.calculate_completion!(0, error_size)

        # convert discussions ( = delete)
        errors[:discussions]&.each do |error|
          dt = context.all_discussion_topics.active.find(error[:id])
          dt&.destroy
        end
        progress&.increment_completion!(1)

        # convert groups ( = delete)
        errors[:groups]&.each do |error|
          group = context.groups.find(error[:id])
          group&.destroy
        end
        progress&.increment_completion!(1)

        errors[:assignments]&.each do |error|
          has_rubrics = error[:errors][:rubric].present?
          has_incompatible_submission_types = error[:errors][:submission_types].present?
          assignment = context.assignments.find(error[:id])
          assignment&.update!(
            peer_reviews: false,
            peer_review_count: 0,
            automatic_peer_reviews: false,
            group_category_id: nil
          )
          if has_rubrics
            assignment&.rubric_association&.destroy
          end
          if has_incompatible_submission_types
            assignment&.update!(submission_types: "online_text_entry")
          end
          assignment&.save!
        end
        progress&.increment_completion!(1)

        if validate_course_contents(context, ->(_x, _y, _z) { "" }).empty?
          context.update!(horizon_course: true)
        end
      end

      private

      def map_to_error_object(id, name, link, errors)
        { id:, name:, link:, errors: errors.group_by_attribute }
      end

      def validate_entities(context, entities, validator, errors, link_transformer, error_key)
        entities.active.each do |entity|
          validator.validate(entity)
          next if entity.errors.empty?

          name = entity.respond_to?(:title) ? entity.title : entity.name
          link = case error_key
                 when :assignments
                   link_transformer.call(context, :context_assignment_url, entity.id)
                 when :discussions
                   link_transformer.call(context, :context_discussion_topic_url, entity.id)
                 when :quizzes
                   link_transformer.call(context, :context_quiz_url, entity.id)
                 when :groups
                   link_transformer.call(context, :context_groups_url)
                 when :collaborations
                   link_transformer.call(context, :context_collaboration_url, entity.id)
                 when :outcomes
                   link_transformer.call(context, :context_outcome_url, entity.id)
                 else
                   nil
                 end
          errors[error_key] ||= []
          errors[error_key] << map_to_error_object(entity.id, name, link, entity.errors)
        end
      end
    end
  end
end
