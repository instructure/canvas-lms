require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes students" do
  it_should_behave_like "quizzes selenium tests"

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
    f("#question_#{q[:id]}_answer_#{q[:answers][0][:id]}").click
    submit_form('#submit_quiz_form')

    quiz_sub = @fake_student.reload.submissions.find_by_assignment_id(quiz.assignment.id)
    quiz_sub.should be_present
    quiz_sub.workflow_state.should eql "graded"
  end
end
