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
      def validate_course_contents(course, link_transformer = nil)
        errors = {}

        # check assignments
        assignment_validator = HorizonValidators::AssignmentValidator.new
        validate_entities(course, course.assignments, assignment_validator, errors, link_transformer, :assignments)

        # check groups
        group_validator = HorizonValidators::GroupValidator.new
        validate_entities(course, course.groups, group_validator, errors, link_transformer, :groups)

        # check discussions
        discussions_validator = HorizonValidators::DiscussionsValidator.new
        validate_entities(course, course.discussion_topics, discussions_validator, errors, link_transformer, :discussions)

        # check quizzes
        quizzes_validator = HorizonValidators::QuizzesValidator.new
        validate_entities(course, course.quizzes, quizzes_validator, errors, link_transformer, :quizzes)

        # check collaborations
        collaborations_validator = HorizonValidators::CollaborationsValidator.new
        validate_entities(course, course.collaborations, collaborations_validator, errors, link_transformer, :collaborations)

        # check outcomes
        outcomes_validator = HorizonValidators::OutcomesValidator.new
        validate_entities(course, course.learning_outcomes, outcomes_validator, errors, link_transformer, :outcomes)

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

        # convert assignments
        errors[:assignments]&.each do |error|
          has_rubrics = error[:errors][:rubric].present?
          has_incompatible_submission_types = error[:errors][:submission_types].present?
          is_published = error[:errors][:workflow_state].present?
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
          if is_published
            assignment&.unpublish
          end
          assignment&.save!
        end
        progress&.increment_completion!(1)

        post_errors = validate_course_contents(context)

        if post_errors.empty? || post_errors.except(:collaborations, :outcomes).empty?
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
          link_mapping = {
            assignments: :context_assignment_url,
            discussions: :context_discussion_topic_url,
            quizzes: :context_quiz_url,
            groups: :context_groups_url,
            collaborations: :context_collaboration_url,
            outcomes: :context_outcome_url
          }
          link = link_transformer&.call(context, link_mapping[error_key], entity.id)
          errors[error_key] ||= []
          errors[error_key] << map_to_error_object(entity.id, name, link, entity.errors)
        end
      end
    end
  end
end
