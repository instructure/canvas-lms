require File.expand_path(File.dirname(__FILE__) + '/../common')

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

    submit_form(question)
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

    submit_form(question)
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

    submit_form(question)
    wait_for_ajaximations
  end

  def add_quiz_question(points)
    @points_total += points.to_i
    @question_count += 1
    driver.find_element(:css, '.add_question_link').click
    question = find_with_jquery('.question_form:visible')
    replace_content(question.find_element(:css, "input[name='question_points']"), points)
    submit_form(question)
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
    answers = {'answer_0' => {'id' => 1}, 'answer_1' => {'id' => 2}, 'answer_2' => {'id' => 3}}
    @quest1 = @q.quiz_questions.create!(:question_data => {:name => "first question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => a)
    @quest2 = @q.quiz_questions.create!(:question_data => {:name => "second question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => b)
    yield bank, @q if block_given?

    @q.generate_quiz_data
    @q.save!
    get "/courses/#{@course.id}/quizzes/#{@q.id}/edit"
    @q
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

  def take_quiz
    @quiz ||= quiz_with_new_questions

    get "/courses/#{@course.id}/quizzes/#{@quiz.id}/take?user_id=#{@user.id}"
    expect_new_page_load {
      driver.find_element(:link_text, 'Take the Quiz').click
    }

    # sleep because display is updated on timer, not ajax callback
    sleep 1
    
    yield
  ensure
    #This step is to prevent selenium from freezing when the dialog appears when leaving the page
    driver.find_element(:link, 'Quizzes').click
    confirm_dialog = driver.switch_to.alert
    confirm_dialog.accept
  end

  def set_feedback_content(el, text)
    el.find_element(:css, ".comment_focus").click
    el.find_element(:css, "textarea").should be_displayed
    el.find_element(:css, "textarea").send_keys(text)
  end

  def hover_first_question
    question = f('.display_question')
    driver.action.move_to(question).perform
  end

  def edit_first_question
    hover_first_question
    f('.edit_question_link').click
    wait_for_animations
  end

  def save_question
    submit_form('.question_form')
    wait_for_ajax_requests
  end

  def change_quiz_type_to(option_text)
    click_option '#quiz_assignment_id', option_text
  end

  def save_settings
    f('.save_quiz_button').click
    wait_for_ajax_requests
  end

  def edit_first_multiple_choice_answer(text)
    element = fj('input[name=answer_text]:visible')
    element.click
    element.send_keys text
  end

  def edit_and_save_first_multiple_choice_answer(text)
    edit_first_question
    edit_first_multiple_choice_answer text
    save_question
  end

  def delete_first_multiple_choice_answer
    driver.execute_script "$('.answer').addClass('hover');"
    fj('.delete_answer_link:visible').click
  end


  ##
  # creates a question group through the browser
  def create_question_group
    f('.add_question_group_link').click
    submit_form('#group_top_new form')
    wait_for_ajax_requests
    @group = QuizGroup.last
  end

  ##
  # Returns the question/group data as an array of hashes
  #
  # a question hash looks like this:
  #
  #   {:id => 23, :el => <#SeleniumElement>, :type => 'question'}
  #
  # a group looks like
  #
  #   {:id => 2, :el => <#SeleniumElement>, :type => 'group', :questions => []}
  #
  # where :questions is an array of questions in the group
  def get_question_data
    els = ff '#questions > *'
    last_group_id = nil
    data = []
    els.each do |el|
      # its a question
      if el['class'].match(/question_holder/)
        id = el.find_element(:css, 'a')['name'].gsub(/question_/, '')
        question = {
          :id => id.to_i,
          :el => el,
          :type => 'question'
        }

        if last_group_id
          # add question to last group
          data.last[:questions] << question
        else
          # not in a group
          data << question
        end

      # its a group
      elsif el['class'].match(/group_top/)
        last_group_id = el['id'].gsub(/group_top_/, '').to_i
        data << {
          :id => last_group_id,
          :questions => [],
          :type => 'group',
          :el => el
        }

      # group ended
      elsif el['class'].match(/group_bottom/)
        last_group_id = nil
      end
    end

    data
  end

  ##
  # Gets the questions hashes out of a group
  def get_question_data_for_group(id)
    data = get_question_data
    group_data = data.detect do |item|
      item[:type] == 'group' && item[:id] == id
    end
    group_data[:questions]
  end

  ##
  # moves the cursor to a question preparatory to dragging it
  def move_to_question(id)
    element = f "#question_#{id}"
    driver.action.move_to(element).perform
  end

  ##
  # moves the cursor to a group preparatory to dragging it
  def move_to_group(id)
    group = f "#group_top_#{id}"
    driver.action.move_to(group).perform
  end


  ##
  # Drags a question with ActiveRecord id `question_id` into group with
  # ActiveRecord id `group_id`
  def drag_question_into_group(question_id, group_id)
    move_to_question question_id
    source = "#question_#{question_id} .move_icon"
    target = "#group_top_#{group_id}"
    js_drag_and_drop source, target
    wait_for_ajax_requests
  end

  ##
  # Asserts that a group contains a question both in the database and
  # in the interface
  def group_should_contain_question(group, question)
    # check active record
    question.reload
    question.quiz_group_id.should == group.id

    # check the interface
    questions = get_question_data_for_group group.id
    questions.detect { |item| item[:id] == question.id }.should_not be_nil
  end

  ##
  # Drags a question with ActiveRecord id of `id` to the top of the list
  def drag_question_to_top(id)
    move_to_question id
    source = "#question_#{id} .move_icon"
    target = '#questions > *'
    js_drag_and_drop source, target
    wait_for_ajax_requests
  end

  ##
  # Drags a group with ActiveRecord id of `id` to the top of the question list
  def drag_group_to_top(id)
    move_to_group id
    source = "#group_top_#{id} .move_icon"
    target = '#questions > *'
    js_drag_and_drop source, target
    wait_for_ajax_requests
  end

  ##
  # Drags a question to the top of the group
  def drag_question_to_top_of_group(question_id, group_id)
    move_to_question question_id
    source = "#question_#{question_id} .move_icon"
    target = "#group_top_#{group_id} + *"
    js_drag_and_drop source, target
  end

end

