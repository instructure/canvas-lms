# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module AcademicBenchmarks
  module Standards
    class Standard
      delegate :description, to: :statement

      def resolve_number
        @resolve_number ||= (number&.enhanced || number&.raw)
      end

      def build_outcomes(ratings={}, parent=nil)
        hash = {
          migration_id: guid,
          vendor_guid: guid,
          low_grade: low_grade,
          high_grade: high_grade,
          is_global_standard: true,
          description: description
        }
        if has_children?
          # create outcome group
          hash[:type] = 'learning_outcome_group'
          hash[:title] = build_title
          hash[:outcomes] = children.map {|c| c.build_outcomes(ratings)}
        else
          # create outcome
          hash[:type] = 'learning_outcome'
          hash[:title] = build_num_title
          set_default_ratings(hash, ratings)
        end
        hash
      end

      # standards don't have titles so they are built from parent standards/groups
      # it is generated like this:
      # if I have a number, use it and all parent nums on standards
      # if I don't have a number, use my description (potentially truncated at 50)
      def build_num_title
        if parent.is_a?(Standard) && parent.resolve_number.present?
          base = parent.build_num_title
          if base && resolve_number
            resolve_number.include?(base) ? resolve_number : [base, resolve_number].join(".")
          else
            base || resolve_number
          end
        elsif resolve_number.present?
          resolve_number
        else
          cropped_description
        end
      end

      def build_title
        if resolve_number
          [build_num_title, cropped_description].join(" - ")
        else
          cropped_description
        end
      end

      def cropped_description
        Standard.crop(description)
      end

      def set_default_ratings(hash, overrides={})
        hash[:ratings] = [{:description => "Exceeds Expectations", :points => 5},
                          {:description => "Meets Expectations", :points => 3},
                          {:description => "Does Not Meet Expectations", :points => 0}]
        hash[:mastery_points] = 3
        hash[:points_possible] = 5
        hash.merge!(overrides)
      end

      def low_grade
        education_levels&.grades&.first&.code
      end

      def high_grade
        education_levels&.grades&.last&.code
      end

      def self.crop(text)
        # get the first 50 chars of description in a utf-8 friendly way
        d = text
        d && d[/.{0,50}/u]
      end

      private

      def group_hash(itm)
        {
          type: 'learning_outcome_group',
          title: Standard.crop(itm.try(:description) || itm.try(:title)),
          migration_id: itm.guid,
          vendor_guid: itm.guid,
          is_global_standard: true,
          outcomes: []
        }
      end
    end
  end
end
