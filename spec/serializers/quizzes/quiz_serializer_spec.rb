#
# Copyright (C) 2013 - present Instructure, Inc.
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

require 'spec_helper'

describe Quizzes::QuizSerializer do

  def quiz_serializer(options={})
    options.reverse_merge!({
      controller: controller,
      scope: @user,
      session: @session
    })
    Quizzes::QuizSerializer.new(@quiz, options)
  end
  let(:quiz) { @quiz }
  let(:context ) { @context }
  let(:serializer) { @serializer }
  let(:host_name) { 'example.com' }
  let(:json) { @json }
  let(:session) { @session }
  let(:controller) do
    ActiveModel::FakeController.new(accepts_jsonapi: true, stringify_json_ids: false)
  end

  before do
    @context = Account.default.courses.new
    @context.id = 1
    @quiz = Quizzes::Quiz.new title: 'test quiz', description: 'default quiz description'
    @quiz.id = 1
    @quiz.context = @context
    @user = User.new
    allow(@quiz).to receive(:locked_for?).and_return false
    allow(@quiz).to receive(:check_right?).and_return true
    @session = double(:[] => nil)
    allow(controller).to receive(:session).and_return session
    allow(controller).to receive(:context).and_return context
    allow(@quiz).to receive(:grants_right?).at_least(:once).and_return true
    allow(@context).to receive(:grants_right?).at_least(:once).and_return true
    @serializer = quiz_serializer
    @json = @serializer.as_json[:quiz]
  end

  [
    :title, :quiz_type, :hide_results, :time_limit,
    :shuffle_answers, :show_correct_answers, :scoring_policy,
    :allowed_attempts, :one_question_at_a_time, :question_count,
    :points_possible, :cant_go_back, :access_code, :ip_filter, :due_at,
    :lock_at, :unlock_at, :published, :show_correct_answers_at,
    :hide_correct_answers_at, :show_correct_answers_last_attempt,
    :has_access_code, :migration_id
  ].each do |attribute|

      it "serializes #{attribute}" do
        expect(json[attribute]).to eq quiz.send(attribute)
      end
    end

  it "serializes mobile_url" do
    expect(json[:mobile_url]).to eq 'http://example.com/courses/1/quizzes/1?force_user=1&persist_headless=1'
  end

  it "serializes html_url" do
    expect(json[:html_url]).to eq 'http://example.com/courses/1/quizzes/1'
  end


  describe "description" do
    it "serializes description with a formatter if given" do
      @serializer = quiz_serializer(
        serializer_options: {
          description_formatter: -> (_) {return "description from formatter"}
        }
      )
      json = @serializer.as_json[:quiz]

      expect(json[:description]).to eq "description from formatter"
    end

    it "returns desctiption otherwise" do
      expect(json[:description]).to eq quiz.description
    end
  end

  describe "description for locked quiz" do
    it "returns an empty string for students" do
      serializer = quiz_serializer()
      allow(serializer).to receive('quiz_locked_for_user?').and_return true
      allow(serializer).to receive('user_is_student?').and_return true
      json = serializer.as_json[:quiz]
      expect(json[:description]).to eq ''
    end

    it "returns description for non-students" do
      json = serializer.as_json[:quiz]
      allow(serializer).to receive('quiz_locked_for_user?').and_return true
      allow(serializer).to receive('user_is_student?').and_return false
      expect(json[:description]).to eq quiz.description
    end
  end

  it "serializes speed_grader_url" do
    # No assignment, so it should be nil
    expect(json[:speed_grader_url]).to be_nil
    assignment = Assignment.new
    assignment.id = 1
    assignment.context_id = @context.id
    allow(@quiz).to receive(:assignment).and_return assignment

    # nil when quiz is unpublished
    allow(@quiz).to receive(:published?).and_return false
    expect(@serializer.as_json[:quiz][:speed_grader_url]).to be_nil

    # nil when context doesn't allow speedgrader
    allow(@quiz).to receive(:published?).and_return true
    expect(assignment).to receive(:can_view_speed_grader?).with(@user).and_return false
    expect(@serializer.as_json[:quiz][:speed_grader_url]).to be_nil

    expect(assignment).to receive(:can_view_speed_grader?).with(@user).and_return true
    json = @serializer.as_json[:quiz]
    expect(json[:speed_grader_url]).to eq(
      controller.send(:speed_grader_course_gradebook_url, @quiz.context, assignment_id: @quiz.assignment.id)
    )

    # Students shouldn't be able to see speed_grader_url
    allow(@quiz).to receive(:grants_right?).and_return false
    allow(@context).to receive(:grants_right?).and_return false
    expect(@serializer.as_json[:quiz]).not_to have_key :speed_grader_url
  end

  it "doesn't include the section count unless the user can grade" do
    result = true
    allow(quiz.context).to receive(:grants_right?).with(@user, :manage_grades) { result }
    expect(serializer.as_json[:quiz]).to have_key :section_count

    result = false
    expect(serializer.as_json[:quiz]).not_to have_key :section_count
  end

  it "uses available_question_count for question_count" do
    allow(quiz).to receive(:available_question_count).and_return 5
    expect(serializer.as_json[:quiz][:question_count]).to eq 5
  end

  it "sends the message_students_url when user can grade" do
    result = true
    allow(quiz.context).to receive(:grants_right?) { result }
    expect(serializer.as_json[:quiz][:message_students_url]).to eq(
      controller.send(:api_v1_course_quiz_submission_users_message_url, quiz, quiz.context)
    )

    result = false
    expect(serializer.as_json[:quiz]).not_to have_key :message_students_url
  end

  describe "access code" do
    it "is included if the user can grade" do
      expect(quiz.context).to receive(:grants_right?).with(@user, :manage_grades).
        at_least(:once).and_return true
      expect(serializer.as_json[:quiz]).to have_key :access_code
    end

    it "is included if the user can manage" do
      expect(quiz.context).to receive(:grants_right?).with(@user, :manage_assignments).
        at_least(:once).and_return true
      expect(serializer.as_json[:quiz]).to have_key :access_code
    end

    it "is not included if the user can't grade or manage" do
      expect(quiz.context).to receive(:grants_right?).with(@user, :manage_grades).
        at_least(:once).and_return false
      expect(quiz.context).to receive(:grants_right?).with(@user, :manage_assignments).
        at_least(:once).and_return false
      expect(serializer.as_json[:quiz]).not_to have_key :access_code
    end
  end

  describe "id" do

    it "stringifys when stringify_json_ids? is true" do
      expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return false
      expect(controller).to receive(:stringify_json_ids?).at_least(:once).and_return true
      expect(serializer.as_json[:quiz][:id]).to eq quiz.id.to_s
    end

    it "when stringify_json_ids? is false" do
      expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return false
      expect(serializer.as_json[:quiz][:id]).to eq quiz.id
      expect(serializer.as_json[:quiz][:id].is_a?(Integer)).to be_truthy
    end

  end

  describe "lock_info" do
    it "includes lock_info when appropriate" do
      expect(quiz).to receive(:locked_for?).
        with(@user, check_policies: true, context: @context).
        and_return({due_at: true})
      json = quiz_serializer.as_json[:quiz]
      expect(json).to have_key :lock_info
      expect(json).to have_key :lock_explanation
      expect(json[:locked_for_user]).to eq true

      expect(quiz).to receive(:locked_for?).
        with(@user, check_policies: true, context: @context).
        and_return false
      json = quiz_serializer.as_json[:quiz]
      expect(json).not_to have_key :lock_info
      expect(json).not_to have_key :lock_explanation
      expect(json[:locked_for_user]).to eq false
    end

    it "doesn't if skip_lock_tests is on" do
      json = quiz_serializer({
        serializer_options: {
          skip_lock_tests: true
        }
      }).as_json[:quiz]
      expect(json).not_to have_key :lock_info
      expect(json).not_to have_key :lock_explanation
      expect(json).not_to have_key :locked_for_user
    end
  end

  describe "unpublishable" do

    it "is not present unless the user can manage the quiz's assignments" do
      manage_result = true
      allow(context).to receive(:grants_right?).with(@user, :manage_assignments) { manage_result }
      expect(serializer.filter(serializer.class._attributes)).to include :unpublishable

      manage_result = false
      expect(serializer.filter(serializer.class._attributes)).not_to include :unpublishable
    end
  end

  describe "takeable" do
    before { skip }
    before do
      course_with_teacher(active_all: true)
      course_quiz(true)
      quiz_with_graded_submission([], user: @teacher, quiz: @quiz)
      @serializer = quiz_serializer(quiz_submissions: { @quiz.id => @quiz_submission })
    end

    it "is true when there is no quiz submision" do
      Quizzes::QuizSubmission.delete_all
      expect(quiz_serializer.as_json[:quiz][:takeable]).to eq true
    end

    it "is true when quiz_submission is present but not completed" do
      @quiz_submission.workflow_state = "settings_only"
      expect(@serializer.as_json[:quiz][:takeable]).to eq true
    end

    it "is true when the quiz submission is completed but quiz has unlimited attempts" do
      @quiz_submission.workflow_state = "complete"
      @quiz.allowed_attempts = -1
      expect(@serializer.as_json[:quiz][:takeable]).to eq true
    end

    it "is true when quiz submission is completed, !quiz.unlimited_attempts" do
      @quiz_submission.workflow_state = "complete"
      @quiz.allowed_attempts = 2
      # false when attempts left attempts is 0
      expect(@quiz_submission).to receive(:attempts_left).at_least(:once).and_return 0
      expect(@serializer.as_json[:quiz][:takeable]).to eq false
      # true when than attempts left greater than 0
      expect(@quiz_submission).to receive(:attempts_left).at_least(:once).and_return 1
      expect(@serializer.as_json[:quiz][:takeable]).to eq true
    end
  end

  describe "preview_url" do

    it "is only present when the user can grade the quiz" do
      course_with_teacher(active_all: true)
      course_quiz(true)
      expect(quiz_serializer(scope: @teacher).as_json[:quiz][:preview_url]).
        to eq controller.send(:course_quiz_take_url, @quiz.context, @quiz, preview: '1')
      course_with_student(active_all: true, course: @course)
      expect(quiz_serializer(scope: @student).as_json[:quiz]).not_to have_key :preview_url
    end
  end

  describe "links" do

    describe "assignment_group" do

      context "controller accepts_jsonapi?" do
        before { skip }

        it "serialize the assignment group's url when present" do
          allow(@quiz).to receive(:context).and_return course = Account.default.courses.new
          course.id = 1
          @quiz.assignment_group = assignment_group = AssignmentGroup.new
          assignment_group.id = 1
          expect(serializer.as_json[:quiz]['links']['assignment_group']).to eq(
            controller.send(:api_v1_course_assignment_group_url, course.id,
                            assignment_group.id)
          )
        end

        it "doesn't serialize the assignment group's url if not present" do
          expect(serializer.as_json[:quiz]).not_to have_key(:links)
        end
      end

      context "controller doesn't accept jsonapi" do

        it "serialized the assignment_group as assignment_group_id" do
          expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return false
          expect(serializer.as_json[:quiz]['assignment_group_id']).to be_nil

          group = quiz.assignment_group = AssignmentGroup.new
          group.id = quiz.assignment_group_id = 1
          expect(serializer.as_json[:quiz][:assignment_group_id]).to eq 1
        end
      end
    end

    describe "student_quiz_submissions" do
      before { skip }
      context "when user may grade" do

        it "sends the url for all submissions" do
          course_with_teacher(active_all: true)
          quiz_with_graded_submission([], course: @course)
          serializer = quiz_serializer(scope: @teacher)
          expect(serializer.as_json[:quiz]['links']['student_quiz_submissions']).to eq(
            controller.send(:api_v1_course_quiz_submissions_url, @quiz.context.id, @quiz.id)
          )
        end

        it "sends the url when no student_quiz_submissions are present" do
          course_with_teacher(active_all: true)
          serializer = quiz_serializer(scope: @teacher)
          expect(serializer.as_json[:quiz]['links']['student_quiz_submissions']).to eq(
            controller.send(:api_v1_course_quiz_submissions_url, @quiz.context.id, @quiz.id)
          )
        end

      end

      context "when user may not grade" do

        it "sends nil" do
          course_with_student(active_all: true)
          quiz_with_graded_submission([], user: @student, course: @course)
          serializer = quiz_serializer(scope: @student)
          expect(serializer.as_json[:quiz]['links']['student_quiz_submissions']).to be_nil
        end

      end

    end

    describe "quiz_submission" do
      before { skip }
      it "includes the quiz_submission in the response if it is present" do
        course_with_student(active_all: true)
        quiz_with_graded_submission([], user: @student, course: @course)
        serializer = quiz_serializer(scope: @student)
        json = serializer.as_json
        expect(json['quiz_submissions'].length).to eq 1
        expect(json[:quiz]['links']['quiz_submission']).to eq @quiz_submission.id.to_s
      end
    end

    describe 'quiz_reports' do
      it 'sends the url' do
        allow(quiz).to receive_messages(context: Account.default.courses.create!)
        expect(serializer.as_json[:quiz]['links']['quiz_reports']).to eq(
          controller.send(:api_v1_course_quiz_reports_url, quiz.context.id, quiz.id)
        )
      end

      it 'sends the url as quiz_reports_url' do
        expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return false
        allow(quiz).to receive_messages(context: Account.default.courses.create!)
        expect(serializer.as_json[:quiz][:quiz_reports_url]).to eq(
          controller.send(:api_v1_course_quiz_reports_url, quiz.context.id, quiz.id)
        )
      end
    end

    describe "quiz_statistics" do
      it "sends the url" do
        allow(quiz).to receive_messages(context: Account.default.courses.create!)
        expect(serializer.as_json[:quiz]['links']['quiz_statistics']).to eq(
          controller.send(:api_v1_course_quiz_statistics_url, quiz.context.id, quiz.id)
        )
      end

      it "sends the url in non-JSONAPI too" do
        expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return false
        allow(quiz).to receive_messages(context: Account.default.courses.create!)
        expect(serializer.as_json[:quiz][:quiz_statistics_url]).to eq(
          controller.send(:api_v1_course_quiz_statistics_url, quiz.context.id, quiz.id)
        )
      end
    end

    describe "submitted_students" do
      before { skip }
      it "sends nil if user can't grade" do
        course_with_student(active_all: true)
        @quiz.unstub(:check_right?)
        @quiz.unstub(:grants_right?)
        @quiz.context.unstub(:grants_right?)
        serializer = quiz_serializer(scope: @student)
        expect(serializer.as_json[:quiz]['links']).not_to have_key 'unsubmitted_students'
      end

      it "sends a url if there are submissions and user can grade" do
        course_with_teacher(active_all: true)
        course_with_student(active_all: true, course: @course)
        quiz_with_graded_submission([], user: @student, course: @course)
        serializer = quiz_serializer(scope: @teacher)
        expect(serializer.as_json[:quiz]['links']['submitted_students']).
          to eq controller.send(:api_v1_course_quiz_submission_users_url,
                                    @quiz.context,
                                    @quiz,
                                    submitted: true)
      end
    end

    describe "unsubmitted_students" do
      before { skip }
      it "sends nil if user can't grade" do
        @quiz.unstub(:check_right?)
        @quiz.unstub(:grants_right?)
        @quiz.context.unstub(:grants_right?)
        course_with_student(active_all: true)
        serializer = quiz_serializer(scope: @student)
        expect(serializer.as_json[:quiz]['links']).not_to have_key 'unsubmitted_students'
      end

      it "sends a url if there are submissions and user can grade" do
        course_with_teacher(active_all: true)
        course_with_student(active_all: true, course: @course)
        course_with_student(active_all: true, course: @course)
        quiz_with_graded_submission([], user: @student, course: @course)
        serializer = quiz_serializer(scope: @teacher)
        expect(serializer.as_json[:quiz]['links']['unsubmitted_students']).
          to eq controller.send(:api_v1_course_quiz_submission_users_url,
                                    @quiz.context,
                                    @quiz,
                                    submitted: 'false')
      end
    end
  end

  describe "quiz_submission_html_url" do
    it "includes a url to the quiz_submission html only if JSONAPI request" do
      expect(serializer.as_json[:quiz][:quiz_submission_html_url]).to eq(
        controller.send(:course_quiz_submission_html_url, context.id, quiz.id)
      )
      expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return false
      expect(serializer.as_json[:quiz]).not_to have_key :quiz_submission_html_url
    end
  end

  describe "quiz_submissions_zip_url" do
    it "includes a url to download all files" do
      expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return true
      expect(serializer).to receive(:user_may_grade?).at_least(:once).and_return true
      expect(serializer).to receive(:has_file_uploads?).at_least(:once).and_return true
      expect(serializer.as_json[:quiz][:quiz_submissions_zip_url]).to eq(
        'http://example.com/courses/1/quizzes/1/submissions?zip=1'
      )
    end

    it "doesn't if it's not a JSON-API request" do
      expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return false
      expect(serializer).to receive(:user_may_grade?).at_least(:once).and_return true
      expect(serializer.as_json[:quiz]).not_to have_key :quiz_submissions_zip_url
    end

    it "doesn't if the user may not grade" do
      expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return true
      expect(serializer).to receive(:user_may_grade?).at_least(:once).and_return false
      expect(serializer.as_json[:quiz]).not_to have_key :quiz_submissions_zip_url
    end

    it "doesn't if the quiz has no file upload questions" do
      expect(controller).to receive(:accepts_jsonapi?).at_least(:once).and_return true
      expect(serializer).to receive(:user_may_grade?).at_least(:once).and_return true
      expect(serializer).to receive(:has_file_uploads?).at_least(:once).and_return false
      expect(serializer.as_json[:quiz]).not_to have_key :quiz_submissions_zip_url
    end
  end

  describe "permissions" do
    it "serializes permissions" do
      expect(serializer.as_json[:quiz][:permissions]).to eq({
        read: true,
        submit: true,
        review_grades: true,
        create: true,
        update: true,
        read_statistics: true,
        view_answer_audits: true,
        manage: true,
        delete: true,
        grade: true,
        preview: true
      })
    end
  end

  it 'displays overridden dates for students' do
    course_with_student(active_all: true)
    course_quiz(true)
    serializer = quiz_serializer(scope: @student)
    student_overrides = {
      due_at: 5.minutes.from_now,
      lock_at: nil,
      unlock_at: 3.minutes.from_now
    }

    allow(serializer).to receive(:due_dates).and_return [student_overrides]

    output = serializer.as_json[:quiz]
    expect(output).not_to have_key :all_dates

    [ :due_at, :lock_at, :unlock_at ].each do |key|
      expect(output[key]).to eq student_overrides[key]
    end
  end

  it 'displays quiz dates for students if not overridden' do
    student_overrides = []

    expect(quiz).to receive(:due_at).at_least(:once).and_return 5.minutes.from_now
    expect(quiz).to receive(:lock_at).at_least(:once).and_return nil
    expect(quiz).to receive(:unlock_at).at_least(:once).and_return 3.minutes.from_now
    allow(serializer).to receive(:due_dates).and_return student_overrides

    output = serializer.as_json[:quiz]

    [ :due_at, :lock_at, :unlock_at ].each do |key|
      expect(output[key]).to eq quiz.send(key)
    end
  end

  it 'includes all_dates for teachers and observers' do
    quiz.due_at = 1.hour.from_now

    teacher_overrides = [{
      due_at: quiz.due_at,
      lock_at: nil,
      unlock_at: nil,
      base: true
    }, {
      due_at: 30.minutes.from_now,
      lock_at: 1.hour.from_now,
      unlock_at: 10.minutes.from_now,
      title: 'Some Section'
    }]

    expect(quiz).to receive(:due_at).at_least(:once)
    allow(serializer).to receive(:all_dates).and_return teacher_overrides
    allow(serializer).to receive(:include_all_dates?).and_return true

    output = serializer.as_json[:quiz]
    expect(output).to have_key :all_dates
    expect(output[:all_dates].length).to eq 2
    expect(output[:all_dates].detect { |e| e[:base] }).to eq teacher_overrides[0]
    expect(output[:all_dates].detect { |e| !e[:base] }).to eq teacher_overrides[1]
    expect(output[:due_at]).to eq quiz.due_at
  end

  describe "only_visible_to_overrides" do
    context "as a teacher" do
      before :once do
        course_with_teacher(active_all: true)
        course_quiz(true)
      end

      it "returns the value for DA" do
        @quiz.only_visible_to_overrides = true
        json = quiz_serializer(scope: @teacher).as_json
        expect(json[:quiz][:only_visible_to_overrides]).to be_truthy

        @quiz.only_visible_to_overrides = false
        json = quiz_serializer(scope: @teacher).as_json
        expect(json[:quiz]).to have_key :only_visible_to_overrides
        expect(json[:quiz][:only_visible_to_overrides]).to be_falsey
      end
    end

    context "as a student" do
      before :once do
        course_with_student(active_all: true)
        course_quiz(true)
      end

      it "is not in the hash" do
        @quiz.only_visible_to_overrides = true
        json = quiz_serializer(scope: @student).as_json
        expect(json[:quiz]).not_to have_key :only_visible_to_overrides
      end
    end

  end

  it "includes anonymous_submisions if quiz is a survey quiz" do
    expect(json.keys).to_not include(:anonymous_submissions)

    quiz.quiz_type = 'survey'
    quiz.anonymous_submissions = true
    new_json = quiz_serializer.as_json[:quiz]
    expect(new_json[:anonymous_submissions]).to eq true
  end

  it "does not include question_types" do
    expect(json.keys).not_to include(:question_types)
  end
end
