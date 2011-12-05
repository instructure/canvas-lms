require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "quiz selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should allow a teacher to create a quiz from the quizzes tab directly" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/quizzes"
    driver.find_element(:css, ".new-quiz-link").click
    driver.find_element(:css, ".save_quiz_button").click
    assert_flash_notice_message /Quiz data saved/
  end

  it "should create a new quiz" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/quizzes"
    expect_new_page_load {
      driver.find_element(:css, '.new-quiz-link').click
    }
    #check url
    driver.current_url.should match %r{/courses/\d+/quizzes/(\d+)\/edit}
    driver.current_url =~ %r{/courses/\d+/quizzes/(\d+)\/edit}
    quiz_id = $1.to_i
    quiz_id.should be > 0

    #input name and description then save quiz
    driver.find_element(:css, '#quiz_options_form input#quiz_title').clear
    driver.find_element(:css, '#quiz_options_form input#quiz_title').send_keys('new quiz')
    test_text = "new description"
    keep_trying_until{ driver.find_element(:id, 'quiz_description_ifr').should be_displayed }
    type_in_tiny '#quiz_description', test_text
    in_frame "quiz_description_ifr" do
      driver.find_element(:id, 'tinymce').should include_text(test_text)
    end
    driver.find_element(:css, '.save_quiz_button').click
    wait_for_ajax_requests

    #check quiz preview
    driver.find_element(:link, 'Preview the Quiz').click
    driver.find_element(:css ,'#content h2').text.should == 'new quiz'

  end

  it "should correctly hide form when cancelling quiz edit" do
    course_with_teacher_logged_in

    get "/courses/#{@course.id}/quizzes/new"

    keep_trying_until {
      driver.find_element(:css, ".add_question .add_question_link").click
      driver.find_elements(:css, "#questions .question_holder").length > 0
    }
    holder = driver.find_element(:css, "#questions .question_holder")
    holder.should be_displayed
    holder.find_element(:css, ".cancel_link").click
    driver.find_elements(:css, "#questions .question_holder").length.should == 0
  end

  it "should edit a quiz" do
    course_with_teacher_logged_in
    @context = @course
    q = quiz_model
    q.generate_quiz_data
    q.save!

    get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
    wait_for_ajax_requests

    test_text = "changed description"
    keep_trying_until{ driver.find_element(:id, 'quiz_description_ifr').should be_displayed }
    type_in_tiny '#quiz_description', test_text
    in_frame "quiz_description_ifr" do
      driver.find_element(:id, 'tinymce').text.include?(test_text).should be_true
    end
    driver.find_element(:css, '.save_quiz_button').click
    wait_for_ajax_requests

    get "/courses/#{@course.id}/quizzes/#{q.id}"

    driver.find_element(:css, '#main .description').should include_text(test_text) 
  end

  it "should edit a quiz question" do
    course_with_teacher_logged_in
    @context = @course
    q = quiz_model
    quest1 = q.quiz_questions.create!(:question_data => { :name => "first question" } )
    q.generate_quiz_data
    q.save!
    get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
    wait_for_ajax_requests

    hover_and_click(".edit_question_link")
    wait_for_animations
    question = find_with_jquery(".question_form:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="multiple_choice_question"]').click
    question.find_element(:css, 'input[name="question_name"]').clear
    question.find_element(:css, 'input[name="question_name"]').send_keys('edited question')

    answers = question.find_elements(:css, ".form_answers > .answer")
    answers.length.should eql(2)
    question.find_element(:css, ".add_answer_link").click
    question.find_element(:css, ".add_answer_link").click
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers.length.should eql(4)
    answers[3].find_element(:css, ".delete_answer_link").click
    answers = question.find_elements(:css, "div.form_answers > div.answer")
    answers.length.should eql(3)

    driver.find_element(:css, '.question_form').submit
    question = driver.find_element(:css, "#question_#{quest1.id}")
    question.find_element(:css, ".question_name").text.should == 'edited question'
    driver.find_element(:id, 'show_question_details').click
    question.find_elements(:css, '.answers .answer').length.should == 3
  end

  it "should not show 'Missing Word' option in question types dropdown" do
    course_with_teacher_logged_in
    
    get "/courses/#{@course.id}/quizzes/new"
    
    driver.find_elements(:css, "#question_form_template option.missing_word").length.should == 1

    keep_trying_until {
      driver.find_element(:css, ".add_question .add_question_link").click
      driver.find_elements(:css, "#questions .question_holder").length > 0
    }
    driver.find_elements(:css, "#questions .question_holder option.missing_word").length.should == 0
  end

  def start_quiz_question
    course_with_teacher_logged_in
    
    get "/courses/#{@course.id}/quizzes"
    expect_new_page_load {
      driver.find_element(:css, '.new-quiz-link').click
    }

    driver.find_element(:css, '.add_question_link').click 
  end
 
  def replace_content(el, value)
    el.clear
    el.send_keys(value)
  end
    
  def set_feedback_content(el, text)
    el.find_element(:css, ".comment_focus").click
    el.find_element(:css, "textarea").should be_displayed
    el.find_element(:css, "textarea").send_keys(text)
  end

  it "should create a quiz with a multiple choice question" do
    start_quiz_question
    quiz = Quiz.last
    
    question = find_with_jquery(".question_form:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="multiple_choice_question"]').click
    
    type_in_tiny ".question_form:visible textarea.question_content", 'Hi, this is a multiple choice question.'
    
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers.length.should eql(4)
    replace_content(answers[0].find_element(:css, ".select_answer input"), "Correct Answer")
    set_feedback_content(answers[0].find_element(:css, ".answer_comments"), "Good job!")
    replace_content(answers[1].find_element(:css, ".select_answer input"), "Wrong Answer #1")
    set_feedback_content(answers[1].find_element(:css, ".answer_comments"), "Bad job :(")
    replace_content(answers[2].find_element(:css, ".select_answer input"), "Second Wrong Answer")
    replace_content(answers[3].find_element(:css, ".select_answer input"), "Wrongest Answer")
    
    set_feedback_content(question.find_element(:css, "div.text .question_correct_comment"), "Good job on the question!")
    set_feedback_content(question.find_element(:css, "div.text .question_incorrect_comment"), "You know what they say - study long study wrong.")
    set_feedback_content(question.find_element(:css, "div.text .question_neutral_comment"), "Pass or fail, you're a winner!")
    
    question.submit
    wait_for_ajax_requests
    
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
    start_quiz_question
    quiz = Quiz.last
    
    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="true_false_question"]').click
    
    replace_content(question.find_element(:css, "input[name='question_points']"), '4')
    
    type_in_tiny '.question:visible textarea.question_content', 'This is not a true/false question.'
    
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers.length.should eql(2)
    answers[1].find_element(:css, ".select_answer_link").click # false - get it?
    answers[1].find_element(:css, ".comment_focus").click
    answers[1].find_element(:css, ".answer_comments textarea").send_keys("Good job!")
    
    question.submit
    wait_for_ajax_requests
    
    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}").should be_displayed
  end 

  it "should create a quiz question with a fill in the blank question" do
    start_quiz_question
    quiz = Quiz.last
    
    question = find_with_jquery(".question_form:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="short_answer_question"]').click
    
    replace_content(question.find_element(:css, "input[name='question_points']"), '4')
    
    type_in_tiny '.question_form:visible textarea.question_content', 'This is a fill in the _________ question.'

    answers = question.find_elements(:css, ".form_answers > .answer")
    replace_content(answers[0].find_element(:css, ".short_answer input"), "blank")
    replace_content(answers[1].find_element(:css, ".short_answer input"), "Blank")
    
    question.submit
    wait_for_ajax_requests
    
    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}").should be_displayed
  end

  it "should create a quiz question with a fill in multiple blanks question" do
    start_quiz_question
    quiz = Quiz.last
    
    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="fill_in_multiple_blanks_question"]').click
    
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

    replace_content( answers[0].find_element(:css, '.short_answer input'), 'red')
    replace_content( answers[1].find_element(:css, '.short_answer input'), 'green')
    options[1].click
    wait_for_animations
    answers = question.find_elements(:css, ".form_answers > .answer")

    answers[2].find_element(:css, ".select_answer_link").click
    replace_content( answers[2].find_element(:css, '.short_answer input'), 'blue')
    replace_content( answers[3].find_element(:css, '.short_answer input'), 'purple')
    
    question.submit
    wait_for_ajax_requests
    
    driver.find_element(:id, 'show_question_details').click
    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
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
    start_quiz_question
    quiz = Quiz.last
    
    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="multiple_answers_question"]').click
    
    type_in_tiny '.question:visible textarea.question_content', 'This is a multiple answer question.'

    answers = question.find_elements(:css, ".form_answers > .answer")

    replace_content( answers[0].find_element(:css, '.select_answer input'), 'first answer')
    replace_content( answers[2].find_element(:css, '.select_answer input'), 'second answer')
    answers[2].find_element(:css, ".select_answer_link").click

    question.submit
    wait_for_ajax_requests

    driver.find_element(:id, 'show_question_details').click
    question_data = quiz.quiz_questions[0].question_data
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed
    finished_question.find_elements(:css, '.correct_answer').length.should == 2 
  end 

  it "should create a quiz question with a multiple dropdown question" do
    start_quiz_question
    quiz = Quiz.last
 
    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="multiple_dropdowns_question"]').click
 
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

    replace_content( answers[0].find_element(:css, '.select_answer input'), 'red')
    replace_content( answers[1].find_element(:css, '.select_answer input'), 'green')
    options[1].click
    wait_for_animations
    answers = question.find_elements(:css, ".form_answers > .answer")

    answers[2].find_element(:css, ".select_answer_link").click
    replace_content( answers[2].find_element(:css, '.select_answer input'), 'blue')
    replace_content( answers[3].find_element(:css, '.select_answer input'), 'purple')
    
    question.submit
    wait_for_ajax_requests
    
    driver.find_element(:id, 'show_question_details').click
    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
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
    start_quiz_question
    quiz = Quiz.last
    
    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="matching_question"]').click

    type_in_tiny '.question:visible textarea.question_content', 'This is a matching question.'
    
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers[0] = question.find_element(:name, 'answer_match_left').send_keys('first left side')
    answers[0] = question.find_element(:name, 'answer_match_right').send_keys('first right side')
    answers[1] = question.find_element(:name, 'answer_match_left').send_keys('second left side')
    answers[2] = question.find_element(:name, 'answer_match_right').send_keys('second right side')
    question.find_element(:name, 'matching_answer_incorrect_matches').send_keys('first_distractor')

    question.submit
    wait_for_ajax_requests

    driver.find_element(:id, 'show_question_details').click
    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed

    first_answer = finished_question.find_element(:css, '.answer_match')
    first_answer.find_element(:css, '.answer_match_left').should include_text('first left side')
    first_answer.find_element(:css, '.answer_match_right').should include_text('first right side')
  end

    #### Numerical Answer
  it "should create a quiz question with a numerical question" do
    start_quiz_question
    quiz = Quiz.last
    
    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="numerical_question"]').click

    type_in_tiny '.question:visible textarea.question_content', 'This is a numerical question.'
    
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers[0].find_element(:name, 'answer_exact').send_keys('1')
    answers[0].find_element(:name, 'answer_error_margin').send_keys('0.1')
    select_box = answers[1].find_element(:css, '.numerical_answer_type')
    select_box.click
    select_box.find_element(:css, 'option[value="range_answer"]').click
    answers[1].find_element(:name, 'answer_range_start').send_keys('2')
    answers[1].find_element(:name, 'answer_range_end').send_keys('5')

    question.submit
    wait_for_ajax_requests

    driver.find_element(:id, 'show_question_details').click
    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should be_displayed
  end

  it "should create a quiz question with a formula question" do
    start_quiz_question
    quiz = Quiz.last
    
    question = find_with_jquery(".question_form:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="calculated_question"]').click
    
    type_in_tiny '.question_form:visible textarea.question_content','If [x] + [y] is a whole number, then this is a formula question.'
    
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
    
    question.submit
    wait_for_ajax_requests
    
    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}").should be_displayed
  end

  it "should create a quiz question with an essay question" do
    start_quiz_question
    quiz = Quiz.last
    
    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="essay_question"]').click

    type_in_tiny '.question:visible textarea.question_content', 'This is an essay question.'
    question.submit
    wait_for_ajax_requests

    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should_not be_nil
    finished_question.find_element(:css, '.text').should include_text('This is an essay question.')
  end

  it "should create a quiz question with a text question" do
    start_quiz_question
    quiz = Quiz.last
    
    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="text_only_question"]').click

    type_in_tiny '.question:visible textarea.question_content', 'This is a text question.'
    question.submit
    wait_for_ajax_requests

    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    finished_question = driver.find_element(:id, "question_#{quiz.quiz_questions[0].id}")
    finished_question.should_not be_nil
    finished_question.find_element(:css, '.text').should include_text('This is a text question.')
  end

  it "should not show the display details for text questions" do
    start_quiz_question
    quiz = Quiz.last

    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="text_only_question"]').click
    question.submit
    wait_for_ajax_requests

    quiz.reload

    show_el = driver.find_element(:id, 'show_question_details')
    show_el.should_not be_displayed
  end

  it "should not show the display details for essay questions" do
    start_quiz_question
    quiz = Quiz.last

    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="essay_question"]').click
    question.submit
    wait_for_ajax_requests

    quiz.reload

    show_el = driver.find_element(:id, 'show_question_details')
    show_el.should_not be_displayed
  end

  it "should show the display details when questions other than text or essay questions exist" do
    start_quiz_question
    show_el = driver.find_element(:id, 'show_question_details')
    quiz = Quiz.last
    question = find_with_jquery(".question_form:visible")

    show_el.should_not be_displayed

    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="multiple_choice_question"]').click
    question.submit
    wait_for_ajax_requests
    quiz.reload

    show_el.should be_displayed
  end

  it "should calculate correct quiz question points total" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/quizzes"
    expect_new_page_load {
      driver.find_element(:css, '.new-quiz-link').click
    }
    @question_count = 0
    @points_total = 0

    def add_quiz_question(points)
      @points_total += points.to_i
      @question_count += 1
      driver.find_element(:css, '.add_question_link').click 
      question = find_with_jquery('.question_form:visible')
      replace_content(question.find_element(:css, "input[name='question_points']"), points)
      question.submit
      wait_for_ajax_requests
      questions = find_all_with_jquery(".question_holder:visible")
      questions.length.should eql(@question_count)
      driver.find_element(:css, "#right-side .points_possible").text.should eql(@points_total.to_s)
    end
   
    add_quiz_question('1')
    add_quiz_question('2')
    add_quiz_question('3')
    add_quiz_question('4')

    driver.find_element(:css, '.save_quiz_button').click
    wait_for_ajax_requests
    quiz = Quiz.last
    quiz.reload
    quiz.quiz_questions.length.should == @question_count
  end

  it "message students who... should do something" do
    course_with_teacher_logged_in
    @context = @course
    q = quiz_model
    q.generate_quiz_data
    q.save!
    # add a student to the course
    student = student_in_course(:active_enrollment => true).user
    student.conversations.size.should eql(0)

    get "/courses/#{@course.id}/quizzes/#{q.id}"

    driver.find_element(:partial_link_text, "Message Students Who...").click
    dialog = find_all_with_jquery("#message_students_dialog:visible")
    dialog.length.should eql(1)
    dialog = dialog.first

    dialog.
      find_element(:css, 'select.message_types').
      find_element(:css, 'option[value="0"]').click # Have taken the quiz
    students = find_all_with_jquery(".student_list > .student:visible")

    students.length.should eql(0)

    dialog.
      find_element(:css, 'select.message_types').
      find_element(:css, 'option[value="1"]').click # Have NOT taken the quiz
    students = find_all_with_jquery(".student_list > .student:visible")
    students.length.should eql(1)

    dialog.find_element(:css, 'textarea#body').send_keys('This is a test message.')
    
    button = dialog.find_element(:css, "button.send_button")
    button.click
    keep_trying_until{ button.text != "Sending Message..." }
    button.text.should eql("Message Sent!")

    student.conversations.size.should eql(1)
  end

  it "should tally up question bank question points" do
    course_with_teacher_logged_in
    quiz = @course.quizzes.create!(:title => "My Quiz")
    bank = AssessmentQuestionBank.create!(:context => @course)
    3.times { bank.assessment_questions << assessment_question_model }
    harder = bank.assessment_questions.last
    harder.question_data[:points_possible] = 15
    harder.save!
    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
    find_questions_link = driver.find_element(:link, "Find Questions")
    keep_trying_until {
      find_questions_link.click
      driver.find_element(:link, "Select All")
    }.click
    find_with_jquery("div#find_question_dialog button.submit_button").click
    keep_trying_until { find_with_jquery("#quiz_display_points_possible .points_possible").text.should == "17" }
  end

  it "should allow you to use inherited question banks" do
    course_with_teacher_logged_in
    @course.account = Account.default
    @course.save
    quiz = @course.quizzes.create!(:title => "My Quiz")
    bank = AssessmentQuestionBank.create!(:context => @course.account)
    bank.assessment_questions << assessment_question_model

    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"

    keep_trying_until {
      driver.find_element(:css, '.find_question_link').click
      driver.find_element(:id, 'find_question_dialog').should be_displayed
      wait_for_ajaximations
      driver.find_element(:link, "Select All").should be_displayed
    }
    driver.find_element(:link, "Select All").click
    find_with_jquery("div#find_question_dialog button.submit_button").click
    keep_trying_until { find_with_jquery("#quiz_display_points_possible .points_possible").text.should == "1" }

    driver.find_element(:link, "New Question Group").click
    driver.find_element(:link, "Link to a Question Bank").click
    keep_trying_until {
      find_with_jquery("#find_bank_dialog .bank:visible")
    }.click
    find_with_jquery("#find_bank_dialog .submit_button").click
    find_with_jquery("#group_top_new button[type=submit]").click
    keep_trying_until { find_with_jquery("#quiz_display_points_possible .points_possible").text.should == "2" }
  end

  it "should allow you to use bookmarked question banks" do
    course_with_teacher_logged_in
    @course.account = Account.default
    @course.save
    quiz = @course.quizzes.create!(:title => "My Quiz")
    bank = AssessmentQuestionBank.create!(:context => Course.create)
    bank.assessment_questions << assessment_question_model
    @user.assessment_question_banks << bank

    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"

    keep_trying_until {
      driver.find_element(:css, '.find_question_link').click
      driver.find_element(:id, 'find_question_dialog').should be_displayed
      wait_for_ajaximations
      driver.find_element(:link, "Select All").should be_displayed
    }
    driver.find_element(:link, "Select All").click
    find_with_jquery("div#find_question_dialog button.submit_button").click
    keep_trying_until { find_with_jquery("#quiz_display_points_possible .points_possible").text.should == "1" }

    driver.find_element(:link, "New Question Group").click
    driver.find_element(:link, "Link to a Question Bank").click
    keep_trying_until {
      find_with_jquery("#find_bank_dialog .bank:visible")
    }.click
    find_with_jquery("#find_bank_dialog .submit_button").click
    find_with_jquery("#group_top_new button[type=submit]").click
    keep_trying_until { find_with_jquery("#quiz_display_points_possible .points_possible").text.should == "2" }
  end

  it "should check permissions when retrieving question banks" do
    course_with_teacher_logged_in
    @course.account = Account.default
    @course.account.role_overrides.create(:permission => 'read_question_banks', :enrollment_type => 'TeacherEnrollment', :enabled => false)
    @course.save
    quiz = @course.quizzes.create!(:title => "My Quiz")

    course_bank = AssessmentQuestionBank.create!(:context => @course)
    course_bank.assessment_questions << assessment_question_model

    account_bank = AssessmentQuestionBank.create!(:context => @course.account)
    account_bank.assessment_questions << assessment_question_model

    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"

    keep_trying_until {
      driver.find_element(:css, '.find_question_link').click
      driver.find_element(:id, 'find_question_dialog').should be_displayed
      wait_for_ajaximations
      driver.find_element(:link, "Select All").should be_displayed
    }
    find_all_with_jquery("#find_question_dialog .bank:visible").size.should eql 1

    driver.find_element(:css, '.ui-icon-closethick').click
    keep_trying_until {
      driver.find_element(:css, '.add_question_group_link').click
      driver.find_element(:css, '.find_bank_link').should be_displayed
    }
    driver.find_element(:link, "Link to a Question Bank").click
    wait_for_ajaximations
    find_all_with_jquery("#find_bank_dialog .bank:visible").size.should eql 1
  end

  it "should not duplicate unpublished quizzes each time you open the publish multiple quizzes dialog" do
    course_with_teacher_logged_in
    5.times { @course.quizzes.create!(:title => "My Quiz") }
    get "/courses/#{@course.id}/quizzes"
    publish_multiple = driver.find_element(:css, '.publish_multiple_quizzes_link')
    cancel = driver.find_element(:css, '#publish_multiple_quizzes_dialog .cancel_button')

    5.times do
      publish_multiple.click
      find_all_with_jquery('#publish_multiple_quizzes_dialog .quiz_item:not(.blank)').length.should == 5
      cancel.click
    end
  end

  it "should import questions from a question bank" do
    course_with_teacher_logged_in

    get "/courses/#{@course.id}/quizzes/new"

    driver.find_element(:css, '.add_question_group_link').click
    group_form = driver.find_element(:css, '#group_top_new .quiz_group_form')
    group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
    group_form.find_element(:name, 'quiz_group[question_points]').clear
    group_form.find_element(:name, 'quiz_group[question_points]').send_keys('2')
    group_form.submit
    driver.find_element(:css, '#questions .group_top .group_display.name').should include_text('new group') 

  end


  it "should create a new question group" do
    course_with_teacher_logged_in

    get "/courses/#{@course.id}/quizzes/new"

    driver.find_element(:css, '.add_question_group_link').click
    group_form = driver.find_element(:css, '#questions .quiz_group_form')
    group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
    group_form.find_element(:name, 'quiz_group[question_points]').clear
    group_form.find_element(:name, 'quiz_group[question_points]').send_keys('3')
    group_form.submit
    group_form.find_element(:css, '.group_display.name').should include_text('new group')

  end

  it "should moderate quiz" do
    course_with_teacher_logged_in
    teacher = @user
    student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
    @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
    @context = @course
    q = quiz_model
    q.generate_quiz_data
    q.save!

    get "/courses/#{@course.id}/quizzes/#{q.id}/moderate"

    driver.find_element(:css, '.moderate_student_link').click
    driver.find_element(:id, 'extension_extra_attempts').send_keys('2')
    driver.find_element(:id, 'moderate_student_form').submit
    wait_for_ajax_requests
    driver.find_element(:css, '.attempts_left').text.should == '3'

  end

  it "should flag a quiz question while taking a quiz as a teacher" do
    course_with_teacher_logged_in
    @context = @course
    bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    q = quiz_model
    a = AssessmentQuestion.create!
    b = AssessmentQuestion.create!
    bank.assessment_questions << a
    bank.assessment_questions << b
    answers = {'answer_0' => {'id' => 1}, 'answer_1' => {'id' => 2}}
    quest1 = q.quiz_questions.create!(:question_data => { :name => "first question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => a)
    quest2 = q.quiz_questions.create!(:question_data => { :name => "second question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => b)

    q.generate_quiz_data
    q.save!
    get "/courses/#{@course.id}/quizzes/#{q.id}/edit"

    expect_new_page_load {
      driver.find_element(:css, '.publish_quiz_button').click
    }
    wait_for_ajax_requests

    expect_new_page_load {
      driver.find_element(:link, 'Take the Quiz').click
    }

    #flag first question
    hover_and_click("#question_#{quest1.id} .flag_icon")

    #click second answer
    driver.find_element(:css, "#question_#{quest2.id} .answers .answer:first-child input").click
    driver.find_element(:id, 'submit_quiz_form').submit

    #dismiss dialog and submit quiz
    confirm_dialog = driver.switch_to.alert
    confirm_dialog.dismiss
    driver.find_element(:css, "#question_#{quest1.id} .answers .answer:last-child input").click
    expect_new_page_load {
      driver.find_element(:id, 'submit_quiz_form').submit
    }
    driver.find_element(:id, 'quiz_title').text.should == q.title
  end

  it "should indicate when it was last saved" do
    course_with_teacher_logged_in
    @context = @course
    bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    q = quiz_model
    a = AssessmentQuestion.create!
    b = AssessmentQuestion.create!
    bank.assessment_questions << a
    bank.assessment_questions << b
    answers = {'answer_0' => {'id' => 1}, 'answer_1' => {'id' => 2}}
    quest1 = q.quiz_questions.create!(:question_data => { :name => "first question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => a)
    quest2 = q.quiz_questions.create!(:question_data => { :name => "second question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => b)

    q.generate_quiz_data
    q.save!
    get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
    driver.find_element(:css, '.publish_quiz_button')

    get "/courses/#{@course.id}/quizzes/#{q.id}/take?user_id=#{@user.id}"
    expect_new_page_load {
      driver.find_element(:link_text, 'Take the Quiz').click
    }

    # sleep because display is updated on timer, not ajax callback
    sleep(1)
    indicator = driver.find_element(:css, '#last_saved_indicator')

    indicator.text.should == 'Not saved'
    driver.find_element(:css, 'input[type=radio]').click

    # too fast, this always fails
    #indicator.text.should == 'Saving...'

    wait_for_ajax_requests
    indicator.text.should match(/^Saved at \d+:\d+(pm|am)$/)

    #This step is to prevent selenium from freezing when the dialog appears when leaving the page
    driver.find_element(:link, I18n.t('links_to.quizzes', 'Quizzes')).click
    confirm_dialog = driver.switch_to.alert
    confirm_dialog.accept
    wait_for_dom_ready
  end

  it "should round numeric questions thes same when created and taking a quiz" do
    start_quiz_question
    quiz = Quiz.last
    question = find_with_jquery(".question:visible")
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="numerical_question"]').click

    type_in_tiny '.question:visible textarea.question_content', 'This is a numerical question.'

    answers = question.find_elements(:css, ".form_answers > .answer")
    answers[0].find_element(:name, 'answer_exact').send_keys('0.000675')
    driver.execute_script <<-JS
      $('input[name=answer_exact]').trigger('change');
    JS
    answers[0].find_element(:name, 'answer_error_margin').send_keys('0')
    question.submit
    wait_for_ajax_requests

    expect_new_page_load {
      driver.find_element(:css, '.publish_quiz_button').click
    }

    expect_new_page_load {
      driver.find_element(:link, 'Take the Quiz').click
    }

    input = driver.find_element(:css, 'input[type=text]')
    input.click
    input.send_keys('0.000675')
    driver.execute_script <<-JS
      $('input[type=text]').trigger('change');
    JS
    expect_new_page_load {
      driver.find_element(:css, '.submit_button').click
    }
    driver.find_element(:css, '.score_value').text.strip.should == '1'
  end


  context "select element behavior" do
    before do
      course_with_teacher_logged_in
      @context = @course
      bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
      q = quiz_model
      b = bank.assessment_questions.create!
      quest2 = q.quiz_questions.create!(:assessment_question => b)
      quest2.write_attribute(:question_data, { :neutral_comments=>"", :question_text=>"<p>My hair is [x] and my wife's is [y].</p>", :points_possible=>1, :question_type=>"multiple_dropdowns_question", :answers=>[{:comments=>"", :weight=>100, :blank_id=>"x", :text=>"brown", :id=>2624}, {:comments=>"", :weight=>0, :blank_id=>"x", :text=>"black", :id=>3085}, {:comments=>"", :weight=>100, :blank_id=>"y", :text=>"brown", :id=>5780}, {:comments=>"", :weight=>0, :blank_id=>"y", :text=>"red", :id=>8840}], :correct_comments=>"", :name=>"Question", :question_name=>"Question", :incorrect_comments=>"", :assessment_question_id=>nil})
  
      q.generate_quiz_data
      q.save!
      get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
      driver.find_element(:css, '.publish_quiz_button')
      get "/courses/#{@course.id}/quizzes/#{q.id}/take?user_id=#{@user.id}"
      driver.find_element(:link, 'Take the Quiz').click

      wait_for_ajax_requests
    end

    after do
      #This step is to prevent selenium from freezing when the dialog appears when leaving the page
      driver.find_element(:link, 'Quizzes').click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_dom_ready
    end

    # see blur.unhoverQuestion in take_quiz.js. avoids a windows chrome display glitch 
    it "should not unhover a question so long as one of its selects has focus" do
      container = driver.find_element(:css, '.question')
      driver.execute_script("$('.question').mouseenter()")
      container.attribute(:class).should match(/hover/)

      container.find_element(:css, 'select').click

      driver.execute_script("$('.question').mouseleave()")
      container.attribute(:class).should match(/hover/)

      driver.execute_script("$('.question select').blur()")
      container.attribute(:class).should_not match(/hover/)
    end

    it "should cancel mousewheel events on select elements" do
      driver.execute_script <<-EOF
        window.mousewheelprevented = false;
        jQuery('select').bind('mousewheel', function(event) {
          mousewheelprevented = event.isDefaultPrevented();
        }).trigger('mousewheel');
      EOF

      is_prevented = driver.execute_script('return window.mousewheelprevented')
      is_prevented.should be_true
    end

  end

  it "should display quiz statistics" do
    course_with_teacher_logged_in
    quiz_with_submission
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

    driver.find_element(:link, "Quiz Statistics").click

    driver.find_element(:css, '#content .question_name').should include_text("Question 1")
  end
end

describe "quiz Windows-Firefox-Tests" do
  it_should_behave_like "quiz selenium tests"
end
