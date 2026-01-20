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

require_relative "../spec_helper"
require_relative "../../lib/llm_conversation"
require_relative "../../lib/llm_conversation/errors"

describe AiConversationsController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @course.root_account.enable_feature!(:ai_experiences)
    @ai_experience = @course.ai_experiences.create!(
      title: "Customer Service Training",
      description: "Practice customer service scenarios",
      facts: "You are a customer service representative helping customers with billing issues.",
      learning_objective: "Students will learn to handle customer complaints professionally",
      pedagogical_guidance: "A customer calls about incorrect billing"
    )
  end

  describe "GET #active_conversation" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "returns existing active conversation with progress" do
        conversation = @ai_experience.ai_conversations.create!(
          llm_conversation_id: "existing-llm-conv-id",
          user: @teacher,
          course: @course,
          root_account: @course.root_account,
          account: @course.account,
          workflow_state: "active"
        )

        mock_client = instance_double(LLMConversationClient)
        allow(LLMConversationClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:messages_with_conversation_progress).and_return({
                                                                                         messages: [
                                                                                           { role: "User", text: "Hello" },
                                                                                           { role: "Assistant", text: "Hi there!" }
                                                                                         ],
                                                                                         progress: {
                                                                                           current: 1,
                                                                                           total: 3,
                                                                                           percentage: 33,
                                                                                           objectives: [
                                                                                             { objective: "Objective 1", status: "covered" },
                                                                                             { objective: "Objective 2", status: "" },
                                                                                             { objective: "Objective 3", status: "" }
                                                                                           ]
                                                                                         }
                                                                                       })

        get :active_conversation,
            params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
            format: :json

        expect(response).to be_successful
        json_response = json_parse(response.body)
        expect(json_response["id"]).to eq(conversation.id)
        expect(json_response["messages"]).to be_an(Array)
        expect(json_response["progress"]).to be_present
        expect(json_response["progress"]["percentage"]).to eq(33)
        expect(json_response["progress"]["current"]).to eq(1)
        expect(json_response["progress"]["total"]).to eq(3)
      end

      it "returns empty object when no active conversation" do
        get :active_conversation,
            params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
            format: :json

        expect(response).to be_successful
        json_response = json_parse(response.body)
        expect(json_response).to eq({})
      end
    end

    context "as unenrolled user" do
      before :once do
        @unenrolled_user = user_factory(active_all: true)
      end

      before { user_session(@unenrolled_user) }

      it "returns forbidden for unenrolled users" do
        get :active_conversation,
            params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
            format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET #show" do
    before :once do
      @student2 = student_in_course(active_all: true, course: @course).user
      @conversation = @ai_experience.ai_conversations.create!(
        llm_conversation_id: "student-conv-123",
        user: @student2,
        course: @course,
        root_account: @course.root_account,
        account: @course.account,
        workflow_state: "active"
      )
    end

    context "as teacher" do
      before do
        user_session(@teacher)
        mock_client = instance_double(LLMConversationClient)
        allow(LLMConversationClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:messages_with_conversation_progress).and_return({
                                                                                         messages: [
                                                                                           { role: "User", text: "Hello" },
                                                                                           { role: "Assistant", text: "Hi there!" }
                                                                                         ],
                                                                                         progress: {
                                                                                           current: 1,
                                                                                           total: 2,
                                                                                           percentage: 50,
                                                                                           objectives: []
                                                                                         }
                                                                                       })
      end

      it "returns student conversation with messages" do
        get :show,
            params: { course_id: @course.id, ai_experience_id: @ai_experience.id, id: @conversation.id },
            format: :json

        expect(response).to be_successful
        json_response = json_parse(response.body)
        expect(json_response["id"]).to eq(@conversation.id)
        expect(json_response["user_id"]).to eq(@student2.id.to_s)
        expect(json_response["messages"]).to be_an(Array)
        expect(json_response["messages"].length).to eq(2)
        expect(json_response["progress"]).to be_present
      end

      it "returns 404 for non-existent conversation" do
        get :show,
            params: { course_id: @course.id, ai_experience_id: @ai_experience.id, id: 99_999 },
            format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns unauthorized when viewing another student's conversation" do
        get :show,
            params: { course_id: @course.id, ai_experience_id: @ai_experience.id, id: @conversation.id },
            format: :json

        assert_forbidden
      end
    end
  end

  describe "POST #create" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "creates a new conversation and returns initial messages with progress" do
        mock_client = instance_double(LLMConversationClient)
        allow(LLMConversationClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:starting_messages).and_return({
                                                                       conversation_id: "llm-conv-id",
                                                                       messages: [
                                                                         { role: "User", text: "Hello" },
                                                                         { role: "Assistant", text: "Hi there!" }
                                                                       ],
                                                                       progress: {
                                                                         current: 0,
                                                                         total: 2,
                                                                         percentage: 0,
                                                                         objectives: [
                                                                           { objective: "Objective 1", status: "" },
                                                                           { objective: "Objective 2", status: "" }
                                                                         ]
                                                                       }
                                                                     })

        post :create,
             params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
             format: :json

        expect(response).to have_http_status(:created)
        json_response = json_parse(response.body)
        expect(json_response["id"]).to be_present
        expect(json_response["messages"]).to be_an(Array)
        expect(json_response["messages"].length).to eq(2)
        expect(json_response["conversation_id"]).to be_nil # Should not expose LLM conversation ID
        expect(json_response["progress"]).to be_present
        expect(json_response["progress"]["percentage"]).to eq(0)
        expect(json_response["progress"]["objectives"]).to be_an(Array)
      end

      it "creates an AiConversation record" do
        mock_client = instance_double(LLMConversationClient)
        allow(LLMConversationClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:starting_messages).and_return({
                                                                       conversation_id: "llm-conv-id",
                                                                       messages: []
                                                                     })

        expect do
          post :create,
               params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
               format: :json
        end.to change(AiConversation, :count).by(1)

        conversation = AiConversation.last
        expect(conversation.user).to eq(@teacher)
        expect(conversation.ai_experience).to eq(@ai_experience)
        expect(conversation.workflow_state).to eq("active")
      end

      it "completes existing active conversation and creates a new one" do
        existing_conversation = @ai_experience.ai_conversations.create!(
          llm_conversation_id: "existing-id",
          user: @teacher,
          course: @course,
          root_account: @course.root_account,
          account: @course.account,
          workflow_state: "active"
        )

        mock_client = instance_double(LLMConversationClient)
        allow(LLMConversationClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:starting_messages).and_return({
                                                                       conversation_id: "new-llm-conv-id",
                                                                       messages: []
                                                                     })

        post :create,
             params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
             format: :json

        expect(response).to have_http_status(:created)

        # Check that old conversation was marked as completed
        existing_conversation.reload
        expect(existing_conversation.workflow_state).to eq("completed")

        # Check that new conversation was created
        new_conversation = AiConversation.active.for_user(@teacher.id).first
        expect(new_conversation).to be_present
        expect(new_conversation.id).not_to eq(existing_conversation.id)
      end

      it "returns service unavailable on conversation error" do
        mock_client = instance_double(LLMConversationClient)
        allow(LLMConversationClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:starting_messages)
          .and_raise(LlmConversation::Errors::ConversationError, "Service unavailable")

        post :create,
             params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
             format: :json

        expect(response).to have_http_status(:service_unavailable)
        json_response = json_parse(response.body)
        expect(json_response["error"]).to eq("Service unavailable")
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "allows students to create conversations" do
        mock_client = instance_double(LLMConversationClient)
        allow(LLMConversationClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:starting_messages).and_return({
                                                                       conversation_id: "llm-conv-id",
                                                                       messages: []
                                                                     })

        post :create,
             params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
             format: :json

        expect(response).to have_http_status(:created)
      end
    end

    context "as unenrolled user" do
      before :once do
        @unenrolled_user = user_factory(active_all: true)
      end

      before { user_session(@unenrolled_user) }

      it "returns forbidden for unenrolled users" do
        post :create,
             params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
             format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST #post_message" do
    before do
      @conversation = @ai_experience.ai_conversations.create!(
        llm_conversation_id: "llm-conv-id",
        user: @teacher,
        course: @course,
        root_account: @course.root_account,
        account: @course.account,
        workflow_state: "active"
      )
    end

    context "as teacher" do
      before { user_session(@teacher) }

      it "posts a message and returns updated messages with progress" do
        mock_client = instance_double(LLMConversationClient)
        allow(LLMConversationClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive_messages(messages: {
                                                 messages: [
                                                   { role: "User", text: "Hello" }
                                                 ],
                                                 progress: nil
                                               },
                                               continue_conversation: {
                                                 conversation_id: "llm-conv-id",
                                                 messages: [
                                                   { role: "User", text: "Hello" },
                                                   { role: "User", text: "How are you?" },
                                                   { role: "Assistant", text: "I'm doing well!" }
                                                 ],
                                                 progress: {
                                                   current: 1,
                                                   total: 2,
                                                   percentage: 50,
                                                   objectives: [
                                                     { objective: "Objective 1", status: "covered" },
                                                     { objective: "Objective 2", status: "" }
                                                   ]
                                                 }
                                               })

        post :post_message,
             params: {
               course_id: @course.id,
               ai_experience_id: @ai_experience.id,
               id: @conversation.id,
               message: "How are you?"
             },
             format: :json

        expect(response).to be_successful
        json_response = json_parse(response.body)
        expect(json_response["id"]).to eq(@conversation.id)
        expect(json_response["messages"]).to be_an(Array)
        expect(json_response["messages"].length).to eq(3)
        expect(json_response["conversation_id"]).to be_nil # Should not expose LLM conversation ID
        expect(json_response["progress"]).to be_present
        expect(json_response["progress"]["percentage"]).to eq(50)
      end

      it "returns bad request when message is missing" do
        post :post_message,
             params: { course_id: @course.id, ai_experience_id: @ai_experience.id, id: @conversation.id },
             format: :json

        expect(response).to have_http_status(:bad_request)
        json_response = json_parse(response.body)
        expect(json_response["error"]).to eq("message is required")
      end

      it "returns service unavailable on conversation error" do
        mock_client = instance_double(LLMConversationClient)
        allow(LLMConversationClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:messages)
          .and_raise(LlmConversation::Errors::ConversationError, "Failed to send")

        post :post_message,
             params: {
               course_id: @course.id,
               ai_experience_id: @ai_experience.id,
               id: @conversation.id,
               message: "Test"
             },
             format: :json

        expect(response).to have_http_status(:service_unavailable)
      end
    end

    context "as student" do
      before do
        user_session(@student)
        @student_conversation = @ai_experience.ai_conversations.create!(
          llm_conversation_id: "student-llm-conv-id",
          user: @student,
          course: @course,
          root_account: @course.root_account,
          account: @course.account,
          workflow_state: "active"
        )
      end

      it "allows students to post messages to their own conversations" do
        mock_client = instance_double(LLMConversationClient)
        allow(LLMConversationClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive_messages(messages: { messages: [], progress: nil },
                                               continue_conversation: {
                                                 conversation_id: "student-llm-conv-id",
                                                 messages: [],
                                                 progress: nil
                                               })

        post :post_message,
             params: {
               course_id: @course.id,
               ai_experience_id: @ai_experience.id,
               id: @student_conversation.id,
               message: "Test"
             },
             format: :json

        expect(response).to be_successful
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @conversation = @ai_experience.ai_conversations.create!(
        llm_conversation_id: "llm-conv-id",
        user: @teacher,
        course: @course,
        root_account: @course.root_account,
        account: @course.account,
        workflow_state: "active"
      )
    end

    context "as teacher" do
      before { user_session(@teacher) }

      it "marks the conversation as completed" do
        delete :destroy,
               params: { course_id: @course.id, ai_experience_id: @ai_experience.id, id: @conversation.id },
               format: :json

        expect(response).to be_successful
        json_response = json_parse(response.body)
        expect(json_response["message"]).to eq("Conversation completed successfully")

        @conversation.reload
        expect(@conversation.workflow_state).to eq("completed")
      end
    end

    context "as student" do
      before do
        user_session(@student)
        @student_conversation = @ai_experience.ai_conversations.create!(
          llm_conversation_id: "student-llm-conv-id",
          user: @student,
          course: @course,
          root_account: @course.root_account,
          account: @course.account,
          workflow_state: "active"
        )
      end

      it "allows students to delete their own conversations" do
        delete :destroy,
               params: { course_id: @course.id, ai_experience_id: @ai_experience.id, id: @student_conversation.id },
               format: :json

        expect(response).to be_successful
      end
    end
  end

  describe "ai_experiences feature flag" do
    context "when feature flag is disabled" do
      before do
        @course.root_account.disable_feature!(:ai_experiences)
      end

      context "as teacher" do
        before { user_session(@teacher) }

        it "returns 404 for create" do
          post :create,
               params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
               format: :json

          expect(response).to have_http_status(:not_found)
        end

        it "renders proper 404 template for HTML requests" do
          post :create,
               params: { course_id: @course.id, ai_experience_id: @ai_experience.id }

          expect(response).to have_http_status(:not_found)
          expect(response).to render_template("shared/errors/404_message")
        end

        it "returns JSON error for JSON requests" do
          post :create,
               params: { course_id: @course.id, ai_experience_id: @ai_experience.id },
               format: :json

          expect(response).to have_http_status(:not_found)
          json_response = json_parse(response.body)
          expect(json_response["error"]).to eq("Resource Not Found")
        end
      end
    end
  end
end
