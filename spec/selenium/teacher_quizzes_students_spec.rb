require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes students" do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  include_examples "quizzes selenium tests"

  context "as a teacher " do

    it "should allow a student view student to take a quiz" do
      course_with_teacher_logged_in

      quiz = @course.quizzes.create!(:title => "new quiz")
      quiz.quiz_questions.create!(:question_data => {
          :name => 'test 3',
          :question_type => 'multiple_choice_question',
          :answers => {'answer_0' => {'answer_text' => '0'}, 'answer_1' => {'answer_text' => '1'}}})
      quiz.generate_quiz_data
      quiz.workflow_state = 'available'
      quiz.save
      @fake_student = @course.student_view_student
      enter_student_view
      get "/courses/#{@course.id}/quizzes/#{quiz.id}"

      f("#take_quiz_link").click
      wait_for_ajaximations

      q = quiz.stored_questions[0]

      fj("input[type=radio][value=#{q[:answers][0][:id]}]").click
      expect(fj("input[type=radio][value=#{q[:answers][0][:id]}]").selected?).to be_truthy

      wait_for_js
      driver.execute_script("$('#submit_quiz_form .btn-primary').click()")

      keep_trying_until { expect(f('.quiz-submission .quiz_score .score_value')).to be_displayed }
      quiz_sub = @fake_student.reload.submissions.find_by_assignment_id(quiz.assignment.id)
      expect(quiz_sub).to be_present
      expect(quiz_sub.workflow_state).to eq "graded"
    end
  end
end
