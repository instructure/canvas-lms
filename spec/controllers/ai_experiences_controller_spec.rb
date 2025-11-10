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
      pedagogical_guidance: "A customer calls about incorrect billing"
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
          learning_objective: "Test objective",
          pedagogical_guidance: "Test pedagogical guidance",
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
          learning_objective: "Test objective",
          pedagogical_guidance: "Test pedagogical guidance",
          workflow_state: "published"
        )

        get :index, params: { course_id: @course.id, workflow_state: "published" }, format: :json
        experiences = json_parse(response.body)
        expect(experiences.length).to eq 1
        expect(experiences.first["id"]).to eq published_experience.id
      end

      it "sets COURSE_ID in js_env and page title for HTML format" do
        get :index, params: { course_id: @course.id }
        expect(assigns[:js_env][:COURSE_ID]).to eq(@course.id)
        expect(assigns(:page_title)).to eq("AI Experiences")
      end

      it "sets the active tab" do
        get :index, params: { course_id: @course.id }
        expect(assigns(:active_tab)).to eq("ai_experiences")
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns forbidden" do
        get :index, params: { course_id: @course.id }, format: :json
        assert_forbidden
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

      it "sets the active tab and page title" do
        get :show, params: { course_id: @course.id, id: @ai_experience.id }
        expect(assigns(:active_tab)).to eq("ai_experiences")
        expect(assigns(:page_title)).to eq(@ai_experience.title)
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns forbidden" do
        get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        assert_forbidden
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
          pedagogical_guidance: "Test pedagogical guidance"
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
        expect(created_experience.pedagogical_guidance).to eq("Test pedagogical guidance")
      end

      it "returns bad request with invalid params" do
        invalid_params = {
          title: "", # title is required
          learning_objective: "", # learning_objective is required
          pedagogical_guidance: "" # pedagogical_guidance is required
        }

        initial_count = AiExperience.count
        post :create, params: { course_id: @course.id, ai_experience: invalid_params }, format: :json
        expect(AiExperience.count).to eq(initial_count)

        expect(response).to have_http_status(:bad_request)
      end

      it "creates a new AI experience without facts (facts is optional)" do
        experience_params = {
          title: "New Experience Without Facts",
          learning_objective: "Test objective",
          pedagogical_guidance: "Test pedagogical guidance"
        }

        initial_count = AiExperience.count
        post :create, params: { course_id: @course.id, ai_experience: experience_params }, format: :json
        expect(AiExperience.count).to eq(initial_count + 1)

        expect(response).to have_http_status(:created)

        created_experience = AiExperience.last
        expect(created_experience.title).to eq("New Experience Without Facts")
        expect(created_experience.facts).to be_nil
        expect(created_experience.learning_objective).to eq("Test objective")
        expect(created_experience.pedagogical_guidance).to eq("Test pedagogical guidance")
      end

      it "sets the correct associations for course, account, and root_account" do
        experience_params = {
          title: "New Experience",
          learning_objective: "Test objective",
          pedagogical_guidance: "Test pedagogical guidance"
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
          learning_objective: "Test objective",
          pedagogical_guidance: "Test pedagogical guidance"
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
          pedagogical_guidance: "Updated pedagogical guidance"
        }

        put :update, params: { course_id: @course.id, id: @ai_experience.id, ai_experience: update_params }, format: :json

        expect(response).to have_http_status(:ok)

        @ai_experience.reload
        expect(@ai_experience.title).to eq("Updated Experience")
        expect(@ai_experience.description).to eq("Updated description")
        expect(@ai_experience.facts).to eq("Updated prompt")
        expect(@ai_experience.learning_objective).to eq("Updated objective")
        expect(@ai_experience.pedagogical_guidance).to eq("Updated pedagogical guidance")
      end

      it "returns bad request with invalid params" do
        invalid_params = {
          title: "", # title is required
          learning_objective: "", # learning_objective is required
          pedagogical_guidance: "" # pedagogical_guidance is required
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

      it "sets COURSE_ID in js_env and page title" do
        get :new, params: { course_id: @course.id }
        expect(assigns[:js_env][:COURSE_ID]).to eq(@course.id)
        expect(assigns(:page_title)).to eq("New AI Experience")
      end

      it "sets the active tab" do
        get :new, params: { course_id: @course.id }
        expect(assigns(:active_tab)).to eq("ai_experiences")
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns unauthorized" do
        get :new, params: { course_id: @course.id }
        assert_unauthorized
      end
    end
  end

  describe "GET #edit" do
    context "as teacher" do
      before { user_session(@teacher) }

      it "sets COURSE_ID and AI_EXPERIENCE_ID in js_env and page title" do
        get :edit, params: { course_id: @course.id, id: @ai_experience.id }
        expect(assigns[:js_env][:COURSE_ID]).to eq(@course.id)
        expect(assigns[:js_env][:AI_EXPERIENCE_ID]).to eq(@ai_experience.id.to_s)
        expect(assigns(:page_title)).to eq("Edit #{@ai_experience.title}")
      end

      it "sets the active tab" do
        get :edit, params: { course_id: @course.id, id: @ai_experience.id }
        expect(assigns(:active_tab)).to eq("ai_experiences")
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns unauthorized" do
        get :edit, params: { course_id: @course.id, id: @ai_experience.id }
        assert_unauthorized
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
          post :create, params: { course_id: @course.id, ai_experience: { title: "Test", facts: "Test", learning_objective: "Test", pedagogical_guidance: "Test" } }, format: :json
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

        it "renders proper 404 template for HTML requests" do
          get :index, params: { course_id: @course.id }
          expect(response).to have_http_status(:not_found)
          expect(response).to render_template("shared/errors/404_message")
        end

        it "returns JSON error for JSON requests" do
          get :index, params: { course_id: @course.id }, format: :json
          expect(response).to have_http_status(:not_found)
          json_response = json_parse(response.body)
          expect(json_response["error"]).to eq("Resource Not Found")
        end
      end
    end
  end
end
