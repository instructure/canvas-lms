require_relative "../common"

shared_examples_for "quizzes selenium tests" do
  include_examples "in-process server selenium tests"

  def create_quiz_with_default_due_dates
    due_at = Time.zone.now
    unlock_at = Time.zone.now.advance(days:-2)
    lock_at = Time.zone.now.advance(days:4)
    @context = @course
    @quiz = quiz_model
    @quiz.generate_quiz_data
    @quiz.due_at = due_at
    @quiz.lock_at = lock_at
    @quiz.unlock_at = unlock_at
    @quiz.save!
    @quiz
  end

  def create_multiple_choice_question
    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Multiple Choice')

    type_in_tiny ".question_form:visible textarea.question_content", 'Hi, this is a multiple choice question.'

    answers = question.find_elements(:css, ".form_answers > .answer")
    expect(answers.length).to eq 4
    replace_content(answers[0].find_element(:css, ".select_answer input"), "Correct Answer")
    set_answer_comment(0, "Good job!")
    replace_content(answers[1].find_element(:css, ".select_answer input"), "Wrong Answer #1")
    set_answer_comment(1, "Bad job :(")
    replace_content(answers[2].find_element(:css, ".select_answer input"), "Second Wrong Answer")
    replace_content(answers[3].find_element(:css, ".select_answer input"), "Wrongest Answer")

    set_question_comment(".question_correct_comment", "Good job on the question!")
    set_question_comment(".question_incorrect_comment", "You know what they say - study long study wrong.")
    set_question_comment(".question_neutral_comment", "Pass or fail you are a winner!")

    submit_form(question)
    wait_for_ajaximations
  end

  def create_true_false_question
    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'True/False')

    replace_content(question.find_element(:css, "input[name='question_points']"), '4')

    type_in_tiny '.question:visible textarea.question_content', 'This is not a true/false question.'

    answers = question.find_elements(:css, ".form_answers > .answer")
    expect(answers.length).to eq 2
    answers[1].find_element(:css, ".select_answer_link").click # false - get it?
    set_answer_comment(1, "Good job!")

    submit_form(question)
    wait_for_ajaximations
  end

  def create_fill_in_the_blank_question
    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Fill In the Blank')

    replace_content(question.find_element(:css, "input[name='question_points']"), '4')

    type_in_tiny '.question_form:visible textarea.question_content', 'This is a fill in the _________ question.'

    answers = question.find_elements(:css, ".form_answers > .answer")
    replace_content(answers[0].find_element(:css, ".short_answer input"), "blank")
    replace_content(answers[1].find_element(:css, ".short_answer input"), "Blank")

    submit_form(question)
    wait_for_ajaximations
  end

  def create_file_upload_question
    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'File Upload Question')

    replace_content(question.find_element(:css, "input[name='question_points']"), '4')

    type_in_tiny '.question_form:visible textarea.question_content', 'This is a file upload question.'

    submit_form(question)
    wait_for_ajaximations
  end

  def add_quiz_question(points)
    click_questions_tab
    @points_total += points.to_i
    @question_count += 1
    click_new_question_button
    wait_for_ajaximations
    question = fj('.question_form:visible')
    replace_content(question.find_element(:css, "input[name='question_points']"), points)
    submit_form(question)
    wait_for_ajaximations
    questions = ffj(".question_holder:visible")
    expect(questions.length).to eq @question_count
    click_settings_tab
    expect(f(".points_possible").text).to eq @points_total.to_s
  end

  def quiz_with_new_questions(goto_edit=true)
    @context = @course
    bank = @course.assessment_question_banks.create!(:title => 'Test Bank')
    @q = quiz_model
    a = bank.assessment_questions.create!
    b = bank.assessment_questions.create!

    answers = [ {'id' => 1}, {'id' => 2}, {'id' => 3} ]

    @quest1 = @q.quiz_questions.create!(:question_data => {:name => "first question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => a)

    @quest2 = @q.quiz_questions.create!(:question_data => {:name => "second question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => b)
    yield bank, @q if block_given?

    @q.generate_quiz_data
    @q.save!
    get "/courses/#{@course.id}/quizzes/#{@q.id}/edit" if goto_edit
    @q
  end

  def click_settings_tab
    fj('#quiz_tabs ul:first a:eq(0)').click
  end

  def click_questions_tab
    fj('#quiz_tabs ul:first a:eq(1)').click
  end

  # Locate an anchor using its text() node value. The anchor is expected to
  # contain an "accessible variant"; a span.screenreader-only with a clone of its
  # text() value.
  #
  # @argument text [String]
  #   The label, or text() value, of the anchor.
  #
  # We can't use Selenium's `:link_text` because the text() of <a> will actually
  # contain two times the text value for the reason above, so we'll use XPath
  # instead.
  #
  # We can't use Selenium's `:partial_link_text` or XPath's `fn:contains` either
  # because we're not after a partial match (ie, "New Question" would match
  # "New Question Group" and that's incorrect.)
  def find_accessible_link(text)
    driver.find_elements(:xpath, "//a[normalize-space(.)=\"#{text} #{text}\"]")[0]
  end

  # Matcher for a label (or a word) to be used against a block of text that
  # contains an accessible variant.
  #
  # @argument label [String]
  #   The label, or text() value of the element, to create the matcher for.
  #
  # Example: testing the content of an accessible link whose label is 'Publish'
  #
  #     my_link.text.should match accessible_variant_of 'Publish' # => passes
  #     my_link.text.should == 'Publish' # => fails, text will be 'Publish Publish'
  #
  # See #find_accessible_link for more info.
  def accessible_variant_of(label)
    /(?:#{label}\s*){2}/
  end

  def click_new_question_button
    find_accessible_link('New Question').click
  end

  def click_quiz_statistics_button
    find_accessible_link('Quiz Statistics').click
  end

  def click_save_settings_button
    f('.save_quiz_button').click
  end

  def start_quiz_question
    get "/courses/#{@course.id}/quizzes"
    expect_new_page_load {
      f('.new-quiz-link').click
    }
    click_questions_tab
    click_new_question_button
    wait_for_ajaximations
    Quizzes::Quiz.last
  end

  def take_quiz
    @quiz ||= quiz_with_new_questions(!:goto_edit)

    get "/courses/#{@course.id}/quizzes/#{@quiz.id}/take?user_id=#{@user.id}"
    expect_new_page_load { f("#take_quiz_link").click }

    # sleep because display is updated on timer, not ajax callback
    sleep 1

    yield
  ensure
    #This step is to prevent selenium from freezing when the dialog appears when leaving the page
    driver.find_element(:link, 'Quizzes').click
    driver.switch_to.alert.accept
  end

  # @argument answer_chooser [#call]
  #   You can pass a block to specify which answer to choose, the block will
  #   receive the set of possible answers. If you don't, the first (and correct)
  #   answer will be chosen.
  def take_and_answer_quiz(submit=true, &answer_chooser)
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}/take?user_id=#{@user.id}"
    expect_new_page_load { driver.find_element(:link_text, 'Take the Quiz').click }

    answer = if block_given?
      yield(@quiz.stored_questions[0][:answers])
    else
      @quiz.stored_questions[0][:answers][0][:id]
    end

    if answer
      fj("input[type=radio][value=#{answer}]").click
      wait_for_js
    end

    if submit
      driver.execute_script("$('#submit_quiz_form .btn-primary').click()")

      keep_trying_until do
        expect(f('.quiz-submission .quiz_score .score_value')).to be_displayed
      end
    end
  end

  def set_answer_comment(answer_num, text)
    driver.execute_script("$('.question_form:visible .form_answers .answer:eq(#{answer_num}) .comment_focus').click()")
    wait_for_ajaximations
    driver.execute_script("$('.question_form:visible .form_answers .answer:eq(#{answer_num}) .answer_comment_box').val('#{text}')\;")
  end

  def set_question_comment(selector, text)
    driver.execute_script("$('.question_form:visible #{selector} .comment_focus').click()")
    wait_for_ajaximations
    driver.execute_script("$('.question_form:visible #{selector} .comments').val('#{text}')\;")
  end

  def hover_first_question
    question = f('.display_question')
    driver.action.move_to(question).perform
  end

  def edit_first_question
    hover_first_question
    f('.edit_question_link').click
    wait_for_ajaximations
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
    wait_for_ajaximations
  end

  def edit_quiz
    expect_new_page_load {
      wait_for_ajaximations
      f('.quiz-edit-button').click
    }
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
    click_questions_tab
    find_accessible_link('New Question Group').click
    submit_form('#group_top_new form')
    wait_for_ajax_requests
    @group = Quizzes::QuizGroup.last
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
    source = "#question_#{question_id} .draggable-handle"
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
    expect(question.quiz_group_id).to eq group.id

    # check the interface
    questions = get_question_data_for_group group.id
    expect(questions.detect { |item| item[:id] == question.id }).not_to be_nil
  end

  ##
  # Drags a question with ActiveRecord id of `id` to the top of the list
  def drag_question_to_top(id)
    move_to_question id
    source = "#question_#{id} .draggable-handle"
    target = '#questions > *'
    js_drag_and_drop source, target
    wait_for_ajax_requests
  end

  ##
  # Drags a group with ActiveRecord id of `id` to the top of the question list
  def drag_group_to_top(id)
    move_to_group id
    source = "#group_top_#{id} .draggable-handle"
    target = '#questions > *'
    js_drag_and_drop source, target
    wait_for_ajax_requests
  end

  ##
  # Drags a question to the top of the group
  def drag_question_to_top_of_group(question_id, group_id)
    move_to_question question_id
    source = "#question_#{question_id} .draggable-handle"
    target = "#group_top_#{group_id} + *"
    js_drag_and_drop source, target
  end
end
