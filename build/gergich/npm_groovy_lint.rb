# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class Gergich::NpmGroovyLint
  # npm-groovy-lint outputs in the following format:
  #
  # [4m/usr/src/app/Jenkinsfile[24m
  #   58    [90minfo   [39m  There is whitespace between the method name and parenthesis in a method call: lock  SpaceAfterMethodCallName
  #   589   [90minfo   [39m  The expression using || is compared to a constant  UnnecessaryBooleanExpression
  #
  # Where [4m is ANSI underline, [24m is end underline, [90m is gray, [39m is reset
  def run(output)
    # Strip ANSI color codes
    output = output.gsub(/\e\[\d+m/, "")

    comments = []
    current_file = nil

    output.each_line do |line|
      line = line.strip

      # Check if this is a file path line (starts with /)
      if line.start_with?("/")
        current_file = line
      # Check if this is a linter message line (starts with line number)
      elsif current_file && line =~ /^\s*(\d+)\s+(info|warning|error)\s+(.+?)\s{2,}(\S+)\s*$/
        line_number = $1.to_i
        severity = $2
        message = $3.strip
        rule = $4

        # Only capture warnings and errors, skip info messages
        next if severity == "info"

        # Truncate message if too long (Gerrit has a 16KB limit for comments)
        max_message_length = 500
        full_message = "[#{rule}] #{message}"
        if full_message.length > max_message_length
          full_message = "#{full_message[0...max_message_length]}... (message truncated)"
        end

        comments << {
          path: current_file,
          position: line_number,
          message: full_message,
          severity: "error"
        }
      end
    end

    comments
  end
end
