# frozen_string_literal: true

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

require "fileutils"
require "tempfile"
require "time"

module TatlTael
  module Linters
    class CopyrightLinter < BaseLinter
      def run
        bad_paths = paths_missing_copyright

        if auto_correct
          bad_paths.each do |path|
            perform_auto_correct(path)
          end
        end

        bad_paths.map { |path| comment_for(path) }
      end

      def comment_for(path)
        {
          path:,
          message: auto_correct ? config[:auto_correct][:message] : config[:message],
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
        changes_matching(**config[:precondition])
      end

      def missing_copyright?(path)
        !copyright?(path)
      end

      def copyright?(path)
        lines = potential_copyright_lines(path)

        return false unless lines

        while first_line_exception?(lines.first)
          lines.shift
        end

        valid_copyright_lines?(lines)
      end

      # first line could be an exception (e.g. "#!/usr/bin/env ruby")
      # second line could be block comment start (e.g. "/*")
      # then two extra lines in case the line breaks are different
      COPYRIGHT_LINES_BUFFER = 4
      def potential_copyright_lines(path_from_root)
        lines = head(path_from_root, copyright_line_count + COPYRIGHT_LINES_BUFFER)
        return unless lines

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
        lines.grep_v(/^\s+$/)
      end

      def valid_title?(title)
        title =~ copyright_title_regex
      end

      # example:
      #   input: "Copyright (C) CURRENT_YEAR - present Instructure, Inc."
      #   output: /Copyright\ \(C\)\ (\d{4})\ \-\ present\ Instructure,\ Inc\./
      def copyright_title_regex
        Regexp.new(
          copyright_title
            .split(config[:copyright_year_placeholder])
            .map { |p| Regexp.quote(p) }
            .join("\\d{4}")
        )
      end

      def valid_body?(body)
        body == copyright_body
      end

      def copyright_title
        copyright.split("\n").first
      end

      def copyright_body
        copyright.split("\n")[1..].join("\n") # remove first line
                 .gsub(/\s+/, " ").strip
      end

      def copyright_line_count
        @copyright_line_count ||= copyright.count("\n")
      end

      def copyright
        @copyright ||= config[:copyright]
      end

      # auto correct logic
      def perform_auto_correct(original_path)
        saved_line = saved_first_line(original_path)
        ext = original_path.split(".").last
        text = copyright_for_ext(ext)
        temp_file = Tempfile.open("tatl_tael--copyright-linter")
        begin
          # add saved line if found (e.g. "# encoding: UTF-8")
          temp_file.write(saved_line) if saved_line
          # prepend copyright text
          temp_file.puts text
          # append old file contents, potentially skipping old header
          write_old_to_temp(temp_file, original_path, ext)
          FileUtils.mv(temp_file.path, original_path)
        ensure
          temp_file.close
          temp_file.unlink
        end

        copyright_lines_found = 0
        File.readlines(original_path).each do |line|
          copyright_lines_found += 1 if line.include?(config[:auto_correct][:raise_if_two_lines_with])
          if copyright_lines_found > 1
            raise "FOUND TWO COPYRIGHT LINES in #{original_path}"
          end
        end
      end

      ENDING_BLOCK_COMMENT_REGEX = %r{^(\s+)?(\*+/)(\s+)?$}
      def ending_block_comment_only?(line, _ext)
        line =~ ENDING_BLOCK_COMMENT_REGEX
      end

      # skips old copyright header if detected
      def write_old_to_temp(temp_file, original_path, ext)
        done_skipping = !existing_copyright_header?(original_path)
        first_line_about_to_write = true
        File.readlines(original_path).each do |line|
          unless done_skipping
            done_skipping = line.include?(config[:copyright_ending_token])
            next
          end

          if first_line_about_to_write
            if first_line_exception?(line) || # e.g. "# encoding: UTF-8"
               ending_block_comment_only?(line, ext) # e.g. "*/"
              next
            elsif !blank_or_comment_symbol_only?(line, ext)
              temp_file.write "\n"
            end
          end

          first_line_about_to_write = false
          temp_file.write(line)
        end
      end

      def copyright_for_ext(ext)
        comment_symbols = config[:comment_symbols][ext.to_sym]
        line_comment = comment_symbols[:line]
        end_comment = comment_symbols[:block_end]
        start_comment = comment_symbols[:block_start]

        copy = copyright.gsub(config[:copyright_year_placeholder], Time.now.year.to_s)
                        .split("\n")
                        .map { |line| "#{line_comment} #{line}".rstrip }

        copy.unshift(start_comment) if start_comment
        copy.push(end_comment) if end_comment

        copy.join("\n")
      end

      def blank_or_comment_symbol_only?(line, ext)
        comment_symbols = config[:comment_symbols][ext.to_sym]
        line =~ if comment_symbols[:block]
                  /^\s*?$/
                else
                  /^#{comment_symbols[:line]}?\s*?$/
                end
      end

      def existing_copyright_header?(path_from_root)
        lines = head(path_from_root, copyright_line_count + COPYRIGHT_LINES_BUFFER)
        return false unless lines

        lines.any? { |line| line.include?(config[:copyright_ending_token]) }
      end

      def saved_first_line(path)
        first_line = head(path, 1).first
        first_line if first_line && first_line_exception?(first_line)
      end

      def head(path, line_count)
        return unless File.exist?(path)

        File.foreach(path).first(line_count)
      end
    end
  end
end
