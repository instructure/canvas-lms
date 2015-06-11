require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')

describe 'Speedgrader' do
  include_examples "in-process server selenium tests"

  let(:quiz_data) do
    [
        {
            question_name: 'Multiple Choice',
            points_possible: 10,
            question_text: 'Pick wisely...',
            answers: [
                {weight: 100, answer_text: 'Correct', id: 1},
                {weight: 0, answer_text: 'Wrong', id: 2},
                {weight: 0, answer_text: 'Wrong', id: 3}
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
        }
    ]
  end

  let(:rubric_data) do
    [
        {
            description: 'Awesomeness',
            points: 10,
            id: 'crit1',
            ratings: [
                {description: 'Much Awesome', points: 10, id: 'rat1'},
                {description: 'So Awesome', points: 5, id: 'rat2'},
                {description: 'Lame', points: 0, id: 'rat3'}
            ]
        },
        {
            description: 'Wow',
            points: 10,
            id: 'crit2',
            ratings: [
                {description: 'Much Wow', points: 10, id: 'rat4'},
                {description: 'So Wow', points: 5, id: 'rat5'},
                {description: 'Wow... not', points: 0, id: 'rat6'}
            ]
        }
    ]
  end

  context 'grading' do
    before do
    end

    it 'complete/incomplete', priority: "1", test_id: 164014 do
      init_course_with_students 2

      assignment = @course.assignments.create!(
        title: 'Complete?',
        grading_type: 'pass_fail'
      )
      assignment.grade_student @students[0], {grade: 'complete'}
      assignment.grade_student @students[1], {grade: 'incomplete'}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}#"
      expect(f('#grading-box-extended').attribute 'value').to eq 'complete'
      f('a.next').click
      expect(f('#grading-box-extended').attribute 'value').to eq 'incomplete'
    end

    it 'letter grade', priority: "1", test_id: 164015 do
      init_course_with_students 2

      assignment = @course.assignments.create!(
        title: 'Letter Grade',
        grading_type: 'letter_grade',
        points_possible: 20
      )
      assignment.grade_student @students[0], {grade: 'A'}
      assignment.grade_student @students[1], {grade: 'C'}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}#"
      expect(f('#grading-box-extended').attribute 'value').to eq 'A'
      f('a.next').click
      expect(f('#grading-box-extended').attribute 'value').to eq 'C'

      assignment.grade_student @students[0], {grade: ''}
      assignment.grade_student @students[1], {grade: ''}

      refresh_page
      expect(f('#grading-box-extended').attribute 'value').to eq ''
      f('a.next').click
      expect(f('#grading-box-extended').attribute 'value').to eq ''

    end

    context 'Using a rubric saves grades', priority: "1", test_id: 164016 do
      before do
        init_course_with_students
        @teacher = @user
        @assignment = @course.assignments.create!(
            title: 'Rubric',
            points_possible: 20
        )

        rubric = @course.rubrics.build(
            title: 'Everything is Awesome',
            points_possible: 20,
        )
        rubric.data = rubric_data
        rubric.save!
        rubric.associate_with(@assignment, @course, purpose: 'grading', use_for_grading: true)
        rubric.reload

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
        f('button.toggle_full_rubric').click
        [f('#rating_rat1'), f('#rating_rat5')].each(&:click)
        f('button.save_rubric_button').click
        wait_for_ajaximations
      end

      it 'in speedgrader', priority: "1", test_id: 164016 do
        expect(f('#grading-box-extended').attribute('value')).to eq '15'
        expect(f('#grading span.rubric_total').text).to eq '15'
      end

      it 'in assignment page ', priority: "1", test_id: 217611 do
        get "/courses/#{@course.id}/grades/#{@students[0].id}"
        f("#submission_#{@assignment.id}  i.icon-rubric").click

        expect(f('#criterion_crit1 span.criterion_rating_points').text).to eq '10'
        expect(f('#criterion_crit2 span.criterion_rating_points').text).to eq '5'
      end

      it 'in submissions page', priority: "1", test_id: 217612 do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@students[0].id}"
        f('a.assess_submission_link').click

        expect(f('#criterion_crit1 input.criterion_points').attribute 'value').to eq '10'
        expect(f('#criterion_crit2 input.criterion_points').attribute 'value').to eq '5'

        replace_content f('#criterion_crit1 input.criterion_points'), '5'
        f('button.save_rubric_button').click
        wait_for_ajaximations

        expect(f("#student_grading_#{@assignment.id}").attribute 'value').to eq '10'
      end

    end
  end

  context 'assignment group' do
    it 'should update grades for all students in group', priority: "1", test_id: 164017 do
      skip "Skipped because this spec fails if not run in foreground\nThis is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
      init_course_with_students 5
      seed_groups 1, 1
      scores = [5, 7, 10]

      (0..2).each do |i|
        @testgroup[0].add_user @students[i]
      end

      @testgroup[0].save!

      assignment = @course.assignments.create!(
        title: 'Group Assignment',
        group_category_id: @testgroup[0].id,
        grade_group_students_individually: false,
        points_possible: 20
      )

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}#"

      # menu needs to be expanded for this to work
      options = ff('#students_selectmenu-menu li')
      # driver.execute_script("$('#students_selectmenu-menu li').focus()")

      options.each_with_index do |option, i|
        f('#students_selectmenu-button').click
        option.click
        f('#grading-box-extended').send_keys scores[i]
      end

      get "/courses/#{@course.id}/gradebook"
      cells = ff('#gradebook_grid .container_1 .slick-cell')

      # For whatever reason, this spec fails occasionally.
      # Expected "10"
      # Got "-"

      expect(cells[0].text).to eq '10'
      expect(cells[3].text).to eq '10'
      expect(cells[6].text).to eq '10'
      expect(cells[9].text).to eq '5'
      expect(cells[12].text).to eq '7'
    end
  end

  def seed_quiz(num=1)
    quiz = @course.quizzes.create title: 'Quiz Me!'

    num.times do
      quiz_data.each do |question|
        quiz.quiz_questions.create! question_data: question
      end
    end

    quiz.workflow_state = 'available'
    quiz.save!

    submission = quiz.generate_submission @students[0]
    submission.workflow_state = 'complete'
    submission.save!

    quiz
  end

  context 'grade by question' do
    it 'displays question navigation bar when setting is enabled', priority: "1", test_id: 164019 do
      init_course_with_students

      quiz = seed_quiz

      user_session(@teacher)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{quiz.assignment_id}"

      driver.switch_to.frame f('#speedgrader_iframe')
      expect(f('header.quiz-header').text).to include quiz.title
      expect(f('#quiz-nav-inner-wrapper')).to be_nil

      @teacher.preferences[:enable_speedgrader_grade_by_question] = true
      @teacher.save!
      refresh_page

      driver.switch_to.frame f('#speedgrader_iframe')
      expect(f('header.quiz-header').text).to include quiz.title
      expect(f('#quiz-nav-inner-wrapper')).to be_displayed
      nav = ff('.quiz-nav-li')
      expect(nav.length).to eq 3
    end

    it 'scrolls nav bar and to questions', priority: "1", test_id: 164020 do
      init_course_with_students

      quiz = seed_quiz 10

      @teacher.preferences[:enable_speedgrader_grade_by_question] = true
      @teacher.save!
      user_session(@teacher)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{quiz.assignment_id}"

      driver.switch_to.frame f('#speedgrader_iframe')
      wrapper = f('#quiz-nav-inner-wrapper')
      expect(f('header.quiz-header').text).to include quiz.title

      expect(wrapper).to be_displayed
      expect(ff('.quiz-nav-li').length).to eq 30

      # check scrolling
      first_left = wrapper.css_value('left')

      f('#nav-link-next').click
      second_left = wrapper.css_value('left')
      expect(first_left).to be > second_left

      # check anchors
      anchors = ff('#quiz-nav-inner-wrapper li a')

      [17, 5, 25].each do |index|
        data_id = anchors[index].attribute 'data-id'
        anchors[index].click
        wait_for_animations
        expect(f("#question_#{data_id}")).to have_class 'selected_single_question'
      end
    end
  end

  it 'updates scores', priority: "1", test_id: 164021 do
    skip "Skipped because this spec fails if not run in foreground\nThis is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"

    init_course_with_students
    quiz = seed_quiz 10

    @teacher.preferences[:enable_speedgrader_grade_by_question] = true
    @teacher.save!
    user_session(@teacher)
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{quiz.assignment_id}"

    driver.switch_to.frame f('#speedgrader_iframe')
      list = ff('#questions .user_points input')
      [9, 17, 25].each do |index|
        driver.execute_script("$('#questions .user_points input').focus()")
        replace_content list[index], "1\t"
      end
      expect(f('#after_fudge_points_total').text).to eq '3'

    # For whatever reason, this spec fails occasionally.
    # Expected "3"
    # Got "2"

    replace_content f('#fudge_points_entry'), "7\t"
    expect_new_page_load {f('button.update-scores').click}
    expect(f('#after_fudge_points_total').text). to eq '10'
  end
end