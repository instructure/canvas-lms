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

  module Helpers
    def enroll_student
      last_user = @teacher = @user
      student_in_course(active_all: true)
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

    def make_second_attempt
      @quiz_submission.attempt = 2
      @quiz_submission.with_versioning(true, &:save!)
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

    def qs_api_time(raw = false, data = {})
      url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}/time"
      params = { :controller => 'quizzes/quiz_submissions_api',
                 :action => 'time',
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
      expect(json.key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].size).to eq 0
    end

    it 'should return an empty list for a student' do
      enroll_student

      @user = @student

      json = qs_api_index
      expect(json.key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].size).to eq 0
    end

    it 'should list quiz submissions' do
      enroll_student_and_submit

      json = qs_api_index
      expect(json['quiz_submissions'].size).to eq 1
      # checking for the new field added in JSON response as part of fix CNVS-19664
      expect(json['quiz_submissions'].first["overdue_and_needs_submission"]).to eq false
    end

    it 'should be accessible by the owner student' do
      enroll_student_and_submit

      json = qs_api_index
      expect(json.key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
    end

    it 'should show multiple attempts of the same quiz' do
      enroll_student_and_submit
      make_second_attempt

      @user = @student

      json = qs_api_index
      expect(json.key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 2
    end

    it 'should show in progress attempt only when applicable' do
      enroll_student
      @quiz_submission = @quiz.generate_submission(@student)
      json = qs_api_index

      expect(json.key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
      expect(json['quiz_submissions'].first['started_at']).to be_truthy
      expect(json['quiz_submissions'].first['workflow_state']).to eq 'untaken'
      expect(json['quiz_submissions'].first['finished_at']).to eq nil
    end

    it 'should show most recent attemps of quiz to teacher' do
      enroll_student_and_submit
      make_second_attempt

      json = qs_api_index
      expect(json.key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
      expect(json['quiz_submissions'].first["attempt"]).to eq 2
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
      expect(json.key?('quiz_submissions')).to be_truthy
      expect(json['quiz_submissions'].length).to eq 1
    end

    it 'should be accessible implicitly to its own student as "self"' do
      @user = @student
      @quiz_submission.stubs(:id).returns 'self'

      json = qs_api_show
      expect(json.key?('quiz_submissions')).to be_truthy
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
        expect(json.key?('quiz_submissions')).to be_truthy

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
        expect(json.key?('quiz_submissions')).to be_truthy
        expect(json['quiz_submissions'][0]['time_spent']).to eq 5.minutes
      end

      it 'should include html_url' do
        json = qs_api_show
        expect(json.key?('quiz_submissions')).to be_truthy

        qs_json = json['quiz_submissions'][0]
        expect(qs_json['html_url']).to eq course_quiz_quiz_submission_url(@course, @quiz, @quiz_submission)
      end

      it 'should include results_url only when completed or needs_grading' do
        json = qs_api_show
        expect(json['quiz_submissions'][0].key?('result_url')).to be_truthy
        expected_url = course_quiz_history_url(
          @course, @quiz,
          quiz_submission_id: @quiz_submission.id, version: @quiz_submission.version_number
        )
        expect(json['quiz_submissions'][0]['result_url']).to eq expected_url

        @quiz_submission.update_attribute :workflow_state, 'in_progress'
        json = qs_api_show
        expect(json['quiz_submissions'][0].key?('result_url')).to be_falsey
      end
    end

    context 'Links' do
      it 'should include its linked user' do
        json = qs_api_show(false, {
          :include => [ 'user' ]
        })

        expect(json.key?('users')).to be_truthy
        expect(json['quiz_submissions'].size).to eq 1
        expect(json['users'].size).to eq 1
        expect(json['users'][0]['id']).to eq json['quiz_submissions'][0]['user_id']
      end

      it 'should include its linked quiz' do
        json = qs_api_show(false, {
          :include => [ 'quiz' ]
        })

        expect(json.key?('quizzes')).to be_truthy
        expect(json['quiz_submissions'].size).to eq 1
        expect(json['quizzes'].size).to eq 1
        expect(json['quizzes'][0]['id']).to eq json['quiz_submissions'][0]['quiz_id']
      end

      it 'should include its linked submission' do
        json = qs_api_show(false, {
          :include => [ 'submission' ]
        })

        expect(json.key?('submissions')).to be_truthy
        expect(json['quiz_submissions'].size).to eq 1
        expect(json['submissions'].size).to eq 1
        expect(json['submissions'][0]['id']).to eq json['quiz_submissions'][0]['submission_id']
      end

      it 'should include its linked user, quiz, and submission' do
        json = qs_api_show(false, {
          :include => [ 'user', 'quiz', 'submission' ]
        })

        expect(json.key?('users')).to be_truthy
        expect(json.key?('quizzes')).to be_truthy
        expect(json.key?('submissions')).to be_truthy
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
    context 'as a teacher' do
      it 'should create a preview quiz submission' do
        json = qs_api_create false, { preview: true }
        expect(Quizzes::QuizSubmission.find(json['quiz_submissions'][0]['id']).preview?).to be_truthy
      end
    end

    context 'as a student' do
      before :once do
        enroll_student
        @user = @student
      end

      it 'should create a quiz submission' do
        json = qs_api_create
        expect(json.key?('quiz_submissions')).to be_truthy
        expect(json['quiz_submissions'].length).to eq 1
        expect(json['quiz_submissions'][0]['workflow_state']).to eq 'untaken'
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

      context "unpublished module quiz" do
        before do
          student_in_course(active_all: true)
          @quiz = @course.quizzes.create! title: "Test Quiz w/ Module"
          @quiz.quiz_questions.create!(
            {
              question_data:
              {
                name: 'question',
                points_possible: 1,
                question_type: 'multiple_choice_question',
                'answers' =>
                  [
                    {'answer_text' => '1', 'weight' => '100'},
                    {'answer_text' => '2'},
                    {'answer_text' => '3'},
                    {'answer_text' => '4'}
                  ]
              }
          })
          @quiz.published_at = Time.zone.now
          @quiz.workflow_state = 'available'
          @quiz.save!
          @pre_module = @course.context_modules.create!(:name => 'pre_module')
          # No meaning in this URL
          @tag = @pre_module.add_item(:type => 'external_url', :url => 'http://example.com', :title => 'example')
          @tag.publish! if @tag.unpublished?
          @pre_module.completion_requirements = { @tag.id => { :type => 'must_view' } }
          @pre_module.save!

          locked_module = @course.context_modules.create!(name: 'locked_module', require_sequential_progress: true)
          locked_module.add_item(:id => @quiz.id, :type => 'quiz')
          locked_module.prerequisites = "module_#{@pre_module.id}"
          locked_module.save!
        end

        it "shouldn't allow access to quiz until module is completed" do
          expect(@quiz.grants_right?(@student, :submit)).to be_truthy # precondition
          json = api_call(:post,
                          "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions",
                          {
                            controller: "quizzes/quiz_submissions_api",
                            action: "create",
                            format: "json",
                            course_id: "#{@course.id}",
                            quiz_id: "#{@quiz.id}"
                          },
                          {},
                          {'Accept' => 'application/vnd.api+json'},
                          {expected_status: 400})
          expect(json['status']).to eq "bad_request"
        end

        it "should allow access to quiz once module is completed" do
          @course.context_modules.first.update_for(@student, :read, @tag)
          @course.context_modules.first.update_downstreams
          expect(@quiz.grants_right?(@student, :submit)).to be_truthy # precondition
          json = api_call(:post,
                          "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions",
                          {
                            controller: "quizzes/quiz_submissions_api",
                            action: "create",
                            format: "json",
                            course_id: "#{@course.id}",
                            quiz_id: "#{@quiz.id}"
                          },
                          {},
                          {'Accept' => 'application/vnd.api+json'})
          expect(json['quiz_submissions'][0]['user_id']).to eq @student.id
        end
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

      expect(json.key?('quiz_submissions')).to be_truthy
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

      expect(json.key?('quiz_submissions')).to be_truthy
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

      expect(json.key?('quiz_submissions')).to be_truthy
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

  describe "GET /courses/:course_id/quizzes/:quiz_id/submssions/:id/time" do
    before :once do
      enroll_student
      @user = @student

      @quiz_submission = @quiz.generate_submission(@student)
      @quiz_submission.update_attribute(:end_at, Time.now + 1.hour)
      Quizzes::QuizSubmission.where(:id => @quiz_submission).update_all(:updated_at => 1.hour.ago)
    end
    it "should give times for the quiz" do
      json = qs_api_time(false)
      expect(json).to have_key("time_left")
      expect(json).to have_key("end_at")
      expect(json["time_left"]).to be_within(5.0).of(60*60)
    end
    it "should reject a teacher other student" do
      @user = @teacher
      json = qs_api_time(true)
      assert_status(401)
    end
    it "should reject another student" do
      enroll_student
      @user = @student
      json = qs_api_time(true)
      assert_status(401)
    end
  end
end
