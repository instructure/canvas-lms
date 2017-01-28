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
    def api_index(options={}, data={})
      url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/outstanding_quiz_submissions"
      params =  { controller: "quizzes/outstanding_quiz_submissions",
                  action: "index",
                  format: "json",
                  course_id: @course.id,
                  quiz_id: @quiz.id }
      headers = { 'Accept' => 'application/vnd.api+json' }
      if options[:raw]
        raw_api_call(:get, url, params, data, headers)
      else
        api_call(:get, url, params, data, headers)
      end
      JSON.parse(response.body)
    end

    before :once do
      course_factory
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
        expect(json["quiz_submissions"].first["id"]).to eq @submission.id
      end
    end
  end

  describe "POST /courses/:course_id/quizzes/:quiz_id/outstanding_quiz_submissions [grade]" do
    def api_grade(options={}, data={})
      url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/outstanding_quiz_submissions"
      params = { controller: "quizzes/outstanding_quiz_submissions",
                 action: "grade",
                 format: "json",
                 course_id: @course.id,
                 quiz_id: @quiz.id }
      headers = { 'Accept' => 'application/vnd.api+json' }
      if options[:raw]
        raw_api_call(:post, url, params, data, headers)
      else
        api_call(:post, url, params, data, headers)
      end
    end

    before :once do
      course_factory
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
        expect(@submission.needs_grading?).to eq false
        api_grade({raw: true},{quiz_submission_ids: [@submission.id, @submission2.id]})
        @submission2.reload
        expect(@submission2.needs_grading?).to eq false
        expect(Quizzes::OutstandingQuizSubmissionManager.new(@quiz).find_by_quiz.size).to eq 0
        assert_status 204
      end
    end
  end
end
