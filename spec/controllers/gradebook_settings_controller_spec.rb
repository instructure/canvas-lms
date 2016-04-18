require 'spec_helper'

RSpec.describe GradebookSettingsController, type: :controller do
  let!(:account) { course_with_teacher; @teacher }
  before do
    user_session(account)
  end

  describe "PUT update" do
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
        request.accept = "application/json"
        expect { put :update, valid_params }.to change {
          account.preferences.fetch(:gradebook_settings, {})
        }.from({}).to( @course.id => show_settings )

        expect(response).to be_ok
        json_response = JSON.parse(response.body)
        expect(json_response["gradebook_settings"]).to eql({
          @course.id => show_settings
        }.as_json)
      end
    end

    context "given invalid params" do
      let(:invalid_params) { { "course_id" => @course.id} }
      it "give an error response" do
        request.accept = "application/json"
        put :update, invalid_params

        expect(response).to_not be_ok
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          "errors" => [{
            "message" => "gradebook_settings is missing"
          }]
        )
      end
    end
  end
end
