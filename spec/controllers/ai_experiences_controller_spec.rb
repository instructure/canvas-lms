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
        json_response = json_parse(response.body)
        experiences = json_response["experiences"]
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
        json_response = json_parse(response.body)
        experiences = json_response["experiences"]
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

      it "returns can_manage true for teachers" do
        get :index, params: { course_id: @course.id }, format: :json
        json_response = json_parse(response.body)
        expect(json_response["can_manage"]).to be true
      end

      it "does not include submission_status for teachers" do
        get :index, params: { course_id: @course.id }, format: :json
        json_response = json_parse(response.body)
        experiences = json_response["experiences"]

        experiences.each do |exp|
          expect(exp).not_to have_key("submission_status")
        end
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns http success" do
        get :index, params: { course_id: @course.id }, format: :json
        expect(response).to be_successful
      end

      it "returns only published experiences for students" do
        unpublished_experience = @course.ai_experiences.create!(
          title: "Unpublished Experience",
          facts: "Test prompt",
          learning_objective: "Test objective",
          pedagogical_guidance: "Test pedagogical guidance",
          workflow_state: "unpublished"
        )
        published_experience = @course.ai_experiences.create!(
          title: "Published Experience",
          facts: "Test prompt",
          learning_objective: "Test objective",
          pedagogical_guidance: "Test pedagogical guidance",
          workflow_state: "published"
        )

        get :index, params: { course_id: @course.id }, format: :json
        json_response = json_parse(response.body)
        experiences = json_response["experiences"]
        experience_ids = experiences.pluck("id")
        expect(experience_ids).to include(published_experience.id)
        expect(experience_ids).not_to include(unpublished_experience.id)
      end

      it "returns can_manage false for students" do
        get :index, params: { course_id: @course.id }, format: :json
        json_response = json_parse(response.body)
        expect(json_response["can_manage"]).to be false
      end

      context "with submission status" do
        it "includes submission_status as not_started when no conversation exists" do
          published_experience = @course.ai_experiences.create!(
            title: "Published Experience",
            facts: "Test prompt",
            learning_objective: "Test objective",
            pedagogical_guidance: "Test guidance",
            workflow_state: "published"
          )

          get :index, params: { course_id: @course.id }, format: :json
          json_response = json_parse(response.body)
          experiences = json_response["experiences"]

          experience = experiences.find { |e| e["id"] == published_experience.id }
          expect(experience["submission_status"]).to eq("not_started")
        end

        it "includes submission_status as in_progress when active conversation exists" do
          published_experience = @course.ai_experiences.create!(
            title: "Published Experience",
            facts: "Test prompt",
            learning_objective: "Test objective",
            pedagogical_guidance: "Test guidance",
            workflow_state: "published"
          )

          # Create an active conversation for the student
          published_experience.ai_conversations.create!(
            llm_conversation_id: "test-conversation-id",
            user: @student,
            course: @course,
            root_account: @course.root_account,
            account: @course.account,
            workflow_state: "active"
          )

          get :index, params: { course_id: @course.id }, format: :json
          json_response = json_parse(response.body)
          experiences = json_response["experiences"]

          experience = experiences.find { |e| e["id"] == published_experience.id }
          expect(experience["submission_status"]).to eq("in_progress")
        end

        it "includes submission_status as submitted when completed conversation exists" do
          published_experience = @course.ai_experiences.create!(
            title: "Published Experience",
            facts: "Test prompt",
            learning_objective: "Test objective",
            pedagogical_guidance: "Test guidance",
            workflow_state: "published"
          )

          # Create a completed conversation for the student
          published_experience.ai_conversations.create!(
            llm_conversation_id: "test-conversation-id",
            user: @student,
            course: @course,
            root_account: @course.root_account,
            account: @course.account,
            workflow_state: "completed"
          )

          get :index, params: { course_id: @course.id }, format: :json
          json_response = json_parse(response.body)
          experiences = json_response["experiences"]

          experience = experiences.find { |e| e["id"] == published_experience.id }
          expect(experience["submission_status"]).to eq("submitted")
        end

        it "uses the latest conversation when multiple exist" do
          published_experience = @course.ai_experiences.create!(
            title: "Published Experience",
            facts: "Test prompt",
            learning_objective: "Test objective",
            pedagogical_guidance: "Test guidance",
            workflow_state: "published"
          )

          # Create an older completed conversation
          published_experience.ai_conversations.create!(
            llm_conversation_id: "old-conversation-id",
            user: @student,
            course: @course,
            root_account: @course.root_account,
            account: @course.account,
            workflow_state: "completed",
            created_at: 2.days.ago,
            updated_at: 2.days.ago
          )

          # Create a newer active conversation
          published_experience.ai_conversations.create!(
            llm_conversation_id: "new-conversation-id",
            user: @student,
            course: @course,
            root_account: @course.root_account,
            account: @course.account,
            workflow_state: "active",
            created_at: 1.day.ago,
            updated_at: 1.day.ago
          )

          get :index, params: { course_id: @course.id }, format: :json
          json_response = json_parse(response.body)
          experiences = json_response["experiences"]

          experience = experiences.find { |e| e["id"] == published_experience.id }
          # Should use the newer active conversation
          expect(experience["submission_status"]).to eq("in_progress")
        end

        it "ignores deleted conversations" do
          published_experience = @course.ai_experiences.create!(
            title: "Published Experience",
            facts: "Test prompt",
            learning_objective: "Test objective",
            pedagogical_guidance: "Test guidance",
            workflow_state: "published"
          )

          # Create a deleted conversation
          published_experience.ai_conversations.create!(
            llm_conversation_id: "deleted-conversation-id",
            user: @student,
            course: @course,
            root_account: @course.root_account,
            account: @course.account,
            workflow_state: "deleted"
          )

          get :index, params: { course_id: @course.id }, format: :json
          json_response = json_parse(response.body)
          experiences = json_response["experiences"]

          experience = experiences.find { |e| e["id"] == published_experience.id }
          # Should show not_started since deleted conversations are ignored
          expect(experience["submission_status"]).to eq("not_started")
        end
      end
    end

    context "as teacher from different course" do
      before do
        @original_course = @course
        @original_teacher = @teacher
        course_with_teacher(active_all: true, user: user_factory, course_name: "Other Course")
        @other_teacher = @teacher
        @other_course = @course
        @course = @original_course
        @teacher = @original_teacher
        user_session(@other_teacher)
      end

      it "returns forbidden for teachers not enrolled in this course" do
        get :index, params: { course_id: @course.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as unenrolled user" do
      before :once do
        @unenrolled_user = user_factory(active_all: true)
      end

      before { user_session(@unenrolled_user) }

      it "returns forbidden for unenrolled users" do
        get :index, params: { course_id: @course.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "renders unauthorized page for HTML requests" do
        get :index, params: { course_id: @course.id }
        expect(response).to have_http_status(:unauthorized)
        expect(response).to render_template("shared/unauthorized")
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

      it "returns can_manage true in JSON response" do
        get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        json_response = json_parse(response.body)
        expect(json_response["can_manage"]).to be true
      end

      it "sets the active tab and page title" do
        get :show, params: { course_id: @course.id, id: @ai_experience.id }
        expect(assigns(:active_tab)).to eq("ai_experiences")
        expect(assigns(:page_title)).to eq(@ai_experience.title)
      end
    end

    context "as student" do
      before { user_session(@student) }

      it "returns success for published experiences" do
        @ai_experience.update!(workflow_state: "published")
        get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        expect(response).to be_successful
      end

      it "returns can_manage false in JSON response" do
        @ai_experience.update!(workflow_state: "published")
        get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        json_response = json_parse(response.body)
        expect(json_response["can_manage"]).to be false
      end

      it "returns forbidden for unpublished experiences" do
        @ai_experience.update!(workflow_state: "unpublished")
        get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "renders unauthorized page for unpublished experiences in HTML format" do
        @ai_experience.update!(workflow_state: "unpublished")
        get :show, params: { course_id: @course.id, id: @ai_experience.id }
        expect(response).to have_http_status(:unauthorized)
        expect(response).to render_template("shared/unauthorized")
      end
    end

    context "as teacher from different course" do
      before do
        @original_course = @course
        @original_teacher = @teacher
        course_with_teacher(active_all: true, user: user_factory, course_name: "Other Course")
        @other_teacher = @teacher
        @other_course = @course
        @course = @original_course
        @teacher = @original_teacher
        user_session(@other_teacher)
      end

      it "returns forbidden for teachers not enrolled in this course" do
        @ai_experience.update!(workflow_state: "published")
        get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as unenrolled user" do
      before :once do
        @unenrolled_user = user_factory(active_all: true)
      end

      before { user_session(@unenrolled_user) }

      it "returns forbidden for published experiences when unenrolled" do
        @ai_experience.update!(workflow_state: "published")
        get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "returns forbidden for unpublished experiences when unenrolled" do
        @ai_experience.update!(workflow_state: "unpublished")
        get :show, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST #create" do
    context "as teacher from different course" do
      before do
        @original_course = @course
        @original_teacher = @teacher
        course_with_teacher(active_all: true, user: user_factory, course_name: "Other Course")
        @other_teacher = @teacher
        @other_course = @course
        @course = @original_course
        @teacher = @original_teacher
        user_session(@other_teacher)
      end

      it "returns forbidden for teachers not enrolled in this course" do
        post :create,
             params: {
               course_id: @course.id,
               ai_experience: {
                 title: "New Experience",
                 learning_objective: "Test objective",
                 pedagogical_guidance: "Test guidance"
               }
             },
             format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

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
    context "as teacher from different course" do
      before do
        @original_course = @course
        @original_teacher = @teacher
        course_with_teacher(active_all: true, user: user_factory, course_name: "Other Course")
        @other_teacher = @teacher
        @other_course = @course
        @course = @original_course
        @teacher = @original_teacher
        user_session(@other_teacher)
      end

      it "returns forbidden for teachers not enrolled in this course" do
        put :update,
            params: {
              course_id: @course.id,
              id: @ai_experience.id,
              ai_experience: { title: "Updated Title" }
            },
            format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

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
    context "as teacher from different course" do
      before do
        @original_course = @course
        @original_teacher = @teacher
        course_with_teacher(active_all: true, user: user_factory, course_name: "Other Course")
        @other_teacher = @teacher
        @other_course = @course
        @course = @original_course
        @teacher = @original_teacher
        user_session(@other_teacher)
      end

      it "returns forbidden for teachers not enrolled in this course" do
        delete :destroy,
               params: { course_id: @course.id, id: @ai_experience.id },
               format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

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

  describe "GET #ai_conversations_index" do
    before :once do
      @student1 = @student
      @student2 = student_in_course(active_all: true, course: @course).user
      @student3 = student_in_course(active_all: true, course: @course).user

      # Create conversations for students
      @conversation1 = @ai_experience.ai_conversations.create!(
        llm_conversation_id: "conv-student1",
        user: @student1,
        course: @course,
        root_account: @course.root_account,
        account: @course.account,
        workflow_state: "active"
      )

      @conversation2 = @ai_experience.ai_conversations.create!(
        llm_conversation_id: "conv-student2",
        user: @student2,
        course: @course,
        root_account: @course.root_account,
        account: @course.account,
        workflow_state: "completed"
      )

      # Student 3 has no conversation
    end

    context "as teacher" do
      before { user_session(@teacher) }

      it "returns all students including those without conversations" do
        get :ai_conversations_index, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        expect(response).to be_successful

        json_response = json_parse(response.body)
        conversations = json_response["conversations"]
        expect(conversations.length).to eq(3) # All 3 students

        # Check that students with conversations have IDs
        students_with_convs = conversations.select { |c| c["id"].present? }
        expect(students_with_convs.length).to eq(2)

        conversation_ids = students_with_convs.pluck("id")
        expect(conversation_ids).to include(@conversation1.id, @conversation2.id)

        # Check that student without conversation is included with nil ID
        student_without_conv = conversations.find { |c| c["user_id"] == @student3.id.to_s }
        expect(student_without_conv).to be_present
        expect(student_without_conv["id"]).to be_nil
        expect(student_without_conv["has_conversation"]).to be(false)
      end

      it "includes student information in each conversation" do
        get :ai_conversations_index, params: { course_id: @course.id, id: @ai_experience.id }, format: :json

        json_response = json_parse(response.body)
        conversations = json_response["conversations"]

        conversations.each do |conv|
          expect(conv).to have_key("student")
          expect(conv["student"]).to have_key("id")
          expect(conv["student"]).to have_key("name")
        end
      end

      it "excludes deleted conversations but includes student without conversation" do
        @conversation1.update_column(:workflow_state, "deleted")

        get :ai_conversations_index, params: { course_id: @course.id, id: @ai_experience.id }, format: :json

        json_response = json_parse(response.body)
        conversations = json_response["conversations"]
        expect(conversations.length).to eq(3) # All 3 students

        # Only conversation2 should have an ID
        students_with_convs = conversations.select { |c| c["id"].present? }
        expect(students_with_convs.length).to eq(1)
        expect(students_with_convs.first["id"]).to eq(@conversation2.id)

        # Student1 should now appear without conversation (since theirs was deleted)
        student1_entry = conversations.find { |c| c["user_id"] == @student1.id.to_s }
        expect(student1_entry["id"]).to be_nil
        expect(student1_entry["has_conversation"]).to be(false)
      end

      it "returns the latest conversation for each student" do
        # Create an older conversation for student1
        @ai_experience.ai_conversations.create!(
          llm_conversation_id: "conv-student1-old",
          user: @student1,
          course: @course,
          root_account: @course.root_account,
          account: @course.account,
          workflow_state: "completed",
          created_at: 2.days.ago,
          updated_at: 2.days.ago
        )

        get :ai_conversations_index, params: { course_id: @course.id, id: @ai_experience.id }, format: :json

        json_response = json_parse(response.body)
        conversations = json_response["conversations"]

        student1_conversations = conversations.select { |c| c["user_id"] == @student1.id }
        expect(student1_conversations.length).to eq(1)
        expect(student1_conversations.first["id"]).to eq(@conversation1.id)
      end
    end

    context "as student" do
      before { user_session(@student1) }

      it "returns unauthorized" do
        get :ai_conversations_index, params: { course_id: @course.id, id: @ai_experience.id }, format: :json
        assert_forbidden
      end
    end

    context "with invalid experience" do
      before { user_session(@teacher) }

      it "returns 404 for non-existent experience" do
        get :ai_conversations_index, params: { course_id: @course.id, id: 99_999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #ai_conversation_show" do
    before :once do
      @student1 = @student
      @conversation = @ai_experience.ai_conversations.create!(
        llm_conversation_id: "conv-123",
        user: @student1,
        course: @course,
        root_account: @course.root_account,
        account: @course.account,
        workflow_state: "active"
      )
    end

    context "as teacher" do
      before do
        user_session(@teacher)
        # Mock the LLM client
        allow_any_instance_of(LLMConversationClient).to receive(:messages_with_conversation_progress).and_return({
                                                                                                                   messages: [
                                                                                                                     { role: "assistant", content: "Hello!" },
                                                                                                                     { role: "user", content: "Hi there!" }
                                                                                                                   ],
                                                                                                                   progress: { status: "in_progress" }
                                                                                                                 })
      end

      it "returns conversation with messages" do
        get :ai_conversation_show, params: { course_id: @course.id, id: @ai_experience.id, conversation_id: @conversation.id }, format: :json
        expect(response).to be_successful

        json_response = json_parse(response.body)
        expect(json_response["id"]).to eq(@conversation.id)
        expect(json_response).to have_key("messages")
        expect(json_response["messages"].length).to eq(2)
      end

      it "includes student information" do
        get :ai_conversation_show, params: { course_id: @course.id, id: @ai_experience.id, conversation_id: @conversation.id }, format: :json

        json_response = json_parse(response.body)
        expect(json_response).to have_key("student")
        expect(json_response["student"]["id"]).to eq(@student1.id)
      end

      it "includes progress information" do
        get :ai_conversation_show, params: { course_id: @course.id, id: @ai_experience.id, conversation_id: @conversation.id }, format: :json

        json_response = json_parse(response.body)
        expect(json_response).to have_key("progress")
        expect(json_response["progress"]["status"]).to eq("in_progress")
      end

      it "returns 404 for conversation from different experience" do
        other_experience = @course.ai_experiences.create!(
          title: "Other Experience",
          learning_objective: "Test",
          pedagogical_guidance: "Test"
        )

        get :ai_conversation_show, params: { course_id: @course.id, id: other_experience.id, conversation_id: @conversation.id }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for non-existent conversation" do
        get :ai_conversation_show, params: { course_id: @course.id, id: @ai_experience.id, conversation_id: 99_999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it "returns service unavailable when LLM service fails" do
        allow_any_instance_of(LLMConversationClient).to receive(:messages_with_conversation_progress)
          .and_raise(LlmConversation::Errors::ConversationError.new("Service unavailable"))

        get :ai_conversation_show, params: { course_id: @course.id, id: @ai_experience.id, conversation_id: @conversation.id }, format: :json
        expect(response).to have_http_status(:service_unavailable)

        json_response = json_parse(response.body)
        expect(json_response["error"]).to include("Service unavailable")
      end
    end

    context "as student" do
      before { user_session(@student1) }

      it "returns unauthorized" do
        get :ai_conversation_show, params: { course_id: @course.id, id: @ai_experience.id, conversation_id: @conversation.id }, format: :json
        assert_forbidden
      end
    end
  end
end
