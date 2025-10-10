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

describe AiExperiencesController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @course.root_account.enable_feature!(:ai_experiences)
    @ai_experience = @course.ai_experiences.create!(
      title: "Customer Service Training",
      description: "Practice customer service scenarios",
      facts: "You are a customer service representative helping customers with billing issues.",
      learning_objective: "Students will learn to handle customer complaints professionally",
      scenario: "A customer calls about incorrect billing"
    )
  end

  describe "GET #index" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "returns http success" do
        get :index, params: { course_id: @course.id }, format: :json
        expect(response).to be_successful
      end

      it "returns all experiences for teachers" do
        published_experience = @course.ai_experiences.create!(
          title: "Published Experience",
          facts: "Test prompt",
          workflow_state: "published"
        )

        get :index, params: { course_id: @course.id }, format: :json
        experiences = json_parse(response.body)
        expect(experiences.length).to eq 2
        experience_ids = experiences.pluck("id")
        expect(experience_ids).to include(@ai_experience.id)
        expect(experience_ids).to include(published_experience.id)
      end

      it "filters by workflow_state" do
        published_experience = @course.ai_experiences.create!(
          title: "Published Experience",
          facts: "Test prompt",
          workflow_state: "published"
        )

        get :index, params: { course_id: @course.id, workflow_state: "published" }, format: :json
        experiences = json_parse(response.body)
        expect(experiences.length).to eq 1
        expect(experiences.first["id"]).to eq published_experience.id
      end

      it "sets COURSE_ID in js_env for HTML format" do
        get :index, params: { course_id: @course.id }
        expect(assigns[:js_env][:COURSE_ID]).to eq(@course.id)
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns http success" do
        get :index, params: { course_id: @course.id }, format: :json
        expect(response).to be_successful
      end

      it "returns published experiences" do
        @ai_experience.publish!
        get :index, params: { course_id: @course.id }, format: :json
        expect(response).to be_successful
        experiences = json_parse(response.body)
        expect(experiences.length).to eq 1
        expect(experiences.first["id"]).to eq @ai_experience.id
      end

      it "filters by workflow_state" do
        @ai_experience.publish!
        @course.ai_experiences.create!(
          title: "Unpublished Experience",
          facts: "Test prompt"
        )

        get :index, params: { course_id: @course.id, workflow_state: "published" }, format: :json
        experiences = json_parse(response.body)
        expect(experiences.length).to eq 1
        expect(experiences.first["id"]).to eq @ai_experience.id
      end

      it "returns unauthorized for other courses" do
        other_course = course_factory
        get :index, params: { course_id: other_course.id }
        assert_unauthorized
      end
    end
  end

  describe "GET #show" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "returns success for HTML format" do
        get :show, params: { course_id: @course.id, id: @ai_experience.id }
        expect(response).to be_successful
      end

      it "returns JSON for JSON format" do
        get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        expect(response).to be_successful
        experience = json_parse(response.body)
        expect(experience["id"]).to eq(@ai_experience.id)
        expect(experience["title"]).to eq(@ai_experience.title)
      end

      it "sets the active tab" do
        get :show, params: { course_id: @course.id, id: @ai_experience.id }
        expect(assigns(:active_tab)).to eq("ai_experiences")
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns success for HTML format" do
        get :show, params: { course_id: @course.id, id: @ai_experience.id }
        expect(response).to be_successful
      end

      it "returns success for JSON format" do
        get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        expect(response).to be_successful
        experience = json_parse(response.body)
        expect(experience["id"]).to eq(@ai_experience.id)
        expect(experience["title"]).to eq(@ai_experience.title)
      end
    end
  end

  describe "POST #create" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "creates a new AI experience with valid params" do
        experience_params = {
          title: "New Experience",
          description: "A test experience",
          facts: "Test prompt",
          learning_objective: "Test objective",
          scenario: "Test scenario"
        }

        initial_count = AiExperience.count
        post :create, params: { course_id: @course.id, ai_experience: experience_params }, format: :json
        expect(AiExperience.count).to eq(initial_count + 1)

        expect(response).to have_http_status(:created)

        created_experience = AiExperience.last
        expect(created_experience.title).to eq("New Experience")
        expect(created_experience.description).to eq("A test experience")
        expect(created_experience.facts).to eq("Test prompt")
        expect(created_experience.learning_objective).to eq("Test objective")
        expect(created_experience.scenario).to eq("Test scenario")
      end

      it "returns bad request with invalid params" do
        invalid_params = {
          title: "", # title is required
          facts: "" # facts is required
        }

        initial_count = AiExperience.count
        post :create, params: { course_id: @course.id, ai_experience: invalid_params }, format: :json
        expect(AiExperience.count).to eq(initial_count)

        expect(response).to have_http_status(:bad_request)
      end

      it "sets the correct associations for course, account, and root_account" do
        experience_params = {
          title: "New Experience",
          facts: "Test prompt"
        }

        post :create, params: { course_id: @course.id, ai_experience: experience_params }, format: :json

        created_experience = AiExperience.last
        expect(created_experience.course).to eq(@course)
        expect(created_experience.root_account).to eq(@course.root_account)
        expect(created_experience.account).to eq(@course.account)
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns forbidden" do
        experience_params = {
          title: "New Experience",
          facts: "Test prompt"
        }

        post :create, params: { course_id: @course.id, ai_experience: experience_params }, format: :json
        assert_forbidden
      end
    end
  end

  describe "PUT #update" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "updates an AI experience with valid params" do
        update_params = {
          title: "Updated Experience",
          description: "Updated description",
          facts: "Updated prompt",
          learning_objective: "Updated objective",
          scenario: "Updated scenario"
        }

        put :update, params: { course_id: @course.id, id: @ai_experience.id, ai_experience: update_params }, format: :json

        expect(response).to have_http_status(:ok)

        @ai_experience.reload
        expect(@ai_experience.title).to eq("Updated Experience")
        expect(@ai_experience.description).to eq("Updated description")
        expect(@ai_experience.facts).to eq("Updated prompt")
        expect(@ai_experience.learning_objective).to eq("Updated objective")
        expect(@ai_experience.scenario).to eq("Updated scenario")
      end

      it "returns bad request with invalid params" do
        invalid_params = {
          title: "", # title is required
          facts: "" # facts is required
        }

        put :update, params: { course_id: @course.id, id: @ai_experience.id, ai_experience: invalid_params }, format: :json

        expect(response).to have_http_status(:bad_request)

        @ai_experience.reload
        expect(@ai_experience.title).to eq("Customer Service Training") # unchanged
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns forbidden" do
        update_params = {
          title: "Student Updated Experience"
        }

        put :update, params: { course_id: @course.id, id: @ai_experience.id, ai_experience: update_params }, format: :json
        assert_forbidden
      end
    end
  end

  describe "DELETE #destroy" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "soft deletes an AI experience" do
        delete :destroy, params: { course_id: @course.id, id: @ai_experience.id }, format: :json

        expect(response).to have_http_status(:ok)

        @ai_experience.reload
        expect(@ai_experience.workflow_state).to eq("deleted")
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns forbidden" do
        delete :destroy, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        assert_forbidden

        @ai_experience.reload
        expect(@ai_experience.workflow_state).not_to eq("deleted")
      end
    end
  end

  describe "GET #new" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "sets COURSE_ID in js_env" do
        get :new, params: { course_id: @course.id }
        expect(assigns[:js_env][:COURSE_ID]).to eq(@course.id)
      end
    end
  end

  describe "GET #edit" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "sets COURSE_ID and AI_EXPERIENCE_ID in js_env" do
        get :edit, params: { course_id: @course.id, id: @ai_experience.id }
        expect(assigns[:js_env][:COURSE_ID]).to eq(@course.id)
        expect(assigns[:js_env][:AI_EXPERIENCE_ID]).to eq(@ai_experience.id.to_s)
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

        it "returns 404 for index" do
          get :index, params: { course_id: @course.id }, format: :json
          expect(response).to have_http_status(:not_found)
        end

        it "returns 404 for show" do
          get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
          expect(response).to have_http_status(:not_found)
        end

        it "returns 404 for create" do
          post :create, params: { course_id: @course.id, ai_experience: { title: "Test", facts: "Test" } }, format: :json
          expect(response).to have_http_status(:not_found)
        end

        it "returns 404 for update" do
          put :update, params: { course_id: @course.id, id: @ai_experience.id, ai_experience: { title: "Updated" } }, format: :json
          expect(response).to have_http_status(:not_found)
        end

        it "returns 404 for destroy" do
          delete :destroy, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
          expect(response).to have_http_status(:not_found)
        end

        it "returns 404 for new" do
          get :new, params: { course_id: @course.id }, format: :json
          expect(response).to have_http_status(:not_found)
        end

        it "returns 404 for edit" do
          get :edit, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "POST #continue_conversation" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "returns starting messages when no previous messages" do
        mock_service = instance_double(LLMConversationService)
        allow(LLMConversationService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:starting_messages).and_return([
                                                                        { role: "User", text: "Hello", timestamp: Time.zone.now },
                                                                        { role: "Assistant", text: "Hi there!", timestamp: Time.zone.now }
                                                                      ])

        post :continue_conversation,
             params: { course_id: @course.id, id: @ai_experience.id },
             format: :json

        expect(response).to be_successful
        json_response = json_parse(response.body)
        expect(json_response["messages"]).to be_an(Array)
        expect(json_response["messages"].length).to eq(2)
        expect(json_response["messages"][0]["role"]).to eq("User")
        expect(json_response["messages"][1]["role"]).to eq("Assistant")
      end

      it "continues conversation with new user message" do
        mock_service = instance_double(LLMConversationService)
        allow(LLMConversationService).to receive(:new).and_return(mock_service)

        existing_messages = [
          { role: "User", text: "Hello", timestamp: Time.zone.now },
          { role: "Assistant", text: "Hi there!", timestamp: Time.zone.now }
        ]
        new_messages = existing_messages + [
          { role: "User", text: "How are you?", timestamp: Time.zone.now },
          { role: "Assistant", text: "I'm doing well!", timestamp: Time.zone.now }
        ]

        # Use hash_including to handle ActionController::Parameters
        allow(mock_service).to receive(:continue_conversation)
          .with(hash_including(new_user_message: "How are you?"))
          .and_return(new_messages)

        post :continue_conversation,
             params: {
               course_id: @course.id,
               id: @ai_experience.id,
               messages: existing_messages,
               new_user_message: "How are you?"
             },
             format: :json

        expect(response).to be_successful
        json_response = json_parse(response.body)
        expect(json_response["messages"].length).to eq(4)
      end

      it "initializes LLMConversationService with correct parameters" do
        expect(LLMConversationService).to receive(:new).with(
          current_user: @teacher,
          root_account_uuid: @course.root_account.uuid,
          facts: @ai_experience.facts,
          learning_objectives: @ai_experience.learning_objective,
          scenario: @ai_experience.scenario
        ).and_call_original

        allow_any_instance_of(LLMConversationService)
          .to receive(:starting_messages)
          .and_return([])

        post :continue_conversation,
             params: { course_id: @course.id, id: @ai_experience.id },
             format: :json
      end

      it "returns service unavailable on conversation error" do
        mock_service = instance_double(LLMConversationService)
        allow(LLMConversationService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:starting_messages)
          .and_raise(CedarAi::Errors::ConversationError, "Service unavailable")

        post :continue_conversation,
             params: { course_id: @course.id, id: @ai_experience.id },
             format: :json

        expect(response).to have_http_status(:service_unavailable)
        json_response = json_parse(response.body)
        expect(json_response["error"]).to eq("Service unavailable")
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns starting messages for students with read access" do
        mock_service = instance_double(LLMConversationService)
        allow(LLMConversationService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:starting_messages).and_return([
                                                                        { role: "User", text: "Hello", timestamp: Time.zone.now },
                                                                        { role: "Assistant", text: "Hi there!", timestamp: Time.zone.now }
                                                                      ])

        post :continue_conversation,
             params: { course_id: @course.id, id: @ai_experience.id },
             format: :json

        expect(response).to be_successful
        json_response = json_parse(response.body)
        expect(json_response["messages"]).to be_an(Array)
      end
    end
  end
end
