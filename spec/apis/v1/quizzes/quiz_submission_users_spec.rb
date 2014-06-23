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
require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../models/quizzes/quiz_user_messager_spec_helper')

describe Quizzes::QuizSubmissionUsersController, type: :request do
  before do
    course_with_teacher_logged_in(active_all: true)
    course_quiz(true)
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

    before do
      @finder = Quizzes::QuizUserFinder.new(@quiz, @teacher)
      course_with_student(active_all: true, course: @course)
      @user = @teacher
    end

    def send_message(target_group)
      raw_api_call(
        :post,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submission_users/message",
        controller_options(
          action: 'message',
          conversations: [
            { body: 'Ohi!', recipients: target_group.to_s }
          ]
        )
      )
      run_jobs
    end

    it "sends a message to unsubmitted users" do
      expect { send_message(:unsubmitted) }.to change { recipient_messages(:unsubmitted) }.by 1
      recipient_messages(:submitted).should == 0
    end

    it "sends a message to submitted users" do
      sub = @quiz.generate_submission(@student)
      sub.mark_completed
      sub.grade_submission
      expect { send_message(:submitted) }.to change { recipient_messages(:submitted) }.by 1
      recipient_messages(:unsubmitted).should == 0
    end
  end

  describe "GET submission_users" do

    def get_submitted_users(options={})
      options = controller_options(options.reverse_merge!(action: 'index'))
      raw_api_call(
        :get,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submission_users",
        options,
        { 'Accept' => 'application/json'}
      )
      JSON.parse(response.body) if response.success?
    end

    it "does not allow students to view information at the endpoint" do
      course_with_student_logged_in(course: @course, active_all: true)
      get_submitted_users
      response.should_not be_success
    end

    it "allows teachers to see submitted students with ?submitted=true" do
      course_with_student(active_all: true, course: @course)
      quiz_with_graded_submission([], course: @course, user: @student)
      @user = @teacher
      json = get_submitted_users(submitted: true)
      response.should be_success
      json['users'].first['id'].should == @student.id.to_s
    end

    it "allows teachers to see unsubmitted students with ?submitted=false" do
      course_with_student(active_all: true, course: @course)
      @student_frd = @student
      quiz_with_graded_submission([], course: @course, user: @student_frd)
      course_with_student(active_all: true, course: @course)
      @user = @teacher
      json = get_submitted_users(submitted: false)
      response.should be_success
      user_ids = json['users'].map { |h| h['id'] }
      user_ids.should_not include @student_frd.id.to_s
      user_ids.should include @student.id.to_s
    end

    it "allows teachers to see all students for quiz when submitted parameter not passed" do
      course_with_student(active_all: true, course: @course)
      @student_frd = @student
      quiz_with_graded_submission([], course: @course, user: @student_frd)
      course_with_student(active_all: true, course: @course)
      @user = @teacher
      json = get_submitted_users
      response.should be_success
      user_ids = json['users'].map { |h| h['id'] }
      user_ids.should include @student_frd.id.to_s
      user_ids.should include @student.id.to_s
    end

    it "will sideload quiz_submissions" do
      course_with_student(active_all: true, course: @course)
      @student_frd = @student
      quiz_with_graded_submission([], course: @course, user: @student_frd)
      course_with_student(active_all: true, course: @course)
      @user = @teacher
      json = get_submitted_users(include: ['quiz_submissions'])
      response.should be_success
      json['quiz_submissions'].first.with_indifferent_access[:id].should == @quiz_submission.id.to_s
      json['quiz_submissions'].length.should == 1
    end
  end
end
