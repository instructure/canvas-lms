# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe SisApiController do
  describe "GET sis_assignments" do
    let(:account) { account_model }
    let(:course) { course_model(account:, workflow_state: "available") }
    let(:admin) { account_admin_user(account:) }

    before do
      bypass_rescue
      user_session(admin)
    end

    it "responds with 400 when sis_assignments is disabled" do
      get "sis_assignments", params: { course_id: course.id }

      parsed_json = json_parse(response.body)
      expect(response).to have_http_status :bad_request
      expect(parsed_json["code"]).to eq "not_enabled"
    end

    context "with post_grades enabled" do
      before do
        course.enable_feature!(:post_grades)
      end

      it "responds with 200" do
        get "sis_assignments", params: { course_id: course.id }

        parsed_json = json_parse(response.body)
        expect(response).to have_http_status :ok
        expect(parsed_json).to eq []
      end

      it "includes only assignments with post_to_sis enabled" do
        assignment_model(course:, workflow_state: "published")
        assignment = assignment_model(course:, post_to_sis: true, workflow_state: "published")

        get "sis_assignments", params: { course_id: course.id }

        parsed_json = json_parse(response.body)
        expect(parsed_json.size).to eq 1
        expect(parsed_json.first["id"]).to eq assignment.id
      end

      context "with student overrides" do
        let(:assignment) { assignment_model(course:, post_to_sis: true, workflow_state: "published") }

        before do
          @student1 = student_in_course({ course:, workflow_state: "active" }).user
          @student2 = student_in_course({ course:, workflow_state: "active" }).user
          managed_pseudonym(@student2, sis_user_id: "SIS_ID_2", account:)
          due_at = Time.zone.parse("2017-02-08 22:11:10")
          @override = create_adhoc_override_for_assignment(assignment, [@student1, @student2], due_at:)
        end

        it "does not include student overrides by default" do
          get "sis_assignments", params: { course_id: course.id }

          parsed_json = json_parse(response.body)
          expect(parsed_json.first).not_to have_key("user_overrides")
        end

        it "does includes student override data by including student_overrides" do
          get "sis_assignments", params: { course_id: course.id, include: ["student_overrides"] }

          parsed_json = json_parse(response.body)
          expect(parsed_json.first["user_overrides"].size).to eq 1
          expect(parsed_json.first["user_overrides"].first["id"]).to eq @override.id

          students = parsed_json.first["user_overrides"].first["students"]
          expect(students.size).to eq 2
          expect(students).to include({ "user_id" => @student1.id, "sis_user_id" => nil })
          expect(students).to include({ "user_id" => @student2.id, "sis_user_id" => "SIS_ID_2" })
        end
      end
    end
  end
end
