require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'Grading quizzes' do
  include_context 'in-process server selenium tests'
  include QuizzesCommon

  context 'as a teacher' do
    before(:once) do
      course_with_teacher(active_all: 1)
      student_in_course(active_all: 1)
      @quiz = seed_quiz_with_submission(1, student: @student)
    end

    before(:each) { user_session(@teacher) }

    context 'when on the course home page' do
      before(:each) { get "/courses/#{@course.id}" }

      it 'To Do List includes quizzes with submissions that need grading', priority: "1", test_id: 140614 do
        expect(f('.right-side-list.to-do-list')).to include_text 'Grade Quiz Me!'
      end
    end

    context 'after changing a quiz question\'s correct answer' do
      before(:each) do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        click_questions_tab

        edit_first_question
        select_different_correct_answer(1)
      end

      it 'shows the regrade options', priority: "1", test_id: 140622 do
        # verify presence of regrade alert
        expect(fj('.ui-dialog:visible .alert')).to include_text 'Choose a regrade option for students who have already taken the quiz'

        # verify all regrade options are present
        expect(visible_regrade_options.count).to eq 4
      end

      it 'displays the selected regrade option on the correct answer' do
        option_text = fj('.regrade_enabled .regrade_option_text').text
        select_regrade_option
        expect(f('.correct_answer .regrade_option_text').text).to eq option_text
      end

      it 'remembers the selected regrade option', priority: "1", test_id: 140625 do
        select_regrade_option
        save_question

        edit_first_question
        select_different_correct_answer(1)
        expect(find_radio_button_by_value('current_and_previous_correct', '.regrade_enabled').selected?).to be_truthy
      end
    end

    context 'after deleting an answer to a quiz question' do
      it 'doesn\'t offer regrade options', priority: "1", test_id: 140626 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        click_questions_tab
        edit_first_question

        delete_possible_answer(1)

        # verify alert message
        expect(driver.switch_to.alert.text).to eq 'Are you sure? Deleting answers from a question with' \
          ' submissions disables the option to regrade this question.'
        accept_alert

        select_different_correct_answer(1)

        # verify explanation message
        expect(fj('.ui-dialog:visible .regrade_option_text')).to include_text 'Regrading is not allowed on this question' \
          ' because either an answer was removed or the question type was changed after a student' \
          ' completed a submission.'

        expect(f("#content")).not_to contain_jqcss(".regrade_enabled label.checkbox:visible")
      end
    end
  end
end
