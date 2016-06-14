require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'Viewing graded quizzes' do
  include_context 'in-process server selenium tests'
  include QuizzesCommon

  def quiz_regrade_banner
    fj('.regraded-warning')
  end

  def quiz_question_regrade_banner
    fj('div.ui-state-warning:nth-child(2)')
  end

  def quiz_question_points_summary
    fj('.user_points', '.question_points_holder')
  end

  before(:once) do
    course_with_teacher(active_all: 1)
    student_in_course(active_all: 1)
    quiz_create(course: @course, unlimited_attempts: true)
  end

  context 'as a student' do
    before(:each) do
      user_session(@student)
      take_and_answer_quiz
    end

    context 'after the quiz questions have changed' do
      before(:each) do
        user_session(@teacher)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        click_questions_tab

        edit_first_question
        select_different_correct_answer(1)
        close_regrade_tooltip

        select_regrade_option(1)
        save_question
        expect_new_page_load { click_save_settings_button }

        # run delayed jobs to trigger quiz regrade
        run_jobs

        user_session(@student)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      end

      it 'shows a regrade banner on the quiz show page', priority: "1", test_id: 140630 do
        expect(quiz_regrade_banner).to include_text 'This quiz has been regraded; your score was affected.'
      end

      it 'shows the correct quiz score after regrading', priority: "1", test_id: 140631 do
        original_score = fj('.ic-Table > tbody:nth-child(2) > tr:nth-child(1) > td:nth-child(4)')
        expect(original_score.text).to eq '1 out of 1'

        regraded_score = fj('td.regraded')
        expect(regraded_score.text).to eq '0 out of 1'
      end

      it 'shows the correct quiz question score after regrading', priority: "1", test_id: 140632 do
        expect(quiz_question_regrade_banner).to include_text 'This question has been regraded.'
        expect(quiz_question_points_summary).to include_text 'Original Score: 1 / 1 pts'
        expect(quiz_question_points_summary).to include_text 'Regraded Score: 0 / 1 pts'
      end

      it 'hides all regrade banners and regrade info after resubmitting', priority: "1", test_id: 140633 do
        take_and_answer_quiz

        expect(quiz_regrade_banner).to be_nil

        expect(quiz_question_regrade_banner).to be_nil

        expect(quiz_question_points_summary).to include_text '0 / 1 pts'
        expect(quiz_question_points_summary).not_to include_text 'Original Score'
        expect(quiz_question_points_summary).not_to include_text 'Regraded Score'
      end
    end
  end
end
