# Copyright (C) 2017 - present Instructure, Inc.
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

module TatlTael
  module Linters
    class CopyrightLinter < BaseLinter
      def run
        paths_missing_copyright.map { |path| comment_for(path) }
      end

      def comment_for(path)
        {
          path: path,
          message: config[:message],
          severity: config[:severity],
          position: 0
        }
      end

      def paths_missing_copyright
        precondition_changes
          .select { |change| missing_copyright?(change.path_from_root) }
          .map(&:path)
      end

      def precondition_changes
        changes_matching(config[:precondition])
      end

      def missing_copyright?(path)
        !copyright?(path)
      end

      def copyright?(path)
        lines = potential_copyright_lines(path)

        return false unless lines

        if first_line_exception?(lines.first)
          # TODO: in autocorrect, save this line
          lines.shift
        end

        valid_copyright_lines?(lines)
      end

      # first line could be an exception (e.g. "#!/usr/bin/env ruby")
      # second line could be block comment start (e.g. "/*")
      # then two extra lines in case the line breaks are different
      COPYRIGHT_LINES_BUFFER = 4
      def potential_copyright_lines(path_from_root)
        return unless File.exist?(path_from_root)

        lines = File.foreach(path_from_root)
          .first(copyright_line_count + COPYRIGHT_LINES_BUFFER)

        index_of_copyright_end = lines.index { |line| line.include?(config[:copyright_ending_token]) }
        return unless index_of_copyright_end

        # +1 to include the ending line
        lines.take(index_of_copyright_end + 1)
      end

      def first_line_exception?(line)
        config[:regexes][:first_line_exceptions].any? { |regex| line =~ regex }
      end

      def valid_copyright_lines?(lines)
        file_header_title, file_header_body = title_and_body(lines)
        valid_title?(file_header_title) && valid_body?(file_header_body)
      end

      def title_and_body(lines)
        clean_lines = remove_blank_lines(strip_comments(lines))
        title = clean_lines.shift
        body = clean_lines.join.gsub(/\s+/, " ").strip
        [title, body]
      end

      def strip_comments(lines)
        lines.map { |line| line.sub(config[:regexes][:comment_prefix_regex], "") }
      end

      def remove_blank_lines(lines)
        lines.reject { |line| line =~ /^\s+$/ }
      end

      def valid_title?(title)
        title =~ copyright_title_regex
      end

      # transform the first copyright line into regex with year capture group.
      # example:
      #   input: "Copyright (C) CURRENT_YEAR - present Instructure, Inc."
      #   output: /Copyright\ \(C\)\ (\d{4})\ \-\ present\ Instructure,\ Inc\./
      def copyright_title_regex
        Regexp.new(
          copyright_title
            .split("CURRENT_YEAR")
            .map { |p| Regexp.quote(p) }
            .join("(\\d{4})") # captured for upcoming autocorrect
        )
      end

      def valid_body?(body)
        body == copyright_body
      end

      def copyright_title
        copyright.split("\n").first
      end

      def copyright_body
        copyright.split("\n")[1..-1].join("\n") # remove first line
          .gsub(/\s+/, " ").strip
      end

      def copyright_line_count
        @copyright_line_count ||= copyright.count("\n")
      end

      def copyright
        @copyright ||= config[:copyright]
      end
    end
  end
end