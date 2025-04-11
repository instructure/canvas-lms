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

describe AutoGradeService do
  let(:assignment_text) { "Write an essay about your summer vacation" }
  let(:essay) { "I went to the beach and had a great time..." }

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

  let(:mock_graphql_response) do
    {
      "data" => {
        "answerPrompt" => mock_cedar_response.to_json
      }
    }
  end

  before do
    allow(DynamicSettings).to receive(:find).with("project_lhotse", default_ttl: 5.minutes).and_return(
      {
        "cedar_uri" => "https://cedar.example.com/graphql",
        "cedar_auth_token" => "mock_token"
      }
    )
    allow(Rails.env).to receive(:test?).and_return(true)
  end

  describe "#call" do
    let(:rubric) do
      [
        {
          description: "Content",
          points: 10,
          ratings: [
            { long_description: "Excellent content", points: 10 },
            { long_description: "Good content", points: 7 },
            { long_description: "Poor content", points: 3 }
          ]
        }
      ]
    end
    let(:assignment) { "Write an essay about your favorite book." }

    it "calls Cedar and returns enriched response" do
      mock_response = double("HTTPResponse", is_a?: true, body: mock_graphql_response.to_json)
      mock_request = double("HTTPRequest")
      allow(mock_request).to receive(:body=)
      mock_http = double("HTTPClient")
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:ssl_timeout=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:request).with(mock_request).and_return(mock_response)

      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)

      result = described_class.new(
        assignment: assignment_text,
        essay:,
        rubric: rubric_data
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

    it "raises an error when Cedar returns a failure response" do
      mock_response = double("HTTPResponse", is_a?: false, body: { error: "Invalid request" }.to_json)
      mock_request = double("HTTPRequest")
      allow(mock_request).to receive(:body=)
      mock_http = double("HTTPClient")
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:ssl_timeout=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:request).with(mock_request).and_return(mock_response)

      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)

      expect do
        described_class.new(
          assignment: assignment_text,
          essay:,
          rubric: rubric_data
        ).call
      end.to raise_error(CedarAIGraderError, /Invalid request/)
    end
  end

  describe "#map_criteria_ids_to_grades (instance method)" do
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

    let(:service) { described_class.new(assignment: "", essay: "", rubric:) }

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

    it "raises error if rubric category is not found" do
      invalid_response = [{ "rubric_category" => "Nonexistent", "criterion" => "X" }]
      expect do
        service.send(:map_criteria_ids_to_grades, invalid_response, rubric)
      end.to raise_error(CedarAIGraderError, /Missing Rubric Category 'Nonexistent'/)
    end

    it "raises error if criterion is not found" do
      invalid_response = [{ "rubric_category" => "Content", "criterion" => "Missing" }]
      expect do
        service.send(:map_criteria_ids_to_grades, invalid_response, rubric)
      end.to raise_error(CedarAIGraderError, /Missing Criterion 'Missing' from Rubric Category 'Content'/)
    end
  end

  describe "#sanitize_essay" do
    let(:service) { described_class.new(assignment: "Test Assignment", essay: "", rubric: []) }

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

    it "removes content between HTML tags" do
      sanitized = service.send(:sanitize_essay, "<script>alert('Injected!')</script>This is safe.")
      expect(sanitized).to eq("This is safe.")
    end

    it "removes lines starting with more than 3 # characters" do
      sanitized = service.send(:sanitize_essay, "#### This line should be removed\nThis line should stay.")
      expect(sanitized).to eq("This line should stay.")
    end

    it "removes extra spaces and trims the text" do
      sanitized = service.send(:sanitize_essay, "   This   has   extra   spaces.   ")
      expect(sanitized).to eq("This has extra spaces.")
    end
  end

  describe "#rubric_matches_default_template" do
    let(:service) { described_class.new(assignment: "Test Assignment", essay: "Test Essay", rubric:) }

    context "when rubric matches a default template" do
      it "returns true for Exit Ticket template" do
        rubric = [
          { description: "Exit Ticket Prompt" },
          { description: "Preparation" },
          { description: "Time" },
          { description: "Participation" }
        ]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:)
        expect(service.send(:rubric_matches_default_template)).to be true
      end

      it "returns true for Peer Review template" do
        rubric = [{ description: "Peer Review" }]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:)
        expect(service.send(:rubric_matches_default_template)).to be true
      end

      it "returns true for generic criterion template" do
        rubric = [{ description: "Description of criterion" }]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:)
        expect(service.send(:rubric_matches_default_template)).to be true
      end
    end

    context "when rubric does not match any default template" do
      it "returns false for custom criteria" do
        rubric = [
          { description: "Custom Criterion 1" },
          { description: "Custom Criterion 2" }
        ]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:)
        expect(service.send(:rubric_matches_default_template)).to be false
      end

      it "returns false for partial template match" do
        rubric = [
          { description: "Exit Ticket Prompt" },
          { description: "Custom Criterion" }
        ]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:)
        expect(service.send(:rubric_matches_default_template)).to be false
      end
    end
  end

  describe "#filter_repeating_keys" do
    let(:service) { described_class.new(assignment: "Test Assignment", essay: "Test Essay", rubric: []) }

    context "when JSON array contains duplicate criteria" do
      let(:json_array) do
        [
          {
            "rubric_category" => "Content",
            "reasoning" => "First reasoning",
            "criterion" => "Meets requirements"
          },
          {
            "rubric_category" => "Grammar",
            "reasoning" => "Second reasoning",
            "criterion" => "Meets requirements" # Duplicate criterion
          },
          {
            "rubric_category" => "Style",
            "reasoning" => "Third reasoning",
            "criterion" => "Unique criterion"
          }
        ]
      end

      it "removes entries with duplicate criterion values" do
        filtered_array = service.send(:filter_repeating_keys, json_array)

        expect(filtered_array.length).to eq(2)
        expect(filtered_array.map { |item| item["criterion"] }).to match_array(["Meets requirements", "Unique criterion"])
      end

      it "keeps the first occurrence of duplicate criteria" do
        filtered_array = service.send(:filter_repeating_keys, json_array)

        duplicate_entry = filtered_array.find { |item| item["criterion"] == "Meets requirements" }
        expect(duplicate_entry["reasoning"]).to eq("First reasoning")
        expect(duplicate_entry["rubric_category"]).to eq("Content")
      end
    end

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
        filtered_array = service.send(:filter_repeating_keys, unique_array)

        expect(filtered_array).to eq(unique_array)
        expect(filtered_array.length).to eq(2)
      end
    end
  end
end
