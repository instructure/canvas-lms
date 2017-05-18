#
# Copyright (C) 2016 - present Instructure, Inc.
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

require 'spec_helper'

RSpec.describe GradebookSettingsController, type: :controller do
  let!(:teacher) do
    course_with_teacher
    @teacher
  end

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
          "show_concluded_enrollments" => "false",
          "show_unpublished_assignments" => "true",
          "student_column_display_as" => "last_first",
          "student_column_secondary_info" => "login_id",
          "sort_rows_by_column_id" => "student",
          "sort_rows_by_setting_key" => "sortable_name",
          "sort_rows_by_direction" => "descending"
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
        expect(teacher.preferences[:gradebook_settings]).to eq expected_settings
        expect(json_response["gradebook_settings"]).to eql expected_settings.as_json
      end

      it "allows saving gradebook settings for multiple courses" do
        previous_course = Course.create!(name: 'Previous Course')
        teacher.preferences[:gradebook_settings] = { previous_course.id => show_settings }
        teacher.save

        put :update, valid_params.merge({ "course_id" => @course.id })

        expected_user_settings = {
          @course.id => show_settings,
          previous_course.id => show_settings
        }
        expected_response = {
          @course.id.to_s => show_settings
        }

        expect(teacher.reload.preferences[:gradebook_settings]).to eq(expected_user_settings)
        expect(json_response["gradebook_settings"]).to eq(expected_response)
      end

      it "is allowed for courses in concluded enrollment terms" do
        term = teacher.account.enrollment_terms.create!(start_at: 2.months.ago, end_at: 1.month.ago)
        @course.enrollment_term = term # `update_attribute` with a term has unwanted side effects
        @course.save!

        put :update, valid_params
        expect(response).to be_ok

        expected_settings = { @course.id => show_settings }
        expect(teacher.preferences[:gradebook_settings]).to eq expected_settings
        expect(json_response["gradebook_settings"]).to eql expected_settings.as_json
      end

      it "is allowed for courses with concluded workflow state" do
        @course.workflow_state = "concluded"
        @course.save!

        put :update, valid_params
        expect(response).to be_ok

        expected_settings = { @course.id => show_settings }
        expect(teacher.preferences[:gradebook_settings]).to eq expected_settings
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
