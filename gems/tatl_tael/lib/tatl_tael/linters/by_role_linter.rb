# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

require "fileutils"
require "tempfile"
require "time"

module TatlTael
  module Linters
    class ByRoleLinter < BaseLinter
      def run
        changes_with_by_role(precondition_changes).map do |path, line_number|
          comment_for(path, line_number)
        end
      end

      def comment_for(path, position)
        {
          path:,
          message: config[:message],
          severity: config[:severity],
          position:,
          ignore_boyscout_severity_change: true
        }
      end

      def changes_with_by_role(paths)
        changes = []
        paths.each do |path|
          line_numbers = diff&.dig(path, :change)
          next unless line_numbers

          File.open(path, "r") do |file|
            file.each_line do |line|
              if line_numbers.include?(file.lineno) && line.match(config[:regexes][:by_role])
                changes.push([path, file.lineno])
              end
            end
          end
        end
        changes
      end

      def precondition_changes
        changes_matching(**config[:precondition]).map(&:path)
      end
    end
  end
end
