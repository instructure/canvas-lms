require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "equation editor" do
  include_examples "quizzes selenium tests"

  let(:equation_selector){ "div[aria-label='Insert Math Equation'] button" }


  it "should remove bookmark when clicking close" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/quizzes"
    f('.new-quiz-link').click

    wait_for_tiny(f("#quiz_description"))
    type_in_tiny 'textarea#quiz_description', 'foo'

    equation_editor = keep_trying_until do
      f(equation_selector).click
      wait_for_ajaximations
      equation_editor = fj(".mathquill-editor:visible")
      expect(equation_editor).not_to be_nil
      equation_editor
    end

    fj('.ui-dialog-titlebar-close:visible').click
    type_in_tiny 'textarea#quiz_description', 'bar'
    f('.save_quiz_button').click

    description = keep_trying_until do
      f('.description')
    end

    expect(description.text).to eq 'foobar'

  end

  it "should support multiple equation editors on the same page" do
    skip("193")
    course_with_teacher_logged_in

    get "/courses/#{@course.id}/quizzes"
    f('.new-quiz-link').click

    def save_question_and_wait
      submit_form('.question_form')
      wait_for_ajaximations
    end
    wait_for_tiny(f("#quiz_description"))

    2.times do |time|
      click_questions_tab
      click_new_question_button

      questions = ffj(".question_holder:visible")
      expect(questions.length).to eq time + 1
      question = questions[time]

      wait_for_tiny(question.find_element(:css, 'textarea.question_content'))

      equation_editor = keep_trying_until do
        question.find_element(:css, equation_selector).click
        wait_for_ajaximations
        equation_editor = fj(".mathquill-editor:visible")
        expect(equation_editor).not_to be_nil
        equation_editor
      end
      f('.ui-dialog-buttonset .btn-primary').click
      question.find_element(:css, '.toggle_question_content_views_link').click
      expect(question.find_element(:css, 'textarea.question_content').attribute(:value)).to include('<img class="equation_image" title="" src="/equation_images/" alt="" />')
      save_question_and_wait

      expect(question.find_elements(:css, 'img.equation_image').size).to eq 1

      click_settings_tab
      expect(f(".points_possible").text).to eq (time + 1).to_s
    end
  end
end
