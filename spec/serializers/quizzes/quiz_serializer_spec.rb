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
    @context = Course.new
    @context.id = 1
    @quiz = Quizzes::Quiz.new title: 'test quiz'
    @quiz.id = 1
    @quiz.context = @context
    @user = User.new
    @quiz.stubs(:locked_for?).returns false
    @quiz.stubs(:grants_right?).returns true
    @session = stub(:[] => nil)
    controller.stubs(:session).returns session
    controller.stubs(:context).returns context
    @quiz.stubs(:grants_right?).at_least_once.returns true
    @serializer = quiz_serializer
    @json = @serializer.as_json[:quiz]
  end

  [
    :title, :description, :quiz_type, :hide_results,
    :time_limit, :shuffle_answers, :show_correct_answers, :scoring_policy,
    :allowed_attempts, :one_question_at_a_time, :question_count,
    :points_possible, :cant_go_back, :access_code, :ip_filter, :due_at,
    :lock_at, :unlock_at, :published, :show_correct_answers_at,
    :hide_correct_answers_at
  ].each do |attribute|

      it "serializes #{attribute}" do
        json[attribute].should == quiz.send(attribute)
      end
    end

  it "serializes mobile_url" do
    json[:mobile_url].should == 'http://example.com/courses/1/quizzes/1?force_user=1&persist_headless=1'
  end

  it "serializes html_url" do
    json[:html_url].should == 'http://example.com/courses/1/quizzes/1'
  end

  it "serializes speed_grader_url" do
    # No assignment, so it should be nil
    json[:speed_grader_url].should be_nil
    assignment = Assignment.new
    assignment.id = 1
    assignment.context_id = @context.id
    @quiz.stubs(:assignment).returns assignment

    # nil when quiz is unpublished
    @quiz.stubs(:published?).returns false
    @serializer.as_json[:quiz][:speed_grader_url].should be_nil

    # nil when context doesn't allow speedgrader
    @quiz.stubs(:published?).returns true
    @context.expects(:allows_speed_grader?).returns false
    @serializer.as_json[:quiz][:speed_grader_url].should be_nil

    @context.expects(:allows_speed_grader?).returns true
    json = @serializer.as_json[:quiz]
    json[:speed_grader_url].should ==
      controller.send(:speed_grader_course_gradebook_url, @quiz.context, assignment_id: @quiz.assignment.id)

    # Students shouldn't be able to see speed_grader_url
    @quiz.stubs(:grants_right?).returns false
    @serializer.as_json[:quiz].should_not have_key :speed_grader_url
  end

  it "doesn't include the access code unless the user can grade" do
    quiz.expects(:grants_right?).with(@user, @session, :grade).
      at_least_once.returns true
    serializer.as_json[:quiz].should have_key :access_code

    quiz.expects(:grants_right?).with(@user, @session, :grade).
      at_least_once.returns false
    serializer.as_json[:quiz].should_not have_key :access_code
  end

  it "uses available_question_count for question_count" do
    quiz.stubs(:available_question_count).returns 5
    serializer.as_json[:quiz][:question_count].should == 5
  end

  it "sends the message_students_url when user can grade" do
    quiz.expects(:grants_right?).at_least_once.returns true
    serializer.as_json[:quiz][:message_students_url].should ==
      controller.send(:api_v1_course_quiz_submission_users_message_url, quiz, quiz.context)

    quiz.expects(:grants_right?).at_least_once.returns false
    serializer.as_json[:quiz].should_not have_key :message_students_url
  end

  describe "id" do

    it "stringifys when stringify_json_ids? is true" do
      controller.expects(:accepts_jsonapi?).at_least_once.returns false
      controller.expects(:stringify_json_ids?).at_least_once.returns true
      serializer.as_json[:quiz][:id].should == quiz.id.to_s
    end

    it "when stringify_json_ids? is false" do
      controller.expects(:accepts_jsonapi?).at_least_once.returns false
      serializer.as_json[:quiz][:id].should == quiz.id
      serializer.as_json[:quiz][:id].is_a?(Fixnum).should be_true
    end

  end

  describe "lock_info" do
    it "includes lock_info when appropriate" do
      quiz.expects(:locked_for?).
        with(@user, check_policies: true, context: @context).
        returns({due_at: true})
      json = quiz_serializer.as_json[:quiz]
      json.should have_key :lock_info
      json.should have_key :lock_explanation
      json[:locked_for_user].should == true

      quiz.expects(:locked_for?).
        with(@user, check_policies: true, context: @context).
        returns false
      json = quiz_serializer.as_json[:quiz]
      json.should_not have_key :lock_info
      json.should_not have_key :lock_explanation
      json[:locked_for_user].should == false
    end
  end

  describe "unpublishable" do

    it "is not present unless the user can manage the quiz's assignments" do
      quiz.expects(:grants_right?).with(@user, session, :manage).returns true
      serializer.filter(serializer.class._attributes).should include :unpublishable
      quiz.unstub(:grants_right?)
      quiz.expects(:grants_right?).with(@user, session, :grade).at_least_once.returns false
      quiz.expects(:grants_right?).with(@user, session, :manage).at_least_once.returns false
      serializer.filter(serializer.class._attributes).should_not include :unpublishable
    end
  end

  describe "links" do

    describe "assignment_group" do

      context "controller accepts_jsonapi?" do

        it "serialize the assignment group's url when present" do
          @quiz.stubs(:context).returns course = Course.new
          course.id = 1
          @quiz.assignment_group = assignment_group = AssignmentGroup.new
          assignment_group.id = 1
          serializer.as_json[:quiz]['links']['assignment_group'].should ==
            controller.send(:api_v1_course_assignment_group_url, course.id,
                            assignment_group.id)
        end

        it "doesn't serialize the assignment group's url if not present" do
          serializer.as_json[:quiz].should_not have_key(:links)
        end
      end

      context "controller doesn't accept jsonapi" do

        it "serialized the assignment_group as assignment_group_id" do
          controller.expects(:accepts_jsonapi?).at_least_once.returns false
          serializer.as_json[:quiz]['assignment_group_id'].should be_nil

          group = quiz.assignment_group = AssignmentGroup.new
          group.id = 1
          serializer.as_json[:quiz]['assignment_group_id'].should == 1
        end
      end
    end

    describe "quiz_submissions" do

      it "sends the url for all submissions when user may grade" do
        course_with_teacher_logged_in(active_all: true)
        quiz_with_graded_submission([], course: @course)
        serializer = quiz_serializer(scope: @teacher)
        serializer.as_json[:quiz]['links']['quiz_submissions'].should ==
          controller.send(:api_v1_course_quiz_submissions_url, @quiz.context.id, @quiz.id)
      end

      it "sends the url to a student's submission for students" do
        course_with_student_logged_in(active_all: true)
        quiz_with_graded_submission([], user: @student, course: @course)
        serializer = quiz_serializer(scope: @student)
        serializer.as_json[:quiz]['links']['quiz_submissions'].should ==
          controller.send(:api_v1_course_quiz_submission_url,
                          @quiz.context.id,
                          @quiz.id,
                          @quiz.quiz_submissions.where(user_id: @student).first.id)
      end

      it "sends nil if user can't grade and doesn't have a submission" do
        course_with_student_logged_in(active_all: true)
        serializer = quiz_serializer(scope: @student)
        serializer.as_json[:quiz]['links']['quiz_submissions'].should be_nil
      end
    end

    describe 'quiz_reports' do
      it 'sends the url' do
        quiz.stubs(context: Course.new.tap { |c| c.id = 3 })
        serializer.as_json[:quiz]['links']['quiz_reports'].should ==
          controller.send(:api_v1_course_quiz_reports_url, 3, quiz.id)
      end

      it 'sends the url as quiz_reports_url' do
        controller.expects(:accepts_jsonapi?).at_least_once.returns false
        quiz.stubs(context: Course.new.tap { |c| c.id = 3 })
        serializer.as_json[:quiz][:quiz_reports_url].should ==
          controller.send(:api_v1_course_quiz_reports_url, 3, quiz.id)
      end
    end

    describe "quiz_statistics" do
      it "sends the url" do
        quiz.stubs(context: Course.new.tap { |c| c.id = 3 })
        serializer.as_json[:quiz]['links']['quiz_statistics'].should ==
          controller.send(:api_v1_course_quiz_statistics_url, 3, quiz.id)
      end

      it "sends the url in non-JSONAPI too" do
        controller.expects(:accepts_jsonapi?).at_least_once.returns false
        quiz.stubs(context: Course.new.tap { |c| c.id = 3 })
        serializer.as_json[:quiz][:quiz_statistics_url].should ==
          controller.send(:api_v1_course_quiz_statistics_url, 3, quiz.id)
      end
    end

    describe "submitted_students" do

      it "sends nil if user can't grade" do
        course_with_student_logged_in(active_all: true)
        @quiz.unstub(:grants_right?)
        serializer = quiz_serializer(scope: @student)
        serializer.as_json[:quiz]['links'].should_not have_key 'unsubmitted_students'
      end

      it "sends a url if there are submissions and user can grade" do
        course_with_teacher_logged_in(active_all: true)
        course_with_student_logged_in(active_all: true, course: @course)
        quiz_with_graded_submission([], user: @student, course: @course)
        serializer = quiz_serializer(scope: @teacher)
        serializer.as_json[:quiz]['links']['submitted_students'].
          should == controller.send(:api_v1_course_quiz_submission_users_url,
                                    @quiz.context,
                                    @quiz,
                                    submitted: true)
      end
    end

    describe "unsubmitted_students" do

      it "sends nil if user can't grade" do
        @quiz.unstub(:grants_right?)
        course_with_student_logged_in(active_all: true)
        serializer = quiz_serializer(scope: @student)
        serializer.as_json[:quiz]['links'].should_not have_key 'unsubmitted_students'
      end

      it "sends a url if there are submissions and user can grade" do
        course_with_teacher_logged_in(active_all: true)
        course_with_student_logged_in(active_all: true, course: @course)
        course_with_student_logged_in(active_all: true, course: @course)
        quiz_with_graded_submission([], user: @student, course: @course)
        serializer = quiz_serializer(scope: @teacher)
        serializer.as_json[:quiz]['links']['unsubmitted_students'].
          should == controller.send(:api_v1_course_quiz_submission_users_url,
                                    @quiz.context,
                                    @quiz,
                                    submitted: 'false')
      end
    end
  end

  describe "quiz_submission_html_url" do
    it "includes a url to the quiz_submission html only if JSONAPI request" do
      serializer.as_json[:quiz][:quiz_submission_html_url].should ==
        controller.send(:course_quiz_submission_html_url, context.id, quiz.id)
      controller.expects(:accepts_jsonapi?).at_least_once.returns false
      serializer.as_json[:quiz].should_not have_key :quiz_submission_html_url
    end
  end

  describe "permissions" do
    it "serializes permissions" do
      serializer.as_json[:quiz][:permissions].should == {
        read: true,
        submit: true,
        review_grades: true,
        create: true,
        update: true,
        read_statistics: true,
        manage: true,
        delete: true,
        grade: true
      }
    end
  end

  it 'displays overridden dates for students' do
    student_overrides = {
      due_at: 5.minutes.from_now,
      lock_at: nil,
      unlock_at: 3.minutes.from_now
    }

    quiz.expects(:due_at).never
    quiz.expects(:lock_at).never
    quiz.expects(:unlock_at).never
    serializer.stubs(:due_dates).returns [student_overrides, nil]

    output = serializer.as_json[:quiz]
    output.should_not have_key :all_dates

    [ :due_at, :lock_at, :unlock_at ].each do |key|
      output[key].should == student_overrides[key]
    end
  end

  it 'displays quiz dates for students if not overridden' do
    quiz.expects(:due_at).at_least_once.returns 5.minutes.from_now
    quiz.expects(:lock_at).at_least_once.returns nil
    quiz.expects(:unlock_at).at_least_once.returns 3.minutes.from_now
    serializer.stubs(:due_dates).returns [nil, nil]

    output = serializer.as_json[:quiz]

    [ :due_at, :lock_at, :unlock_at ].each do |key|
      output[key].should == quiz.send(key)
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

    quiz.expects(:due_at).at_least_once
    quiz.expects(:lock_at).at_least_once
    quiz.expects(:unlock_at).at_least_once
    serializer.stubs(:due_dates).returns [nil, teacher_overrides]

    output = serializer.as_json[:quiz]
    output.should have_key :all_dates
    output[:all_dates].length.should == 2
    output[:all_dates].detect { |e| e[:base] }.should == teacher_overrides[0]
    output[:all_dates].detect { |e| !e[:base] }.should == teacher_overrides[1]
    output[:due_at].should == quiz.due_at
  end

end
