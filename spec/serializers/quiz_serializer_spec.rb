require 'spec_helper'

describe QuizSerializer do
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
    @quiz = Quiz.new title: 'test quiz'
    @quiz.id = 1
    @quiz.context = @context
    @user = User.new
    @quiz.stubs(:locked_for?).returns false
    @quiz.stubs(:grants_right?).returns true
    @session = stub
    controller.stubs(:session).returns session
    controller.stubs(:context).returns context
    @serializer = QuizSerializer.new(@quiz,
                                     controller: controller,
                                     scope: @user,
                                     session: @session)
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
    json[:mobile_url].should ==
      controller.polymorphic_url([context, quiz],
                                 persist_headless: 1, force_user: 1)
  end

  it "serializes html_url" do
    json[:html_url].should ==
      controller.polymorphic_url([context, quiz])
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
      json = QuizSerializer.new(quiz, scope: @user, controller: controller).
        as_json[:quiz]
      json.should have_key :lock_info
      json.should have_key :lock_explanation
      json[:locked_for_user].should == true

      quiz.expects(:locked_for?).
        with(@user, check_policies: true, context: @context).
        returns false
      json = QuizSerializer.new(quiz, scope: @user, controller: controller).
        as_json[:quiz]
      json.should_not have_key :lock_info
      json.should_not have_key :lock_explanation
      json[:locked_for_user].should == false
    end
  end

  describe "unpublishable" do

    it "is not present unless the user can manage the quiz's assignments" do
      quiz.expects(:grants_right?).with(@user, session, :manage).returns true
      serializer.as_json[:quiz].should have_key :unpublishable
      quiz.unstub(:grants_right?)

      quiz.expects(:grants_right?).with(@user, session, :update).at_least_once.returns false
      quiz.expects(:grants_right?).with(@user, session, :grade).at_least_once.returns false
      quiz.expects(:grants_right?).with(@user, session, :manage).at_least_once.returns false
      serializer.as_json[:quiz].should_not have_key :unpublishable
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
          serializer.as_json[:quiz][:links][:assignment_group].should ==
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
  end

end
