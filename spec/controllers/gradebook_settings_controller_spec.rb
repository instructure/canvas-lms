# frozen_string_literal: true

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

RSpec.describe GradebookSettingsController do
  let(:teacher) { course_with_teacher.user }

  before do
    user_session(teacher)
    request.accept = "application/json"
  end

  describe "PUT update" do
    context "given valid params" do
      let(:gradebook_settings) do
        {
          "enter_grades_as" => {
            "2301" => "points"
          },
          "filter_columns_by" => {
            "grading_period_id" => "1401",
            "assignment_group_id" => "888"
          },
          "filter_rows_by" => {
            "section_id" => "null",
            "student_group_id" => "null"
          },
          "hide_assignment_group_totals" => "false",
          "hide_total" => "false",
          "selected_view_options_filters" => ["assignmentGroups"],
          "show_inactive_enrollments" => "true", # values must be strings
          "show_concluded_enrollments" => "false",
          "show_unpublished_assignments" => "true",
          "student_column_display_as" => "last_first",
          "show_separate_first_last_names" => "true",
          "student_column_secondary_info" => "login_id",
          "sort_rows_by_column_id" => "student",
          "sort_rows_by_setting_key" => "sortable_name",
          "sort_rows_by_direction" => "descending",
          "view_ungraded_as_zero" => "true",
          "colors" => {
            "late" => "#000000",
            "missing" => "#000001",
            "resubmitted" => "#000002",
            "dropped" => "#000003",
            "excused" => "#000004"
          }
        }
      end

      let(:gradebook_settings_massaged) do
        gradebook_settings.merge("filter_rows_by" => { "section_id" => nil, "student_group_id" => nil })
      end

      let(:valid_params) do
        {
          "course_id" => @course.id,
          "gradebook_settings" => gradebook_settings
        }
      end

      let(:expected_settings) do
        {
          @course.id => gradebook_settings_massaged.except("colors"),
          :colors => gradebook_settings_massaged.fetch("colors")
        }.as_json
      end

      context "given a valid PUT request" do
        subject { json_parse.fetch("gradebook_settings").fetch(@course.global_id.to_s) }

        before { put :update, params: valid_params }

        it { expect(response).to be_ok }
        it { is_expected.to include "enter_grades_as" => { "2301" => "points" } }
        it { is_expected.to include "filter_columns_by" => { "grading_period_id" => "1401", "assignment_group_id" => "888" } }
        it { is_expected.to include "filter_rows_by" => { "section_id" => nil, "student_group_id" => nil } }
        it { is_expected.to include "hide_assignment_group_totals" => "false" }
        it { is_expected.to include "hide_total" => "false" }
        it { is_expected.to include "selected_view_options_filters" => ["assignmentGroups"] }
        it { is_expected.to include "show_inactive_enrollments" => "true" }
        it { is_expected.to include "show_concluded_enrollments" => "false" }
        it { is_expected.to include "show_unpublished_assignments" => "true" }
        it { is_expected.to include "show_separate_first_last_names" => "true" }
        it { is_expected.to include "student_column_display_as" => "last_first" }
        it { is_expected.to include "student_column_secondary_info" => "login_id" }
        it { is_expected.to include "sort_rows_by_column_id" => "student" }
        it { is_expected.to include "sort_rows_by_setting_key" => "sortable_name" }
        it { is_expected.to include "sort_rows_by_direction" => "descending" }
        it { is_expected.to include "view_ungraded_as_zero" => "true" }
        it { is_expected.not_to include "colors" }
        it { is_expected.to have(16).items } # ensure we add specs for new additions

        context "colors" do
          subject { json_parse.fetch("gradebook_settings").fetch("colors") }

          it { is_expected.to have(5).items } # ensure we add specs for new additions

          it do
            expect(subject).to include({
                                         "late" => "#000000",
                                         "missing" => "#000001",
                                         "resubmitted" => "#000002",
                                         "dropped" => "#000003",
                                         "excused" => "#000004"
                                       })
          end
        end
      end

      it "transforms 'null' string values to nil" do
        put :update, params: valid_params

        section_id = teacher.get_preference(:gradebook_settings, @course.global_id)
                            .fetch("filter_rows_by")
                            .fetch("section_id")

        expect(section_id).to be_nil
      end

      it "allows saving gradebook settings for multiple courses" do
        previous_course = Course.create!(name: "Previous Course")
        teacher.update!(preferences: {
                          gradebook_settings: {
                            previous_course.id => gradebook_settings_massaged.except("colors"),
                            :colors => gradebook_settings_massaged.fetch("colors")
                          }
                        })
        put :update, params: valid_params

        expect(json_parse.fetch("gradebook_settings")).to eql expected_settings
      end

      it "is allowed for courses in concluded enrollment terms" do
        @course.update!(enrollment_term: teacher.account.enrollment_terms.create!(start_at: 2.months.ago, end_at: 1.month.ago))
        put :update, params: valid_params

        expect(json_parse.fetch("gradebook_settings")).to eql expected_settings
      end

      it "is allowed for courses with concluded workflow state" do
        @course.update!(workflow_state: "concluded")
        put :update, params: valid_params

        expect(json_parse.fetch("gradebook_settings")).to eql expected_settings
      end

      context "given invalid status colors (but otherwise valid params)" do
        subject { response }

        let(:malevolent_color) { "; background: url(https://httpbin.org/basic-auth/user/passwd)" }
        let(:invalid_params) do
          {
            "course_id" => @course.id,
            "gradebook_settings" => {
              "colors" => {
                "dropped" => "#FEF0E5",
                "excused" => "#FEF7E5",
                "late" => "#cccccc",
                "missing" => malevolent_color,
                "resubmitted" => "#E5F7E5"
              }
            }
          }
        end

        before { put :update, params: invalid_params }

        it { is_expected.to be_ok }

        it "does not store invalid status colors" do
          colors = json_parse.fetch("gradebook_settings").fetch("colors")
          expect(colors).not_to have_key "missing"
        end
      end
    end

    context "given invalid params" do
      subject { response }

      before do
        invalid_params = { "course_id" => @course.id }
        put :update, params: invalid_params
      end

      it { is_expected.to have_http_status :bad_request }

      it "gives an error message" do
        expect(json_parse).to include "errors" => [{ "message" => "gradebook_settings is missing" }]
      end
    end
  end
end
