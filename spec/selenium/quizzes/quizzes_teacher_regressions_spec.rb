require_relative '../common'
require_relative '../helpers/quizzes_common'
require_relative '../helpers/assignment_overrides'

describe 'quizzes regressions' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  before(:each) do
    course_with_teacher_logged_in(course_name: 'teacher course')
    @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
    @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')
  end

  it 'calendar pops up on top of #main', priority: "1", test_id: 209957 do
    get "/courses/#{@course.id}/quizzes/new"
    wait_for_ajaximations
    fj('.ui-datepicker-trigger:first').click
    cal = f('#ui-datepicker-div')
    expect(cal).to be_displayed
    expect(cal.style('z-index')).to be > f('#main').style('z-index')
  end

  it 'marks questions as answered when the window loses focus', priority: "1", test_id: 209959 do
    skip('This spec is fragile')
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
      keep_trying_until { expect(ff('#question_list .answered').size).to eq 1 }

      expect(input).to have_attribute(:value, '1.0000')
    end
  end

  it 'quiz show page displays the quiz due date', priority: "1", test_id: 209960 do
    due_date = Time.zone.now + 4.days
    create_quiz_with_due_date(due_at: due_date)
    verify_quiz_show_page_due_date(format_date_for_view(due_date))
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
    expect(f("#content")).not_to contain_jqcss('.rubric_grading:visible')
  end
end
