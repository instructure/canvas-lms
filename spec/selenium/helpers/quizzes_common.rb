#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module QuizzesCommon

  def create_quiz_with_due_date(opts={})
    @context = opts.fetch(:course, @course)
    @quiz = quiz_model
    @quiz.generate_quiz_data
    @quiz.due_at = opts.fetch(:due_at, default_time_for_due_date(Time.zone.now))
    @quiz.lock_at = opts.fetch(:lock_at, default_time_for_lock_date(4.days.from_now))
    @quiz.unlock_at = opts.fetch(:unlock_at, default_time_for_unlock_date(1.week.ago))
    @quiz.save!
    @quiz
  end

  # The default time for a quiz due date is 11:59pm
  def default_time_for_due_date(date)
    date.change({ hour: 23, min: 59 })
  end

  # The default time for a quiz lock date is 11:59pm
  def default_time_for_lock_date(date)
    date.change({ hour: 23, min: 59 })
  end

  # The default time for a quiz unlock date is 12am
  def default_time_for_unlock_date(date)
    date.change({ hour: 0, min: 0 })
  end

  def assign_quiz_to_no_one
    f('.ContainerDueDate .ic-token-delete-button').click
  end

  def create_multiple_choice_question(opts={})
    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Multiple Choice')

    question_description = opts.fetch(:description, 'Hi, this is a multiple choice question.')
    type_in_tiny ".question_form:visible textarea.question_content", question_description

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

    button_locator = "//button[contains(.,'Update Question') and not(contains(.,'Create'))]"
    update_question_button=driver.find_element(:xpath,button_locator)
    scroll_to(update_question_button)
    update_question_button.click
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
    click_new_question_button
    wait_for_ajaximations
    question = fj('.question_form:visible')
    replace_content(question.find_element(:css, "input[name='question_points']"), points)
    submit_form(question)
    wait_for_ajaximations
    click_settings_tab
  end

  def quiz_with_multiple_type_questions(goto_edit=true)
    @context = @course
    bank = @context.assessment_question_banks.create!(:title => 'Test Bank')
    @quiz = quiz_model
    a = bank.assessment_questions.create!
    b = bank.assessment_questions.create!
    c = bank.assessment_questions.create!
    answers = [ {'id' => 1}, {'id' => 2}, {'id' => 3} ]

    @quest1 = @quiz.quiz_questions.create!(
      question_data: {
        name: 'first question',
        question_type: 'multiple_choice_question',
        answers: answers,
        points_possible: 1
      },
      assessment_question: a
    )

    @quest2 = @quiz.quiz_questions.create!(
      question_data: {
        name: 'second question',
        question_text: 'What is 5+5?',
        question_type: 'numerical_question',
        answers: [],
        points_possible: 1
      },
      assessment_question: b
    )

    @quest3 = @quiz.quiz_questions.create!(
      question_data: {
        name: 'third question',
        question_type: 'essay_question',
        answers: [],
        points_possible: 1
      },
      assessment_question: c
    )

    yield bank, @quiz if block_given?

    @quiz.generate_quiz_data
    @quiz.save!
    open_quiz_edit_form if goto_edit
    @quiz
  end

  def quiz_with_essay_questions(goto_edit=true)
    # TODO: DRY this up
    @context = @course
    bank = @context.assessment_question_banks.create!(:title => 'Test Bank')
    @quiz = quiz_model
    a = bank.assessment_questions.create!
    b = bank.assessment_questions.create!
    c = bank.assessment_questions.create!
    answers = [ {'id' => 1}, {'id' => 2}, {'id' => 3} ]

    @quest1 = @quiz.quiz_questions.create!(
      question_data: {
        name: 'first question',
        question_type: 'essay_question',
        answers: [],
        points_possible: 1
      },
      assessment_question: a
    )

    @quest2 = @quiz.quiz_questions.create!(
      question_data: {
        name: 'second question',
        question_type: 'essay_question',
        answers: [],
        points_possible: 1
      },
      assessment_question: b
    )

    @quest3 = @quiz.quiz_questions.create!(
      question_data: {
        name: 'third question',
        question_type: 'essay_question',
        answers: [],
        points_possible: 1
      },
      assessment_question: c
    )

    yield bank, @quiz if block_given?

    @quiz.generate_quiz_data
    @quiz.save!
    open_quiz_edit_form if goto_edit
    @quiz
  end

  def quiz_with_new_questions(goto_edit=true, *answers)
    @context = @course
    bank = @context.assessment_question_banks.create!(title: 'Test Bank')
    @quiz = quiz_model
    a = bank.assessment_questions.create!
    b = bank.assessment_questions.create!

    answers = [ {id: 1}, {id: 2}, {id: 3} ] if answers.empty?

    @quest1 = @quiz.quiz_questions.create!(
      question_data: {
        name: 'first question',
        question_type: 'multiple_choice_question',
        answers: answers,
        points_possible: 1
      },
      assessment_question: a
    )

    @quest2 = @quiz.quiz_questions.create!(
      question_data: {
        name: 'second question',
        question_type: 'multiple_choice_question',
        answers: answers,
        points_possible: 1
      },
      assessment_question: b
    )

    yield bank, @quiz if block_given?

    @quiz.generate_quiz_data
    @quiz.save!
    open_quiz_edit_form if goto_edit
    @quiz
  end

  def click_settings_tab
    wait_for_ajaximations
    fj('#quiz_tabs ul:first a:eq(0)').click
  end

  def click_questions_tab
    wait_for_ajaximations
    dismiss_flash_messages_if_present
    f("a[href='#questions_tab']").click
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

  def click_new_quiz_button
    f('.new-quiz-link').click
    wait_for_new_page_load
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
    @context = @course
    quiz_model
    open_quiz_edit_form
    click_questions_tab
    click_new_question_button
    wait_for_ajaximations
    Quizzes::Quiz.last
  end

  def rcs_start_quiz_question
    @context = @course
    quiz_model
    open_quiz_edit_form
    wait_for_ajaximations
    click_questions_tab
    wait_for_ajaximations
    click_new_question_button
    wait_for_ajaximations
    Quizzes::Quiz.last
  end

  def select_question_from_column_links(question_id)
    f("#list_question_#{question_id} > a:nth-child(1)").click
    wait_for_ajaximations
  end

  def answer_question(question_answer_id)
    fj("input[type=radio][value=#{question_answer_id}]").click
  end

  def take_quiz
    @quiz ||= quiz_with_new_questions(!:goto_edit)
    begin_quiz

    yield
  ensure
    # This step is to prevent selenium from freezing when the dialog appears when leaving the page
    fln('Quizzes').click
    driver.switch_to.alert.accept if alert_present?
  end

  def take_and_answer_quiz(opts={})
    @quiz = opts[:quiz] if opts.fetch(:quiz, false)
    submit = opts.fetch(:submit, true)
    access_code = opts.fetch(:access_code, nil)

    begin_quiz(access_code, opts)
    complete_and_submit_quiz(submit)
  end

  def begin_quiz(access_code=nil, opts={})
    get take_quiz_url

    # do this as close to submission creation as possible to avoid being locked by the time the page loads
    if opts[:lock_after]
      @quiz.lock_at = Time.now + opts[:lock_after]
      @quiz.save!
    end

    if access_code.nil?
      wait_for_new_page_load { f('#take_quiz_link').click }
    else
      f('#quiz_access_code').send_keys(access_code)
      wait_for_new_page_load { fj('.btn', '#main').click }
    end or raise "unable to start quiz"

    wait_for_quiz_to_begin
  end

  # uses sleep() because the display is updated on a timer, not an ajax callback
  def wait_for_quiz_to_begin
    sleep 1
  end

  def submit_quiz
    f('#submit_quiz_button').click
    accept_alert if alert_present?
    wait_for_ajax_requests

    expect(f('.quiz-submission .quiz_score .score_value')).to be_truthy
  end

  def preview_quiz(submit=true)
    open_quiz_show_page

    expect_new_page_load { f('#preview_quiz_button').click }
    wait_for_quiz_to_begin

    complete_and_submit_quiz(submit)
  end

  def wait_for_quiz_publish_button_to_populate
    link = f('#quiz-publish-link')
    keep_trying_until { link.text.present? }
  end

  # @argument answer_chooser [#call]
  #   You can pass a block to specify which answer to choose, the block will
  #   receive the set of possible answers. If you don't, the first (and correct)
  #   answer will be chosen.
  def complete_and_submit_quiz(submit=true)
    answer =
      if block_given?
        yield(@quiz.stored_questions[0][:answers])
      else
        @quiz.stored_questions[0][:answers][0][:id]
      end

    answer_question(answer) if answer

    submit_quiz if submit
  end

  def answer_questions_and_submit(quiz, num_questions, submit = true)
    num_questions.times do |o|
     question = quiz.stored_questions[o][:id]
     case quiz.stored_questions[o][:question_type]
     when "multiple_choice_question"
       fj("input[type=radio][name= 'question_#{question}']").click
     when "essay_question"
       type_in_tiny ".question:visible textarea[name = 'question_#{question}']", 'This is an essay question.'
     when "numerical_question"
       fj("input[type=text][name= 'question_#{question}']").send_keys('10')
     end
    end

    submit_quiz if submit
  end

  def set_answer_comment(answer_num, text)
    driver.execute_script("$('.question_form:visible .form_answers .answer:eq(#{answer_num}) .comment_focus').click()")
    wait_for_ajaximations
    type_in_tiny(".question_form:visible .form_answers .answer:eq(#{answer_num}) .answer_comments textarea", text)
  end

  def set_question_comment(selector, text)
    driver.execute_script("$('.question_form:visible #{selector} .comment_focus').click()")
    wait_for_ajaximations
    type_in_tiny(".question_form:visible #{selector} textarea", text)
  end

  def question_answers
    ffj('.answer', '.form_answers')
  end

  def delete_possible_answer(question_answer_index)
    question_answer = question_answers[question_answer_index]
    hover(question_answer)

    delete_question_link = fj('.delete_answer_link', question_answer)
    hover(delete_question_link)
    delete_question_link.click
  end

  def select_different_correct_answer(index_of_new_correct_answer)
    new_correct_answer = fj('.select_answer_link', question_answers[index_of_new_correct_answer])
    hover(new_correct_answer)
    new_correct_answer.click
    wait_for_ajaximations
  end

  def hover_first_question
    question = f('.display_question')
    hover(question)
  end

  def select_regrade_option(option_index=0)
    visible_regrade_options[option_index].click
    fj('.ui-dialog:visible .btn-primary').click
    wait_for_ajaximations
  end

  def visible_regrade_options
    ffj('label.checkbox:visible', '.regrade_enabled')
  end

  # clicks |Okay, fine|
  def close_times_up_dialog
    times_up_dialog = fj('div#times_up_dialog:visible')
    fj('button.submit_quiz_button', times_up_dialog).click unless times_up_dialog.nil?
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
    expect_new_page_load { f('.quiz-edit-button').click }
  end

  def cancel_quiz_edit
    expect_new_page_load { fj('#cancel_button', 'div#quiz_edit_actions').click }
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
    # drag math gets off if we don't do this and things end up dropped in the wrong place
    scroll_page_to_top
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
    # drag math gets off if we don't do this and things end up dropped in the wrong place
    scroll_page_to_top
    js_drag_and_drop source, target
    wait_for_ajax_requests
  end

  ##
  # Drags a group with ActiveRecord id of `id` to the top of the question list
  def drag_group_to_top(id)
    move_to_group id
    source = "#group_top_#{id} .draggable-handle"
    target = '#questions > *'
    # drag math gets off if we don't do this and things end up dropped in the wrong place
    scroll_page_to_top
    js_drag_and_drop source, target
    wait_for_ajax_requests
  end

  ##
  # Drags a question to the top of the group
  def drag_question_to_top_of_group(question_id, group_id)
    move_to_question question_id
    source = "#question_#{question_id} .draggable-handle"
    target = "#group_top_#{group_id} + *"
    # drag math gets off if we don't do this and things end up dropped in the wrong place
    scroll_page_to_top
    js_drag_and_drop source, target
  end

  def quiz_create(opts={})
    course = opts.fetch(:course, @course)
    @quiz = course.quizzes.create

    data = {
      question_name: 'Question 1',
      points_possible: 1,
      question_text: 'This is a multiple choice question',
      answers: [
        { weight: 100, answer_text: 'A', answer_comments: '', id: 1490 },
        { weight: 0, answer_text: 'B', answer_comments: '', id: 1020 },
        { weight: 0, answer_text: 'C', answer_comments: '', id: 7051 }
      ],
      question_type: 'multiple_choice_question'
    }

    @quiz.quiz_questions.create!(question_data: data)

    @quiz.allowed_attempts = -1 if opts.fetch(:unlimited_attempts, false)
    @quiz.lock_at = opts.fetch(:lock_at, nil)
    @quiz.due_at = opts.fetch(:due_at, nil)
    @quiz.unlock_at = opts.fetch(:unlock_at, nil)

    @quiz.generate_quiz_data
    @quiz.publish!
    @quiz.save!
    @quiz
  end

  def seed_quiz_with_submission(num=1, opts={})
    quiz_data = opts[:question_data] || [
      {
        question_name: 'Multiple Choice',
        points_possible: 10,
        question_text: 'Pick wisely...',
        answers: [
          { weight: 100, answer_text: 'Correct', id: 1 },
          { weight: 0, answer_text: 'Wrong', id: 2 },
          { weight: 0, answer_text: 'Wrong', id: 3 }
        ],
        question_type: 'multiple_choice_question'
      },
      {
        question_name: 'File Upload',
        points_possible: 5,
        question_text: 'Upload a file',
        question_type: 'file_upload_question'
      },
      {
        question_name: 'Short Essay',
        points_possible: 20,
        question_text: 'Write an essay',
        question_type: 'essay_question'
      },
      {
        question_name: 'Text (no question)',
        question_text: 'This is just text',
        question_type: 'text_only_question'
      }
    ]

    quiz = @course.quizzes.create title: 'Quiz Me!'
    num.times do
      quiz_data.each do |question|
        quiz.quiz_questions.create! question_data: question
      end
    end

    quiz.workflow_state = 'available'
    quiz.save!

    submission = quiz.generate_submission opts[:student] || @students[0]
    submission.workflow_state = 'complete'
    submission.save!

    quiz
  end

  def verify_quiz_show_page_due_date(due_date)
    open_quiz_show_page
    expect(f('#quiz_show')).to include_text due_date
  end

  def verify_quiz_is_locked
    open_quiz_show_page unless driver.current_url == quiz_show_page_url
    expect(fj('.lock_explanation')).to include_text 'This quiz was locked'
  end

  def verify_quiz_is_submitted
    open_quiz_show_page unless driver.current_url == quiz_show_page_url
    expect(fj('.quiz-submission')).to include_text 'Submitted'
  end

  def verify_quiz_submission_is_late
    verify_quiz_submission_late_status(:late)
  end

  def verify_quiz_submission_is_not_late
    verify_quiz_submission_late_status(!:late)
  end

  def open_quiz_show_page
    get quiz_show_page_url
  end

  def open_student_quiz_submission
    get quiz_student_submission_url
  end

  def verify_quiz_submission_is_late_in_speedgrader
    verify_quiz_submission_status_in_speedgrader(:late)
  end

  def verify_quiz_submission_is_not_late_in_speedgrader
    verify_quiz_submission_status_in_speedgrader(!:late)
  end

  def open_quiz_in_speedgrader
    user_session(@teacher)
    get quiz_submission_speedgrader_url
  end

  def open_quiz_edit_form
    get quiz_edit_form_url
  end

  private

  def quiz_show_page_url
    "/courses/#{@course.id}/quizzes/#{@quiz.id}"
  end

  def quiz_edit_form_url
    "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
  end

  def quiz_student_submission_url
    "/courses/#{@course.id}/assignments/#{@quiz.assignment_id}/submissions/#{@student.id}"
  end

  def quiz_submission_speedgrader_url
    "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@quiz.assignment_id}"
  end

  def take_quiz_url
    "/courses/#{@course.id}/quizzes/#{@quiz.id}/take?user_id=#{@user.id}"
  end

  def verify_quiz_submission_late_status(late)
    open_student_quiz_submission
    submission_page_info = f('.submission_details', f('#not_right_side'))

    if late
      expect(submission_page_info).to contain_css('.submission-late-pill')
    else
      expect(submission_page_info).not_to contain_css('.submission-late-pill')
    end
  end

  def verify_quiz_submission_status_in_speedgrader(late)
    open_quiz_in_speedgrader
    speedgrader_submission_details = f('#submission_details', f('.right_side_content'))

    if late
      expect(speedgrader_submission_details).to contain_css('.submission-late-pill')
    else
      expect(speedgrader_submission_details).not_to contain_css('.submission-late-pill')
    end
  end

  def generate_and_save_submission(quiz, student)
    submission = quiz.generate_submission student
    submission.workflow_state = 'complete'
    submission.save!
  end
end
