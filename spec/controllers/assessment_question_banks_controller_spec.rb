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

describe AssessmentQuestionBanksController do
  describe "GET #show" do
    context "with a course-level question bank" do
      before :once do
        course_with_teacher(active_all: true)
        @bank = @course.assessment_question_banks.create!(title: "Test Bank")
        3.times { @bank.assessment_questions.create! }
      end

      it "requires authorization" do
        get :show, params: { id: @bank.id }, format: :json
        assert_unauthorized
      end

      it "returns the question bank as JSON" do
        user_session(@teacher)
        get :show, params: { id: @bank.id }, format: :json
        expect(response).to be_successful

        json = json_parse(response.body)
        expect(json["id"]).to eq(@bank.id)
        expect(json["context_id"]).to eq(@course.id)
        expect(json["context_type"]).to eq("Course")
        expect(json["title"]).to eq("Test Bank")
        expect(json["workflow_state"]).to eq("active")
        expect(json["context_code"]).to eq("course_#{@course.id}")
      end

      it "includes question count when requested" do
        user_session(@teacher)
        get :show, params: { id: @bank.id, include_question_count: true }, format: :json
        expect(response).to be_successful

        json = json_parse(response.body)
        expect(json["assessment_question_count"]).to eq(3)
      end

      it "denies access for students" do
        student_in_course(active_all: true)
        user_session(@student)
        get :show, params: { id: @bank.id }, format: :json
        expect(response).to be_forbidden
      end
    end

    context "with an account-level question bank" do
      before :once do
        @admin = account_admin_user(active_all: true)
        @account = @admin.account
        @bank = @account.assessment_question_banks.create!(title: "Account Bank")
      end

      it "returns the account question bank as JSON" do
        user_session(@admin)
        get :show, params: { id: @bank.id }, format: :json
        expect(response).to be_successful

        json = json_parse(response.body)
        expect(json["id"]).to eq(@bank.id)
        expect(json["context_id"]).to eq(@account.id)
        expect(json["context_type"]).to eq("Account")
        expect(json["title"]).to eq("Account Bank")
        expect(json["context_code"]).to eq("account_#{@account.id}")
      end

      it "denies access for non-admin users" do
        course_with_teacher(active_all: true, account: @account)
        user_session(@teacher)
        get :show, params: { id: @bank.id }, format: :json
        expect(response).to be_forbidden
      end
    end

    context "with a deleted question bank" do
      before :once do
        course_with_teacher(active_all: true)
        @bank = @course.assessment_question_banks.create!(title: "Deleted Bank")
        @bank.destroy
      end

      it "still returns the bank if user has access" do
        user_session(@teacher)
        get :show, params: { id: @bank.id }, format: :json
        expect(response).to be_successful

        json = json_parse(response.body)
        expect(json["workflow_state"]).to eq("deleted")
      end
    end
  end

  describe "GET #index" do
    context "with a course context" do
      before :once do
        course_with_teacher(active_all: true)
        @bank1 = @course.assessment_question_banks.create!(title: "Bank 1")
        @bank2 = @course.assessment_question_banks.create!(title: "Bank 2")
        3.times { @bank1.assessment_questions.create! }
        5.times { @bank2.assessment_questions.create! }
      end

      it "requires authorization" do
        get :index, params: { context_type: "Course", context_id: @course.id }, format: :json
        assert_unauthorized
      end

      it "returns the list of question banks as JSON" do
        user_session(@teacher)
        get :index, params: { context_type: "Course", context_id: @course.id }, format: :json
        expect(response).to be_successful

        json = json_parse(response.body)
        expect(json).to be_an(Array)
        expect(json.length).to eq(2)

        bank_titles = json.pluck("title")
        expect(bank_titles).to contain_exactly("Bank 1", "Bank 2")

        expect(json.first["context_type"]).to eq("Course")
        expect(json.first["context_id"]).to eq(@course.id)
      end

      it "includes question count when requested" do
        user_session(@teacher)
        get :index, params: { context_type: "Course", context_id: @course.id, include_question_count: true }, format: :json
        expect(response).to be_successful

        json = json_parse(response.body)
        bank1_json = json.find { |b| b["title"] == "Bank 1" }
        bank2_json = json.find { |b| b["title"] == "Bank 2" }

        expect(bank1_json["assessment_question_count"]).to eq(3)
        expect(bank2_json["assessment_question_count"]).to eq(5)
      end

      it "only returns active banks" do
        @bank2.destroy
        user_session(@teacher)
        get :index, params: { context_type: "Course", context_id: @course.id }, format: :json
        expect(response).to be_successful

        json = json_parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first["title"]).to eq("Bank 1")
      end

      it "denies access for students" do
        student_in_course(active_all: true)
        user_session(@student)
        get :index, params: { context_type: "Course", context_id: @course.id }, format: :json
        expect(response).to be_forbidden
      end
    end

    context "with an account context" do
      before :once do
        @admin = account_admin_user(active_all: true)
        @account = @admin.account
        @bank1 = @account.assessment_question_banks.create!(title: "Account Bank 1")
        @bank2 = @account.assessment_question_banks.create!(title: "Account Bank 2")
      end

      it "returns the list of account question banks as JSON" do
        user_session(@admin)
        get :index, params: { context_type: "Account", context_id: @account.id }, format: :json
        expect(response).to be_successful

        json = json_parse(response.body)
        expect(json).to be_an(Array)
        expect(json.length).to eq(2)

        bank_titles = json.pluck("title")
        expect(bank_titles).to contain_exactly("Account Bank 1", "Account Bank 2")

        expect(json.first["context_type"]).to eq("Account")
        expect(json.first["context_id"]).to eq(@account.id)
      end

      it "denies access for non-admin users" do
        course_with_teacher(active_all: true, account: @account)
        user_session(@teacher)
        get :index, params: { context_type: "Account", context_id: @account.id }, format: :json
        expect(response).to be_forbidden
      end
    end

    context "with invalid parameters" do
      before :once do
        course_with_teacher(active_all: true)
      end

      it "returns 400 when context_type is missing" do
        user_session(@teacher)
        get :index, params: { context_id: @course.id }, format: :json
        expect(response).to have_http_status(:bad_request)

        json = json_parse(response.body)
        expect(json["errors"]).to eq("context_type and context_id are required")
      end

      it "returns 400 when context_id is missing" do
        user_session(@teacher)
        get :index, params: { context_type: "Course" }, format: :json
        expect(response).to have_http_status(:bad_request)

        json = json_parse(response.body)
        expect(json["errors"]).to eq("context_type and context_id are required")
      end

      it "returns 400 when context_type is invalid" do
        user_session(@teacher)
        get :index, params: { context_type: "User", context_id: @teacher.id }, format: :json
        expect(response).to have_http_status(:bad_request)

        json = json_parse(response.body)
        expect(json["errors"]).to eq("context_type must be 'Course' or 'Account'")
      end

      it "returns forbidden when context_id does not exist" do
        user_session(@teacher)
        get :index, params: { context_type: "Course", context_id: 99_999 }, format: :json
        expect(response).to be_forbidden
      end
    end
  end
end
