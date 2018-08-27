#
# Copyright (C) 2018 - present Instructure, Inc.
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

module CanvasAPI
  module Deprecatable
    def deprecated?
      !!@deprecated
    end

    private

    def parse_deprecation_info(line)
      validate_line(line)
      dates = extract_deprecation_dates(line)
      validate_deprecation_dates(dates)
      @effective_date = dates[:EFFECTIVE]
      @notice_date = dates[:NOTICE]
    end

    def line_without_deprecation_tags(line)
      line.gsub(/NOTICE \S+\s?|\s?EFFECTIVE \S+\s?/, '')
    end

    def extract_deprecation_dates(line)
      args = line.split(/\s/)
      deprecation_keys = [@deprecated_date_key, @effective_date_key]
      dates = {}
      args.each_with_index do |arg, index|
        key = arg.to_sym
        next unless deprecation_keys.include?(key)
        dates[key] = args[index + 1]
      end
      dates
    end

    def validate_deprecation_dates(provided_dates)
      date_keys = [@deprecated_date_key, @effective_date_key]
      date_keys.each { |key| validate_date(key, provided_dates) }
      validate_date_range(provided_dates)
    end

    def reference_line
      return @tag_declaration_line if @tag_declaration_line.blank?

      "\n  #{@tag_declaration_line}"
    end

    def validate_deprecation_description
      if @description.blank?
        raise(
          ArgumentError,
          "Expected a description for #{@description_key.present? ? "`#{@description_key}`": 'the deprecation'}" \
          ", but it was not provided.#{reference_line}"
        )
      end
    end

    def validate_line(text)
      line_count = (text || '').split("\n", 2).length
      if line_count < 2
        raise(
          ArgumentError,
          "Expected two lines: a tag declaration line with deprecation arguments, " \
          "and a description line, but found #{line_count} #{'line'.pluralize(line_count)}.#{reference_line}"
        )
      end
    end

    def validate_date(key, provided_dates)
      if !provided_dates.key?(key)
        raise(ArgumentError, "Expected argument `#{key}`, but it was not provided.#{reference_line}")
      elsif provided_dates.fetch(key).blank?
        raise(
          ArgumentError,
          "Expected a value to be present for argument `#{key}`, but it was blank.#{reference_line}"
        )
      end

      date = provided_dates[key]
      begin
        Date.iso8601(date)
      rescue ArgumentError
        raise(
          ArgumentError,
          "Expected date `#{date}` for key `#{key}` to be in ISO 8601 format (YYYY-MM-DD).#{reference_line}"
        )
      end
    end

    def validate_date_range(provided_dates)
      deprecated_date = provided_dates[@deprecated_date_key]
      effective_date = provided_dates[@effective_date_key]
      days_deprecated = Date.iso8601(effective_date) - Date.iso8601(deprecated_date)
      if days_deprecated < 90
        raise(
          ArgumentError,
          "Expected >= 90 days between the `#{@deprecated_date_key}` (#{deprecated_date}) " \
          "and `#{@effective_date_key}` (#{effective_date}) dates, but the actual " \
          "difference was #{days_deprecated.to_i} days.#{reference_line}"
        )
      end
    end
  end
end
