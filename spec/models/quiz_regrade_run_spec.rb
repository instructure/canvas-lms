require 'spec_helper'

describe QuizRegradeRun do

  def create_regrade_variables!
    course_with_student_logged_in
    course_quiz(course: @course)
    @regrade = QuizRegrade.create!(
      user_id: @student.id, quiz_id: @quiz.id, quiz_version: 1
    )
  end

  def create_regrade_run!
    run = QuizRegradeRun.
      create!(quiz_regrade_id: @regrade.id, started_at: Time.now)
    run.finished_at = Time.now
    run.save!
    run
  end

  it "validates presence of quiz_regrade_id" do
    QuizRegradeRun.new(quiz_regrade_id: 1).should be_valid
    QuizRegradeRun.new(quiz_regrade_id: nil).should_not be_valid
  end

  it "only sends notifications the first time a quiz regrade is performed" do
    # Load notifications into the database
    Canvas::MessageHelper.create_notification(
      name: 'Quiz Regrade Finished',
      delay_for: 0,
      category: 'Grading'
    )

    create_regrade_variables!
    run = create_regrade_run!
    run.reload.messages_sent.keys.size.should == 1
    run.clear_broadcast_messages

    # Should the regrade run ever get updated, don't send the notifications
    # again.
    run.finished_at = Time.now
    run.save!
    run.reload.messages_sent.keys.size.should == 0
    run.clear_broadcast_messages

    # Create another regrade run, as if a student turned in a submission after
    # the first regrade was kicked off.
    run2 = create_regrade_run!

    run2.reload.messages_sent.keys.size.should == 0
    run.reload.messages_sent.keys.size.should == 0
  end

  describe "#perform" do
    before(:each) do
      create_regrade_variables!
    end

    it "creates a new quiz regrade run" do
      QuizRegradeRun.first.should be_nil

      QuizRegradeRun.perform(@regrade) do
        # noop
      end

      run = QuizRegradeRun.first
      run.started_at.should_not be_nil
      run.finished_at.should_not be_nil
    end
  end
end
