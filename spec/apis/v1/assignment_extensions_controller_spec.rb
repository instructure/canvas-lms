#
# Copyright (C) 2018 - present Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe AssignmentExtensionsController, type: :request do
  before :once do
    course_factory
    @assignment = @course.assignments.create!(title: "assignment")
    @assignment.workflow_state = "available"
    @assignment.submission_types = "online_upload"
    @assignment.save!
    @student = student_in_course(course: @course, active_all: true).user
  end

  describe "POST /api/v1/courses/:course_id/assignments/:assignment_id/extensions (create)" do
    def api_create_assignment_extensions(assignment_extension_params, opts={}, raw=false)
      api_method = raw ? :raw_api_call : :api_call

      send(api_method,
        :post,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/extensions",
        {
          controller: "assignment_extensions",
          action: "create",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s
        },
        {
          assignment_extensions: assignment_extension_params
        },
        {
          "Accept" => "application/vnd.api+json"
        },
        opts)
    end

    context "as a student" do
      it "should be unauthorized" do
        @user = @student
        assignment_extension_params = [
          { user_id: @student.id, extra_attempts: 3 },
        ]
        api_create_assignment_extensions(assignment_extension_params, {}, true)
        assert_status(401)
      end
    end

    context "as a teacher" do
      before :once do
        @student2 = user_factory
        @course.enroll_user(@student2, "StudentEnrollment", {})
        @teacher = teacher_in_course(course: @course, active_all: true).user
        @user = @teacher
      end

      it "should extend attempts for the existing submission" do
        submission = @student.submissions.find_by(assignment_id: @assignment.id)
        assignment_extension_params = [
          { user_id: @student.id, extra_attempts: 3 },
        ]

        api_create_assignment_extensions(assignment_extension_params)
        expect(submission.reload.extra_attempts).to eq(3)
      end

      it "should extend attempts for multiple students" do
        submission_1 = @student.submissions.find_by(assignment_id: @assignment.id)
        submission_2 = @student2.submissions.find_by(assignment_id: @assignment.id)
        assignment_extension_params = [
          { user_id: @student.id, extra_attempts: 3 },
          { user_id: @student2.id, extra_attempts: 10 },
        ]

        api_create_assignment_extensions(assignment_extension_params)
        expect(submission_1.reload.extra_attempts).to eq(3)
        expect(submission_2.reload.extra_attempts).to eq(10)
      end

      it "should error out if any of the extensions were invalid, and the response should indicate which ones were incorrect" do
        submission_1 = @student.submissions.find_by(assignment_id: @assignment.id)
        submission_2 = @student2.submissions.find_by(assignment_id: @assignment.id)
        assignment_extension_params = [
          { user_id: @student.id, extra_attempts: -10 },
          { user_id: @student2.id, extra_attempts: 10 },
        ]

        response = api_create_assignment_extensions(assignment_extension_params)
        expect(submission_1.reload.extra_attempts).to be_nil
        expect(submission_2.reload.extra_attempts).to be_nil
        expect(response["errors"]).to eq([
          { "user_id" => @student.id, "errors" => ["Extra attempts must be greater than or equal to 0"] }
        ])
      end
    end
  end
end
