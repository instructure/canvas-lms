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

require "spec_helper"
require_relative "../../app/services/auto_grade_orchestration_service"

RSpec.describe GradeService do
  # Test data setup
  let(:assignment_text) { "Write an essay about your summer vacation" }
  let(:essay) { "I went to the beach and had a great time..." }
  let(:root_account_uuid) { "mock-root-uuid" }

  # Sample rubric data with two criteria: Content and Grammar
  let(:rubric_data) do
    [
      {
        id: "criteria_1",
        description: "Content",
        ratings: [
          { id: "rating_1", long_description: "Meets requirements", points: 3 }
        ],
        points: 4
      },
      {
        id: "criteria_2",
        description: "Grammar",
        ratings: [
          { id: "rating_2", long_description: "Excellent grammar", points: 4 }
        ],
        points: 4
      }
    ]
  end

  # Mock response from Cedar AI that includes all criteria
  let(:mock_cedar_response) do
    [
      {
        "rubric_category" => "Content",
        "reasoning" => "Well developed ideas",
        "criterion" => "Meets requirements"
      },
      {
        "rubric_category" => "Grammar",
        "reasoning" => "Flawless grammar",
        "criterion" => "Excellent grammar"
      }
    ]
  end

  # Setup CedarClient mock for all tests
  before do
    allow(Rails.env).to receive(:test?).and_return(true)

    stub_const("CedarClient", Class.new do
      def self.prompt(*)
        [
          {
            "rubric_category" => "Content",
            "reasoning" => "Well developed ideas",
            "criterion" => "Meets requirements"
          },
          {
            "rubric_category" => "Grammar",
            "reasoning" => "Flawless grammar",
            "criterion" => "Excellent grammar"
          }
        ].to_json
      end
    end)
  end

  describe "#call" do
    let(:rubric) { rubric_data }
    let(:assignment) { assignment_text }

    # Test the happy path - Cedar returns valid data for all criteria
    it "calls CedarClient and returns enriched response" do
      expect(CedarClient).to receive(:prompt).with(
        prompt: kind_of(String),
        model: "anthropic.claude-3-haiku-20240307-v1:0",
        feature_slug: "grading-assistance",
        root_account_uuid: "mock-root"
      ).and_return(mock_cedar_response.to_json)

      result = described_class.new(
        assignment:,
        essay:,
        rubric:,
        root_account_uuid: "mock-root"
      ).call

      expect(result).to eq(
        [
          {
            "id" => "criteria_1",
            "description" => "Content",
            "rating" => {
              "id" => "rating_1",
              "description" => "Meets requirements",
              "rating" => 3,
              "reasoning" => "Well developed ideas"
            }
          },
          {
            "id" => "criteria_2",
            "description" => "Grammar",
            "rating" => {
              "id" => "rating_2",
              "description" => "Excellent grammar",
              "rating" => 4,
              "reasoning" => "Flawless grammar"
            }
          }
        ]
      )
    end

    # Test error handling for malformed JSON responses
    it "raises an error when CedarClient returns malformed JSON" do
      allow(CedarClient).to receive(:prompt).and_return("not-valid-json")

      expect do
        described_class.new(
          assignment:,
          essay:,
          rubric:,
          root_account_uuid:
        ).call
      end.to raise_error(CedarAIGraderError, /Invalid JSON response/)
    end

    # Test handling of partial responses from Cedar
    context "when Cedar returns partial criteria" do
      before do
        allow(CedarClient).to receive(:prompt).and_return(
          [
            {
              "rubric_category" => "Content",
              "reasoning" => "Well developed ideas",
              "criterion" => "Meets requirements"
            }
            # Grammar is missing from response, but this is a valid partial response
          ].to_json
        )
      end

      it "returns only the criteria that were graded, without error" do
        result = described_class.new(
          assignment:,
          essay:,
          rubric:,
          root_account_uuid: "mock-root"
        ).call

        expect(result.length).to eq(1)
        expect(result.first["description"]).to eq("Content")
      end
    end

    # Test handling of invalid criteria in Cedar's response
    context "when Cedar returns invalid criteria" do
      before do
        allow(CedarClient).to receive(:prompt).and_return(
          [
            {
              "rubric_category" => "Invalid Category", # This category doesn't exist in our rubric
              "reasoning" => "Some reasoning",
              "criterion" => "Invalid Criterion"
            },
            {
              "rubric_category" => "Content", # This is valid
              "reasoning" => "Well developed ideas",
              "criterion" => "Meets requirements"
            }
          ].to_json
        )
      end

      it "filters out invalid criteria and returns only valid ones" do
        result = described_class.new(
          assignment:,
          essay:,
          rubric:,
          root_account_uuid: "mock-root"
        ).call

        expect(result.length).to eq(1)
        expect(result.first["description"]).to eq("Content")
      end
    end
  end

  describe "#map_criteria_ids_to_grades" do
    # Test data for mapping criteria
    let(:grader_response) do
      [
        {
          "rubric_category" => "Content",
          "reasoning" => "Good content",
          "criterion" => "Meets requirements"
        }
      ]
    end

    let(:rubric) do
      [
        {
          id: "criteria_1",
          description: "Content",
          ratings: [
            { id: "rating_1", long_description: "Meets requirements", points: 3 }
          ]
        }
      ]
    end

    let(:service) { described_class.new(assignment: "", essay: "", rubric:, root_account_uuid:) }

    # Test successful mapping of valid criteria
    it "maps grader response to rubric structure" do
      result = service.send(:map_criteria_ids_to_grades, grader_response, rubric)

      expect(result).to eq(
        [
          {
            "id" => "criteria_1",
            "description" => "Content",
            "rating" => {
              "id" => "rating_1",
              "description" => "Meets requirements",
              "rating" => 3,
              "reasoning" => "Good content"
            }
          }
        ]
      )
    end

    # Test handling of nonexistent rubric categories
    it "filters out items with nonexistent rubric category" do
      invalid_response = [
        { "rubric_category" => "Nonexistent", "criterion" => "X" },
        { "rubric_category" => "Content", "criterion" => "Meets requirements", "reasoning" => "Good content" }
      ]
      result = service.send(:map_criteria_ids_to_grades, invalid_response, rubric)

      expect(result).to eq(
        [
          {
            "id" => "criteria_1",
            "description" => "Content",
            "rating" => {
              "id" => "rating_1",
              "description" => "Meets requirements",
              "rating" => 3,
              "reasoning" => "Good content"
            }
          }
        ]
      )
    end

    # Test handling of nonexistent criteria within valid categories
    it "filters out items with nonexistent criterion" do
      invalid_response = [
        { "rubric_category" => "Content", "criterion" => "Missing", "reasoning" => "Bad" },
        { "rubric_category" => "Content", "criterion" => "Meets requirements", "reasoning" => "Good content" }
      ]
      result = service.send(:map_criteria_ids_to_grades, invalid_response, rubric)

      expect(result).to eq(
        [
          {
            "id" => "criteria_1",
            "description" => "Content",
            "rating" => {
              "id" => "rating_1",
              "description" => "Meets requirements",
              "rating" => 3,
              "reasoning" => "Good content"
            }
          }
        ]
      )
    end

    # Test handling of completely invalid responses
    it "returns empty array when all items are invalid" do
      invalid_response = [
        { "rubric_category" => "Nonexistent", "criterion" => "X" },
        { "rubric_category" => "Content", "criterion" => "Missing" }
      ]
      result = service.send(:map_criteria_ids_to_grades, invalid_response, rubric)

      expect(result).to be_empty
    end
  end

  describe "#sanitize_essay" do
    let(:service) { described_class.new(assignment: "Test Assignment", essay: "", rubric: [], root_account_uuid: "mock-root") }

    # Test essay length validation
    context "when validating essay length" do
      it "raises an error for essays with less than 5 words" do
        short_essay = "Too short essay"
        expect do
          service.send(:validate_essay_length, short_essay)
        end.to raise_error("Submission must be at least 5 words long")
      end

      it "does not raise an error for essays with 5 or more words" do
        valid_essay = "This is a valid essay text"
        expect do
          service.send(:validate_essay_length, valid_essay)
        end.not_to raise_error
      end
    end

    # Test HTML sanitization
    it "removes content between HTML tags" do
      sanitized = service.send(:sanitize_essay, "<script>alert('Injected!')</script>This is safe.")
      expect(sanitized).to eq("This is safe.")
    end

    # Test markdown header removal
    it "removes lines starting with more than 3 # characters" do
      sanitized = service.send(:sanitize_essay, "#### This line should be removed\nThis line should stay.")
      expect(sanitized).to eq("This line should stay.")
    end

    # Test whitespace normalization
    it "removes extra spaces and trims the text" do
      sanitized = service.send(:sanitize_essay, "   This   has   extra   spaces.   ")
      expect(sanitized).to eq("This has extra spaces.")
    end
  end

  describe "#rubric_matches_default_template" do
    let(:service) { described_class.new(assignment: "Test Assignment", essay: "Test Essay", rubric:, root_account_uuid:) }

    # Test various default rubric templates
    context "when rubric matches a default template" do
      it "returns true for Exit Ticket template" do
        rubric = [
          { description: "Exit Ticket Prompt" },
          { description: "Preparation" },
          { description: "Time" },
          { description: "Participation" }
        ]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:, root_account_uuid:)
        expect(service.send(:rubric_matches_default_template)).to be true
      end

      it "returns true for Peer Review template" do
        rubric = [{ description: "Peer Review" }]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:, root_account_uuid:)
        expect(service.send(:rubric_matches_default_template)).to be true
      end

      it "returns true for generic criterion template" do
        rubric = [{ description: "Description of criterion" }]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:, root_account_uuid:)
        expect(service.send(:rubric_matches_default_template)).to be true
      end
    end

    # Test custom rubric templates
    context "when rubric does not match any default template" do
      it "returns false for custom criteria" do
        rubric = [
          { description: "Custom Criterion 1" },
          { description: "Custom Criterion 2" }
        ]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:, root_account_uuid:)
        expect(service.send(:rubric_matches_default_template)).to be false
      end

      it "returns false for partial template match" do
        rubric = [
          { description: "Exit Ticket Prompt" },
          { description: "Custom Criterion" }
        ]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:, root_account_uuid:)
        expect(service.send(:rubric_matches_default_template)).to be false
      end
    end
  end

  describe "#filter_repeating_keys" do
    let(:service) { described_class.new(assignment: "Test Assignment", essay: "Test Essay", rubric: [], root_account_uuid: "mock-root") }

    # Test handling of duplicate criteria
    context "when JSON array contains duplicate criteria" do
      let(:json_array) do
        [
          {
            "rubric_category" => "Content",
            "reasoning" => "First reasoning",
            "criterion" => "Meets requirements"
          },
          {
            "rubric_category" => "Content", # Duplicate
            "reasoning" => "Second reasoning",
            "criterion" => "Meets requirements"
          },
          {
            "rubric_category" => "Style",
            "reasoning" => "Third reasoning",
            "criterion" => "Unique criterion"
          }
        ]
      end

      it "removes entries with duplicate criterion values" do
        filtered = service.send(:filter_repeating_keys, json_array)

        expect(filtered.length).to eq(2)
        expect(filtered.map { |item| item["criterion"] }).to match_array(["Meets requirements", "Unique criterion"])
      end

      it "keeps the first occurrence of duplicate criteria" do
        filtered = service.send(:filter_repeating_keys, json_array)

        dup = filtered.find { |item| item["criterion"] == "Meets requirements" }
        expect(dup["reasoning"]).to eq("First reasoning")
        expect(dup["rubric_category"]).to eq("Content")
      end
    end

    # Test handling of unique criteria
    context "when JSON array has no duplicates" do
      let(:unique_array) do
        [
          {
            "rubric_category" => "Content",
            "reasoning" => "First reasoning",
            "criterion" => "Criterion 1"
          },
          {
            "rubric_category" => "Grammar",
            "reasoning" => "Second reasoning",
            "criterion" => "Criterion 2"
          }
        ]
      end

      it "returns the original array unchanged" do
        filtered = service.send(:filter_repeating_keys, unique_array)

        expect(filtered).to eq(unique_array)
        expect(filtered.length).to eq(2)
      end
    end
  end
end
