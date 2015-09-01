require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/speed_grader_common')

describe 'Speedgrader' do
  include_context "in-process server selenium tests"

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
    it 'complete/incomplete', priority: "1", test_id: 164014 do
      init_course_with_students 2

      @assignment = @course.assignments.create!(
        title: 'Complete?',
        grading_type: 'pass_fail'
      )
      @assignment.grade_student @students[0], {grade: 'complete'}
      @assignment.grade_student @students[1], {grade: 'incomplete'}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      expect(f('#grading-box-extended').attribute 'value').to eq 'complete'
      f('a.next').click
      expect(f('#grading-box-extended').attribute 'value').to eq 'incomplete'
    end

    it 'should display letter grades correctly', priority: "1", test_id: 164015 do
      init_course_with_students 2

      @assignment = create_assignment_with_type('letter_grade')
      @assignment.grade_student @students[0], {grade: 'A'}
      @assignment.grade_student @students[1], {grade: 'C'}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      expect(f('#grading-box-extended').attribute 'value').to eq 'A'
      f('a.next').click
      expect(f('#grading-box-extended').attribute 'value').to eq 'C'

      clear_grade_and_validate
    end

    it 'should display percent grades correctly', priority: "1", test_id: 164202 do
      init_course_with_students 2

      @assignment = create_assignment_with_type('percent')
      @assignment.grade_student @students[0], {grade: 15}
      @assignment.grade_student @students[1], {grade: 10}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      expect(f('#grading-box-extended').attribute 'value').to eq '75'
      f('a.next').click
      expect(f('#grading-box-extended').attribute 'value').to eq '50'

      clear_grade_and_validate
    end

    it 'should display points grades correctly', priority: "1", test_id: 164203 do
      init_course_with_students 2

      @assignment = create_assignment_with_type('points')
      @assignment.grade_student @students[0], {grade: 15}
      @assignment.grade_student @students[1], {grade: 10}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      sleep 5
      expect(f('#grading-box-extended').attribute 'value').to eq '15'
      f('a.next').click
      expect(f('#grading-box-extended').attribute 'value').to eq '10'

      clear_grade_and_validate
    end

    it 'should display gpa scale grades correctly', priority: "1", test_id: 164204 do
      init_course_with_students 2

      @assignment = create_assignment_with_type('gpa_scale')
      @assignment.grade_student @students[0], {grade: 'A'}
      @assignment.grade_student @students[1], {grade: 'D'}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      expect(f('#grading-box-extended').attribute 'value').to eq 'A'
      f('a.next').click
      expect(f('#grading-box-extended').attribute 'value').to eq 'D'

      clear_grade_and_validate
    end

    context 'Using a rubric saves grades' do
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

  context 'grade by question' do
    it 'displays question navigation bar when setting is enabled', priority: "1", test_id: 164019 do
      init_course_with_students

      quiz = seed_quiz_wth_submission

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

      quiz = seed_quiz_wth_submission 10

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

  it 'should have working student drop-down arrows ', priority: "1", test_id: 164018 do
    init_course_with_students 2
    assignment = create_assignment_with_type('letter_grade')

    # see first student
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}#"
    expect(fj('span.ui-selectmenu-item-header')).to include_text(@students[0].name)
    expect(f('#x_of_x_students_frd')).to include_text('Student 1 of 2')

    # click next to second student
    fj('.next').click
    expect(fj('span.ui-selectmenu-item-header')).to include_text(@students[1].name)
    expect(f('#x_of_x_students_frd')).to include_text('Student 2 of 2')

    # go bak to the first student
    fj('.prev').click
    expect(fj('span.ui-selectmenu-item-header')).to include_text(@students[0].name)
    expect(f('#x_of_x_students_frd')).to include_text('Student 1 of 2')
  end

  it 'Student drop-down arrows should wrap around to start when you reach the last student', priority: "1", test_id: 272512 do
    init_course_with_students 2
    assignment = create_assignment_with_type('letter_grade')

    # see first student
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}#"
    expect(fj('span.ui-selectmenu-item-header')).to include_text(@students[0].name)
    expect(f('#x_of_x_students_frd')).to include_text('Student 1 of 2')

    # click next to second student
    fj('.next').click
    expect(fj('span.ui-selectmenu-item-header')).to include_text(@students[1].name)
    expect(f('#x_of_x_students_frd')).to include_text('Student 2 of 2')

    # wrap around to the first student
    fj('.next').click
    expect(fj('span.ui-selectmenu-item-header')).to include_text(@students[0].name)
    expect(f('#x_of_x_students_frd')).to include_text('Student 1 of 2')
  end

  it 'Student drop-down should list all students', priority: "1", test_id: 164206 do
    init_course_with_students 2
    assignment = create_assignment_with_type('letter_grade')

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}#"
    expect(fj('span.ui-selectmenu-item-header')).to include_text(@students[0].name)

    f('a.ui-selectmenu').click
    expect(fj('div.ui-selectmenu-menu.ui-selectmenu-open')).to include_text(@students[0].name)
    expect(fj('div.ui-selectmenu-menu.ui-selectmenu-open')).to include_text(@students[1].name)
  end
end
