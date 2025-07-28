# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe RubricAssessmentImportsController do
  describe "GET 'show'" do
    before do
      course_with_teacher_logged_in(active_all: true)
      @assignment = @course.assignments.create!(title: "Some Assignment")
      rubric_association_model(user: @user, context: @course, association_object: @assignment, purpose: "grading")
      @rubric_import = RubricAssessmentImport.create_with_attachment(
        @assignment, fixture_file_upload("rubric/assessments.csv", "text/csv"), @current_user
      )
    end

    it "returns the rubric assessment import with the correct assignment_id" do
      get :show, params: { course_id: @course.id, assignment_id: @assignment.id, id: @rubric_import.id }

      expect(response).to be_successful
      response_body = json_parse(response.body)

      expect(response_body["id"]).to eq(@rubric_import.id)
      expect(response_body["assignment_id"]).to eq(@assignment.id)
      expect(response_body["workflow_state"]).to eq("created")
      expect(response_body["course_id"]).to eq(@course.id)
    end
  end

  describe "POST 'create'" do
    before do
      course_with_teacher_logged_in(active_all: true)
      @assignment = @course.assignments.create!(title: "Some Assignment")
      rubric_association_model(user: @user, context: @course, association_object: @assignment, purpose: "grading")
      assessor = User.create!
      @course.enroll_student(assessor)
      @attachment = fixture_file_upload("rubric/assessments.csv", "text/csv")
    end

    context "anonymous grading" do
      it "return error if anonymous grading" do
        @assignment.update!(anonymous_grading: true, moderated_grading: true, grader_count: 1)
        post :create, params: { course_id: @course.id, assignment_id: @assignment.id, attachment: @attachment }
        expect(response).to be_bad_request
        expect(response.body).to match(/Rubric import is not supported for assignments with anonymous grading/)
      end

      it "create import if de-anonymized students" do
        @assignment.update!(
          anonymous_grading: true, moderated_grading: true, grader_count: 1, grades_published_at: 1.hour.ago
        )
        post :create, params: { course_id: @course.id, assignment_id: @assignment.id, attachment: @attachment }
        expect(response).to be_successful
        response_body = json_parse(response.body)
        expect(response_body["assignment_id"]).to eq(@assignment.id)
        expect(response_body["workflow_state"]).to eq("created")
      end
    end

    it "returns bad request if file attachment not passed in" do
      post :create, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_bad_request
    end

    it "returns bad request if assignment does not exist" do
      post :create, params: { course_id: @course.id, assignment_id: "some-bad-id", attachment: @attachment }
      expect(response).to be_not_found
    end

    it "returns bad request if rubric association for assignment does not exist" do
      assignment_2 = @course.assignments.create!(title: "Some Assignment")
      post :create, params: { course_id: @course.id, assignment_id: assignment_2.id, attachment: @attachment }

      expect(response).to be_bad_request
      error_message = json_parse(response.body)["message"]
      expect(error_message).to eq("Assignment not found or does not have a rubric association")
    end

    it "returns the rubric assessment import job id" do
      post :create, params: { course_id: @course.id, assignment_id: @assignment.id, attachment: @attachment }
      expect(response).to be_successful
      response_body = json_parse(response.body)
      expect(response_body["assignment_id"]).to eq(@assignment.id)
      expect(response_body["workflow_state"]).to eq("created")
    end
  end
end
