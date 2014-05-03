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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')

shared_examples_for 'Quiz Submissions API Restricted Endpoints' do
  it 'should require the LDB' do
    @quiz.require_lockdown_browser = true
    @quiz.save

    Quizzes::Quiz.stubs(:lockdown_browser_plugin_enabled?).returns true

    fake_plugin = Object.new
    fake_plugin.stubs(:authorized?).returns false
    fake_plugin.stubs(:base).returns fake_plugin

    subject.stubs(:ldb_plugin).returns fake_plugin
    Canvas::LockdownBrowser.stubs(:plugin).returns fake_plugin
    
    @request_proxy.call true, {
      attempt: 1
    }

    assert_status(403)
    response.body.should match(/requires the lockdown browser/i)
  end
end

describe Quizzes::QuizSubmissionsApiController, type: :request do
  module Helpers
    def enroll_student(opts = {})
      last_user = @teacher = @user
      student_in_course
      @student = @user
      @user = last_user

      if opts[:login]
        remove_user_session
        user_session(@student)
      end
    end

    def enroll_student_and_submit(submission_data = {}, login=false)
      enroll_student({ login: login })

      @quiz_submission = @quiz.generate_submission(@student)
      @quiz_submission.submission_data = submission_data
      @quiz_submission.mark_completed
      @quiz_submission.grade_submission
      @quiz_submission.reload
    end

    def normalize(value)
      value = 0 if value == 0.0
      value.to_json.to_s
    end

    def qs_api_index(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions.json",
        { :controller => 'quizzes/quiz_submissions_api', :action => 'index', :format => 'json',
          :course_id => @course.id.to_s,
          :quiz_id => @quiz.id.to_s
        }, data)
    end

    def qs_api_show(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}.json",
        { :controller => 'quizzes/quiz_submissions_api',
          :action => 'show',
          :format => 'json',
          :course_id => @course.id.to_s,
          :quiz_id => @quiz.id.to_s,
          :id => @quiz_submission.id.to_s
        }, data)
    end

    def qs_api_create(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:post,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions",
        { :controller => 'quizzes/quiz_submissions_api',
          :action => 'create',
          :format => 'json',
          :course_id => @course.id.to_s,
          :quiz_id => @quiz.id.to_s
        }, data)
    end

    def qs_api_complete(raw = false, data = {})
      data = {
        validation_token: @quiz_submission.validation_token
      }.merge(data)

      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:post,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}/complete",
        { :controller => 'quizzes/quiz_submissions_api',
          :action => 'complete',
          :format => 'json',
          :course_id => @course.id.to_s,
          :quiz_id => @quiz.id.to_s,
          :id => @quiz_submission.id.to_s
        }, data)
    end

    def qs_api_update(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:put,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}",
        { :controller => 'quizzes/quiz_submissions_api',
          :action => 'update',
          :format => 'json',
          :course_id => @course.id.to_s,
          :quiz_id => @quiz.id.to_s,
          :id => @quiz_submission.id.to_s
        }, data)
    end
  end

  include Helpers

  before :each do
    course_with_teacher_logged_in :active_all => true

    @quiz = Quizzes::Quiz.create!(:title => 'quiz', :context => @course)
    @quiz.published_at = Time.now
    @quiz.workflow_state = 'available'
    @quiz.save!
  end

  describe 'GET /courses/:course_id/quizzes/:quiz_id/submissions [INDEX]' do
    it 'should return an empty list' do
      json = qs_api_index
      json.has_key?('quiz_submissions').should be_true
      json['quiz_submissions'].size.should == 0
    end

    it 'should list quiz submissions' do
      enroll_student_and_submit

      json = qs_api_index
      json['quiz_submissions'].size.should == 1
    end

    it 'should be accessible by the owner student' do
      enroll_student_and_submit({}, true)

      json = qs_api_index
      json.has_key?('quiz_submissions').should be_true
      json['quiz_submissions'].length.should == 1
    end

    it 'should restrict access to itself' do
      student_in_course
      json = qs_api_index(true)
      assert_status(401)
    end
  end

  describe 'GET /courses/:course_id/quizzes/:quiz_id/submissions/:id [SHOW]' do
    before :each do
      enroll_student_and_submit
    end

    it 'should grant access to its student' do
      @user = @student
      json = qs_api_show
      json.has_key?('quiz_submissions').should be_true
      json['quiz_submissions'].length.should == 1
    end

    it 'should be accessible implicitly to its own student as "self"' do
      @user = @student
      @quiz_submission.stubs(:id).returns 'self'

      json = qs_api_show
      json.has_key?('quiz_submissions').should be_true
      json['quiz_submissions'].length.should == 1
    end

    it 'should deny access by other students' do
      student_in_course
      qs_api_show(true)
      assert_status(401)
    end

    context 'Output' do
      it 'should include the allowed quiz submission output fields' do
        json = qs_api_show
        json.has_key?('quiz_submissions').should be_true

        qs_json = json['quiz_submissions'][0].with_indifferent_access

        output_fields = [] +
          Api::V1::QuizSubmission::QUIZ_SUBMISSION_JSON_FIELDS +
          Api::V1::QuizSubmission::QUIZ_SUBMISSION_JSON_FIELD_METHODS

        output_fields.each do |field|
          qs_json.should have_key field
          normalize(qs_json[field]).should == normalize(@quiz_submission.send(field))
        end
      end

      it 'should include time spent' do
        @quiz_submission.started_at = Time.now
        @quiz_submission.finished_at = @quiz_submission.started_at + 5.minutes
        @quiz_submission.save!

        json = qs_api_show
        json.has_key?('quiz_submissions').should be_true
        json['quiz_submissions'][0]['time_spent'].should == 5.minutes
      end

      it 'should include html_url' do
        json = qs_api_show
        json.has_key?('quiz_submissions').should be_true

        qs_json = json['quiz_submissions'][0]
        qs_json['html_url'].should == course_quiz_quiz_submission_url(@course, @quiz, @quiz_submission)
      end
    end

    context 'Links' do
      it 'should include its linked user' do
        json = qs_api_show(false, {
          :include => [ 'user' ]
        })

        json.has_key?('users').should be_true
        json['quiz_submissions'].size.should == 1
        json['users'].size.should == 1
        json['users'][0]['id'].should == json['quiz_submissions'][0]['user_id']
      end

      it 'should include its linked quiz' do
        json = qs_api_show(false, {
          :include => [ 'quiz' ]
        })

        json.has_key?('quizzes').should be_true
        json['quiz_submissions'].size.should == 1
        json['quizzes'].size.should == 1
        json['quizzes'][0]['id'].should == json['quiz_submissions'][0]['quiz_id']
      end

      it 'should include its linked submission' do
        json = qs_api_show(false, {
          :include => [ 'submission' ]
        })

        json.has_key?('submissions').should be_true
        json['quiz_submissions'].size.should == 1
        json['submissions'].size.should == 1
        json['submissions'][0]['id'].should == json['quiz_submissions'][0]['submission_id']
      end

      it 'should include its linked user, quiz, and submission' do
        json = qs_api_show(false, {
          :include => [ 'user', 'quiz', 'submission' ]
        })

        json.has_key?('users').should be_true
        json.has_key?('quizzes').should be_true
        json.has_key?('submissions').should be_true
      end
    end

    context 'JSON-API compliance' do
      it 'should conform to the JSON-API spec when returning the object' do
        json = qs_api_show(false)
        assert_jsonapi_compliance(json, 'quiz_submissions')
      end

      it 'should conform to the JSON-API spec when returning linked objects' do
        includes = [ 'user', 'quiz', 'submission' ]

        json = qs_api_show(false, {
          :include => includes
        })

        assert_jsonapi_compliance(json, 'quiz_submissions', includes)
      end
    end
  end

  describe 'POST /courses/:course_id/quizzes/:quiz_id/submissions [create]' do
    before :each do
      enroll_student({ login: true })
    end

    it 'should create a quiz submission' do
      json = qs_api_create
      json.has_key?('quiz_submissions').should be_true
      json['quiz_submissions'].length.should == 1
      json['quiz_submissions'][0]['workflow_state'].should == 'untaken'
    end

    it 'should create a preview quiz submission' do
      json = qs_api_create false, { preview: true }
      Quizzes::QuizSubmission.find(json['quiz_submissions'][0]['id']).preview?.should be_true
    end

    it 'should allow the creation of multiple, subsequent QSes' do
      @quiz.allowed_attempts = -1
      @quiz.save

      json = qs_api_create
      qs = Quizzes::QuizSubmission.find(json['quiz_submissions'][0]['id'])
      qs.mark_completed
      qs.save

      qs_api_create
    end

    context 'access validations' do
      include_examples 'Quiz Submissions API Restricted Endpoints'

      before :each do
        @request_proxy = method(:qs_api_create)
      end

      it 'should reject creating a QS when one already exists' do
        qs_api_create
        qs_api_create(true)
        response.status.to_i.should == 409
      end

      it 'should respect the number of allowed attempts' do
        json = qs_api_create
        qs = Quizzes::QuizSubmission.find(json['quiz_submissions'][0]['id'])
        qs.mark_completed
        qs.save!

        qs_api_create(true)
        response.status.to_i.should == 409
      end
    end
  end

  describe 'POST /courses/:course_id/quizzes/:quiz_id/submissions/:id/complete [complete]' do
    before :each do
      enroll_student({ login: true })

      @quiz_submission = @quiz.generate_submission(@student)
      # @quiz_submission.submission_data = { "question_1" => "1658" }
    end

    it 'should complete a quiz submission' do
      json = qs_api_complete false, {
        attempt: 1
      }

      json.has_key?('quiz_submissions').should be_true
      json['quiz_submissions'].length.should == 1
      json['quiz_submissions'][0]['workflow_state'].should == 'complete'
    end

    context 'access validations' do
      include_examples 'Quiz Submissions API Restricted Endpoints'

      before do
        @request_proxy = method(:qs_api_complete)
      end

      it 'should reject completing an already complete QS' do
        @quiz_submission.mark_completed
        @quiz_submission.grade_submission

        json = qs_api_complete true, {
          attempt: 1
        }

        assert_status(400)
        response.body.should match(/already complete/)
      end

      it 'should require the attempt index' do
        json = qs_api_complete true

        assert_status(400)
        response.body.should match(/invalid attempt/)
      end

      it 'should require the current attempt index' do
        json = qs_api_complete true, {
          attempt: 123123123
        }

        assert_status(400)
        response.body.should match(/attempt.*can not be modified/)
      end

      it 'should require a valid validation token' do
        json = qs_api_complete true, {
          validation_token: 'aaaooeeeee'
        }

        assert_status(403)
        response.body.should match(/invalid token/)
      end
    end
  end

  describe 'PUT /courses/:course_id/quizzes/:quiz_id/submissions/:id [update]' do
    before :each do
      # We're gonna test with 2 questions to make sure there are no side effects
      # when we modify a single question
      @qq1 = @quiz.quiz_questions.create!({
        question_data: multiple_choice_question_data
      })

      @qq2 = @quiz.quiz_questions.create!({
        question_data: true_false_question_data
      })

      @quiz.quiz_data = [ @qq1.question_data, @qq2.question_data ]
      @quiz.generate_quiz_data

      enroll_student_and_submit({
        "question_#{@qq1.id}" => "1658", # correct, nr points: 50
        "question_#{@qq2.id}" => "8950"  # also correct, nr points: 45
      })

      @original_score = @quiz_submission.score # should be 95
    end

    it 'should fudge points' do
      json = qs_api_update false, {
        quiz_submissions: [{
          attempt: @quiz_submission.attempt,
          fudge_points: 2.5
        }]
      }

      json.has_key?('quiz_submissions').should be_true
      json['quiz_submissions'].length.should == 1
      json['quiz_submissions'][0]['fudge_points'].should == 2.5
      json['quiz_submissions'][0]['score'].should == 97.5
    end

    it 'should modify a question score' do
      json = qs_api_update false, {
        quiz_submissions: [{
          attempt: @quiz_submission.attempt,
          questions: {
            "#{@qq1.id}" => {
              score: 10
            }
          }
        }]
      }

      json.has_key?('quiz_submissions').should be_true
      json['quiz_submissions'].length.should == 1
      json['quiz_submissions'][0]['score'].should == 55
    end

    it 'should set a comment' do
      json = qs_api_update false, {
        quiz_submissions: [{
          attempt: @quiz_submission.attempt,
          questions: {
            "#{@qq2.id}" => {
              comment: 'Aaaaaughibbrgubugbugrguburgle'
            }
          }
        }]
      }

      @quiz_submission.reload
      @quiz_submission.submission_data[1]['more_comments'].should == 'Aaaaaughibbrgubugbugrguburgle'

      # make sure no score is affected
      @quiz_submission.submission_data[1]['points'].should == 45
      @quiz_submission.score.should == @original_score
    end
  end
end
