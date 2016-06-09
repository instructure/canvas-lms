require_relative "common"

describe "speed grader - quiz submissions" do
  include_context "in-process server selenium tests"

  before(:each) do
    course_with_teacher_logged_in
    @assignment = @course.assignments.create(
      name: 'Quiz', points_possible: 10, submission_types: 'online_quiz'
    )
    @quiz = Quizzes::Quiz.where(assignment_id: @assignment).first
    student_in_course
    2.times do |i|
      qs = @quiz.generate_submission(@student)
      opts = i == 0 ? {finished_at: (Time.zone.today - 7) + 30.minutes} : {}
      Quizzes::SubmissionGrader.new(qs).grade_submission(opts)
    end
  end

  it "links to the quiz history page when there are too many quiz submissions", priority: "2", test_id: 283742 do
    Setting.set("too_many_quiz_submission_versions", 2)
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    expect(f("#content")).not_to contain_css("#submission_to_view")
    uri = URI.parse(f(".see-all-attempts")[:href])
    expect(uri.path).to eq "/courses/#{@course.id}/quizzes/#{@quiz.id}/history"
    expect(uri.query).to eq "user_id=#{@student.id}"
  end

  it "lets you view previous quiz submissions", priority: "1", test_id: 283743 do
    skip_if_chrome('broken - needs research')
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

    submission_dropdown = f("#submission_to_view")
    expect(submission_dropdown).to be_displayed

    submissions = submission_dropdown.find_elements(:css, "option")
    expect(submissions.size).to eq 2

    submissions.each do |s|
      s.click
      submission_date = s.text
      in_frame('speedgrader_iframe') do
        expect(f('.quiz-submission')).to include_text submission_date
      end
    end
  end

  it "hides student's name from quiz if hide student names is enabled", priority: "1", test_id: 283744 do
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

    f("#settings_link").click
    f('#hide_student_names').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    wait_for_ajaximations

    in_frame 'speedgrader_iframe' do
      expect(f('#main')).to include_text("Quiz Results for Student")
    end
  end

  it "only displays 2 decimal points on a quiz submission", priority: "1", test_id: 283997 do
    # create our quiz and our multiple answers question
    @context = @course
    @q = quiz_model
    answers = [ {'id' => 1, 'text' => 'one', 'weight' => 100},
                {'id' => 2, 'text' => 'two', 'weight' => 100},
                {'id' => 3, 'text' => 'three', 'weight' => 100},
                {'id' => 4, 'text' => 'four', 'weight' => 0} ]
    @quest1 = @q.quiz_questions.create!(
      :question_data => {
        :name => "first question",
        'question_type' => 'multiple_answers_question',
        'answers' => answers,
        :points_possible => 4
      }
    )
    @q.generate_quiz_data
    @q.tap(&:save)

    # create a submission and answer our question
    qs = @q.generate_submission(@student)
    (1..4).each do |var|
       qs.submission_data["question_#{@quest1.id}_answer_#{var}"] = "1"
    end
    Quizzes::SubmissionGrader.new(qs).grade_submission

    # navigate to speedgrader and confirm the point value is rounded to the nearest hundredth
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@q.assignment_id}"
    in_frame('speedgrader_iframe') do
      point_value_script = "return $('#question_#{@quest1.id} .question_input')[0].value"
      # sometimes jquery likes to be slow to load, so we do a keep trying so it can try again if $ is undefined
      keep_trying_until { expect(driver.execute_script(point_value_script)).to eq "2.67" }
    end
  end

  it "hides answers of anonymous graded quizzes", priority: "1", test_id: 283738 do
    @quiz.update_attribute(:anonymous_submissions, true)
    qs = @quiz.generate_submission(@student)
    qs.start_grading
    qs.complete
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    expect(f('#this_student_has_a_submission')).to be_displayed
  end

  it "updates quiz grade automatically when the update button is clicked", priority: "1", test_id: 283739 do
    expected_points = "6"
    @quiz.quiz_questions.create!(
      :quiz => @quiz,
      :question_data => {
        :position => 1,
        :question_type => "true_false_question",
        :points_possible => 3,
        :question_name => "true false question"
      }
    )
    @quiz.quiz_questions.create!(
      :quiz => @quiz,
      :question_data => {
        :position => 2,
        :question_type => "essay_question",
        :points_possible => 7,
        :question_name => "essay question"
      }
    )
    @quiz.generate_quiz_data
    @quiz.workflow_state = 'available'
    @quiz.save!
    qs = @quiz.generate_submission(@student)
    qs.submission_data = {"foo" => "bar1"}
    Quizzes::SubmissionGrader.new(qs).grade_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    in_frame('speedgrader_iframe') do
      question_inputs = ff('.header .question_input')
      question_inputs.each { |qi| replace_content(qi, 3) }
      submit_form('#update_history_form')
    end
    input = f('#grade_container input')
    expect(input).to have_attribute('value', expected_points)
  end

  it "properly displays student quiz results when the teacher also " \
    "has a student enrollment", priority: "2", test_id: 283740 do
    @course.enroll_student(@teacher).accept!

    @quiz.quiz_questions.create!(:quiz => @quiz, :question_data => {
        :position => 1,
        :question_type => "true_false_question",
        :points_possible => 3,
        :question_name => "true false question"})
    @quiz.generate_quiz_data
    @quiz.workflow_state = 'available'
    @quiz.save!

    [@student, @teacher].each do
      @quiz.generate_submission(@student).tap do |qs|
        qs.submission_data = {'foo' => 'bar1'}
        Quizzes::SubmissionGrader.new(qs).grade_submission
      end
    end

    get "/courses/#{@course.id}/gradebook/speed_grader?" \
      "assignment_id=#{@assignment.id}#%7B%22student_id%22%3A#{@student.id}%7D"
    wait_for_ajaximations

    in_frame('speedgrader_iframe') do
      expect(f('#content').text).to match(/User/)
      expect(f('#content').text).not_to match(/nobody@example.com/)
    end
  end

  it "includes fake student (Student View Student) submissions in 'X/Y Graded' text", priority: "2", test_id: 283991 do
    # TODO: this *should* be a quiz, since that's the submission type,
    # but that causes `TypeError: submissionHistory is null` in an ajax
    # callback, which usually causes this spec to hang and ultimately fail
    # in wait_for_ajaximations
    @assignment = @course.assignments.create(:name => 'assignment', :points_possible => 10)

    fake_student = @course.student_view_student
    submission = @assignment.find_or_create_submission(fake_student)
    submission.submission_type = 'online_quiz'
    submission.workflow_state = 'submitted'
    submission.save!
    @assignment.grade_student(fake_student, grade: 8, grader: @teacher)
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(f("#x_of_x_graded").text).to eq "1/2"
  end
end
