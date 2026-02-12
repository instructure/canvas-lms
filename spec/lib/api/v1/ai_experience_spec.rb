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
      pedagogical_guidance: "Handle billing issues"
    )
  end

  let(:api) { Class.new { include Api::V1::AiExperience }.new }
  let(:session) { double }

  describe "ai_experience_json" do
    it "includes all specified attributes" do
      json = api.ai_experience_json(@ai_experience, @teacher, session)
      expected_fields = %w[id title description facts learning_objective pedagogical_guidance workflow_state course_id context_index_status created_at updated_at]

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
      expect(json["pedagogical_guidance"]).to eq @ai_experience.pedagogical_guidance
      expect(json["workflow_state"]).to eq @ai_experience.workflow_state
      expect(json["course_id"]).to eq @ai_experience.course_id
    end

    it "includes submission_status with not_started value when provided" do
      json = api.ai_experience_json(@ai_experience, @teacher, session, { submission_status: "not_started" })
      expect(json).to have_key(:submission_status)
      expect(json[:submission_status]).to eq("not_started")
    end

    it "does not include submission_status when not provided in opts" do
      json = api.ai_experience_json(@ai_experience, @teacher, session)
      expect(json).not_to have_key(:submission_status)
    end

    context "with ai_experiences_context_file_upload feature flag enabled" do
      before { @course.enable_feature!(:ai_experiences_context_file_upload) }

      it "includes context_files array" do
        attachment = attachment_model(context: @course, size: 1.megabyte, filename: "test.pdf")
        AiExperienceContextFile.create!(ai_experience: @ai_experience, attachment:)

        json = api.ai_experience_json(@ai_experience, @teacher, session)

        expect(json).to have_key(:context_files)
        expect(json[:context_files]).to be_an(Array)
        expect(json[:context_files].length).to eq(1)
        expect(json[:context_files].first[:id]).to eq(attachment.id)
        expect(json[:context_files].first[:filename]).to eq("test.pdf")
        expect(json[:context_files].first).to have_key(:size)
        expect(json[:context_files].first).to have_key(:content_type)
        expect(json[:context_files].first).to have_key(:position)
      end
    end

    context "with ai_experiences_context_file_upload feature flag disabled" do
      before { @course.disable_feature!(:ai_experiences_context_file_upload) }

      it "does not include context_files array" do
        attachment = attachment_model(context: @course, size: 1.megabyte)
        AiExperienceContextFile.create!(ai_experience: @ai_experience, attachment:)

        json = api.ai_experience_json(@ai_experience, @teacher, session)

        expect(json).not_to have_key(:context_files)
      end
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
