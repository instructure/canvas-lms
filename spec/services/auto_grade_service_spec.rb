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
      end.to raise_error(/Cedar GraphQL error/)
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
      end.to raise_error("Rubric category 'Nonexistent' not found.")
    end

    it "raises error if criterion is not found" do
      invalid_response = [{ "rubric_category" => "Content", "criterion" => "Missing" }]
      expect do
        service.send(:map_criteria_ids_to_grades, invalid_response, rubric)
      end.to raise_error("Criterion 'Missing' not found in rubric category 'Content'.")
    end
  end
end
