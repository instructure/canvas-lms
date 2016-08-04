require_relative "common"
require_relative "helpers/gradebook2_common"
require_relative "helpers/groups_common"
require_relative "helpers/assignments_common"
require_relative "helpers/quizzes_common"
require_relative "helpers/speed_grader_common"

describe 'Speedgrader' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include Gradebook2Common
  include GroupsCommon
  include AssignmentsCommon
  include SpeedGraderCommon

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

  def let_speedgrader_load
    wait = Selenium::WebDriver::Wait.new(timeout: 5)
    wait.until { f("#grading-box-extended").attribute('value') != "" }
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
      let_speedgrader_load
      expect(f('#grading-box-extended')).to have_value 'complete'
      f('#next-student-button').click
      expect(f('#grading-box-extended')).to have_value 'incomplete'
    end

    it 'should display letter grades correctly', priority: "1", test_id: 164015 do
      init_course_with_students 2

      @assignment = create_assignment_with_type('letter_grade')
      @assignment.grade_student @students[0], {grade: 'A'}
      @assignment.grade_student @students[1], {grade: 'C'}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      let_speedgrader_load
      expect(f('#grading-box-extended')).to have_value 'A'
      f('#next-student-button').click
      expect(f('#grading-box-extended')).to have_value 'C'

      clear_grade_and_validate
    end

    it 'should display percent grades correctly', priority: "1", test_id: 164202 do
      init_course_with_students 2

      @assignment = create_assignment_with_type('percent')
      @assignment.grade_student @students[0], {grade: 15}
      @assignment.grade_student @students[1], {grade: 10}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      let_speedgrader_load
      expect(f('#grading-box-extended')).to have_value '75'
      f('#next-student-button').click
      expect(f('#grading-box-extended')).to have_value '50'

      clear_grade_and_validate
    end

    it 'should display points grades correctly', priority: "1", test_id: 164203 do
      init_course_with_students 2

      @assignment = create_assignment_with_type('points')
      @assignment.grade_student @students[0], {grade: 15}
      @assignment.grade_student @students[1], {grade: 10}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      let_speedgrader_load
      expect(f('#grading-box-extended')).to have_value '15'
      f('#next-student-button').click
      expect(f('#grading-box-extended')).to have_value '10'

      clear_grade_and_validate
    end

    it 'should display gpa scale grades correctly', priority: "1", test_id: 164204 do
      init_course_with_students 2

      @assignment = create_assignment_with_type('gpa_scale')
      @assignment.grade_student @students[0], {grade: 'A'}
      @assignment.grade_student @students[1], {grade: 'D'}

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      let_speedgrader_load
      expect(f('#grading-box-extended')).to have_value 'A'
      f('#next-student-button').click
      expect(f('#grading-box-extended')).to have_value 'D'

      clear_grade_and_validate
    end

    context 'quizzes' do
      before(:each) do
        init_course_with_students
        quiz = seed_quiz_with_submission

        user_session(@teacher)
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{quiz.assignment_id}"
        driver.switch_to.frame f('#speedgrader_iframe')
      end

      it 'should display needs review alert on non-autograde questions', priority: "1", test_id: 441360 do
        expect(ff('#update_history_form .alert')[0]).to include_text('The following questions need review:')
      end

      it 'should only display needs review for file_upload and essay questions', priority: "2", test_id: 452539 do
        questions_to_grade = ff('#questions_needing_review li a')
        expect(questions_to_grade[0]).to include_text('Question 2')
        expect(questions_to_grade[1]).to include_text('Question 3')
      end

      it 'should not display review warning on text only quiz questions', priority: "1", test_id: 377664 do
        expect(ff('#update_history_form .alert')[0]).not_to include_text('Question 4')
      end
    end

    context 'pass/fail assignment grading' do
      before :each do
        init_course_with_students 1
        @assignment = @course.assignments.create!(grading_type: 'pass_fail', points_possible: 0)
        @assignment.grade_student(@students[0], grade: 'pass')
      end

      it 'should allow pass grade on assignments worth 0 points', priority: "1", test_id: 400127 do
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
        let_speedgrader_load
        expect(f('#grading-box-extended')['value']).to eq('complete')
        expect(f('#grade_container label')).to include_text('(0 / 0)')
      end

      it 'should display pass/fail correctly when total points possible is changed', priority: "1", test_id: 419289 do
        @assignment.update_attributes(points_possible: 1)
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
        let_speedgrader_load
        expect(f('#grading-box-extended')['value']).to eq('complete')
        expect(f('#grade_container label')).to include_text('(1 / 1)')
      end
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
        expect(f('#grading-box-extended')).to have_value '15'
        expect(f('#grading span.rubric_total')).to include_text '15'
      end

      it 'in assignment page ', priority: "1", test_id: 217611 do
        get "/courses/#{@course.id}/grades/#{@students[0].id}"
        f("#submission_#{@assignment.id}  i.icon-rubric").click

        expect(f('#criterion_crit1 span.criterion_rating_points').text).to eq '10'
        expect(f('#criterion_crit2 span.criterion_rating_points').text).to eq '5'
      end

      it 'in submissions page', priority: "1", test_id: 217612 do
        driver.manage.window.maximize
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@students[0].id}"
        f('a.assess_submission_link').click

        expect(f('#criterion_crit1 input.criterion_points')).to have_value '10'
        expect(f('#criterion_crit2 input.criterion_points')).to have_value '5'

        replace_content f('#criterion_crit1 input.criterion_points'), '5'
        scroll_into_view('button.save_rubric_button')
        f('button.save_rubric_button').click
        wait_for_ajaximations

        el = f("#student_grading_#{@assignment.id}")
        expect(el).to have_value '10'
      end
    end
    context 'Using a rubric to grade' do
      it 'should display correct grades from a student perspective', priority: "1", test_id: 164205 do
        course_with_student_logged_in(active_all: true)
        rubric_model
        @assignment = @course.assignments.create!(name: 'assignment with rubric', points_possible: 10)
        @association = @rubric.associate_with(@assignment, @course, purpose: 'grading', use_for_grading: true)
        @submission = Submission.create!(user: @student, assignment: @assignment, submission_type: "online_text_entry", has_rubric_assessment: true)
        @assessment = @association.assess(
          user: @student,
          assessor: @teacher,
          artifact: @submission,
          assessment: {
            assessment_type: 'grading',
            criterion_crit1: { points: 5 }
          }
        )
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
        f('a.assess_submission_link').click

        expect(f('#rating_rat2')).to have_class('selected')
        expect(f('#rating_rat2 .points').text).to eq('5')
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

      quiz = seed_quiz_with_submission
      user_session(@teacher)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{quiz.assignment_id}"

      driver.switch_to.frame f('#speedgrader_iframe')
      expect(f('header.quiz-header').text).to include quiz.title
      expect(f("#content")).not_to contain_css('#quiz-nav-inner-wrapper')

      @teacher.preferences[:enable_speedgrader_grade_by_question] = true
      @teacher.save!
      refresh_page

      driver.switch_to.frame f('#speedgrader_iframe')
      expect(f('header.quiz-header').text).to include quiz.title
      expect(f('#quiz-nav-inner-wrapper')).to be_displayed
      nav = ff('.quiz-nav-li')
      expect(nav.length).to eq 4
    end

    it 'scrolls nav bar and to questions', priority: "1", test_id: 164020 do
      skip_if_chrome('broken')
      init_course_with_students

      quiz = seed_quiz_with_submission(10)

      @teacher.preferences[:enable_speedgrader_grade_by_question] = true
      @teacher.save!
      user_session(@teacher)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{quiz.assignment_id}"

      driver.switch_to.frame f('#speedgrader_iframe')
      wrapper = f('#quiz-nav-inner-wrapper')
      expect(f('header.quiz-header').text).to include quiz.title

      expect(wrapper).to be_displayed
      expect(ff('.quiz-nav-li').length).to eq 40

      # check scrolling
      first_left = wrapper.css_value('left').to_f

      f('#nav-link-next').click
      second_left = wrapper.css_value('left').to_f
      expect(first_left).to be > second_left

      # check anchors
      anchors = ff('#quiz-nav-inner-wrapper li a')

      [17, 25, 33].each do |index|
        data_id = anchors[index].attribute 'data-id'
        anchors[index].click
        wait_for_animations
        expect(f("#question_#{data_id}")).to have_class 'selected_single_question'
      end
    end
  end

  it 'updates scores', priority: "1", test_id: 164021 do
    init_course_with_students
    quiz = seed_quiz_with_submission(10)

    @teacher.preferences[:enable_speedgrader_grade_by_question] = true
    @teacher.save!
    user_session(@teacher)
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{quiz.assignment_id}"

    driver.switch_to.frame f('#speedgrader_iframe')
    list = ff('#questions .user_points input')
    [9, 17, 25].each do |index|
      driver.execute_script("$('#questions .user_points input').focus()")
      replace_content list[index], "1", :tab_out => true
    end
    expect_new_page_load {f('button.update-scores').click}
    expect(f('#after_fudge_points_total').text).to eq '3'

    replace_content f('#fudge_points_entry'), "7", :tab_out => true
    expect_new_page_load {f('button.update-scores').click}
    expect(f('#after_fudge_points_total').text).to eq '10'
  end

  context 'Student drop-down' do
    before :each do
      init_course_with_students 2
      assignment = create_assignment_with_type('letter_grade')

      # see first student
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}#"
      expect(f(selectedStudent)).to include_text(@students[0].name)
    end

    let(:selectedStudent) {'span.ui-selectmenu-item-header'}
    let(:studentXofXlabel) {'#x_of_x_students_frd'}
    let(:studentDropdownMenu) {'div.ui-selectmenu-menu.ui-selectmenu-open'}
    let(:studentDropdown) {'a.ui-selectmenu'}
    let(:next_) {'.next'}
    let(:previous) {'.prev'}

    it 'has working next and previous arrows ', priority: "1", test_id: 164018 do
      # click next to second student
      expect(cycle_students_correctly(next_))

      # go bak to the first student
      expect(cycle_students_correctly(previous))
    end

    it 'arrows wrap around to start when you reach the last student', priority: "1", test_id: 272512 do
      # click next to second student
      expect(cycle_students_correctly(next_))

      # wrap around to the first student
      expect(cycle_students_correctly(next_))
    end

    it 'list all students', priority: "1", test_id: 164206 do
      f(studentDropdown).click

      expect(f(studentDropdownMenu)).to include_text(@students[0].name)
      expect(f(studentDropdownMenu)).to include_text(@students[1].name)
    end

    it 'list alias when hide student name is selected', priority: "2", test_id: 164208 do
      f('#settings_link').click
      f('#hide_student_names').click
      expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }

      f(studentDropdown).click
      expect(f(studentDropdownMenu)).to include_text('Student 1')
      expect(f(studentDropdownMenu)).to include_text('Student 2')
    end
  end

  context 'submissions' do
    # set up course and users
    let(:test_course) { course() }
    let(:teacher)     { user(active_all: true) }
    let(:student)     { user(active_all: true) }
    let!(:enroll_teacher_and_students) do
      test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active')
      test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active')
    end
    # create an assignment with online_upload type submission
    let(:assignment) { test_course.assignments.create!( title: 'Assignment A', submission_types: 'online_text_entry,online_upload') }
    # submit to the assignment as a student twice, one with file and other with text
    let(:file_attachment) { attachment_model(:content_type => 'application/pdf', :context => student) }
    let(:submit_with_attachment) do
      assignment.submit_homework(
        student,
        submission_type: 'online_upload',
        attachments: [file_attachment]
      )
    end
    let(:resubmit_with_text) { assignment.submit_homework(student, submission_type: 'online_text_entry', body: 'hello!') }
    it 'should display the correct file submission in the right sidebar', priority: "1", test_id: 525188 do
      submit_with_attachment
      user_session(teacher)

      get "/courses/#{test_course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
      expect(fj('#submission_files_list .submission-file .display_name')).to include_text('unknown.loser')
    end

    it 'should display submissions in order in the submission dropdown', priority: "1", test_id: 525189 do
      Timecop.freeze(1.hour.ago) { submit_with_attachment }
      resubmit_with_text
      user_session(teacher)

      get "/courses/#{test_course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
      f('#submission_to_view').click
      click_option('#submission_to_view', '0', :value)
      wait_for_ajaximations
      expect(f('#submission_files_list .submission-file .display_name')).to include_text('unknown.loser')
    end
  end

  context 'speedgrader nav bar' do
    # set up course, users and assignment
    let(:test_course) { course() }
    let(:teacher)     { user(active_all: true) }
    let(:student)     { user(active_all: true) }
    let!(:enroll_teacher_and_students) do
      test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active')
      test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active')
    end
    let!(:assignment) do
      test_course.assignments.create!(
        title: 'Assignment A',
        submission_types: 'online_text_entry,online_upload'
      )
    end

    it 'opens and closes keyboard shortcut modal via blue info icon', priority: "2", test_id: 759319 do
      user_session(teacher)
      get "/courses/#{test_course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
      keyboard_shortcut_icon = f('#keyboard-shortcut-info-icon')
      keyboard_modal = f('#keyboard_navigation')
      expect(keyboard_shortcut_icon).to be_displayed

      # Open shortcut modal
      keyboard_shortcut_icon.click
      expect(keyboard_modal).to be_displayed

      # Close shortcut modal
      f('.ui-resizable .ui-dialog-titlebar-close').click
      expect(keyboard_modal).not_to be_displayed
    end
  end
end
