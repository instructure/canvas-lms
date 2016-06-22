require 'spec_helper'

RSpec.describe GradebookSettingsController, type: :controller do
  let!(:teacher) { course_with_teacher; @teacher }

  before do
    user_session(teacher)
    request.accept = "application/json"
  end

  describe "PUT update" do
    let(:json_response) { JSON.parse(response.body) }

    context "given valid params" do
      let(:show_settings) do
        {
          "show_inactive_enrollments" => "true", # values must be strings
          "show_concluded_enrollments" => "false"
        }
      end
      let(:valid_params) do
        {
          "course_id" => @course.id,
          "gradebook_settings" => show_settings
        }
      end

      it "saves new gradebook_settings in preferences" do
        put :update, valid_params
        expect(response).to be_ok

        expected_settings = { @course.id => show_settings }
        expect(teacher.preferences.fetch(:gradebook_settings, {})).to eq expected_settings
        expect(json_response["gradebook_settings"]).to eql expected_settings.as_json
      end

      it "is allowed for courses in concluded enrollment terms" do
        term = teacher.account.enrollment_terms.create!(start_at: 2.months.ago, end_at: 1.month.ago)
        @course.enrollment_term = term # `update_attribute` with a term has unwanted side effects
        @course.save!

        put :update, valid_params
        expect(response).to be_ok

        expected_settings = { @course.id => show_settings }
        expect(teacher.preferences.fetch(:gradebook_settings, {})).to eq expected_settings
        expect(json_response["gradebook_settings"]).to eql expected_settings.as_json
      end

      it "is allowed for courses with concluded workflow state" do
        @course.workflow_state = "concluded"
        @course.save!

        put :update, valid_params
        expect(response).to be_ok

        expected_settings = { @course.id => show_settings }
        expect(teacher.preferences.fetch(:gradebook_settings, {})).to eq expected_settings
        expect(json_response["gradebook_settings"]).to eql expected_settings.as_json
      end
    end

    context "given invalid params" do
      it "give an error response" do
        invalid_params = { "course_id" => @course.id }
        put :update, invalid_params

        expect(response).not_to be_ok
        expect(json_response).to include(
          "errors" => [{
            "message" => "gradebook_settings is missing"
          }]
        )
      end
    end
  end
end
