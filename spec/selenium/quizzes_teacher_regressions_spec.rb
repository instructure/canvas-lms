require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe 'quizzes regressions' do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

  before(:each) do
    course_with_teacher_logged_in
    @course.update_attributes(name: 'teacher course')
    @course.save!
    @course.reload
  end

  it 'correctly hides form when cancelling quiz edit', priority: "1", test_id: 209956 do
    get "/courses/#{@course.id}/quizzes/new"

    wait_for_tiny f('#quiz_description')
    click_questions_tab
    click_new_question_button
    expect(ff('.question_holder .question_form').length).to eq 1
    f('.question_holder .question_form .cancel_link').click
    expect(ff('.question_holder .question_form').length).to eq 0
  end

  it 'calendar pops up on top of #main', priority: "1", test_id: 209957 do
    get "/courses/#{@course.id}/quizzes/new"
    wait_for_ajaximations
    fj('.ui-datepicker-trigger:first').click
    cal = f('#ui-datepicker-div')
    expect(cal).to be_displayed
    expect(cal.style('z-index')).to be > f('#main').style('z-index')
  end

  it 'can flag a quiz question while taking a quiz as a teacher', priority: "1", test_id: 209958 do
    quiz_with_new_questions(false)

    get "/courses/#{@course.id}/quizzes/#{@q.id}"

    expect_new_page_load do
      f('#take_quiz_link').click
      wait_for_ajaximations
    end

    #flag first question
    hover_and_click("#question_#{@quest1.id} .flag_question")

    #click second answer
    f("#question_#{@quest2.id} .answers .answer:first-child input").click
    f('#submit_quiz_button').click

    #dismiss dialog and submit quiz
    confirm_dialog = driver.switch_to.alert
    confirm_dialog.dismiss
    f("#question_#{@quest1.id} .answers .answer:last-child input").click
    expect_new_page_load {
      f('#submit_quiz_button').click
    }
    expect(f('#quiz_title').text).to eq @q.title
  end

  it 'marks questions as answered when the window loses focus', priority: "1", test_id: 209959 do
    @quiz = quiz_with_new_questions do |bank, quiz|
      aq1 = bank.assessment_questions.create!
      aq2 = bank.assessment_questions.create!
      quiz.quiz_questions.create!(
        question_data: {
          name: 'numerical',
          question_type: 'numerical_question',
          answers: [],
          points_possible: 1
        },
        assessment_question: aq1
      )
      quiz.quiz_questions.create!(
        question_data: {
          name: 'essay',
          question_type: 'essay_question',
          answers: [],
          points_possible: 1
        },
        assessment_question: aq2
      )
    end

    take_quiz do
      wait_for_tiny f('.essay_question textarea.question_input')
      input = f('.numerical_question_input')
      input.click
      input.send_keys('1')
      in_frame f('.essay_question iframe')[:id] do
        f('#tinymce').send_keys :shift # no content, but it gives the iframe focus
      end
      sleep 1
      wait_for_ajaximations
      keep_trying_until {
        expect(ff('#question_list .answered').size).to eq 1
      }

      expect(input).to have_attribute(:value, '1.0000')
    end
  end

  it 'creates assignment with default due date', priority: "1", test_id: 209960 do
    skip('daylight savings time fix')
    get "/courses/#{@course.id}/quizzes/new"
    wait_for_ajaximations
    fill_assignment_overrides
    replace_content(f('#quiz_title'), 'VDD Quiz')

    expect_new_page_load do
      click_save_settings_button
      wait_for_ajax_requests
    end

    compare_assignment_times(Quizzes::Quiz.where(title: 'VDD Quiz').first)
  end

  it 'loads existing due date data into the form', priority: "1", test_id: 209961 do
    @quiz = create_quiz_with_default_due_dates
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
    wait_for_ajaximations
    compare_assignment_times(@quiz.reload)
  end

  it 'doesn\'t show \'use for grading\' as an option in rubrics', priority: "2", test_id: 209962 do
    course_with_teacher_logged_in
    @context = @course
    q = quiz_model
    q.generate_quiz_data
    q.workflow_state = 'available'
    q.save!
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    f('.al-trigger').click
    f('.show_rubric_link').click
    wait_for_ajaximations
    fj('#rubrics .add_rubric_link:visible').click
    keep_trying_until { expect(fj('.rubric_grading:visible')).to be_nil }
  end
end