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

require "webmock/rspec"

describe AiExperience do
  let(:account) { Account.create! }
  let(:root_account) { Account.default }
  let(:course) { course_factory(account: root_account) }

  let(:valid_attributes) do
    {
      title: "Test AI Experience",
      description: "A test AI experience",
      facts: "These are test facts",
      learning_objective: "Learn something useful",
      pedagogical_guidance: "A test pedagogical guidance",
      course:
    }
  end

  describe "validations" do
    it "requires title, learning_objective, and pedagogical_guidance" do
      experience = AiExperience.new(valid_attributes.except(:title, :learning_objective, :pedagogical_guidance))
      expect(experience).not_to be_valid
      expect(experience.errors[:title]).to include("can't be blank")
      expect(experience.errors[:learning_objective]).to include("can't be blank")
      expect(experience.errors[:pedagogical_guidance]).to include("can't be blank")
    end

    it "validates title length" do
      experience = AiExperience.new(valid_attributes.merge(title: "a" * 256))
      expect(experience).not_to be_valid
    end

    it "validates workflow_state inclusion" do
      experience = AiExperience.new(valid_attributes.merge(workflow_state: "invalid_state"))
      expect(experience).not_to be_valid
      expect(experience.errors[:workflow_state]).to include("is not included in the list")
    end

    it "validates context_index_status inclusion" do
      experience = AiExperience.new(valid_attributes.merge(context_index_status: "invalid_status"))
      expect(experience).not_to be_valid
      expect(experience.errors[:context_index_status]).to include("is not included in the list")
    end

    it "defaults context_index_status to not_started" do
      experience = AiExperience.create!(valid_attributes)
      expect(experience.context_index_status).to eq("not_started")
    end

    it "allows facts to be blank" do
      experience = AiExperience.new(valid_attributes.except(:facts))
      expect(experience).to be_valid
    end
  end

  describe "scopes" do
    let!(:published_exp) { AiExperience.create!(valid_attributes.merge(title: "Published", workflow_state: "published")) }
    let!(:unpublished_exp) { AiExperience.create!(valid_attributes.merge(title: "Unpublished", workflow_state: "unpublished")) }

    it "scopes work correctly" do
      expect(AiExperience.published).to contain_exactly(published_exp)
      expect(AiExperience.unpublished).to contain_exactly(unpublished_exp)
      expect(AiExperience.active).to contain_exactly(published_exp, unpublished_exp)
    end
  end

  describe "workflow state management" do
    let(:experience) { AiExperience.create!(valid_attributes) }

    it "can be published and unpublished" do
      expect(experience.publish!).to be true
      expect(experience.reload).to be_published

      expect(experience.unpublish!).to be true
      expect(experience.reload).to be_unpublished
    end

    it "can be soft deleted" do
      expect(experience.delete).to be true
      expect(experience.reload).to be_deleted
      expect(experience.publish!).to be false # Cannot publish deleted
    end

    it "can be permanently deleted" do
      experience_id = experience.id
      experience.destroy
      expect(AiExperience.find_by(id: experience_id)).to be_nil
    end
  end

  describe "conversation_context lifecycle callbacks" do
    before do
      Setting.set("llm_conversation_base_url", "http://localhost:3001")
      allow(Rails.application.credentials).to receive(:llm_conversation_bearer_token).and_return("test-token")
    end

    describe "after_create" do
      let(:prompt_response) do
        {
          "success" => true,
          "data" => {
            "id" => "prompt-uuid",
            "code" => "alpha",
            "content" => "System prompt"
          }
        }
      end

      let(:create_context_response) do
        {
          "success" => true,
          "data" => {
            "id" => "context-uuid",
            "type" => "assignment",
            "data" => {
              "scenario" => valid_attributes[:pedagogical_guidance],
              "facts" => valid_attributes[:facts],
              "learning_objectives" => valid_attributes[:learning_objective]
            },
            "prompt_id" => "prompt-uuid"
          }
        }
      end

      before do
        stub_request(:get, "http://localhost:3001/prompts/by-code/alpha")
          .to_return(status: 200, body: prompt_response.to_json, headers: { "Content-Type" => "application/json" })

        stub_request(:post, "http://localhost:3001/conversation-context")
          .to_return(status: 200, body: create_context_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "creates conversation_context after creating AI experience" do
        experience = AiExperience.create!(valid_attributes)

        expect(experience.llm_conversation_context_id).to eq("context-uuid")
        expect(WebMock).to have_requested(:post, "http://localhost:3001/conversation-context")
      end

      it "does not fail AI experience creation if context creation fails" do
        stub_request(:post, "http://localhost:3001/conversation-context")
          .to_return(status: 500, body: "Internal Server Error")

        expect do
          experience = AiExperience.create!(valid_attributes)
          expect(experience).to be_persisted
          expect(experience.llm_conversation_context_id).to be_nil
        end.not_to raise_error
      end

      it "logs error when context creation fails" do
        stub_request(:post, "http://localhost:3001/conversation-context")
          .to_return(status: 500, body: "Internal Server Error")

        expect(Rails.logger).to receive(:error).with(/Failed to create conversation context/)

        AiExperience.create!(valid_attributes)
      end
    end

    describe "after_update" do
      let!(:experience) do
        exp = AiExperience.create!(valid_attributes)
        exp.update_column(:llm_conversation_context_id, "context-uuid")
        exp
      end

      let(:update_context_response) do
        {
          "success" => true,
          "data" => {
            "id" => "context-uuid",
            "data" => {
              "scenario" => "Updated scenario",
              "facts" => "Updated facts",
              "learning_objectives" => "Updated objectives"
            }
          }
        }
      end

      before do
        stub_request(:patch, "http://localhost:3001/conversation-context/context-uuid")
          .to_return(status: 200, body: update_context_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "updates conversation_context when pedagogical_guidance changes" do
        experience.update!(pedagogical_guidance: "Updated scenario")

        expect(WebMock).to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
      end

      it "updates conversation_context when facts change" do
        experience.update!(facts: "Updated facts")

        expect(WebMock).to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
      end

      it "updates conversation_context when learning_objective changes" do
        experience.update!(learning_objective: "Updated objectives")

        expect(WebMock).to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
      end

      it "does not update conversation_context when other fields change" do
        experience.update!(title: "New Title")

        expect(WebMock).not_to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
      end

      it "does not update conversation_context if context_id is not set" do
        experience.update_column(:llm_conversation_context_id, nil)
        experience.update!(pedagogical_guidance: "Updated scenario")

        expect(WebMock).not_to have_requested(:patch, %r{http://localhost:3001/conversation-context/})
      end

      it "does not fail AI experience update if context update fails" do
        stub_request(:patch, "http://localhost:3001/conversation-context/context-uuid")
          .to_return(status: 500, body: "Internal Server Error")

        expect do
          experience.update!(pedagogical_guidance: "Updated scenario")
          expect(experience.reload.pedagogical_guidance).to eq("Updated scenario")
        end.not_to raise_error
      end

      it "logs error when context update fails" do
        stub_request(:patch, "http://localhost:3001/conversation-context/context-uuid")
          .to_return(status: 500, body: "Internal Server Error")

        expect(Rails.logger).to receive(:error).with(/Failed to update conversation context/)

        experience.update!(pedagogical_guidance: "Updated scenario")
      end
    end

    describe "before_destroy" do
      let!(:experience) do
        exp = AiExperience.create!(valid_attributes)
        exp.update_column(:llm_conversation_context_id, "context-uuid")
        exp
      end

      before do
        stub_request(:delete, "http://localhost:3001/conversation-context/context-uuid")
          .to_return(status: 200, body: { "success" => true }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "deletes conversation_context when destroying AI experience" do
        experience.destroy

        expect(WebMock).to have_requested(:delete, "http://localhost:3001/conversation-context/context-uuid")
      end

      it "does not delete conversation_context if context_id is not set" do
        experience.update_column(:llm_conversation_context_id, nil)
        experience.destroy

        expect(WebMock).not_to have_requested(:delete, %r{http://localhost:3001/conversation-context/})
      end

      it "does not fail AI experience destruction if context deletion fails" do
        stub_request(:delete, "http://localhost:3001/conversation-context/context-uuid")
          .to_return(status: 500, body: "Internal Server Error")

        experience_id = experience.id

        expect do
          experience.destroy
          expect(AiExperience.find_by(id: experience_id)).to be_nil
        end.not_to raise_error
      end

      it "logs error when context deletion fails" do
        stub_request(:delete, "http://localhost:3001/conversation-context/context-uuid")
          .to_return(status: 500, body: "Internal Server Error")

        expect(Rails.logger).to receive(:error).with(/Failed to delete conversation context/)

        experience.destroy
      end
    end
  end

  describe "#can_unpublish?" do
    let(:experience) { AiExperience.create!(valid_attributes.merge(workflow_state: "published")) }
    let(:student) { user_factory(active_all: true) }
    let(:teacher) { user_factory(active_all: true) }

    before do
      course.enroll_student(student, enrollment_state: "active")
      course.enroll_teacher(teacher, enrollment_state: "active")
    end

    context "when there are no conversations" do
      it "returns true" do
        expect(experience.can_unpublish?).to be true
      end
    end

    context "when there are only teacher conversations" do
      before do
        AiConversation.create!(
          ai_experience: experience,
          course:,
          user: teacher,
          llm_conversation_id: "teacher-conv-1",
          workflow_state: "active",
          root_account: course.root_account,
          account: course.account
        )
      end

      it "returns true" do
        expect(experience.can_unpublish?).to be true
      end
    end

    context "when there are student conversations" do
      before do
        AiConversation.create!(
          ai_experience: experience,
          course:,
          user: student,
          llm_conversation_id: "student-conv-1",
          workflow_state: "active",
          root_account: course.root_account,
          account: course.account
        )
      end

      it "returns false" do
        expect(experience.can_unpublish?).to be false
      end
    end

    context "when there are deleted student conversations" do
      before do
        AiConversation.create!(
          ai_experience: experience,
          course:,
          user: student,
          llm_conversation_id: "student-conv-deleted",
          workflow_state: "deleted",
          root_account: course.root_account,
          account: course.account
        )
      end

      it "returns true" do
        expect(experience.can_unpublish?).to be true
      end
    end

    context "when student enrollment is deleted" do
      before do
        enrollment = course.enroll_student(student, enrollment_state: "active")
        enrollment.destroy

        AiConversation.create!(
          ai_experience: experience,
          course:,
          user: student,
          llm_conversation_id: "student-conv-1",
          workflow_state: "active",
          root_account: course.root_account,
          account: course.account
        )
      end

      it "returns true" do
        expect(experience.can_unpublish?).to be true
      end
    end
  end

  describe "#unpublish_ok?" do
    let(:experience) { AiExperience.create!(valid_attributes.merge(workflow_state: "published")) }
    let(:student) { user_factory(active_all: true) }

    before do
      course.enroll_student(student, enrollment_state: "active")
    end

    context "when can_unpublish? is true" do
      it "allows unpublishing" do
        experience.workflow_state = "unpublished"
        expect(experience).to be_valid
      end
    end

    context "when can_unpublish? is false" do
      before do
        AiConversation.create!(
          ai_experience: experience,
          course:,
          user: student,
          llm_conversation_id: "student-conv-1",
          workflow_state: "active",
          root_account: course.root_account,
          account: course.account
        )
      end

      it "prevents unpublishing" do
        experience.workflow_state = "unpublished"
        expect(experience).not_to be_valid
        expect(experience.errors[:workflow_state]).to include("Can't unpublish if students have started conversations")
      end

      it "allows publishing" do
        experience.unpublish!
        experience.workflow_state = "published"
        expect(experience).to be_valid
      end
    end
  end
end
