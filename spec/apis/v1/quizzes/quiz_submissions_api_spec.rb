# frozen_string_literal: true

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

require_relative "../../api_spec_helper"

shared_examples_for "Quiz Submissions API Restricted Endpoints" do
  it "requires the LDB" do
    @quiz.require_lockdown_browser = true
    @quiz.save

    allow(Quizzes::Quiz).to receive(:lockdown_browser_plugin_enabled?).and_return true

    fake_plugin = Object.new
    allow(fake_plugin).to receive_messages(authorized?: false, base: fake_plugin)

    allow(subject).to receive(:ldb_plugin).and_return fake_plugin
    allow(Canvas::LockdownBrowser).to receive(:plugin).and_return fake_plugin

    @request_proxy.call true, {
      attempt: 1
    }

    assert_status(403)
    expect(response.body).to match(/requires the lockdown browser/i)
  end
end

describe Quizzes::QuizSubmissionsApiController, type: :request do
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
    value = 0 if value.is_a?(Float) && value.abs < Float::EPSILON
    value.to_json.to_s
  end

  def qs_api_index(raw = false, data = {})
    url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions.json"
    params = { controller: "quizzes/quiz_submissions_api",
               action: "index",
               format: "json",
               course_id: @course.id.to_s,
               quiz_id: @quiz.id.to_s }
    if raw
      raw_api_call(:get, url, params, data)
    else
      api_call(:get, url, params, data)
    end
  end

  def qs_api_submission(raw = false, data = {})
    url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submission.json"
    params = { controller: "quizzes/quiz_submissions_api",
               action: "submission",
               format: "json",
               course_id: @course.id.to_s,
               quiz_id: @quiz.id.to_s }
    if raw
      raw_api_call(:get, url, params, data)
    else
      api_call(:get, url, params, data)
    end
  end

  def qs_api_show(raw = false, data = {})
    url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}.json"
    params = { controller: "quizzes/quiz_submissions_api",
               action: "show",
               format: "json",
               course_id: @course.id.to_s,
               quiz_id: @quiz.id.to_s,
               id: @quiz_submission.id.to_s }
    if raw
      raw_api_call(:get, url, params, data)
    else
      api_call(:get, url, params, data)
    end
  end

  def qs_api_create(raw = false, data = {})
    url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions"
    params = { controller: "quizzes/quiz_submissions_api",
               action: "create",
               format: "json",
               course_id: @course.id.to_s,
               quiz_id: @quiz.id.to_s }
    if raw
      raw_api_call(:post, url, params, data)
    else
      api_call(:post, url, params, data)
    end
  end

  def qs_api_complete(raw = false, data = {})
    url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}/complete"
    params = { controller: "quizzes/quiz_submissions_api",
               action: "complete",
               format: "json",
               course_id: @course.id.to_s,
               quiz_id: @quiz.id.to_s,
               id: @quiz_submission.id.to_s }
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
    params = { controller: "quizzes/quiz_submissions_api",
               action: "update",
               format: "json",
               course_id: @course.id.to_s,
               quiz_id: @quiz.id.to_s,
               id: @quiz_submission.id.to_s }
    if raw
      raw_api_call(:put, url, params, data)
    else
      api_call(:put, url, params, data)
    end
  end

  def qs_api_time(raw = false, data = {})
    url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}/time"
    params = { controller: "quizzes/quiz_submissions_api",
               action: "time",
               format: "json",
               course_id: @course.id.to_s,
               quiz_id: @quiz.id.to_s,
               id: @quiz_submission.id.to_s }
    if raw
      raw_api_call(:get, url, params, data)
    else
      api_call(:get, url, params, data)
    end
  end

  before :once do
    course_with_teacher active_all: true

    @quiz = Quizzes::Quiz.create!(title: "quiz", context: @course)
    @quiz.published_at = Time.now
    @quiz.workflow_state = "available"
    @quiz.save!
  end

  describe "GET /courses/:course_id/quizzes/:quiz_id/submissions [INDEX]" do
    it "returns an empty list" do
      json = qs_api_index
      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].size).to eq 0
    end

    it "returns an empty list for a student" do
      enroll_student

      @user = @student

      json = qs_api_index
      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].size).to eq 0
    end

    it "lists quiz submissions" do
      enroll_student_and_submit

      json = qs_api_index
      expect(json["quiz_submissions"].size).to eq 1
      # checking for the new field added in JSON response as part of fix CNVS-19664
      expect(json["quiz_submissions"].first["overdue_and_needs_submission"]).to be false
    end

    it "is accessible by the owner student" do
      enroll_student_and_submit

      json = qs_api_index
      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].length).to eq 1
    end

    it "shows multiple attempts of the same quiz" do
      enroll_student_and_submit
      make_second_attempt

      @user = @student

      json = qs_api_index
      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].length).to eq 2
    end

    it "shows in progress attempt only when applicable" do
      enroll_student
      @quiz_submission = @quiz.generate_submission(@student)
      json = qs_api_index

      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].length).to eq 1
      expect(json["quiz_submissions"].first["started_at"]).to be_truthy
      expect(json["quiz_submissions"].first["workflow_state"]).to eq "untaken"
      expect(json["quiz_submissions"].first["finished_at"]).to be_nil
    end

    it "shows most recent attemps of quiz to teacher" do
      enroll_student_and_submit
      make_second_attempt

      json = qs_api_index
      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].length).to eq 1
      expect(json["quiz_submissions"].first["attempt"]).to eq 2
    end

    it "restricts access to itself" do
      student_in_course
      qs_api_index(true)
      assert_status(401)
    end

    it "includes submissions" do
      enroll_student_and_submit
      json = qs_api_index(false, { include: ["submission"] })
      expect(json).to have_key "submissions"
    end

    it "includes submission grading_status" do
      enroll_student_and_submit
      json = qs_api_index(false, { include: ["submission", "grading_status"] })
      expect(json.fetch("submissions")).to all have_key "grading_status"
    end

    it "includes submission submission_status" do
      enroll_student_and_submit
      json = qs_api_index(false, { include: ["submission", "submission_status"] })
      expect(json.fetch("submissions")).to all have_key "submission_status"
    end
  end

  describe "GET /courses/:course_id/quizzes/:quiz_id/submission" do
    context "as a student" do
      context "without a submission" do
        before do
          enroll_student
          @user = @student
        end

        it "is empty" do
          json = qs_api_submission
          expect(json).to have_key("quiz_submissions")
          expect(json["quiz_submissions"].size).to eq 0
        end
      end

      context "with a submission" do
        before do
          enroll_student_and_submit
          @user = @student
        end

        it "returns the submission" do
          json = qs_api_submission
          expect(json).to have_key("quiz_submissions")
          expect(json["quiz_submissions"].length).to eq 1

          json_quiz_submission = json["quiz_submissions"].first
          expect(json_quiz_submission["id"]).to eq @quiz_submission.id
        end

        context "with multiple attempts" do
          before do
            make_second_attempt
          end

          it "returns the submission" do
            json = qs_api_submission
            expect(json).to have_key("quiz_submissions")
            expect(json["quiz_submissions"].length).to eq 1

            json_quiz_submission = json["quiz_submissions"].first
            expect(json_quiz_submission["id"]).to eq @quiz_submission.id
            expect(json_quiz_submission["attempt"]).to eq 2
          end
        end
      end
    end

    context "as a teacher" do
      context "when a student has a submission" do
        before do
          enroll_student_and_submit
        end

        it "does not include the student submission" do
          json = qs_api_submission
          expect(json).to have_key("quiz_submissions")
          expect(json["quiz_submissions"].size).to eq 0
        end
      end
    end
  end

  describe "GET /courses/:course_id/quizzes/:quiz_id/submissions/:id [SHOW]" do
    before :once do
      enroll_student_and_submit
    end

    it "grants access to its student" do
      @user = @student
      json = qs_api_show
      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].length).to eq 1
    end

    it 'is accessible implicitly to its own student as "self"' do
      @user = @student
      allow(@quiz_submission).to receive(:id).and_return "self"

      json = qs_api_show
      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].length).to eq 1
    end

    it "denies access by other students" do
      student_in_course
      qs_api_show(true)
      assert_status(401)
    end

    context "Output" do
      it "includes the allowed quiz submission output fields" do
        json = qs_api_show
        expect(json).to have_key("quiz_submissions")

        qs_json = json["quiz_submissions"][0].with_indifferent_access

        output_fields = [] +
                        Api::V1::QuizSubmission::QUIZ_SUBMISSION_JSON_FIELDS +
                        Api::V1::QuizSubmission::QUIZ_SUBMISSION_JSON_FIELD_METHODS

        output_fields.each do |field|
          expect(qs_json).to have_key field
          expect(normalize(qs_json[field])).to eq normalize(@quiz_submission.send(field))
        end
      end

      it "includes time spent" do
        @quiz_submission.started_at = Time.now
        @quiz_submission.finished_at = @quiz_submission.started_at + 5.minutes
        @quiz_submission.save!

        json = qs_api_show
        expect(json).to have_key("quiz_submissions")
        expect(json["quiz_submissions"][0]["time_spent"]).to eq 5.minutes
      end

      it "includes html_url" do
        json = qs_api_show
        expect(json).to have_key("quiz_submissions")

        qs_json = json["quiz_submissions"][0]
        expect(qs_json["html_url"]).to eq course_quiz_quiz_submission_url(@course, @quiz, @quiz_submission)
      end

      it "includes results_url only when completed or needs_grading" do
        json = qs_api_show
        expect(json["quiz_submissions"][0]).to have_key("result_url")
        expected_url = course_quiz_history_url(
          @course,
          @quiz,
          quiz_submission_id: @quiz_submission.id,
          version: @quiz_submission.version_number
        )
        expect(json["quiz_submissions"][0]["result_url"]).to eq expected_url

        @quiz_submission.update_attribute :workflow_state, "in_progress"
        json = qs_api_show
        expect(json["quiz_submissions"][0]).not_to have_key("result_url")
      end
    end

    context "Links" do
      it "includes its linked user" do
        json = qs_api_show(false, {
                             include: ["user"]
                           })

        expect(json).to have_key("users")
        expect(json["quiz_submissions"].size).to eq 1
        expect(json["users"].size).to eq 1
        expect(json["users"][0]["id"]).to eq json["quiz_submissions"][0]["user_id"]
      end

      it "includes its linked quiz" do
        json = qs_api_show(false, {
                             include: ["quiz"]
                           })

        expect(json).to have_key("quizzes")
        expect(json["quiz_submissions"].size).to eq 1
        expect(json["quizzes"].size).to eq 1
        expect(json["quizzes"][0]["id"]).to eq json["quiz_submissions"][0]["quiz_id"]
      end

      it "includes its linked submission" do
        json = qs_api_show(false, {
                             include: ["submission"]
                           })

        expect(json).to have_key("submissions")
        expect(json["quiz_submissions"].size).to eq 1
        expect(json["submissions"].size).to eq 1
        expect(json["submissions"][0]["id"]).to eq json["quiz_submissions"][0]["submission_id"]
      end

      it "includes its linked user, quiz, and submission" do
        json = qs_api_show(false, {
                             include: %w[user quiz submission]
                           })

        expect(json).to have_key("users")
        expect(json).to have_key("quizzes")
        expect(json).to have_key("submissions")
      end
    end

    context "JSON-API compliance" do
      it "conforms to the JSON-API spec when returning the object" do
        json = qs_api_show(false)
        assert_jsonapi_compliance(json, "quiz_submissions")
      end

      it "conforms to the JSON-API spec when returning linked objects" do
        includes = %w[user quiz submission]

        json = qs_api_show(false, {
                             include: includes
                           })

        assert_jsonapi_compliance(json, "quiz_submissions", includes)
      end
    end
  end

  describe "POST /courses/:course_id/quizzes/:quiz_id/submissions [create]" do
    context "as a teacher" do
      it "creates a preview quiz submission" do
        json = qs_api_create false, { preview: true }
        expect(Quizzes::QuizSubmission.find(json["quiz_submissions"][0]["id"]).preview?).to be_truthy
      end
    end

    context "as a student" do
      before :once do
        enroll_student
        @user = @student
      end

      it "creates a quiz submission" do
        json = qs_api_create
        expect(json).to have_key("quiz_submissions")
        expect(json["quiz_submissions"].length).to eq 1
        expect(json["quiz_submissions"][0]["workflow_state"]).to eq "untaken"
      end

      it "allows the creation of multiple, subsequent QSes" do
        @quiz.allowed_attempts = -1
        @quiz.save

        json = qs_api_create
        qs = Quizzes::QuizSubmission.find(json["quiz_submissions"][0]["id"])
        qs.mark_completed
        qs.reload
        expect(qs).to be_complete

        qs_api_create
        qs.reload
        expect(qs).to be_untaken
      end

      context "access validations" do
        include_examples "Quiz Submissions API Restricted Endpoints"

        before do
          @request_proxy = method(:qs_api_create)
        end

        it "rejects creating a QS when one already exists" do
          qs_api_create
          qs_api_create(true)
          expect(response.status.to_i).to eq 409
        end

        it "respects the number of allowed attempts" do
          json = qs_api_create
          qs = Quizzes::QuizSubmission.find(json["quiz_submissions"][0]["id"])
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
                :name => "question",
                :points_possible => 1,
                :question_type => "multiple_choice_question",
                "answers" =>
                  [
                    { "answer_text" => "1", "weight" => "100" },
                    { "answer_text" => "2" },
                    { "answer_text" => "3" },
                    { "answer_text" => "4" }
                  ]
              }
            }
          )
          @quiz.published_at = Time.zone.now
          @quiz.workflow_state = "available"
          @quiz.save!
          @pre_module = @course.context_modules.create!(name: "pre_module")
          # No meaning in this URL
          @tag = @pre_module.add_item(type: "external_url", url: "http://example.com", title: "example")
          @tag.publish! if @tag.unpublished?
          @pre_module.completion_requirements = { @tag.id => { type: "must_view" } }
          @pre_module.save!

          locked_module = @course.context_modules.create!(name: "locked_module", require_sequential_progress: true)
          locked_module.add_item(id: @quiz.id, type: "quiz")
          locked_module.prerequisites = "module_#{@pre_module.id}"
          locked_module.save!
        end

        it "does not allow access to quiz until module is completed" do
          expect(@quiz.grants_right?(@student, :submit)).to be_truthy # precondition
          json = api_call(:post,
                          "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions",
                          {
                            controller: "quizzes/quiz_submissions_api",
                            action: "create",
                            format: "json",
                            course_id: @course.id.to_s,
                            quiz_id: @quiz.id.to_s
                          },
                          {},
                          { "Accept" => "application/vnd.api+json" },
                          { expected_status: 400 })
          expect(json["status"]).to eq "bad_request"
        end

        it "allows access to quiz once module is completed" do
          @course.context_modules.first.update_for(@student, :read, @tag)
          @course.context_modules.first.update_downstreams
          expect(@quiz.grants_right?(@student, :submit)).to be_truthy # precondition
          json = api_call(:post,
                          "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions",
                          {
                            controller: "quizzes/quiz_submissions_api",
                            action: "create",
                            format: "json",
                            course_id: @course.id.to_s,
                            quiz_id: @quiz.id.to_s
                          },
                          {},
                          { "Accept" => "application/vnd.api+json" })
          expect(json["quiz_submissions"][0]["user_id"]).to eq @student.id
        end
      end
    end
  end

  describe "POST /courses/:course_id/quizzes/:quiz_id/submissions/:id/complete [complete]" do
    before :once do
      enroll_student

      @quiz_submission = @quiz.generate_submission(@student)
      # @quiz_submission.submission_data = { "question_1" => "1658" }
    end

    it "completes a quiz submission" do
      json = qs_api_complete false, {
        attempt: 1
      }

      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].length).to eq 1
      expect(json["quiz_submissions"][0]["workflow_state"]).to eq "complete"
    end

    context "access validations" do
      include_examples "Quiz Submissions API Restricted Endpoints"

      before do
        @request_proxy = method(:qs_api_complete)
      end

      it "rejects completing an already complete QS" do
        @quiz_submission.mark_completed
        Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission

        qs_api_complete true, {
          attempt: 1
        }

        assert_status(400)
        expect(response.body).to match(/already complete/)
      end

      it "requires the attempt index" do
        qs_api_complete true

        assert_status(400)
        expect(response.body).to match(/invalid attempt/)
      end

      it "requires the current attempt index" do
        qs_api_complete true, {
          attempt: 123_123_123
        }

        assert_status(400)
        expect(response.body).to match(/attempt.*can not be modified/)
      end

      it "requires a valid validation token" do
        qs_api_complete true, {
          validation_token: "aaaooeeeee"
        }

        assert_status(403)
        expect(response.body).to match(/invalid token/)
      end
    end
  end

  describe "PUT /courses/:course_id/quizzes/:quiz_id/submissions/:id [update]" do
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
                                  "question_#{@qq2.id}" => "8950" # also correct, nr points: 45
                                })

      @original_score = @quiz_submission.score # should be 95
    end

    it "fudges points" do
      json = qs_api_update false, {
        quiz_submissions: [{
          attempt: @quiz_submission.attempt,
          fudge_points: 2.5
        }]
      }

      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].length).to eq 1
      expect(json["quiz_submissions"][0]["fudge_points"]).to eq 2.5
      expect(json["quiz_submissions"][0]["score"]).to eq 97.5
    end

    it "modifies a question score" do
      json = qs_api_update false, {
        quiz_submissions: [{
          attempt: @quiz_submission.attempt,
          questions: {
            @qq1.id.to_s => {
              score: 10
            }
          }
        }]
      }

      expect(json).to have_key("quiz_submissions")
      expect(json["quiz_submissions"].length).to eq 1
      expect(json["quiz_submissions"][0]["score"]).to eq 55
    end

    it "sets a comment" do
      qs_api_update false, {
        quiz_submissions: [{
          attempt: @quiz_submission.attempt,
          questions: {
            @qq2.id.to_s => {
              comment: "Aaaaaughibbrgubugbugrguburgle"
            }
          }
        }]
      }

      @quiz_submission.reload
      expect(@quiz_submission.submission_data[1]["more_comments"]).to eq "Aaaaaughibbrgubugbugrguburgle"

      # make sure no score is affected
      expect(@quiz_submission.submission_data[1]["points"]).to eq 45
      expect(@quiz_submission.score).to eq @original_score
    end
  end

  describe "GET /courses/:course_id/quizzes/:quiz_id/submssions/:id/time" do
    now = Time.now.utc
    around(:once_and_each) do |block|
      Timecop.freeze(now) { block.call }
    end

    before :once do
      enroll_student
      @user = @student

      @quiz_submission = @quiz.generate_submission(@student)
      @quiz_submission.update_attribute(:end_at, now + 1.hour)
      Quizzes::QuizSubmission.where(id: @quiz_submission).update_all(updated_at: now - 1.hour)
    end

    it "gives times for the quiz" do
      json = qs_api_time(false)
      expect(json).to have_key("time_left")
      expect(json).to have_key("end_at")
      expect(json["time_left"]).to be_within(5.0).of(60 * 60)
    end

    it "rejects a teacher other student" do
      @user = @teacher
      qs_api_time(true)
      assert_status(401)
    end

    it "rejects another student" do
      enroll_student
      @user = @student
      qs_api_time(true)
      assert_status(401)
    end
  end
end
