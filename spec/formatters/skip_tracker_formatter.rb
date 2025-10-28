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

require "rspec/core/formatters/base_formatter"
require "json"
require "fileutils"
require "jira_ref_parser"

module RSpec
  # Custom formatter to track and report skipped/pending tests. Automatically
  # filters out conditional skips (skips with unless/if modifiers) and only
  # tracks intentional skips that should be fixed.
  #
  # Tracks:
  # - Full test name (description)
  # - Test location (file:line)
  # - JIRA number (extracted from skip reason, defaults to "unknown")
  # - Skip date (YYYY-MM-DD format from skip reason, defaults to "unknown")
  # - Test metadata (example group, described class, etc.)
  #
  # Usage:
  #   # Output to stdout
  #   bin/rspec -r ./spec/formatters/skip_tracker_formatter.rb \
  #     --format RSpec::SkipTrackerFormatter
  #
  #   # Override output path via environment variable (useful for parallel runs)
  #   RSPEC_SKIP_TRACKER_OUTPUT=log/skipped/report.json \
  #     bin/rspec -r ./spec/formatters/skip_tracker_formatter.rb \
  #     --format RSpec::SkipTrackerFormatter
  #
  # Output format:
  #   {
  #     "summary": {
  #       "total_pending": 2,
  #       "generated_at": "2025-01-15T12:34:56Z"
  #     },
  #     "pending": [
  #       {
  #         "description": "Test description",
  #         "location": "./spec/models/foo_spec.rb:42",
  #         "jira_number": "CNVS-12345",
  #         "skip_date": "2025-01-15",
  #         ...
  #       }
  #     ]
  #   }
  #
  class SkipTrackerFormatter < RSpec::Core::Formatters::BaseFormatter
    RSpec::Core::Formatters.register self,
                                     :example_pending,
                                     :dump_summary,
                                     :close

    def initialize(output)
      # Allow override via environment variable, otherwise use RSpec's provided output
      if ENV["RSPEC_SKIP_TRACKER_OUTPUT"]
        output_path = ENV["RSPEC_SKIP_TRACKER_OUTPUT"]
        FileUtils.mkdir_p(File.dirname(output_path))
        # Read existing data BEFORE opening file in write mode (which truncates)
        @existing_data = read_existing_data_from_file(output_path)

        # Open file in write mode - we'll merge with existing data in close()
        custom_output = File.open(output_path, "w")
        super(custom_output)
      else
        super
        @existing_data = { pending: [] }
      end
      @pending_examples = []
    end

    # Called when an example is pending or skipped
    def example_pending(notification)
      example = notification.example
      pending_message = example.execution_result.pending_message

      # Skip conditional skips
      return if conditional_skip?(example)

      skip_info = {
        description: example.full_description,
        location: example.location,
        file_path: example.metadata[:file_path],
        line_number: example.metadata[:line_number],
        execution_result: example.execution_result.status.to_s,
        reason: pending_message,
        pending_fixed: example.execution_result.pending_fixed,
        jira_number: extract_jira_number(pending_message),
        skip_date: extract_skip_date(pending_message),
        timestamp: Time.now.iso8601,
        metadata: extract_metadata(example)
      }

      @pending_examples << skip_info
    end

    # Called at the end of the test suite
    def dump_summary(notification)
      @summary_data = {
        example_count: notification.example_count,
        failed_count: notification.failed_examples.count
      }
    end

    # Called when formatter is closing
    def close(_notification)
      # Merge current run with existing data (read in initialize)
      merged_pending = @existing_data[:pending] + @pending_examples

      report = {
        summary: {
          total_pending: merged_pending.count,
          generated_at: Time.now.iso8601
        },
        pending: merged_pending
      }

      output.puts JSON.pretty_generate(report)
      output.close unless output == $stdout
    end

    private

    def read_existing_data_from_file(file_path)
      # Check if file exists and read its contents before we overwrite it
      return { pending: [] } unless File.exist?(file_path)

      begin
        existing_content = File.read(file_path)
        return { pending: [] } if existing_content.strip.empty?

        existing_json = JSON.parse(existing_content, symbolize_names: true)
        { pending: existing_json[:pending] || [] }
      rescue JSON::ParserError, Errno::ENOENT, Errno::EACCES => e
        # If file is corrupted, doesn't exist, or can't be read, return empty arrays
        warn "Warning: Could not read existing skip report from #{file_path}: #{e.message}"
        { pending: [] }
      end
    end

    def conditional_skip?(example)
      # Conditional skips have "unless" or "if" modifiers on the same line as skip
      #
      # Strategy using RSpec metadata locations:
      # 1. Search within the 'it' block (from example.location)
      # 2. Search parent example_group blocks (from metadata[:example_group])
      # 3. Walk up parent groups until we find a conditional skip or exhaust parents

      # Search within the 'it' block
      return true if conditional_skip_in_test?(example.metadata[:file_path], example.metadata[:line_number])

      # Search parent example groups
      parent_group = example.metadata[:example_group]
      while parent_group
        return true if conditional_skip_in_test_context?(parent_group[:file_path], parent_group[:line_number])

        parent_group = parent_group[:parent_example_group]
      end

      false
    rescue
      # If we can't read the file or metadata, assume it's not a conditional skip
      false
    end

    def conditional_skip_in_test?(file_path, start_line)
      # Search within an 'it' block for conditional skips
      lines = File.readlines(file_path)
      start_index = start_line - 1
      start_indent = lines[start_index][/^(\s*)/, 1].length
      max_lines = [start_index + 20, lines.length - 1].min

      # Start from line after the 'it' declaration to avoid false positives
      # from test names containing "skip" (e.g., it "test skip behavior" do)
      ((start_index + 1)..max_lines).each do |idx|
        line = lines[idx]
        line_stripped = line.strip

        # Stop if we've exited the 'it' block (same or lower indentation)
        break if line[/^(\s*)/, 1].length <= start_indent && !line_stripped.empty?

        # Check for conditional skip
        return line_stripped.match?(/\bskip\b.*\b(unless|if)\b/) if line_stripped.match?(/\bskip\b/)
      end

      false
    end

    def conditional_skip_in_test_context?(file_path, start_line)
      # Search within an example group (context/describe) for conditional skips
      # Only search from group start until the first 'it' block
      lines = File.readlines(file_path)
      start_index = start_line - 1
      max_lines = [start_index + 50, lines.length - 1].min

      (start_index..max_lines).each do |idx|
        line_stripped = lines[idx].strip

        # Stop if we hit an 'it' block (we've left the before/setup area)
        break if line_stripped.match?(/^\s*it\s+["']/)

        # Check for conditional skip
        return true if line_stripped.match?(/\bskip\b.*\b(unless|if)\b/)
      end

      false
    end

    def extract_jira_number(message)
      return "unknown" unless message

      # Use jira_ref_parser gem to match JIRA issue IDs
      match = message.match(/#{JiraRefParser::IssueIdRegex}/o)
      match ? match[0] : "unknown"
    end

    def extract_skip_date(message)
      return "unknown" unless message

      # Only match YYYY-MM-DD format
      match = message.match(/\b(\d{4}-\d{2}-\d{2})\b/)
      match ? match[1] : "unknown"
    end

    def extract_metadata(example)
      metadata = example.metadata
      {
        description_args: metadata[:description_args],
        block: metadata[:block]&.source_location&.join(":"),
        described_class: metadata[:described_class]&.to_s,
        example_group: {
          description: metadata[:example_group][:description],
          file_path: metadata[:example_group][:file_path],
          line_number: metadata[:example_group][:line_number]
        }
      }
    end
  end
end
