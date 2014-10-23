require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes question with html answers" do
  include_examples "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @last_quiz = start_quiz_question
  end

  def edit_first_html_answer(question_type=nil)
    edit_first_question
    click_option('.question_form:visible .question_type', question_type) if question_type
    driver.execute_script "$('.answer').addClass('hover');"
    fj('.edit_html:visible').click
  end

  def close_first_html_answer
    f('.edit-html-done').click
  end

  it "should allow HTML answers for multiple choice" do
    quiz_with_new_questions
    click_questions_tab
    edit_first_html_answer
    type_in_tiny '.answer:eq(3) textarea', 'HTML'
    close_first_html_answer
    html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
    html.should == '<p>HTML</p>'
    submit_form('.question_form')
    refresh_page
    click_questions_tab
    edit_first_question
    html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
    html.should == '<p>HTML</p>'
  end

  def check_for_no_edit_button(option)
    click_option('.question_form:visible .question_type', option)
    driver.execute_script "$('.answer').addClass('hover');"
    fj('.edit_html:visible').should be_nil
  end

  it "should not show the edit html button for question types besides multiple choice and multiple answers" do
    quiz_with_new_questions
    click_questions_tab
    edit_first_question

    check_for_no_edit_button 'True/False'
    check_for_no_edit_button 'Fill In the Blank'
    check_for_no_edit_button 'Fill In Multiple Blanks'
    check_for_no_edit_button 'Multiple Dropdowns'
    check_for_no_edit_button 'Matching'
    check_for_no_edit_button 'Numerical Answer'
  end

  it "should restore normal input when html answer is empty" do
    quiz_with_new_questions
    click_questions_tab
    edit_first_html_answer
    type_in_tiny '.answer:eq(3) textarea', 'HTML'

    # clear tiny
    driver.execute_script "$('.answer:eq(3) textarea')._setContentCode('')"
    close_first_html_answer
    input_length = driver.execute_script "return $('.answer:eq(3) input[name=answer_text]:visible').length"
    input_length.should == 1
  end

  it "should populate the editor and input elements properly" do
    quiz_with_new_questions
    click_questions_tab

    # add text to regular input
    edit_first_question
    input = fj('input[name=answer_text]:visible')
    input.click
    input.send_keys 'ohai'
    submit_form('.question_form')
    wait_for_ajax_requests

    # open it up in the editor, make sure the text matches the input
    edit_first_html_answer
    content = driver.execute_script "return $('.answer:eq(3) textarea')._justGetCode()"
    content.should == '<p>ohai</p>'

    # clear it out, make sure the original input is empty also
    driver.execute_script "$('.answer:eq(3) textarea')._setContentCode('')"
    close_first_html_answer
    value = driver.execute_script "return $('input[name=answer_text]:visible')[0].value"
    value.should == ''
  end

  it "should save open html answers when the question is submitted for multiple choice" do
    quiz_with_new_questions
    click_questions_tab
    edit_first_html_answer
    type_in_tiny '.answer:eq(3) textarea', 'HTML'
    submit_form('.question_form')
    refresh_page
    click_questions_tab
    edit_first_question
    html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
    html.should == '<p>HTML</p>'
  end

  it "should save open html answers when the question is submitted for multiple answers" do
    quiz_with_new_questions
    click_questions_tab
    edit_first_html_answer 'Multiple Answers'
    type_in_tiny '.answer:eq(3) textarea', 'HTML'
    submit_form('.question_form')
    refresh_page
    click_questions_tab
    edit_first_question
    html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
    html.should == '<p>HTML</p>'
  end

end
