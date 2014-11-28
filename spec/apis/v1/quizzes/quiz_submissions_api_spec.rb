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
    expect(response.body).to match(/requires the lockdown browser/i)
  end
end

describe Quizzes::QuizSubmissionsApiController, type: :request do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  module Helpers
    def enroll_student
      last_user = @teacher = @user
      student_in_course
      @student = @user
      @user = last_user
    end

    def enroll_student_and_submit(submission_data = {})
      enroll_student

      @quiz_submission = @quiz.generate_submission(@student)
      @quiz_submission.submission_data = submission_data
      @quiz_submission.mark_completed
      Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission
      @quiz_submission.reload
    end

    def normalize(value)
      value = 0 if value == 0.0
      value.to_json.to_s
    end

    def qs_api_index(raw = false, data = {})
      url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions.json"
      params = { :controller => 'quizzes/quiz_submissions_api', :action => 'index', :format => 'json',
                 :course_id => @course.id.to_s,
                 :quiz_id => @quiz.id.to_s }
      if raw
        raw_api_call(:get, url, params, data)
      else
        api_call(:get, url, params, data)
      end
    end

    def qs_api_show(raw = false, data = {})
      url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}.json"
      params = { :controller => 'quizzes/quiz_submissions_api',
                 :action => 'show',
                 :format => 'json',
                 :course_id => @course.id.to_s,
                 :quiz_id => @quiz.id.to_s,
                 :id => @quiz_submission.id.to_s }
      if raw
        raw_api_call(:get, url, params, data)
      else
        api_call(:get, url, params, data)
      end
    end

    def qs_api_create(raw = false, data = {})
      url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions"
      params = { :controller => 'quizzes/quiz_submissions_api',
                 :action => 'create',
                 :format => 'json',
                 :course_id => @course.id.to_s,
                 :quiz_id => @quiz.id.to_s }
      if raw
        raw_api_call(:post, url, params, data)
      else
        api_call(:post, url, params, data)
      end
    end

    def qs_api_complete(raw = false, data = {})
      url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}/complete"
      params = { :controller => 'quizzes/quiz_submissions_api',
                 :action => 'complete',
                 :format => 'json',
                 :course_id => @course.id.to_s,
                 :quiz_id => @quiz.id.to_s,
                 :id => @quiz_submission.id.to_s }
      data = {
        validation_token: @quiz_submission.validation_token
      }.merge(data)

      if raw
        raw_api_call(:post, url, params, data)
      else
        api_call(:post, url, params, data)
      end
    end

    def qs_api_update(raw = false, data = {})
      url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}"
      params = { :controller => 'quizzes/quiz_submissions_api',
                 :action => 'update',
                 :format => 'json',
                 :course_id => @course.id.to_s,
                 :quiz_id => @quiz.id.to_s,
                 :id => @quiz_submission.id.to_s }
      if raw
        raw_api_call(:put, url, params, data)
      else
        api_call(:put, url, params, data)
      end
    end
  end

  include Helpers

  before :once do
    course_with_teacher :active_all => true

    @quiz = Quizzes::Quiz.create!(:title => 'quiz', :context => @course)
    @quiz.published_at = Time.now
    @quiz.workflow_state = 'available'
    @quiz.save!
  end

  describe 'GET /courses/:course_id/quizzes/:quiz_id/submissions [INDEX]' do
    it 'should return an empty list' do
      json = qs_api_index
      expect(json.has_key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].size).to eq 0
    end

    it 'should list quiz submissions' do
      enroll_student_and_submit

      json = qs_api_index
      expect(json['quiz_submissions'].size).to eq 1
    end

    it 'should be accessible by the owner student' do
      enroll_student_and_submit

      json = qs_api_index
      expect(json.has_key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
    end

    it 'should restrict access to itself' do
      student_in_course
      json = qs_api_index(true)
      assert_status(401)
    end
  end

  describe 'GET /courses/:course_id/quizzes/:quiz_id/submissions/:id [SHOW]' do
    before :once do
      enroll_student_and_submit
    end

    it 'should grant access to its student' do
      @user = @student
      json = qs_api_show
      expect(json.has_key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
    end

    it 'should be accessible implicitly to its own student as "self"' do
      @user = @student
      @quiz_submission.stubs(:id).returns 'self'

      json = qs_api_show
      expect(json.has_key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
    end

    it 'should deny access by other students' do
      student_in_course
      qs_api_show(true)
      assert_status(401)
    end

    context 'Output' do
      it 'should include the allowed quiz submission output fields' do
        json = qs_api_show
        expect(json.has_key?('quiz_submissions')).to be_truthy

        qs_json = json['quiz_submissions'][0].with_indifferent_access

        output_fields = [] +
          Api::V1::QuizSubmission::QUIZ_SUBMISSION_JSON_FIELDS +
          Api::V1::QuizSubmission::QUIZ_SUBMISSION_JSON_FIELD_METHODS

        output_fields.each do |field|
          expect(qs_json).to have_key field
          expect(normalize(qs_json[field])).to eq normalize(@quiz_submission.send(field))
        end
      end

      it 'should include time spent' do
        @quiz_submission.started_at = Time.now
        @quiz_submission.finished_at = @quiz_submission.started_at + 5.minutes
        @quiz_submission.save!

        json = qs_api_show
        expect(json.has_key?('quiz_submissions')).to be_truthy
        expect(json['quiz_submissions'][0]['time_spent']).to eq 5.minutes
      end

      it 'should include questions_regraded_since_last_attempt' do
        @quiz_submission.save!

        json = qs_api_show
        expect(json.has_key?('quiz_submissions')).to be_truthy
        expect(json['quiz_submissions'][0]['questions_regraded_since_last_attempt']).to eq 0
      end

      it 'should include html_url' do
        json = qs_api_show
        expect(json.has_key?('quiz_submissions')).to be_truthy

        qs_json = json['quiz_submissions'][0]
        expect(qs_json['html_url']).to eq course_quiz_quiz_submission_url(@course, @quiz, @quiz_submission)
      end
    end

    context 'Links' do
      it 'should include its linked user' do
        json = qs_api_show(false, {
          :include => [ 'user' ]
        })

        expect(json.has_key?('users')).to be_truthy
        expect(json['quiz_submissions'].size).to eq 1
        expect(json['users'].size).to eq 1
        expect(json['users'][0]['id']).to eq json['quiz_submissions'][0]['user_id']
      end

      it 'should include its linked quiz' do
        json = qs_api_show(false, {
          :include => [ 'quiz' ]
        })

        expect(json.has_key?('quizzes')).to be_truthy
        expect(json['quiz_submissions'].size).to eq 1
        expect(json['quizzes'].size).to eq 1
        expect(json['quizzes'][0]['id']).to eq json['quiz_submissions'][0]['quiz_id']
      end

      it 'should include its linked submission' do
        json = qs_api_show(false, {
          :include => [ 'submission' ]
        })

        expect(json.has_key?('submissions')).to be_truthy
        expect(json['quiz_submissions'].size).to eq 1
        expect(json['submissions'].size).to eq 1
        expect(json['submissions'][0]['id']).to eq json['quiz_submissions'][0]['submission_id']
      end

      it 'should include its linked user, quiz, and submission' do
        json = qs_api_show(false, {
          :include => [ 'user', 'quiz', 'submission' ]
        })

        expect(json.has_key?('users')).to be_truthy
        expect(json.has_key?('quizzes')).to be_truthy
        expect(json.has_key?('submissions')).to be_truthy
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
    before :once do
      enroll_student
    end

    it 'should create a quiz submission' do
      json = qs_api_create
      expect(json.has_key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
      expect(json['quiz_submissions'][0]['workflow_state']).to eq 'untaken'
    end

    it 'should create a preview quiz submission' do
      json = qs_api_create false, { preview: true }
      expect(Quizzes::QuizSubmission.find(json['quiz_submissions'][0]['id']).preview?).to be_truthy
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
        expect(response.status.to_i).to eq 409
      end

      it 'should respect the number of allowed attempts' do
        json = qs_api_create
        qs = Quizzes::QuizSubmission.find(json['quiz_submissions'][0]['id'])
        qs.mark_completed
        qs.save!

        qs_api_create(true)
        expect(response.status.to_i).to eq 409
      end
    end
  end

  describe 'POST /courses/:course_id/quizzes/:quiz_id/submissions/:id/complete [complete]' do
    before :once do
      enroll_student

      @quiz_submission = @quiz.generate_submission(@student)
      # @quiz_submission.submission_data = { "question_1" => "1658" }
    end

    it 'should complete a quiz submission' do
      json = qs_api_complete false, {
        attempt: 1
      }

      expect(json.has_key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
      expect(json['quiz_submissions'][0]['workflow_state']).to eq 'complete'
    end

    context 'access validations' do
      include_examples 'Quiz Submissions API Restricted Endpoints'

      before do
        @request_proxy = method(:qs_api_complete)
      end

      it 'should reject completing an already complete QS' do
        @quiz_submission.mark_completed
        Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission

        json = qs_api_complete true, {
          attempt: 1
        }

        assert_status(400)
        expect(response.body).to match(/already complete/)
      end

      it 'should require the attempt index' do
        json = qs_api_complete true

        assert_status(400)
        expect(response.body).to match(/invalid attempt/)
      end

      it 'should require the current attempt index' do
        json = qs_api_complete true, {
          attempt: 123123123
        }

        assert_status(400)
        expect(response.body).to match(/attempt.*can not be modified/)
      end

      it 'should require a valid validation token' do
        json = qs_api_complete true, {
          validation_token: 'aaaooeeeee'
        }

        assert_status(403)
        expect(response.body).to match(/invalid token/)
      end
    end
  end

  describe 'PUT /courses/:course_id/quizzes/:quiz_id/submissions/:id [update]' do
    before :once do
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

      expect(json.has_key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
      expect(json['quiz_submissions'][0]['fudge_points']).to eq 2.5
      expect(json['quiz_submissions'][0]['score']).to eq 97.5
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

      expect(json.has_key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
      expect(json['quiz_submissions'][0]['score']).to eq 55
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
      expect(@quiz_submission.submission_data[1]['more_comments']).to eq 'Aaaaaughibbrgubugbugrguburgle'

      # make sure no score is affected
      expect(@quiz_submission.submission_data[1]['points']).to eq 45
      expect(@quiz_submission.score).to eq @original_score
    end
  end
end
