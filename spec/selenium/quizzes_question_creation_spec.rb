require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes question creation" do
  it_should_behave_like "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @last_quiz = start_quiz_question
  end

  it "should create a quiz with a multiple choice question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz
    create_multiple_choice_question
    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}").should be_displayed

    question_data[:answers].length.should == 4
    question_data[:answers][0][:text].should == "Correct Answer"
    question_data[:answers][0][:weight].should == 100
    question_data[:answers][1][:text].should == "Wrong Answer #1"
    question_data[:answers][1][:weight].should == 0
    question_data[:answers][2][:text].should == "Second Wrong Answer"
    question_data[:answers][2][:weight].should == 0
    question_data[:answers][3][:text].should == "Wrongest Answer"
    question_data[:answers][3][:weight].should == 0
    question_data[:points_possible].should == 1
    question_data[:question_type].should == "multiple_choice_question"
    question_data[:correct_comments].should == "Good job on the question!"
    question_data[:incorrect_comments].should == "You know what they say - study long study wrong."
    question_data[:neutral_comments].should == "Pass or fail, you're a winner!"
  end


  it "should create a quiz question with a true false question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz
    create_true_false_question
    quiz.reload
    driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}").should be_displayed
  end

  it "should create a quiz question with a fill in the blank question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz
    create_fill_in_the_blank_question
    quiz.reload
    driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}").should be_displayed
  end

  it "should create a quiz question with a fill in multiple blanks question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz

    question = find_with_jquery(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Fill In Multiple Blanks')

    replace_content(question.find_element(:css, "input[name='question_points']"), '4')

    type_in_tiny ".question:visible textarea.question_content", 'Roses are [color1], violets are [color2]'

    #check answer select
    select_box = question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    options[0].text.should == 'color1'
    options[1].text.should == 'color2'

    #input answers for both blank input
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers[0].find_element(:css, ".select_answer_link").click

    replace_content(answers[0].find_element(:css, '.short_answer input'), 'red')
    replace_content(answers[1].find_element(:css, '.short_answer input'), 'green')
    options[1].click
    wait_for_animations
    answers = question.find_elements(:css, ".form_answers > .answer")

    answers[2].find_element(:css, ".select_answer_link").click
    replace_content(answers[2].find_element(:css, '.short_answer input'), 'blue')
    replace_content(answers[3].find_element(:css, '.short_answer input'), 'purple')

    submit_form(question)
    wait_for_ajax_requests

    driver.find_element(:id, 'show_question_details').click
    quiz.reload
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed

    #check select box on finished question
    select_box = finished_question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    options[0].text.should == 'color1'
    options[1].text.should == 'color2'
  end

  it "should create a quiz question with a multiple answers question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz

    question = find_with_jquery(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Multiple Answers')

    type_in_tiny '.question:visible textarea.question_content', 'This is a multiple answer question.'

    answers = question.find_elements(:css, ".form_answers > .answer")

    replace_content(answers[0].find_element(:css, '.select_answer input'), 'first answer')
    replace_content(answers[2].find_element(:css, '.select_answer input'), 'second answer')
    answers[2].find_element(:css, ".select_answer_link").click

    submit_form(question)
    wait_for_ajax_requests

    driver.find_element(:id, 'show_question_details').click
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed
    finished_question.find_elements(:css, '.correct_answer').length.should == 2
  end

  it "should create a quiz question with a multiple dropdown question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz

    question = find_with_jquery(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Multiple Dropdowns')

    type_in_tiny '.question:visible textarea.question_content', 'Roses are [color1], violets are [color2]'

    #check answer select
    select_box = question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    options[0].text.should == 'color1'
    options[1].text.should == 'color2'

    #input answers for both blank input
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers[0].find_element(:css, ".select_answer_link").click

    replace_content(answers[0].find_element(:css, '.select_answer input'), 'red')
    replace_content(answers[1].find_element(:css, '.select_answer input'), 'green')
    options[1].click
    wait_for_animations
    answers = question.find_elements(:css, ".form_answers > .answer")

    answers[2].find_element(:css, ".select_answer_link").click
    replace_content(answers[2].find_element(:css, '.select_answer input'), 'blue')
    replace_content(answers[3].find_element(:css, '.select_answer input'), 'purple')

    submit_form(question)
    wait_for_ajax_requests

    driver.find_element(:id, 'show_question_details').click
    quiz.reload
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed

    #check select box on finished question
    select_box = finished_question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    options[0].text.should == 'color1'
    options[1].text.should == 'color2'
  end

  it "should create a quiz question with a matching question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz

    question = find_with_jquery(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Matching')

    type_in_tiny '.question:visible textarea.question_content', 'This is a matching question.'

    answers = question.find_elements(:css, ".form_answers > .answer")
    answers[0] = question.find_element(:name, 'answer_match_left').send_keys('first left side')
    answers[0] = question.find_element(:name, 'answer_match_right').send_keys('first right side')
    answers[1] = question.find_element(:name, 'answer_match_left').send_keys('second left side')
    answers[2] = question.find_element(:name, 'answer_match_right').send_keys('second right side')
    question.find_element(:name, 'matching_answer_incorrect_matches').send_keys('first_distractor')

    submit_form(question)
    wait_for_ajax_requests

    driver.find_element(:id, 'show_question_details').click
    quiz.reload
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed

    first_answer = finished_question.find_element(:css, '.answer_match')
    first_answer.find_element(:css, '.answer_match_left').should include_text('first left side')
    first_answer.find_element(:css, '.answer_match_right').should include_text('first right side')
  end

  #### Numerical Answer
  it "should create a quiz question with a numerical question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz

    click_option('.question_form:visible .question_type', 'Numerical Answer')
    type_in_tiny '.question:visible textarea.question_content', 'This is a numerical question.'

    quiz_form = driver.find_element(:css, '.question_form')
    answers = quiz_form.find_elements(:css, ".form_answers > .answer")
    replace_content(answers[0].find_element(:name, 'answer_exact'), 5)
    replace_content(answers[0].find_element(:name, 'answer_error_margin'), 2)
    click_option('select.numerical_answer_type:eq(1)', 'Answer in the Range:')
    replace_content(answers[1].find_element(:name, 'answer_range_start'), 5)
    replace_content(answers[1].find_element(:name, 'answer_range_end'), 10)
    submit_form(quiz_form)
    wait_for_ajaximations

    driver.find_element(:id, 'show_question_details').click
    quiz.reload
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed

  end

  it "should create a quiz question with a formula question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz

    question = find_with_jquery(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Formula Question')

    type_in_tiny '.question_form:visible textarea.question_content', 'If [x] + [y] is a whole number, then this is a formula question.'

    find_with_jquery('button.recompute_variables').click
    find_with_jquery('.supercalc:visible').send_keys('x + y')
    find_with_jquery('button.save_formula_button').click
    # normally it's capped at 200 (to keep the yaml from getting crazy big)...
    # since selenium tests take forever, let's make the limit much lower
    driver.execute_script("window.maxCombinations = 10")
    find_with_jquery('.combination_count:visible').send_keys('20') # over the limit
    button = find_with_jquery('button.compute_combinations:visible')
    button.click
    find_with_jquery('.combination_count:visible').attribute(:value).should eql "10"
    keep_trying_until {
      button.text == 'Generate'
    }
    find_all_with_jquery('table.combinations:visible tr').size.should eql 11 # plus header row

    submit_form(question)
    wait_for_ajax_requests

    quiz.reload
    driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}").should be_displayed
  end

  it "should create a quiz question with an essay question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz

    question = find_with_jquery(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Essay Question')

    type_in_tiny '.question:visible textarea.question_content', 'This is an essay question.'
    submit_form(question)
    wait_for_ajax_requests

    quiz.reload
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should_not be_nil
    finished_question.find_element(:css, '.text').should include_text('This is an essay question.')
  end

  it "should create a quiz question with a text question" do
    skip_if_ie('Out of memory')
    quiz = @last_quiz

    question = find_with_jquery(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Text (no question)')

    type_in_tiny '.question_form:visible textarea.question_content', 'This is a text question.'
    submit_form(question)
    wait_for_ajax_requests

    quiz.reload
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should_not be_nil
    finished_question.find_element(:css, '.text').should include_text('This is a text question.')
  end

  it "should create a quiz with a variety of quiz questions" do
    quiz = @last_quiz

    create_multiple_choice_question
    driver.find_element(:css, '.add_question_link').click
    create_true_false_question
    driver.find_element(:css, '.add_question_link').click
    create_fill_in_the_blank_question

    quiz.reload
    refresh_page #making sure the quizzes load up from the database
    3.times do |i|
      driver.find_element(:id, "question_#{quiz.quiz_questions[i].id}").should be_displayed
    end
    questions = driver.find_elements(:css, '.display_question')
    questions[0].should have_class("multiple_choice_question")
    questions[1].should have_class("true_false_question")
    questions[2].should have_class("short_answer_question")
  end

  context "drag and drop reordering" do

    before(:each) do
      quiz_with_new_questions
      create_question_group
    end

    it "should reorder quiz questions" do
      old_data = get_question_data
      drag_question_to_top @quest2.id
      refresh_page
      new_data = get_question_data
      new_data[0][:id].should == old_data[1][:id]
      new_data[1][:id].should == old_data[0][:id]
      new_data[2][:id].should == old_data[2][:id]
    end

    it "should add and remove questions to/from a group" do
      # drag it into the group
      drag_question_into_group @quest1.id, @group.id
      refresh_page
      group_should_contain_question(@group, @quest1)

      # drag it out
      drag_question_to_top @quest1.id
      refresh_page
      data = get_question_data
      data[0][:id].should == @quest1.id
    end

    it "should reorder questions within a group" do
      drag_question_into_group @quest1.id, @group.id
      drag_question_into_group @quest2.id, @group.id
      data = get_question_data_for_group @group.id
      data[0][:id].should == @quest2.id
      data[1][:id].should == @quest1.id

      drag_question_to_top_of_group @quest1.id, @group.id
      refresh_page
      data = get_question_data_for_group @group.id
      data[0][:id].should == @quest1.id
      data[1][:id].should == @quest2.id
    end

    it "should reorder groups and questions" do
      old_data = get_question_data
      drag_group_to_top @group.id
      refresh_page
      new_data = get_question_data
      new_data[0][:id].should == old_data[2][:id]
      new_data[1][:id].should == old_data[0][:id]
      new_data[2][:id].should == old_data[1][:id]
    end
  end

  context "html answers" do

    def edit_first_html_answer(question_type=nil)
      edit_first_question
      click_option('.question_form:visible .question_type', question_type) if question_type
      driver.execute_script "$('.answer').addClass('hover');"
      find_with_jquery('.edit_html:visible').click
    end

    def close_first_html_answer
      driver.find_element(:css, '.edit-html-done').click
    end

    it "should allow HTML answers for multiple choice" do
      skip_if_ie 'Out of memory'
      quiz_with_new_questions
      edit_first_html_answer
      type_in_tiny '.answer:eq(3) textarea', 'HTML'
      close_first_html_answer
      html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
      html.should == '<p>HTML</p>'
      submit_form('.question_form')
      refresh_page
      edit_first_question
      html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
      html.should == '<p>HTML</p>'
    end

    def check_for_no_edit_button(option)
      click_option('.question_form:visible .question_type', option)
      driver.execute_script "$('.answer').addClass('hover');"
      find_with_jquery('.edit_html:visible').should be_nil
    end

    it "should not show the edit html button for question types besides multiple choice and multiple answers" do
      quiz_with_new_questions
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

      # add text to regular input
      edit_first_question
      input = find_with_jquery 'input[name=answer_text]:visible'
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
      edit_first_html_answer
      type_in_tiny '.answer:eq(3) textarea', 'HTML'
      submit_form('.question_form')
      refresh_page
      edit_first_question
      html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
      html.should == '<p>HTML</p>'
    end

    it "should save open html answers when the question is submitted for multiple answers" do
      quiz_with_new_questions
      edit_first_html_answer 'Multiple Answers'
      type_in_tiny '.answer:eq(3) textarea', 'HTML'
      submit_form('.question_form')
      refresh_page
      edit_first_question
      html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
      html.should == '<p>HTML</p>'
    end
  end

  it "should show errors for graded quizzes but not surveys" do
    quiz_with_new_questions
    change_quiz_type_to 'Graded Survey'
    save_settings

    edit_and_save_first_multiple_choice_answer 'instructure!'
    error_displayed?.should be_false

    refresh_page
    edit_and_save_first_multiple_choice_answer 'yog!'
    error_displayed?.should be_false

    change_quiz_type_to 'Graded Quiz'
    save_settings

    edit_first_question
    delete_first_multiple_choice_answer
    save_question
    error_displayed?.should be_true

    refresh_page
    edit_first_question
    delete_first_multiple_choice_answer
    save_question
    error_displayed?.should be_true
  end
end

