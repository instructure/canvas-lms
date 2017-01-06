require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'quizzes question creation' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before(:once) do
    course_with_teacher
  end

  before(:each) do
    user_session(@teacher)
  end

  context "edge cases" do
    before(:each) do
      @last_quiz = start_quiz_question
    end

    it 'should create a quiz with a variety of quiz questions', priority: "1", test_id: 197489 do
      quiz = @last_quiz

      create_multiple_choice_question
      click_new_question_button
      create_true_false_question
      click_new_question_button
      create_fill_in_the_blank_question

      quiz.reload
      refresh_page # make sure the quizzes load up from the database
      dismiss_flash_messages # clears success flash message if exists
      click_questions_tab
      3.times do |i|
        expect(f("#question_#{quiz.quiz_questions[i].id}")).to be_truthy
      end
      questions = ff('.display_question')
      expect(questions[0]).to have_class('multiple_choice_question')
      expect(questions[1]).to have_class('true_false_question')
      expect(questions[2]).to have_class('short_answer_question')
    end

    it 'should not create an extra, blank, correct answer when [answer] is used as a placeholder', priority: "1", test_id: 197490 do
      quiz = @last_quiz

      # be a multiple dropdown question
      question = fj('.question_form:visible')
      click_option('.question_form:visible .question_type', 'Multiple Dropdowns')

      # set up a placeholder (this is the bug)
      type_in_tiny '.question:visible textarea.question_content', 'What is the [answer]'

      # check answer select
      select_box = question.find_element(:css, '.blank_id_select')
      select_box.click
      options = select_box.find_elements(:css, 'option')
      expect(options[0].text).to eq 'answer'

      # input answers for the blank input
      answers = question.find_elements(:css, '.form_answers > .answer')
      answers[0].find_element(:css, '.select_answer_link').click

      # make up some answers
      replace_content(answers[0].find_element(:css, '.select_answer input'), 'a')
      replace_content(answers[1].find_element(:css, '.select_answer input'), 'b')

      # save the question
      submit_form(question)
      wait_for_ajax_requests

      # check to see if the questions displays correctly
      move_to_click('label[for=show_question_details]')
      quiz.reload
      finished_question = f("#question_#{quiz.quiz_questions[0].id}")
      expect(finished_question).to be_displayed

      # check to make sure extra answers were not generated
      expect(quiz.quiz_questions.first.question_data['answers'].count).to eq 2
      expect(quiz.quiz_questions.first.question_data['answers'].detect{|a| a['text'] == ''}).to be_nil
    end

    it 'respects character limits on short answer questions', priority: "2", test_id: 197493 do
      question = fj('.question_form:visible')
      click_option('.question_form:visible .question_type', 'Fill In the Blank')

      replace_content(question.find_element(:css, "input[name='question_points']"), '4')

      answers = question.find_elements(:css, '.form_answers > .answer')
      answer = answers[0].find_element(:css, '.short_answer input')

      trigger_max_characters_alert(answer) do |alert|
        expect(alert.text).to eq 'Answers for fill in the blank questions must be under 80 characters long'
      end
    end


    it 'respects character limits on short answer questions- MFIB', priority: "2", test_id: 1160451 do
      skip('Skipping this as there is already an existing bug CNVS-27665 for this')
      question = fj('.question_form:visible')
      click_option('.question_form:visible .question_type', 'Fill In Multiple Blanks')
      replace_content(question.find_element(:css, "input[name='question_points']"), '4')
      type_in_tiny '.question_form:visible textarea.question_content', 'Roses are [color1], violets are [color2]'

      f('#question_content_0_ifr').send_keys(:tab)
      click_option('div.question.selectable.fill_in_multiple_blanks_question select.blank_id_select', 'color1')

      answers = question.find_elements(:css, '.form_answers > .answer')
      answer_blank_one = answers[0].find_element(:css, '.short_answer input')

      trigger_max_characters_alert(answer_blank_one) do |alert|
        expect(alert.text).to eq 'Answers for fill in the blank questions must be under 80 characters long'
      end

      click_option('div.question.selectable.fill_in_multiple_blanks_question select.blank_id_select', 'color2')

      answers = question.find_elements(:css, '.form_answers > .answer')
      answer2 = answers[2].find_element(:css, '.short_answer input')

      trigger_max_characters_alert(answer2) do |alert|
        expect(alert.text).to eq 'Answers for fill in the blank questions must be under 80 characters long'
      end
    end

    #  This is a function written to capture common code used
    #  in MFIB and FIB case for checking number of characters are <80 in answers
    def trigger_max_characters_alert(web_element)

      short_answer_field = lambda do
        replace_content(web_element, 'a' * 100)
        web_element.send_keys(:tab)
      end

      short_answer_field.call
      alert = driver.switch_to.alert
      yield (driver.switch_to.alert)
      accept_alert
    end
  end

  context 'errors' do
    before :once do
      quiz_with_new_questions(false)
    end

    it 'should show errors for graded quizzes', priority: "1", test_id: 197491 do
      open_quiz_edit_form
      click_questions_tab
      edit_first_question
      delete_first_multiple_choice_answer
      save_question
      expect(error_displayed?).to be_truthy
    end

    it 'should not show errors for surveys', priority: "1", test_id: 197491 do
      @quiz.update_attribute :quiz_type, "graded_survey"
      open_quiz_edit_form
      click_questions_tab
      edit_and_save_first_multiple_choice_answer 'instructure!'
      expect(error_displayed?).to be_falsey
    end
  end
end
