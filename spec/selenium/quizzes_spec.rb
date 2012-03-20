require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/quizzes_common')

describe "quizzes" do
  it_should_behave_like "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should allow a teacher to create a quiz from the quizzes tab directly" do
    skip_if_ie('Out of memory')
    get "/courses/#{@course.id}/quizzes"
    expect_new_page_load { driver.find_element(:css, ".new-quiz-link").click }
    driver.find_element(:css, ".save_quiz_button").click
    wait_for_ajax_requests
    assert_flash_notice_message /Quiz data saved/
  end

  it "should create and preview a new quiz" do
    skip_if_ie('Out of memory')
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
    replace_content(driver.find_element(:css, '#quiz_options_form input#quiz_title'), 'new quiz')
    test_text = "new description"
    keep_trying_until { driver.find_element(:id, 'quiz_description_ifr').should be_displayed }
    type_in_tiny '#quiz_description', test_text
    in_frame "quiz_description_ifr" do
      driver.find_element(:id, 'tinymce').should include_text(test_text)
    end

    #add a question
    driver.find_element(:css, '.add_question_link').click
    find_with_jquery('.question_form:visible').submit
    wait_for_ajax_requests

    #save the quiz
    driver.find_element(:css, '.save_quiz_button').click
    wait_for_ajax_requests

    #check quiz preview
    driver.find_element(:link, 'Preview the Quiz').click
    driver.find_element(:id, 'questions').should be_present
  end

  it "should correctly hide form when cancelling quiz edit" do
    skip_if_ie('Out of memory')

    get "/courses/#{@course.id}/quizzes/new"

    wait_for_tiny driver.find_element(:id, 'quiz_description')
    driver.find_element(:css, ".add_question .add_question_link").click
    driver.find_elements(:css, ".question_holder .question_form").length.should == 1
    driver.find_element(:css, ".question_holder .question_form .cancel_link").click
    driver.find_elements(:css, ".question_holder .question_form").length.should == 0
  end

  it "should pop up calendar on top of #main" do
    get "/courses/#{@course.id}/quizzes/new"
    f('#quiz_lock_at + .ui-datepicker-trigger').click
    cal = f('#ui-datepicker-div')
    cal.should be_displayed
    cal.style('z-index').should > f('#main').style('z-index')
  end

  it "should edit a quiz" do
    skip_if_ie('Out of memory')
    @context = @course
    q = quiz_model
    q.generate_quiz_data
    q.save!

    get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
    wait_for_ajax_requests

    test_text = "changed description"
    keep_trying_until { driver.find_element(:id, 'quiz_description_ifr').should be_displayed }
    type_in_tiny '#quiz_description', test_text
    in_frame "quiz_description_ifr" do
      driver.find_element(:id, 'tinymce').text.include?(test_text).should be_true
    end
    driver.find_element(:css, '.save_quiz_button').click
    wait_for_ajax_requests

    get "/courses/#{@course.id}/quizzes/#{q.id}"

    driver.find_element(:css, '#main .description').should include_text(test_text)
  end

  it "message students who... should do something" do
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

    click_option('.message_types', 'Have taken the quiz')
    students = find_all_with_jquery(".student_list > .student:visible")

    students.length.should eql(0)

    click_option('.message_types', 'Have NOT taken the quiz')
    students = find_all_with_jquery(".student_list > .student:visible")
    students.length.should eql(1)

    dialog.find_element(:css, 'textarea#body').send_keys('This is a test message.')

    button = dialog.find_element(:css, "button.send_button")
    button.click
    keep_trying_until { button.text != "Sending Message..." }
    button.text.should eql("Message Sent!")

    student.conversations.size.should eql(1)
  end

  it "should not duplicate unpublished quizzes each time you open the publish multiple quizzes dialog" do
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

  it "should create a new question group" do
    skip_if_ie('Out of memory')

    get "/courses/#{@course.id}/quizzes/new"

    driver.find_element(:css, '.add_question_group_link').click
    group_form = driver.find_element(:css, '#questions .quiz_group_form')
    group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
    replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '3')
    group_form.submit
    group_form.find_element(:css, '.group_display.name').should include_text('new group')

  end

  it "should moderate quiz" do
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
    skip_if_ie('Out of memory')
    quiz_with_new_questions

    expect_new_page_load {
      driver.find_element(:css, '.publish_quiz_button').click
    }
    wait_for_ajax_requests

    expect_new_page_load {
      driver.find_element(:link, 'Take the Quiz').click
    }

    #flag first question
    hover_and_click("#question_#{@quest1.id} .flag_icon")

    #click second answer
    driver.find_element(:css, "#question_#{@quest2.id} .answers .answer:first-child input").click
    driver.find_element(:id, 'submit_quiz_form').submit

    #dismiss dialog and submit quiz
    confirm_dialog = driver.switch_to.alert
    confirm_dialog.dismiss
    driver.find_element(:css, "#question_#{@quest1.id} .answers .answer:last-child input").click
    expect_new_page_load {
      driver.find_element(:id, 'submit_quiz_form').submit
    }
    driver.find_element(:id, 'quiz_title').text.should == @q.title
  end

  it "should indicate when it was last saved" do
    skip_if_ie('Out of memory')
    @context = @course
    bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    q = quiz_model
    a = AssessmentQuestion.create!
    b = AssessmentQuestion.create!
    bank.assessment_questions << a
    bank.assessment_questions << b
    answers = {'answer_0' => {'id' => 1}, 'answer_1' => {'id' => 2}}
    q.quiz_questions.create!(:question_data => {:name => "first question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => a)
    q.quiz_questions.create!(:question_data => {:name => "second question", 'question_type' => 'multiple_choice_question', 'answers' => answers, :points_possible => 1}, :assessment_question => b)

    q.generate_quiz_data
    q.save!
    get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
    driver.find_element(:css, '.publish_quiz_button')

    get "/courses/#{@course.id}/quizzes/#{q.id}/take?user_id=#{@user.id}"
    expect_new_page_load {
      driver.find_element(:link_text, 'Take the Quiz').click
    }

    # sleep because display is updated on timer, not ajax callback
    sleep 1
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
  end

  it "should display quiz statistics" do
    skip_if_ie('Out of memory')
    quiz_with_submission
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

    driver.find_element(:link, "Quiz Statistics").click

    driver.find_element(:css, '#content .question_name').should include_text("Question 1")
  end
end

