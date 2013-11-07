#
# Copyright (C) 2013 Instructure, Inc.
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

describe QuizSubmissionsApiController, :type => :integration do
  it_should_behave_like 'API tests'

  before :each do
    course_with_teacher_logged_in :active_all => true

    @quiz = Quiz.create!(:title => 'quiz', :context => @course)
    @quiz.quiz_data = [ multiple_choice_question_data ]
    @quiz.generate_quiz_data
    @quiz.published_at = Time.now
    @quiz.workflow_state = 'available'
    @quiz.save!

    @assignment = @quiz.assignment
  end

  def enroll_student_and_submit
    last_user = @user
    student_in_course
    student = @user
    @user = last_user

    quiz_submission = @quiz.generate_submission(student)
    quiz_submission.submission_data = { "question_1" => "1658" }
    quiz_submission.mark_completed
    quiz_submission.grade_submission
    quiz_submission.reload

    [ student, quiz_submission ]
  end

  context 'index' do
    def get_index(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/quiz_submissions.json",
        { :controller => 'quiz_submissions_api', :action => 'index', :format => 'json',
          :course_id => @course.id.to_s,
          :quiz_id => @quiz.id.to_s
        }, data)
    end

    it 'should return an empty list' do
      json = get_index
      json.has_key?('quiz_submissions').should be_true
      json['quiz_submissions'].size.should == 0
    end

    it 'should list quiz submissions' do
      enroll_student_and_submit

      json = get_index
      json['quiz_submissions'].size.should == 1
    end

    it 'should restrict access to itself' do
      student_in_course
      json = get_index(true)
      response.status.to_i.should == 401
    end

    context 'quiz submission objects' do
      before :each do
        @student, @quiz_submission = *enroll_student_and_submit
      end

      it "should include its associated user" do
        json = get_index(false, {
          :include => [ 'user' ]
        })

        json.has_key?('users').should be_true
        json['quiz_submissions'].size.should == 1
        json['users'].size.should == 1
        json['users'][0]['id'].should == json['quiz_submissions'][0]['user_id']
      end

      it "should include its associated quiz" do
        json = get_index(false, {
          :include => [ 'quiz' ]
        })

        json.has_key?('quizzes').should be_true
        json['quiz_submissions'].size.should == 1
        json['quizzes'].size.should == 1
        json['quizzes'][0]['id'].should == json['quiz_submissions'][0]['quiz_id']
      end

      it "should include its associated submission" do
        json = get_index(false, {
          :include => [ 'submission' ]
        })

        json.has_key?('submissions').should be_true
        json['quiz_submissions'].size.should == 1
        json['submissions'].size.should == 1
        json['submissions'][0]['id'].should == json['quiz_submissions'][0]['submission_id']
      end

      it "should include its associated user, quiz, and submission" do
        json = get_index(false, {
          :include => [ 'user', 'quiz', 'submission' ]
        })

        json.has_key?('users').should be_true
        json.has_key?('quizzes').should be_true
        json.has_key?('submissions').should be_true
      end

      context 'JSON-API compliance' do
        it 'should conform to the JSON-API spec when returning the object' do
          json = get_index(false)
          assert_jsonapi_compliance!(json, 'quiz_submissions')
        end

        it 'should conform to the JSON-API spec when returning associated objects' do
          includes = [ 'user', 'quiz', 'submission' ]

          json = get_index(false, {
            :include => includes
          })

          assert_jsonapi_compliance!(json, 'quiz_submissions', includes)
        end
      end

      it "should include time spent" do
        @quiz_submission.started_at = Time.now
        @quiz_submission.finished_at = @quiz_submission.started_at + 5.minutes
        @quiz_submission.save!

        json = get_index
        json.has_key?('quiz_submissions').should be_true
        json['quiz_submissions'][0]['time_spent'].should == 5.minutes
      end
    end
  end
end
