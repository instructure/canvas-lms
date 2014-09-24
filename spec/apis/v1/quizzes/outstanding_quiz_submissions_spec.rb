#
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

describe Quizzes::OutstandingQuizSubmissionsController, type: :request do
  describe "GET /courses/:course_id/quizzes/:quiz_id/outstanding_quiz_submissions [index]" do
    def api_index(options={}, params={})
      helper = method(options[:raw] ? :raw_api_call : :api_call)
      helper.call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/outstanding_quiz_submissions",
        { controller: "quizzes/outstanding_quiz_submissions",
          action: "index",
          format: "json",
          course_id: @course.id,
          quiz_id: @quiz.id },
        params, { 'Accept' => 'application/vnd.api+json' })
      JSON.parse(response.body)
    end
    before :once do
      course
      @user = student_in_course.user
      @quiz = @course.quizzes.create!(:title => "Outstanding")
      @quiz.save
      @submission = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@user, false)
      @submission.submission_data = {}
      @submission.end_at = 20.minutes.ago
      @submission.save!
    end

    it 'denies unprivileged access' do
      json = api_index( raw: true )
      assert_status(401)
    end

    context 'with privileged access' do
      before :once do
        teacher_in_course(:active_all => true)
      end

      it 'returns all outstanding QS' do
        json = api_index({})
        json["quiz_submissions"].first["id"].should == @submission.id
      end
    end
  end

  describe "POST /courses/:course_id/quizzes/:quiz_id/outstanding_quiz_submissions [grade]" do
    def api_grade(options={}, params={})
      helper = method(options[:raw] ? :raw_api_call : :api_call)
      helper.call(:post, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/outstanding_quiz_submissions",
        { controller: "quizzes/outstanding_quiz_submissions",
          action: "grade",
          format: "json",
          course_id: @course.id,
          quiz_id: @quiz.id },
        params, { 'Accept' => 'application/vnd.api+json' })
    end
    before :once do
      course
      @quiz = @course.quizzes.create!(:title => "Outstanding")
      @quiz.save
      @submission = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@user, false)
      @submission.submission_data = {}
      @submission.end_at = 20.minutes.ago
      @submission.save!
    end

    it 'denies unprivileged access' do
      student_in_course
      json = api_grade({raw: true}, {quiz_submission_ids: [@submission.id]})
      assert_status 401
    end

    context "with privileged access" do
      before :once do
        student_in_course(active_all: true)
        @submission2 = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@user, false)
        @submission2.submission_data = {}
        @submission2.end_at = 20.minutes.ago
        @submission2.save!
        teacher_in_course(:active_all => true)
      end

      it "should grade all outstanding quiz submissions" do
        api_grade({raw: true},{quiz_submission_ids: [@submission.id]})
        assert_status 204
      end
      it 'should continue w/o error when given already graded ids' do
        Quizzes::SubmissionGrader.new(@submission).grade_submission
        @submission.needs_grading?.should == false
        api_grade({raw: true},{quiz_submission_ids: [@submission.id, @submission2.id]})
        @submission2.reload
        @submission2.needs_grading?.should == false
        Quizzes::OutstandingQuizSubmissionManager.new(@quiz).find_by_quiz.size.should == 0
        assert_status 204
      end
    end
  end
end
