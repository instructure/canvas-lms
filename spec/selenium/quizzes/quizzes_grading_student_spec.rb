require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'Viewing graded quizzes' do
  include_context 'in-process server selenium tests'
  include QuizzesCommon

  def quiz_regrade_banner_css
    '.regraded-warning'
  end

  def quiz_question_regrade_banner_css
    'div.ui-state-warning:nth-child(2)'
  end

  def quiz_question_points_summary
    f('.question_points_holder .user_points')
  end

  let_once(:question_data) do
    [{:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '', 'answer_html' => '<em>zero</em>', 'answer_weight' => '100'}, {'answer_text' => "", 'answer_html' => "<p>one</p>", 'answer_weight' => '0'}]}}]
  end

  before(:once) do
    course_with_teacher(active_all: 1)
    student_in_course(active_all: 1)

    quiz_with_graded_submission(question_data, user: @student, course: @course) do |questions|
      { "question_#{questions[0].id}" => questions[0].question_data["answers"][0]["id"] }
    end
    @quiz.update_attribute :allowed_attempts, -1
  end

  context 'as a student' do
    context 'after the quiz questions have changed' do
      before :once do
        # change up the quiz and regrade it
        question = @quiz.quiz_questions.first
        question_data = question.question_data.to_hash
        question_data["regrade_option"] = "current_correct_only"
        question_data["answers"][0]["answer_weight"] = 0
        question_data["answers"][1]["answer_weight"] = 100.0
        question_data["regrade_user"] = @teacher
        question.question_data = question_data
        question.save!
        @quiz.with_versioning(true) do
          @quiz.generate_quiz_data
          @quiz.save!
        end
        run_jobs # run it
      end

      before :each do
        user_session(@student)
      end

      it 'shows a regrade banner on the quiz show page', priority: "1", test_id: 140630 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

        expect(f(quiz_regrade_banner_css)).to include_text 'This quiz has been regraded; your score was affected.'
      end

      it 'shows the correct quiz score after regrading', priority: "1", test_id: 140631 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

        original_score = fj('.ic-Table > tbody:nth-child(2) > tr:nth-child(1) > td:nth-child(4)')
        expect(original_score).to include_text '1 out of 1'

        regraded_score = f('td.regraded')
        expect(regraded_score).to include_text '0 out of 1'
      end

      it 'shows the correct quiz question score after regrading', priority: "1", test_id: 140632 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

        expect(f(quiz_question_regrade_banner_css)).to include_text 'This question has been regraded.'
        expect(quiz_question_points_summary).to include_text 'Original Score: 1 / 1 pts'
        expect(quiz_question_points_summary).to include_text 'Regraded Score: 0 / 1 pts'
      end

      it 'hides all regrade banners and regrade info after resubmitting', priority: "1", test_id: 140633 do
        # retake it
        graded_submission(@quiz, @student) do |questions|
          { "question_#{questions[0].id}" => questions[0].question_data["answers"][0]["id"] }
        end

        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

        expect(f("#content")).not_to contain_css(quiz_regrade_banner_css)

        expect(f("#content")).not_to contain_css(quiz_question_regrade_banner_css)

        expect(quiz_question_points_summary).to include_text '0 / 1 pts'
        expect(quiz_question_points_summary).not_to include_text 'Original Score'
        expect(quiz_question_points_summary).not_to include_text 'Regraded Score'
      end
    end
  end
end
