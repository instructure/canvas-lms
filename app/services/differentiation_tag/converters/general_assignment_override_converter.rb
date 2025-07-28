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

module DifferentiationTag
  module Converters
    class GeneralAssignmentOverrideConverter < TagOverrideConverter
      class << self
        def convert_tags_to_adhoc_overrides(learning_object, course)
          @learning_object = learning_object
          @course = course
          @tag_overrides = nil
          @differentiation_tags = nil
          @prepared_overrides = nil

          begin
            prepare_overrides
            convert_overrides
          rescue DifferentiationTagServiceError => e
            return e.message
          end

          # no errors
          nil
        end

        private

        def prepare_overrides
          @tag_overrides = differentiation_tag_overrides_for(@learning_object)
          return unless @tag_overrides.present?

          @prepared_overrides = build_overrides(@learning_object, @tag_overrides)
        end

        def convert_overrides
          ActiveRecord::Base.transaction do
            @prepared_overrides&.each do |override_data|
              errors = AdhocOverrideCreatorService.create_adhoc_override(@course, @learning_object, override_data)
              if errors.present?
                raise(DifferentiationTagServiceError, errors)
              end
            end

            destroy_differentiation_tag_overrides(@tag_overrides)
          end
        end

        def build_overrides(learning_object, tag_overrides)
          final_overrides = []

          # Sort diff tag overrides by due_at descending (latest date first)
          # This allows us to create the right override for each student
          # If a student is in multiple tags, we want to use the latest possible date
          sort_key = get_sort_key(learning_object)
          sorted_tag_overrides = sort_overrides(overrides: tag_overrides, sort_by: sort_key)

          students_overridden = students_already_overridden(learning_object)

          sorted_tag_overrides.each do |override|
            students_to_override = find_students_to_override(override, students_overridden)

            if students_to_override.present?
              final_overrides.push({ override:, student_ids: students_to_override })
            end
          end

          final_overrides
        end

        def get_sort_key(learning_object)
          if learning_object.is_a?(Assignment) || learning_object.is_a?(SubAssignment) || learning_object.is_a?(Quizzes::Quiz)
            :due_at
          else
            :lock_at
          end
        end

        def find_students_to_override(tag_override, students_overridden)
          students = find_students_in_tags([tag_override.set])
          return [] if students.empty?

          students_to_override = []
          students.each do |student_id|
            unless students_overridden.include?(student_id)
              students_overridden.add(student_id)
              students_to_override.push(student_id)
            end
          end

          students_to_override
        end
      end
    end
  end
end
