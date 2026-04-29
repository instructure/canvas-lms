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

describe AiConversation do
  let(:course) { course_factory }
  let(:user) { user_factory }
  let(:ai_experience) do
    AiExperience.create!(
      title: "Test Experience",
      learning_objective: "Test learning objective",
      pedagogical_guidance: "Test pedagogical guidance",
      course:
    )
  end

  let(:valid_attributes) do
    {
      llm_conversation_id: "test-123",
      user:,
      ai_experience:,
      course:
    }
  end

  describe "validations" do
    it "requires llm_conversation_id" do
      conversation = AiConversation.new(valid_attributes.except(:llm_conversation_id))
      expect(conversation).not_to be_valid
      expect(conversation.errors[:llm_conversation_id]).to include("can't be blank")
    end

    it "validates workflow_state inclusion" do
      conversation = AiConversation.new(valid_attributes.merge(workflow_state: "invalid_state"))
      expect(conversation).not_to be_valid
      expect(conversation.errors[:workflow_state]).to include("is not included in the list")
    end
  end

  describe "workflow state management" do
    let(:conversation) { AiConversation.create!(valid_attributes) }

    it "can be completed and deleted" do
      expect(conversation.complete!).to be true
      expect(conversation.reload).to be_completed

      expect(conversation.delete).to be true
      expect(conversation.reload).to be_deleted
      expect(conversation.complete!).to be false # Cannot complete deleted
    end
  end

  describe "scopes" do
    let!(:active_conversation) { AiConversation.create!(valid_attributes.merge(llm_conversation_id: "active-123")) }
    let!(:completed_conversation) { AiConversation.create!(valid_attributes.merge(llm_conversation_id: "completed-123", workflow_state: "completed")) }

    it "filters by workflow state" do
      expect(AiConversation.active).to contain_exactly(active_conversation)
      expect(AiConversation.completed).to contain_exactly(completed_conversation)
    end
  end
end
