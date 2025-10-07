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

describe Api::V1::AiExperience do
  before :once do
    course_with_teacher active_all: true
    @ai_experience = @course.ai_experiences.create!(
      title: "Customer Service Training",
      description: "Practice customer service scenarios",
      facts: "You are a customer service representative",
      learning_objective: "Learn customer service skills",
      scenario: "Handle billing issues"
    )
  end

  let(:api) { Class.new { include Api::V1::AiExperience }.new }
  let(:session) { double }

  describe "ai_experience_json" do
    it "includes all specified attributes" do
      json = api.ai_experience_json(@ai_experience, @teacher, session)
      expected_fields = %w[id title description facts learning_objective scenario workflow_state course_id created_at updated_at]

      expected_fields.each do |field|
        expect(json).to have_key(field)
      end
    end

    it "returns correct attribute values" do
      json = api.ai_experience_json(@ai_experience, @teacher, session)

      expect(json["id"]).to eq @ai_experience.id
      expect(json["title"]).to eq @ai_experience.title
      expect(json["description"]).to eq @ai_experience.description
      expect(json["facts"]).to eq @ai_experience.facts
      expect(json["learning_objective"]).to eq @ai_experience.learning_objective
      expect(json["scenario"]).to eq @ai_experience.scenario
      expect(json["workflow_state"]).to eq @ai_experience.workflow_state
      expect(json["course_id"]).to eq @ai_experience.course_id
    end
  end

  describe "ai_experiences_json" do
    it "returns array of ai experience json objects" do
      experiences = [@ai_experience]
      json = api.ai_experiences_json(experiences, @teacher, session)

      expect(json).to be_an(Array)
      expect(json.length).to eq 1
      expect(json.first["id"]).to eq @ai_experience.id
    end
  end
end
