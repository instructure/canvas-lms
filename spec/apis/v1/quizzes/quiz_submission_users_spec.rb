# frozen_string_literal: true

# Copyright (C) 2014 Instructure, Inc.
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
require_relative "../../api_spec_helper"
require_relative "../../../models/quizzes/quiz_user_messager_spec_helper"

describe Quizzes::QuizSubmissionUsersController, type: :request do
  before :once do
    course_with_teacher(active_all: true)
  end

  def controller_options(options)
    options.reverse_merge!({
                             controller: "quizzes/quiz_submission_users",
                             action: "message",
                             format: "json",
                             course_id: @course.id,
                             id: @quiz.id
                           })
  end

  describe "POST message" do
    include Quizzes::QuizUserMessagerSpecHelper

    before :once do
      course_quiz(true)
      @finder = Quizzes::QuizUserFinder.new(@quiz, @teacher)
      course_with_student(active_all: true, course: @course)
      @user = @teacher
    end

    def send_message(target_group)
      raw_api_call(
        :post,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submission_users/message",
        controller_options(
          action: "message",
          conversations: [
            { body: "Ohi!", recipients: target_group.to_s }
          ]
        )
      )
      run_jobs
    end

    it "sends a message to unsubmitted users" do
      expect { send_message(:unsubmitted) }.to change { recipient_messages(:unsubmitted) }.by 1
      expect(recipient_messages(:submitted)).to eq 0
    end

    it "sends a message to submitted users" do
      sub = @quiz.generate_submission(@student)
      sub.mark_completed
      Quizzes::SubmissionGrader.new(sub).grade_submission
      expect { send_message(:submitted) }.to change { recipient_messages(:submitted) }.by 1
      expect(recipient_messages(:unsubmitted)).to eq 0
    end
  end

  describe "GET submission_users" do
    before :once do
      @student1 = course_with_student(course: @course, active_all: true).user
      quiz_with_graded_submission([], course: @course, user: @student1)
      @student2 = course_with_student(course: @course, active_all: true).user
      @user = @teacher
    end

    def get_submitted_users(options = {})
      options = controller_options(options.reverse_merge!(action: "index"))
      raw_api_call(
        :get,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submission_users",
        options,
        { "Accept" => "application/json" }
      )
      JSON.parse(response.body) if response.successful?
    end

    it "does not allow students to view information at the endpoint" do
      @user = @student1
      get_submitted_users
      expect(response).not_to be_successful
    end

    it "allows teachers to see submitted students with ?submitted=true" do
      json = get_submitted_users(submitted: true)
      expect(response).to be_successful
      expect(json["users"].first["id"]).to eq @student1.id.to_s
    end

    it "allows teachers to see unsubmitted students with ?submitted=false" do
      json = get_submitted_users(submitted: false)
      expect(response).to be_successful
      user_ids = json["users"].pluck("id")
      expect(user_ids).not_to include @student1.id.to_s
      expect(user_ids).to include @student2.id.to_s
    end

    it "allows teachers to see all students for quiz when submitted parameter not passed" do
      json = get_submitted_users
      expect(response).to be_successful
      user_ids = json["users"].pluck("id")
      expect(user_ids).to include @student1.id.to_s
      expect(user_ids).to include @student2.id.to_s
    end

    it "will sideload quiz_submissions" do
      json = get_submitted_users(include: ["quiz_submissions"])
      expect(response).to be_successful
      expect(json["quiz_submissions"].first.with_indifferent_access[:id]).to eq @quiz_submission.id.to_s
      expect(json["quiz_submissions"].length).to eq 1
    end

    context "differentiated_assignments" do
      it "only returns submissions of students with visibility" do
        @quiz.only_visible_to_overrides = true
        @quiz.save!

        json = get_submitted_users(submitted: false)
        expect(response).to be_successful
        user_ids = json["users"].pluck("id")
        expect(user_ids).not_to include @student2.id.to_s

        create_section_override_for_quiz(@quiz, { course_section: @student2.enrollments.current.first.course_section })

        json = get_submitted_users(submitted: false)
        expect(response).to be_successful
        user_ids = json["users"].pluck("id")
        expect(user_ids).to include @student2.id.to_s
      end
    end
  end
end
