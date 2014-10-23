require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes question creation" do
  include_examples "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @last_quiz = start_quiz_question
  end

  it "should create a quiz with a multiple choice question" do
    quiz = @last_quiz
    create_multiple_choice_question
    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    f("#question_#{quiz.quiz_questions[0].id}").should be_displayed

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
    question_data[:neutral_comments].should == "Pass or fail you are a winner!"
  end


  it "should create a quiz question with a true false question" do
    quiz = @last_quiz
    create_true_false_question
    quiz.reload
    keep_trying_until { f("#question_#{quiz.quiz_questions[0].id}").should be_displayed }
  end

  it "should create a quiz question with a fill in the blank question" do
    quiz = @last_quiz
    create_fill_in_the_blank_question
    quiz.reload
    f("#question_#{quiz.quiz_questions[0].id}").should be_displayed
  end

  it "should create a quiz question with a fill in multiple blanks question" do
    quiz = @last_quiz

    question = fj(".question_form:visible")
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

    replace_content(answers[0].find_element(:css, '.short_answer input'), 'red')
    replace_content(answers[1].find_element(:css, '.short_answer input'), 'green')
    options[1].click
    wait_for_ajaximations
    answers = question.find_elements(:css, ".form_answers > .answer")

    replace_content(answers[2].find_element(:css, '.short_answer input'), 'blue')
    replace_content(answers[3].find_element(:css, '.short_answer input'), 'purple')

    submit_form(question)
    wait_for_ajax_requests

    f('#show_question_details').click
    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed

    #check select box on finished question
    select_box = finished_question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    options[0].text.should == 'color1'
    options[1].text.should == 'color2'
  end

  it "should create a quiz question with a multiple answers question" do
    quiz = @last_quiz

    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Multiple Answers')

    type_in_tiny '.question:visible textarea.question_content', 'This is a multiple answer question.'

    answers = question.find_elements(:css, ".form_answers > .answer")

    replace_content(answers[0].find_element(:css, '.select_answer input'), 'first answer')
    replace_content(answers[2].find_element(:css, '.select_answer input'), 'second answer')
    answers[2].find_element(:css, ".select_answer_link").click

    submit_form(question)
    wait_for_ajax_requests

    f('#show_question_details').click
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed
    finished_question.find_elements(:css, '.answer.correct_answer').length.should == 2
  end

  it "should create a quiz question with a multiple dropdown question" do
    quiz = @last_quiz

    question = fj(".question_form:visible")
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
    wait_for_ajaximations
    answers = question.find_elements(:css, ".form_answers > .answer")

    answers[2].find_element(:css, ".select_answer_link").click
    replace_content(answers[2].find_element(:css, '.select_answer input'), 'blue')
    replace_content(answers[3].find_element(:css, '.select_answer input'), 'purple')

    submit_form(question)
    wait_for_ajax_requests

    driver.execute_script("$('#show_question_details').click();")
    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed

    #check select box on finished question
    select_box = finished_question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    options[0].text.should == 'color1'
    options[1].text.should == 'color2'
  end

  it "should create a quiz question with a matching question" do
    quiz = @last_quiz

    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Matching')

    type_in_tiny '.question:visible textarea.question_content', 'This is a matching question.'

    answers = question.find_elements(:css, ".form_answers > .answer")

    answers = answers.each_with_index do |answer, i|
      answer.find_element(:name, 'answer_match_left').send_keys("#{i} left side")
      answer.find_element(:name, 'answer_match_right').send_keys("#{i} right side")
    end
    question.find_element(:name, 'matching_answer_incorrect_matches').send_keys('first_distractor')

    submit_form(question)
    wait_for_ajax_requests

    f('#show_question_details').click

    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed

    finished_question.find_elements(:css, '.answer_match').each_with_index do |filled_answer, i|
      filled_answer.find_element(:css, '.answer_match_left').should include_text("#{i} left side")
      filled_answer.find_element(:css, '.answer_match_right').should include_text("#{i} right side")
    end
  end

  #### Numerical Answer
  it "should create a quiz question with a numerical question" do
    quiz = @last_quiz

    click_option('.question_form:visible .question_type', 'Numerical Answer')
    type_in_tiny '.question:visible textarea.question_content', 'This is a numerical question.'

    quiz_form = f('.question_form')
    answers = quiz_form.find_elements(:css, ".form_answers > .answer")
    replace_content(answers[0].find_element(:name, 'answer_exact'), 5)
    replace_content(answers[0].find_element(:name, 'answer_error_margin'), 2)
    click_option('select.numerical_answer_type:eq(1)', 'Answer in the Range:')
    replace_content(answers[1].find_element(:name, 'answer_range_start'), 5)
    replace_content(answers[1].find_element(:name, 'answer_range_end'), 10)
    submit_form(quiz_form)
    wait_for_ajaximations

    f('#show_question_details').click
    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed

  end

  it "should create a quiz question with a formula question" do
    quiz = @last_quiz

    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Formula Question')

    type_in_tiny '.question_form:visible textarea.question_content', 'If [x] + [y] is a whole number, then this is a formula question.'

    fj('button.recompute_variables').click
    fj('.supercalc:visible').send_keys('x + y')
    fj('button.save_formula_button').click
    # normally it's capped at 200 (to keep the yaml from getting crazy big)...
    # since selenium tests take forever, let's make the limit much lower
    driver.execute_script("ENV.quiz_max_combination_count = 10")
    fj('.combination_count:visible').send_keys('20') # over the limit
    button = fj('button.compute_combinations:visible')
    button.click
    fj('.combination_count:visible').should have_attribute(:value, "10")
    keep_trying_until {
      button.text == 'Generate'
    }
    ffj('table.combinations:visible tr').size.should == 11 # plus header row
    submit_form(question)
    wait_for_ajax_requests

    quiz.reload
    f("#question_#{quiz.quiz_questions[0].id}").should be_displayed
  end

  it "should create a quiz question with an essay question" do
    quiz = @last_quiz

    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Essay Question')

    type_in_tiny '.question:visible textarea.question_content', 'This is an essay question.'
    submit_form(question)
    wait_for_ajax_requests

    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    finished_question.should_not be_nil
    finished_question.find_element(:css, '.text').should include_text('This is an essay question.')
  end

  it "should create a quiz question with a file upload question" do
    quiz = @last_quiz

    create_file_upload_question

    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    finished_question.should_not be_nil
    finished_question.find_element(:css, '.text').should include_text('This is a file upload question.')
  end

  it "should create a quiz question with a text question" do
    quiz = @last_quiz

    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Text (no question)')

    type_in_tiny '.question_form:visible textarea.question_content', 'This is a text question.'
    submit_form(question)
    wait_for_ajax_requests

    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    finished_question.should_not be_nil
    finished_question.find_element(:css, '.text').should include_text('This is a text question.')
  end

end

