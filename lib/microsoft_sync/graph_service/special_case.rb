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

# Used to describe special cases in Microsoft HTTP responses.
module MicrosoftSync
  class GraphService
    class SpecialCase
      attr_reader :status_code, :body_regex, :result

      def initialize(status_code, body_regex = nil, result:)
        @status_code = status_code
        @body_regex = body_regex
        @result = result
      end

      def test(code, body)
        if code == status_code && (body_regex.nil? || body =~ body_regex)
          result.is_a?(Class) ? result.new : result
        end
      end

      def self.match(special_cases, code, body)
        special_cases.reduce(nil) do |result, sc|
          result || sc.test(code, body)
        end
      end
    end
  end
end
