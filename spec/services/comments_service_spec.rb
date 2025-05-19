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
require_relative "../../app/services/auto_grade_orchestration_service"

RSpec.describe CommentsService, type: :service do
  let(:assignment) { "Write an essay about your favorite book." }
  let(:root_account_uuid) { "test-root-uuid" }
  let(:grade_data) do
    [
      {
        "description" => "Content",
        "rating" => { "reasoning" => "Needs more detail." }
      },
      {
        "description" => "Grammar",
        "rating" => { "reasoning" => "Several grammatical errors." }
      }
    ]
  end

  let(:mock_guidance) do
    [
      { "criterion" => "Content", "guidance" => "Add more specific examples to support your points." },
      { "criterion" => "Grammar", "guidance" => "Review your essay for subject-verb agreement and punctuation." }
    ]
  end

  before do
    stub_const("CedarClient", Class.new do
      def self.prompt(*)
        [
          { "criterion" => "Content", "guidance" => "Add more specific examples to support your points." },
          { "criterion" => "Grammar", "guidance" => "Review your essay for subject-verb agreement and punctuation." }
        ].to_json
      end
    end)
  end

  describe "#call" do
    it "calls CedarClient and updates grade_data with comments" do
      service = described_class.new(assignment:, grade_data: grade_data.deep_dup, root_account_uuid:)
      result = service.call

      expect(result[0]["comments"]).to eq("Add more specific examples to support your points.")
      expect(result[1]["comments"]).to eq("Review your essay for subject-verb agreement and punctuation.")
    end

    it "raises CedarAIGraderError on invalid JSON response" do
      stub_const("CedarClient", Class.new do
        def self.prompt(*)
          "not-json"
        end
      end)

      service = described_class.new(assignment:, grade_data: grade_data.deep_dup, root_account_uuid:)
      expect { service.call }.to raise_error(CedarAIGraderError, /Invalid JSON response/)
    end
  end

  describe "#build_prompt" do
    it "includes assignment and list_of_reasonings in the prompt" do
      service = described_class.new(assignment:, grade_data:, root_account_uuid:)
      prompt = service.build_prompt(list_of_reasonings: [{ "CRITERION" => "Content", "REASONING" => "Needs more detail." }])
      expect(prompt).to include("Write an essay about your favorite book.")
      expect(prompt).to include("Needs more detail.")
    end
  end
end
