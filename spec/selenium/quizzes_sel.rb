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
  
  it "should create a quiz with every question type" do
    course_with_teacher_logged_in
    
    get "/courses/#{@course.id}/quizzes"
    driver.find_element(:partial_link_text, "Create a New Quiz").click
    
    driver.current_url.should match %r{/courses/\d+/quizzes/(\d+)\/edit}
    driver.current_url =~ %r{/courses/\d+/quizzes/(\d+)\/edit}
    quiz_id = $1.to_i
    quiz_id.should be > 0
    quiz = Quiz.find(quiz_id)
    
    new_question_link = driver.find_element(:link, "New Question")
    
    def save_question_and_wait(question)
      question.find_element(:css, "button[type='submit']").click
      keep_trying_until { question.find_element(:css, ".loading_image_holder").nil? rescue true }
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
    
    #### Multiple Choice Question
    question_count = 1
    points_total = 1
    new_question_link.click
    
    questions = find_all_with_jquery(".question_holder:visible")
    questions.length.should eql(question_count)
    question = questions[0]
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="multiple_choice_question"]').click
    
    tiny_frame = wait_for_tiny(question.find_element(:css, 'textarea.question_content'))
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys('Hi, this is a multiple choice question.')
    end
    
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
    
    save_question_and_wait(question)
    driver.find_element(:css, "#right-side .points_possible").text.should eql(points_total.to_s)
    
    quiz.reload
    quiz.quiz_questions.length.should == question_count
    question_data = quiz.quiz_questions[0].question_data
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
    
    #### True False Question
    
    new_question_link.click
    question_count += 1
    points_total += (points = 2)
    
    questions = find_all_with_jquery(".question_holder:visible")
    questions.length.should eql(question_count)
    question = questions.last
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="true_false_question"]').click
    
    replace_content(question.find_element(:css, "input[name='question_points']"), points.to_s)
    
    tiny_frame = wait_for_tiny(question.find_element(:css, 'textarea.question_content'))
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys('This is not a true/false question.')
    end
    
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers.length.should eql(2)
    answers[1].find_element(:css, ".select_answer_link").click # false - get it?
    answers[1].find_element(:css, ".comment_focus").click
    answers[1].find_element(:css, ".answer_comments textarea").send_keys("Good job!")
    
    save_question_and_wait(question)
    driver.find_element(:css, "#right-side .points_possible").text.should eql(points_total.to_s)
    
    quiz.reload
    quiz.quiz_questions.length.should == question_count
    
    
    #### Fill in the Blank Question
    
    new_question_link.click
    question_count += 1
    points_total += (points = 1)
    
    questions = find_all_with_jquery(".question_holder:visible")
    questions.length.should eql(question_count)
    question = questions.last
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="short_answer_question"]').click
    
    replace_content(question.find_element(:css, "input[name='question_points']"), points.to_s)
    
    tiny_frame = wait_for_tiny(question.find_element(:css, 'textarea.question_content'))
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys('This is a fill in the _________ question.')
    end
    
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers.length.should eql(2)
    question.find_element(:css, ".add_answer_link").click
    question.find_element(:css, ".add_answer_link").click
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers.length.should eql(4)
    answers[3].find_element(:css, ".delete_answer_link").click
    answers[2].find_element(:css, ".delete_answer_link").click
    answers = question.find_elements(:css, "div.form_answers > div.answer")
    answers.length.should eql(2)
    replace_content(answers[0].find_element(:css, ".short_answer input"), "blank")
    replace_content(answers[1].find_element(:css, ".short_answer input"), "Blank")
    
    save_question_and_wait(question)
    driver.find_element(:css, "#right-side .points_possible").text.should eql(points_total.to_s)
    
    quiz.reload
    quiz.quiz_questions.length.should == question_count
    
    
    #### Fill in Multiple Blanks
    
    #### Multiple Answers
    
    #### Multiple Dropdowns
    
    #### Matching
    
    #### Numerical Answer
    
    #### Formula Question
    
    new_question_link.click
    question_count += 1
    points_total += (points = 1)
    
    questions = find_all_with_jquery(".question_holder:visible")
    questions.length.should eql(question_count)
    question = questions.last
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="calculated_question"]').click
    
    replace_content(question.find_element(:css, "input[name='question_points']"), points.to_s)
    
    tiny_frame = wait_for_tiny(question.find_element(:css, 'textarea.question_content'))
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys('If [x] + [y] is a whole number, then this is a formula question.')
    end
    
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
    
    save_question_and_wait(question)
    driver.find_element(:css, "#right-side .points_possible").text.should eql(points_total.to_s)
    
    quiz.reload
    quiz.quiz_questions.length.should == question_count

    #### Missing Word
    
    #### Essay Question
    
    #### Text (no answer)
    
    
  end

  it "message students who... should do something" do
    course_with_teacher_logged_in
    q = @course.quizzes.build(:title => "My Quiz", :description => "Sup")
    q.generate_quiz_data
    q.published_at = Time.now
    q.workflow_state = 'available'
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

    driver.find_element(:link, "Find Questions").click
    keep_trying_until {
      driver.find_element(:link, "Select All")
    }.click
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

    driver.find_element(:link, "Find Questions").click
    keep_trying_until {
      driver.find_element(:link, "Select All")
    }
    find_all_with_jquery("#find_question_dialog .bank:visible").size.should eql 1

    driver.find_element(:link, "New Question Group").click
    driver.find_element(:link, "Link to a Question Bank").click
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
end

describe "quiz Windows-Firefox-Tests" do
  it_should_behave_like "quiz selenium tests"
end
