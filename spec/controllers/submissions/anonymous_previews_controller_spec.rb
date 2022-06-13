# frozen_string_literal: true

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

require_relative "../../spec_helper"

RSpec.describe Submissions::AnonymousPreviewsController do
  describe "GET :show" do
    before do
      course_with_student_and_submitted_homework
      @course.account.enable_service(:avatars)
      @context = @course
      user_session(@student)
    end

    it "renders show_preview" do
      get :show, params: { course_id: @context.id, assignment_id: @assignment.id, anonymous_id: @submission.anonymous_id, preview: true }
      expect(response).to render_template(:show_preview)
    end

    it "anonymizes student information when the viewer is a teacher and the assignment is currently anonymizing students" do
      assignment = @course.assignments.create!(title: "shhh", anonymous_grading: true)
      user_session(@teacher)

      submission = assignment.submission_for_student(@student)
      get :show, params: { course_id: @course.id, assignment_id: assignment.id, anonymous_id: submission.anonymous_id, preview: true }
      expect(assigns[:anonymize_students]).to be true
    end

    it "does not throw an error when an admin without an enrollment in the course views the preview" do
      assignment = @course.assignments.create!(title: "shhh", anonymous_grading: true)
      admin = account_admin_user(active_all: true, account: Account.site_admin)
      user_session(admin)

      submission = assignment.submission_for_student(@student)
      get :show, params: { course_id: @course.id, assignment_id: assignment.id, anonymous_id: submission.anonymous_id, preview: true }
      expect(response).to be_successful
    end

    it "anonymizes student information when the viewer is a peer reviewer and anonymous peer reviews are enabled" do
      assignment = @course.assignments.create!(title: "ok", peer_reviews: true, anonymous_peer_reviews: true)
      reviewer = @course.enroll_student(User.create!, enrollment_state: "active").user
      assignment.assign_peer_review(reviewer, @student)
      user_session(reviewer)

      submission = assignment.submission_for_student(@student)
      get :show, params: { course_id: @course.id, assignment_id: assignment.id, anonymous_id: submission.anonymous_id, preview: true }
      expect(assigns[:anonymize_students]).to be true
    end
  end
end
