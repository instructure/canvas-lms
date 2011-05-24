require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "quiz selenium tests" do
  it_should_behave_like "in-process server selenium tests"
  
  it "should not show 'Missing Word' option in question types dropdown" do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    e.save!
    login_as(username, password)
    
    get "/courses/#{e.course_id}/quizzes/new"
    
    driver.find_elements(:css, "#question_form_template option.missing_word").length.should == 1

    driver.find_element(:css, ".add_question .add_question_link").click
    keep_trying{ driver.find_elements(:css, "#questions .question_holder").length > 0 }
    driver.find_elements(:css, "#questions .question_holder option.missing_word").length.should == 0
  end
  
  it "should create a quiz with every question type" do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    e.save!
    login_as(username, password)
    
    get "/courses/#{e.course_id}/quizzes"
    driver.find_element(:partial_link_text, "Create a New Quiz").click
    
    driver.current_url.should match %r{/courses/\d+/quizzes/(\d+)\/edit}
    driver.current_url =~ %r{/courses/\d+/quizzes/(\d+)\/edit}
    quiz_id = $1.to_i
    quiz_id.should be > 0
    quiz = Quiz.find(quiz_id)
    
    new_question_link = driver.find_element(:link, "New Question")
    
    def save_question_and_wait(question)
      question.find_element(:css, "button[type='submit']").click
      keep_trying { question.find_element(:css, ".loading_image_holder").nil? rescue true }
    end
    
    def replace_content(el, value)
      el.clear
      el.send_keys(value)
    end
    
    #### Multiple Choice Question
    
    new_question_link.click
    
    questions = find_all_with_jquery(".question_holder:visible")
    questions.length.should eql(1)
    question = questions[0]
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="multiple_choice_question"]').select
    
    tiny_frame = wait_for_tiny(question.find_element(:css, 'textarea.question_content'))
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys('Hi, this is a multiple choice question.')
    end
    
    answers = find_all_with_jquery('.question_holder:visible:first .form_answers > .answer')
    answers.length.should eql(4)
    replace_content(answers[0].find_element(:css, ".select_answer input"), "Correct Answer")
    replace_content(answers[1].find_element(:css, ".select_answer input"), "Wrong Answer #1")
    replace_content(answers[2].find_element(:css, ".select_answer input"), "Second Wrong Answer")
    replace_content(answers[3].find_element(:css, ".select_answer input"), "Wrongest Answer")
    
    save_question_and_wait(question)
    driver.find_element(:css, "#right-side .points_possible").text.should eql("1")
    
    quiz.reload
    quiz.quiz_questions.length.should == 1
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
    
    
    #### True False Question
    
    new_question_link.click
    
    questions = find_all_with_jquery(".question_holder:visible")
    questions.length.should eql(2)
    question = questions[1]
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="true_false_question"]').select
    
    replace_content(question.find_element(:css, "input[name='question_points']"), "2")
    
    tiny_frame = wait_for_tiny(question.find_element(:css, 'textarea.question_content'))
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys('This is not a true/false question.')
    end
    
    answers = find_all_with_jquery('.question_holder:visible:eq(1) .form_answers > .answer')
    answers.length.should eql(2)
    answers[1].find_element(:css, ".select_answer_link").click # false - get it?
    answers[1].find_element(:css, ".comment_focus").click
    answers[1].find_element(:css, ".answer_comments textarea").send_keys("Good job!")
    
    save_question_and_wait(question)
    driver.find_element(:css, "#right-side .points_possible").text.should eql("3")
    
    quiz.reload
    quiz.quiz_questions.length.should == 2
    
    
    #### Fill in the Blank Question
    
    new_question_link.click
    
    questions = find_all_with_jquery(".question_holder:visible")
    questions.length.should eql(3)
    question = questions[2]
    question.
      find_element(:css, 'select.question_type').
      find_element(:css, 'option[value="short_answer_question"]').select
    
    replace_content(question.find_element(:css, "input[name='question_points']"), "1")
    
    tiny_frame = wait_for_tiny(question.find_element(:css, 'textarea.question_content'))
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys('This is a fill in the _________ question.')
    end
    
    answers = find_all_with_jquery('.question_holder:visible:eq(2) .form_answers > .answer')
    answers.length.should eql(2)
    question.find_element(:css, ".add_answer_link").click
    question.find_element(:css, ".add_answer_link").click
    answers = find_all_with_jquery('.question_holder:visible:eq(2) .form_answers > .answer')
    answers.length.should eql(4)
    answers[3].find_element(:css, ".delete_answer_link").click
    answers[2].find_element(:css, ".delete_answer_link").click
    answers = find_all_with_jquery('.question_holder:visible:eq(2) .form_answers > .answer')
    answers.length.should eql(2)
    replace_content(answers[0].find_element(:css, ".short_answer input"), "blank")
    replace_content(answers[1].find_element(:css, ".short_answer input"), "Blank")
    
    save_question_and_wait(question)
    driver.find_element(:css, "#right-side .points_possible").text.should eql("4")
    
    quiz.reload
    quiz.quiz_questions.length.should == 3
    
    
    #### Fill in Multiple Blanks
    
    #### Multiple Answers
    
    #### Multiple Dropdowns
    
    #### Matching
    
    #### Numerical Answer
    
    #### Formula Question
    
    #### Missing Word
    
    #### Essay Question
    
    #### Text (no answer)
    
    
  end

  it "message students who... should do something" do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    e.save!
    q = e.course.quizzes.build(:title => "My Quiz", :description => "Sup")
    q.generate_quiz_data
    q.published_at = Time.now
    q.workflow_state = 'available'
    q.save!
    login_as(username, password)

    get "/courses/#{e.course_id}/quizzes/#{q.id}"

    driver.find_element(:partial_link_text, "Message Students Who...").click
    dialog = find_all_with_jquery("#message_students_dialog:visible")
    dialog.length.should eql(1)
  end
end

describe "quiz Windows-Firefox-Tests" do
  it_should_behave_like "quiz selenium tests"
end

