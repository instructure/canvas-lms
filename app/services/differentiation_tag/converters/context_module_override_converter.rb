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
    class ContextModuleOverrideConverter < TagOverrideConverter
      class << self
        def convert_tags_to_adhoc_overrides(context_module, course)
          @context_module = context_module
          @course = course
          @tag_overrides = nil
          @prepared_override = nil

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
          @tag_overrides = differentiation_tag_overrides_for(@context_module)
          return unless @tag_overrides.present?

          students_to_override = find_students_to_override(@context_module, @tag_overrides)
          return unless students_to_override.present?

          # Since there are no dates for context modules, there is only one override to create
          @prepared_override = { student_ids: students_to_override }
        end

        def convert_overrides
          ActiveRecord::Base.transaction do
            if @prepared_override
              errors = AdhocOverrideCreatorService.create_adhoc_override(@course, @context_module, @prepared_override)
              if errors.present?
                raise(DifferentiationTagServiceError, errors)
              end
            end

            destroy_differentiation_tag_overrides(@tag_overrides)
          end
        end

        def find_students_to_override(context_module, tag_overrides)
          tags = tag_overrides.map(&:set)
          students_in_tags = find_students_in_tags(tags)
          students_already_overridden = students_already_overridden(context_module)

          (students_in_tags - students_already_overridden).to_a
        end
      end
    end
  end
end
