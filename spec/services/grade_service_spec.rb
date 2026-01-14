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
require_relative "../../app/services/grade_service"

GradeResult = Struct.new(:rubric_category, :reasoning, :criterion, :guidance, keyword_init: true)

RSpec.describe GradeService do
  # Test data setup
  let(:assignment_text) { "Write an essay about your summer vacation" }
  let(:essay) { "I went to the beach and had a great time..." }
  let(:root_account_uuid) { "mock-root-uuid" }
  let(:current_user) { instance_double(User) }

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

  before do
    allow(Rails.env).to receive(:test?).and_return(true)
    allow(TextNormalizerHelper).to receive(:normalize) { |text| text }
    stub_const("CedarClient", Class.new)
  end

  describe "#call" do
    let(:rubric) { rubric_data }
    let(:assignment) { assignment_text }

    let(:grading_results) do
      [
        GradeResult.new(
          rubric_category: "Content",
          reasoning: "Well developed ideas",
          criterion: "Meets requirements",
          guidance: "Add more specific historical examples."
        ),
        GradeResult.new(
          rubric_category: "Grammar",
          reasoning: "Flawless grammar",
          criterion: "Excellent grammar",
          guidance: "Great job keeping your grammar clear."
        )
      ]
    end

    it "calls CedarClient.grade_essay and returns mapped rubric ratings including comments" do
      expect(CedarClient).to receive(:grade_essay).with(
        description: assignment,
        essay: kind_of(String),
        rubric: kind_of(Array),
        feature_slug: "grading-assistance",
        root_account_uuid: "mock-root",
        current_user:
      ).and_return(grading_results)

      result = described_class.new(
        assignment:,
        essay:,
        rubric:,
        root_account_uuid: "mock-root",
        current_user:
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
            },
            "comments" => "Add more specific historical examples."
          },
          {
            "id" => "criteria_2",
            "description" => "Grammar",
            "rating" => {
              "id" => "rating_2",
              "description" => "Excellent grammar",
              "rating" => 4,
              "reasoning" => "Flawless grammar"
            },
            "comments" => "Great job keeping your grammar clear."
          }
        ]
      )
    end

    # Test error handling for malformed JSON responses
    it "wraps generic CedarClient errors in CedarAi::Errors::GraderError" do
      allow(CedarClient).to receive(:grade_essay)
        .and_raise(StandardError.new("Some low-level error"))

      service = described_class.new(
        assignment:,
        essay:,
        rubric:,
        root_account_uuid:,
        current_user:
      )

      expect do
        service.call
      end.to raise_error(
        CedarAi::Errors::GraderError,
        /Invalid response from gradeEssay: Some low-level error/
      )
    end

    # Test handling of partial responses from Cedar
    context "when Cedar returns partial criteria" do
      let(:partial_results) do
        [
          GradeResult.new(
            rubric_category: "Content",
            reasoning: "Well developed ideas",
            criterion: "Meets requirements",
            guidance: "Add more examples."
          )
        ]
      end

      it "returns only the criteria that were graded" do
        allow(CedarClient).to receive(:grade_essay).and_return(partial_results)

        result = described_class.new(
          assignment:,
          essay:,
          rubric:,
          root_account_uuid: "mock-root",
          current_user:
        ).call

        expect(result.length).to eq(1)
        expect(result.first["description"]).to eq("Content")
      end
    end

    # Test handling of invalid criteria in Cedar's response
    context "when Cedar returns invalid criteria" do
      let(:mixed_results) do
        [
          GradeResult.new(
            rubric_category: "Invalid Category",
            reasoning: "Some reasoning",
            criterion: "Invalid Criterion",
            guidance: "Irrelevant guidance"
          ),
          GradeResult.new(
            rubric_category: "Content",
            reasoning: "Well developed ideas",
            criterion: "Meets requirements",
            guidance: "Add more examples."
          )
        ]
      end

      it "filters out invalid criteria and returns only valid ones" do
        allow(CedarClient).to receive(:grade_essay).and_return(mixed_results)

        result = described_class.new(
          assignment:,
          essay:,
          rubric:,
          root_account_uuid: "mock-root",
          current_user:
        ).call

        expect(result.length).to eq(1)
        expect(result.first["description"]).to eq("Content")
      end
    end

    context "when rubric matches default template" do
      let(:default_rubric) do
        [
          { description: "Exit Ticket Prompt", ratings: [], points: 1 },
          { description: "Preparation", ratings: [], points: 1 },
          { description: "Time", ratings: [], points: 1 },
          { description: "Participation", ratings: [], points: 1 }
        ]
      end

      it "raises an error before calling Cedar" do
        expect(CedarClient).not_to receive(:grade_essay)

        service = described_class.new(
          assignment:,
          essay:,
          rubric: default_rubric,
          root_account_uuid:,
          current_user:
        )

        expect { service.call }.to raise_error("Rubric criteria not descriptive enough")
      end
    end
  end

  describe "#map_grade_essay_results_to_canvas" do
    let(:grader_response) do
      [
        GradeResult.new(
          rubric_category: "Content",
          reasoning: "Good content",
          criterion: "Meets requirements",
          guidance: "Add more details."
        )
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

    let(:service) do
      described_class.new(
        assignment: "Test",
        essay: "Test essay with enough words",
        rubric:,
        root_account_uuid:,
        current_user:
      )
    end

    it "maps grader response to Canvas rubric structure including comments" do
      result = service.send(:map_grade_essay_results_to_canvas, grader_response, rubric)

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
            },
            "comments" => "Add more details."
          }
        ]
      )
    end

    # Test handling of nonexistent rubric categories
    it "filters out items with nonexistent rubric category" do
      invalid_response = [
        GradeResult.new(
          rubric_category: "Nonexistent",
          reasoning: "X",
          criterion: "X",
          guidance: "X"
        ),
        GradeResult.new(
          rubric_category: "Content",
          reasoning: "Good content",
          criterion: "Meets requirements",
          guidance: "Add more details."
        )
      ]

      result = service.send(:map_grade_essay_results_to_canvas, invalid_response, rubric)

      expect(result.length).to eq(1)
      expect(result.first["description"]).to eq("Content")
    end

    # Test handling of nonexistent criteria within valid categories
    it "filters out items with nonexistent criterion" do
      invalid_response = [
        GradeResult.new(
          rubric_category: "Content",
          reasoning: "Bad",
          criterion: "Missing",
          guidance: "X"
        ),
        GradeResult.new(
          rubric_category: "Content",
          reasoning: "Good content",
          criterion: "Meets requirements",
          guidance: "Add more details."
        )
      ]

      result = service.send(:map_grade_essay_results_to_canvas, invalid_response, rubric)

      expect(result.length).to eq(1)
      expect(result.first["rating"]["description"]).to eq("Meets requirements")
    end

    # Test handling of completely invalid responses
    it "returns empty array when all items are invalid" do
      invalid_response = [
        GradeResult.new(
          rubric_category: "Nonexistent",
          reasoning: "X",
          criterion: "X",
          guidance: "X"
        ),
        GradeResult.new(
          rubric_category: "Content",
          reasoning: "Bad",
          criterion: "Missing",
          guidance: "Y"
        )
      ]

      result = service.send(:map_grade_essay_results_to_canvas, invalid_response, rubric)

      expect(result).to be_empty
    end
  end

  describe "#sanitize_essay" do
    let(:service) do
      described_class.new(
        assignment: "Test Assignment",
        essay: "",
        rubric: [],
        root_account_uuid: "mock-root",
        current_user:
      )
    end

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

  describe "#rubric_matches_default_template?" do
    let(:service) do
      described_class.new(
        assignment: "Test Assignment",
        essay: "Test Essay",
        rubric:,
        root_account_uuid:,
        current_user:
      )
    end

    # Test various default rubric templates
    context "when rubric matches a default template" do
      it "returns true for Exit Ticket template" do
        rubric = [
          { description: "Exit Ticket Prompt" },
          { description: "Preparation" },
          { description: "Time" },
          { description: "Participation" }
        ]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:, root_account_uuid:, current_user:)
        expect(service.send(:rubric_matches_default_template?)).to be true
      end

      it "returns true for Peer Review template" do
        rubric = [{ description: "Peer Review" }]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:, root_account_uuid:, current_user:)
        expect(service.send(:rubric_matches_default_template?)).to be true
      end

      it "returns true for generic criterion template" do
        rubric = [{ description: "Description of criterion" }]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:, root_account_uuid:, current_user:)
        expect(service.send(:rubric_matches_default_template?)).to be true
      end
    end

    # Test custom rubric templates
    context "when rubric does not match any default template" do
      it "returns false for custom criteria" do
        rubric = [
          { description: "Custom Criterion 1" },
          { description: "Custom Criterion 2" }
        ]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:, root_account_uuid:, current_user:)
        expect(service.send(:rubric_matches_default_template?)).to be false
      end

      it "returns false for partial template match" do
        rubric = [
          { description: "Exit Ticket Prompt" },
          { description: "Custom Criterion" }
        ]
        service = described_class.new(assignment: "Test", essay: "Test", rubric:, root_account_uuid:, current_user:)
        expect(service.send(:rubric_matches_default_template?)).to be false
      end
    end
  end
end
