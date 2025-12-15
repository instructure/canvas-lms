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

require_relative "../api_spec_helper"

describe "Submissions API - Peer Review", type: :request do
  describe "GET #show with peer_review_sub_assignment" do
    before :once do
      course_with_teacher(active_all: true)
      @student = student_in_course(course: @course, active_enrollment: true).user
      @course.enable_feature!(:peer_review_allocation_and_grading)

      @assignment = @course.assignments.create!(
        title: "Peer Review Assignment",
        peer_reviews: true
      )
      @peer_review_sub_assignment = @assignment.create_peer_review_sub_assignment!(
        peer_reviews: true,
        peer_review_count: 2
      )

      @submission = @peer_review_sub_assignment.submit_homework(
        @student,
        submission_type: "online_text_entry",
        body: "peer review"
      )
    end

    it "fetches peer review submission by assignment and user id" do
      @user = @teacher
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/assignments/#{@peer_review_sub_assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "show",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @peer_review_sub_assignment.id.to_s,
          user_id: @student.id.to_s
        }
      )

      expect(json["assignment_id"]).to eq @peer_review_sub_assignment.id
      expect(json["user_id"]).to eq @student.id
      expect(json["submission_type"]).to eq "online_text_entry"
    end

    it "includes submission comments when requested" do
      @submission.submission_comments.create!(author: @teacher, comment: "Good review!")
      @user = @teacher

      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/assignments/#{@peer_review_sub_assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "show",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @peer_review_sub_assignment.id.to_s,
          user_id: @student.id.to_s
        },
        { include: ["submission_comments"] }
      )

      expect(json["submission_comments"]).to be_an(Array)
      expect(json["submission_comments"].length).to eq 1
      expect(json["submission_comments"].first["comment"]).to eq "Good review!"
    end
  end

  describe "PUT #update_anonymous with peer_review_sub_assignment" do
    before :once do
      course_with_teacher(active_all: true)
      @student = student_in_course(course: @course, active_enrollment: true).user
      @course.enable_feature!(:peer_review_allocation_and_grading)

      @assignment = @course.assignments.create!(
        title: "Peer Review Assignment",
        peer_reviews: true,
        anonymous_grading: true,
        points_possible: 10
      )
      @peer_review_sub_assignment = @assignment.create_peer_review_sub_assignment!(
        peer_reviews: true,
        anonymous_grading: true,
        points_possible: 10
      )

      @submission = @peer_review_sub_assignment.submit_homework(
        @student,
        submission_type: "online_text_entry",
        body: "anonymous review"
      )
    end

    it "updates peer review submission using anonymous_id" do
      @user = @teacher
      expect do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@peer_review_sub_assignment.id}/anonymous_submissions/#{@submission.anonymous_id}.json",
          {
            controller: "submissions_api",
            action: "update_anonymous",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @peer_review_sub_assignment.id.to_s,
            anonymous_id: @submission.anonymous_id.to_s
          },
          {
            submission: { posted_grade: "8" }
          }
        )
      end.to change {
        @submission.reload.grade
      }.from(nil).to("8")
    end

    it "adds comments to peer review submission" do
      @user = @teacher
      expect do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@peer_review_sub_assignment.id}/anonymous_submissions/#{@submission.anonymous_id}.json",
          {
            controller: "submissions_api",
            action: "update_anonymous",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @peer_review_sub_assignment.id.to_s,
            anonymous_id: @submission.anonymous_id.to_s
          },
          {
            comment: { text_comment: "Great peer review!" }
          }
        )
      end.to change {
        @submission.reload.submission_comments.count
      }.by(1)
    end
  end
end
