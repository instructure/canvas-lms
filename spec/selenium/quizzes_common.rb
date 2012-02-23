shared_examples_for "quizzes selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  def create_multiple_choice_question
    question = find_with_jquery(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Multiple Choice')

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
    wait_for_ajaximations
  end

  def create_true_false_question
    question = find_with_jquery(".question_form:visible")
    click_option('.question_form:visible .question_type', 'True/False')

    replace_content(question.find_element(:css, "input[name='question_points']"), '4')

    type_in_tiny '.question:visible textarea.question_content', 'This is not a true/false question.'

    answers = question.find_elements(:css, ".form_answers > .answer")
    answers.length.should eql(2)
    answers[1].find_element(:css, ".select_answer_link").click # false - get it?
    answers[1].find_element(:css, ".comment_focus").click
    answers[1].find_element(:css, ".answer_comments textarea").send_keys("Good job!")

    question.submit
    wait_for_ajaximations
  end

  def create_fill_in_the_blank_question
    question = find_with_jquery(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Fill In the Blank')

    replace_content(question.find_element(:css, "input[name='question_points']"), '4')

    type_in_tiny '.question_form:visible textarea.question_content', 'This is a fill in the _________ question.'

    answers = question.find_elements(:css, ".form_answers > .answer")
    replace_content(answers[0].find_element(:css, ".short_answer input"), "blank")
    replace_content(answers[1].find_element(:css, ".short_answer input"), "Blank")

    question.submit
    wait_for_ajaximations
  end

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

  def quiz_with_new_questions
    @context = @course
    bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    @q = quiz_model
    a = AssessmentQuestion.create!
    b = AssessmentQuestion.create!
    bank.assessment_questions << a
    bank.assessment_questions << b
    answers = {'answer_0' => {'id' => 1}, 'answer_1' => {'id' => 2}}
    @quest1 = @q.quiz_questions.create!(:question_data => {:name => "first question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => a)
    @quest2 = @q.quiz_questions.create!(:question_data => {:name => "second question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => b)

    @q.generate_quiz_data
    @q.save!
    get "/courses/#{@course.id}/quizzes/#{@q.id}/edit"
  end

  def start_quiz_question
    get "/courses/#{@course.id}/quizzes"
    expect_new_page_load {
      driver.find_element(:css, '.new-quiz-link').click
    }

    driver.find_element(:css, '.add_question_link').click
    wait_for_animations
    Quiz.last
  end

  def set_feedback_content(el, text)
    el.find_element(:css, ".comment_focus").click
    el.find_element(:css, "textarea").should be_displayed
    el.find_element(:css, "textarea").send_keys(text)
  end
end
