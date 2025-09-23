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
#

module JsonUtilsHelper
  def safe_parse_json_array(response)
    return [] if response.blank?

    begin
      parsed = JSON.parse(response)
      return parsed.is_a?(Array) ? parsed : []
    rescue JSON::ParserError
      if response.include?("[") && response.include?("]")
        json_like = response[response.index("["), response.rindex("]") - response.index("[") + 1]
        repaired = escape_inner_quotes(json_like)

        begin
          parsed = JSON.parse(repaired)
          return parsed.is_a?(Array) ? parsed : []
        rescue JSON::ParserError
          raise CedarAi::Errors::GraderError, "Invalid JSON response: could not extract valid JSON array"
        end
      end
    end

    raise CedarAi::Errors::GraderError, "Invalid JSON response: could not extract valid JSON array"
  end

  def escape_inner_quotes(json_str)
    result = json_str.dup
    key_start_regex = /"([^"\\]*)"\s*:\s*"/

    pos = 0
    while (m = key_start_regex.match(result, pos))
      value_start = m.end(0)
      closing_regex = /"(?=\s*(?:,|\}|\]))/
      closing_match_pos = result.index(closing_regex, value_start)

      break unless closing_match_pos

      raw_value = result[value_start...closing_match_pos]
      fixed_value = raw_value.gsub(/(?<!\\)"/, '\"')
      result[value_start...closing_match_pos] = fixed_value
      pos = closing_match_pos + (fixed_value.length - raw_value.length) + 1
    end

    result
  end

  module_function :safe_parse_json_array, :escape_inner_quotes
end
