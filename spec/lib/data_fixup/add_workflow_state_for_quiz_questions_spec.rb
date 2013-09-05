require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper.rb")

describe DataFixup::AddWorkflowStateForQuizQuestions do

  it "adds an active workflow_state to every existing & active quiz question" do
    course_with_teacher_logged_in(active_all: true)
    quiz = @course.quizzes.create!(title: "Test Quiz")
    question_1 = quiz.quiz_questions.create!
    question_1.update_attribute(:workflow_state, nil)
    question_2 = quiz.quiz_questions.create!
    question_2.destroy

    DataFixup::AddWorkflowStateForQuizQuestions.run

    question_2.reload.workflow_state.should == 'deleted'
    question_1.reload.workflow_state.should == 'active'

  end
end

