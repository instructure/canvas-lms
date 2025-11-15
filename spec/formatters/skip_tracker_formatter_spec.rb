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

require "spec_helper"
require_relative "skip_tracker_formatter"
require "json"
require "tempfile"

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe RSpec::SkipTrackerFormatter do
  let(:output) { StringIO.new }
  let(:formatter) { described_class.new(output) }

  # Helper to create a mock example
  def create_example(description:, location:, pending_message:, metadata: {})
    execution_result = double(
      "ExecutionResult",
      status: :pending,
      pending_message:,
      pending_fixed: false
    )

    default_metadata = {
      file_path: location.split(":").first,
      line_number: location.split(":").last.to_i,
      description_args: [description],
      block: nil,
      described_class: nil,
      example_group: {
        description: "ExampleGroup",
        file_path: location.split(":").first,
        line_number: 1
      }
    }

    double(
      "Example",
      full_description: description,
      location:,
      execution_result:,
      metadata: default_metadata.merge(metadata)
    )
  end

  # Helper to create a notification
  def create_notification(example)
    double("Notification", example:)
  end

  # Helper to create summary notification
  def create_summary_notification(example_count: 10, failed_examples: [])
    double(
      "SummaryNotification",
      example_count:,
      failed_examples:
    )
  end

  describe "#example_pending" do
    context "unconditional skips" do
      it "tracks simple skip in test body" do
        example = create_example(
          description: "Test foo",
          location: "./spec/models/foo_spec.rb:42",
          pending_message: "Not implemented yet CNVS-12345 2025-01-15"
        )

        formatter.example_pending(create_notification(example))

        expect(formatter.instance_variable_get(:@pending_examples).length).to eq(1)
        skip_info = formatter.instance_variable_get(:@pending_examples).first
        expect(skip_info[:description]).to eq("Test foo")
        expect(skip_info[:location]).to eq("./spec/models/foo_spec.rb:42")
        expect(skip_info[:jira_number]).to eq("CNVS-12345")
        expect(skip_info[:skip_date]).to eq("2025-01-15")
      end

      it "tracks context-level skip" do
        example = create_example(
          description: "Test bar",
          location: "./spec/models/bar_spec.rb:10",
          pending_message: "Feature not ready"
        )

        formatter.example_pending(create_notification(example))

        expect(formatter.instance_variable_get(:@pending_examples).length).to eq(1)
      end
    end

    context "conditional skips" do
      it "tracks unconditional skip even when 'skip' is in test name" do
        temp_file = Tempfile.new(["skip_in_name", ".rb"])
        temp_file.write(<<~RUBY)
          RSpec.describe "Test" do
            it "test skip behavior" do
              skip "Not ready yet"
              expect(true).to be true
            end
          end
        RUBY
        temp_file.close

        example = create_example(
          description: "test skip behavior",
          location: "#{temp_file.path}:2",
          pending_message: "Not ready yet",
          metadata: {
            file_path: temp_file.path,
            line_number: 2
          }
        )

        formatter.example_pending(create_notification(example))

        expect(formatter.instance_variable_get(:@pending_examples).length).to eq(1)

        temp_file.unlink
      end

      it "does not track conditional skip with unless" do
        temp_file = Tempfile.new(["conditional_unless", ".rb"])
        temp_file.write(<<~RUBY)
          RSpec.describe "Test" do
            context "group" do
              it "should work" do
                skip "reason" unless ENV["CI"]
                expect(true).to be true
              end
            end
          end
        RUBY
        temp_file.close

        example = create_example(
          description: "should work",
          location: "#{temp_file.path}:3",
          pending_message: "reason",
          metadata: {
            file_path: temp_file.path,
            line_number: 3 # Line where 'it' block starts
          }
        )

        formatter.example_pending(create_notification(example))

        expect(formatter.instance_variable_get(:@pending_examples).length).to eq(0)

        temp_file.unlink
      end

      it "does not track conditional skip with if" do
        temp_file = Tempfile.new(["conditional_if", ".rb"])
        temp_file.write(<<~RUBY)
          RSpec.describe "Test" do
            it "test" do
              skip "reason" if some_condition
            end
          end
        RUBY
        temp_file.close

        example = create_example(
          description: "test",
          location: "#{temp_file.path}:2",
          pending_message: "reason",
          metadata: {
            file_path: temp_file.path,
            line_number: 2
          }
        )

        formatter.example_pending(create_notification(example))

        expect(formatter.instance_variable_get(:@pending_examples).length).to eq(0)

        temp_file.unlink
      end

      it "does not track conditional skip in before block" do
        temp_file = Tempfile.new(["before_skip", ".rb"])
        temp_file.write(<<~RUBY)
          RSpec.describe "Test" do
            context "group" do
              before do
                skip "needs setup" unless ENV["SETUP"]
              end

              it "test" do
                expect(true).to be true
              end
            end
          end
        RUBY
        temp_file.close

        example = create_example(
          description: "test",
          location: "#{temp_file.path}:7",
          pending_message: "needs setup",
          metadata: {
            file_path: temp_file.path,
            line_number: 7,
            example_group: {
              description: "group",
              file_path: temp_file.path,
              line_number: 2,
              parent_example_group: nil
            }
          }
        )

        formatter.example_pending(create_notification(example))

        expect(formatter.instance_variable_get(:@pending_examples).length).to eq(0)

        temp_file.unlink
      end
    end
  end

  describe "#extract_jira_number" do
    it "extracts JIRA number from message" do
      message = "Fix this test CNVS-12345 before release"
      jira = formatter.send(:extract_jira_number, message)
      expect(jira).to eq("CNVS-12345")
    end

    it "returns unknown when no JIRA found" do
      message = "No ticket here"
      jira = formatter.send(:extract_jira_number, message)
      expect(jira).to eq("unknown")
    end

    it "returns unknown for nil message" do
      jira = formatter.send(:extract_jira_number, nil)
      expect(jira).to eq("unknown")
    end
  end

  describe "#extract_skip_date" do
    it "extracts YYYY-MM-DD date from message" do
      message = "Skip until 2025-01-15 ready"
      date = formatter.send(:extract_skip_date, message)
      expect(date).to eq("2025-01-15")
    end

    it "returns unknown when no date found" do
      message = "No date here"
      date = formatter.send(:extract_skip_date, message)
      expect(date).to eq("unknown")
    end

    it "returns unknown for nil message" do
      date = formatter.send(:extract_skip_date, nil)
      expect(date).to eq("unknown")
    end

    it "extracts first date when multiple present" do
      message = "2025-01-15 or 2025-02-20"
      date = formatter.send(:extract_skip_date, message)
      expect(date).to eq("2025-01-15")
    end

    it "does not extract invalid date formats" do
      message = "Date is 01-15-2025"
      date = formatter.send(:extract_skip_date, message)
      expect(date).to eq("unknown")
    end
  end

  describe "#extract_metadata" do
    it "extracts example metadata" do
      example = create_example(
        description: "Test",
        location: "./spec/test_spec.rb:1",
        pending_message: "reason"
      )

      metadata = formatter.send(:extract_metadata, example)

      expect(metadata).to have_key(:description_args)
      expect(metadata).to have_key(:block)
      expect(metadata).to have_key(:described_class)
      expect(metadata).to have_key(:example_group)
      expect(metadata[:example_group]).to have_key(:description)
      expect(metadata[:example_group]).to have_key(:file_path)
      expect(metadata[:example_group]).to have_key(:line_number)
    end
  end

  describe "output handling" do
    context "file output via ENV var" do
      let(:temp_output_file) { Tempfile.new(["skip_report", ".json"]) }

      after do
        temp_output_file.unlink
      end

      it "writes to file when RSPEC_SKIP_TRACKER_OUTPUT is set" do
        ENV["RSPEC_SKIP_TRACKER_OUTPUT"] = temp_output_file.path

        formatter_with_file = described_class.new(StringIO.new)
        example = create_example(
          description: "Test",
          location: "./spec/test_spec.rb:1",
          pending_message: "reason"
        )

        formatter_with_file.example_pending(create_notification(example))
        formatter_with_file.dump_summary(create_summary_notification)
        formatter_with_file.close(nil)

        expect(File.exist?(temp_output_file.path)).to be true
        result = JSON.parse(File.read(temp_output_file.path), symbolize_names: true)
        expect(result[:pending].length).to eq(1)

        ENV.delete("RSPEC_SKIP_TRACKER_OUTPUT")
      end

      it "merges with existing file data" do
        # Write initial data
        initial_data = {
          summary: { total_pending: 1, generated_at: Time.now.iso8601 },
          pending: [{
            description: "Existing test",
            location: "./spec/old_spec.rb:1",
            jira_number: "CNVS-111",
            skip_date: "2025-01-01"
          }]
        }
        File.write(temp_output_file.path, JSON.pretty_generate(initial_data))

        ENV["RSPEC_SKIP_TRACKER_OUTPUT"] = temp_output_file.path

        formatter_with_file = described_class.new(StringIO.new)
        example = create_example(
          description: "New test",
          location: "./spec/new_spec.rb:1",
          pending_message: "reason"
        )

        formatter_with_file.example_pending(create_notification(example))
        formatter_with_file.dump_summary(create_summary_notification)
        formatter_with_file.close(nil)

        result = JSON.parse(File.read(temp_output_file.path), symbolize_names: true)
        expect(result[:pending].length).to eq(2)
        expect(result[:pending].pluck(:description)).to include("Existing test", "New test")

        ENV.delete("RSPEC_SKIP_TRACKER_OUTPUT")
      end
    end

    context "corrupted file handling" do
      let(:temp_output_file) { Tempfile.new(["corrupted", ".json"]) }

      after do
        temp_output_file.unlink
      end

      it "handles corrupted JSON gracefully" do
        File.write(temp_output_file.path, "{ invalid json }")

        ENV["RSPEC_SKIP_TRACKER_OUTPUT"] = temp_output_file.path

        expect do
          formatter_with_file = described_class.new(StringIO.new)
          example = create_example(
            description: "Test",
            location: "./spec/test_spec.rb:1",
            pending_message: "reason"
          )

          formatter_with_file.example_pending(create_notification(example))
          formatter_with_file.dump_summary(create_summary_notification)
          formatter_with_file.close(nil)
        end.not_to raise_error

        result = JSON.parse(File.read(temp_output_file.path), symbolize_names: true)
        expect(result[:pending].length).to eq(1)

        ENV.delete("RSPEC_SKIP_TRACKER_OUTPUT")
      end

      it "handles empty file gracefully" do
        File.write(temp_output_file.path, "")

        ENV["RSPEC_SKIP_TRACKER_OUTPUT"] = temp_output_file.path

        formatter_with_file = described_class.new(StringIO.new)
        example = create_example(
          description: "Test",
          location: "./spec/test_spec.rb:1",
          pending_message: "reason"
        )

        formatter_with_file.example_pending(create_notification(example))
        formatter_with_file.dump_summary(create_summary_notification)
        formatter_with_file.close(nil)

        result = JSON.parse(File.read(temp_output_file.path), symbolize_names: true)
        expect(result[:pending].length).to eq(1)

        ENV.delete("RSPEC_SKIP_TRACKER_OUTPUT")
      end
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
