require_relative "../../common"
require_relative "../../helpers/gradebook_common"
require_relative "../../helpers/groups_common"
require_relative "../../helpers/assignments_common"
require_relative "../../helpers/quizzes_common"
require_relative "../../helpers/speed_grader_common"
require_relative "../page_objects/speedgrader_page"
require_relative "../../assignments/page_objects/assignment_page"
require_relative "../../assignments/page_objects/submission_detail_page"

describe 'Speedgrader' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include GradebookCommon
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
    wait.until { Speedgrader.grade_input.attribute('value') != "" }
  end

  context 'grading' do

    context 'should display grades correctly' do

      before(:each) do
        init_course_with_students 2
        user_session(@teacher)
      end

      it 'complete/incomplete', priority: "1", test_id: 164014 do
        @assignment = @course.assignments.create!(
          title: 'Complete?',
          grading_type: 'pass_fail'
        )
        @assignment.grade_student @students[0], grade: 'complete', grader: @teacher
        @assignment.grade_student @students[1], grade: 'incomplete', grader: @teacher

        grader_speedgrader_assignment('complete', 'incomplete', false)
      end

      it 'letter grades', priority: "1", test_id: 164015 do
        create_assignment_type_and_grade('letter_grade', 'A', 'C')
        grader_speedgrader_assignment('A', 'C')
      end

      it 'percent grades', priority: "1", test_id: 164202 do
        create_assignment_type_and_grade('percent', 15, 10)
        grader_speedgrader_assignment('75', '50')
      end

      it 'points grades', priority: "1", test_id: 164203 do
        create_assignment_type_and_grade('points', 15, 10)
        grader_speedgrader_assignment('15', '10')
      end

      it 'gpa scale grades', priority: "1", test_id: 164204 do
        create_assignment_type_and_grade('gpa_scale', 'A', 'D')
        grader_speedgrader_assignment('A', 'D')
      end
    end


    context 'quizzes' do
      before(:once) do
        init_course_with_students
        @quiz = seed_quiz_with_submission
      end

      before(:each) do
        user_session(@teacher)
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@quiz.assignment_id}"
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
      before :once do
        init_course_with_students 1
        @assignment = @course.assignments.create!(
          grading_type: 'pass_fail',
          points_possible: 0
        )
        @assignment.grade_student(@students[0], grade: 'pass', grader: @teacher)
      end

      before :each do
        user_session(@teacher)
      end

      it 'should allow pass grade on assignments worth 0 points', priority: "1", test_id: 400127 do
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
        let_speedgrader_load
        expect(Speedgrader.grade_input['value']).to eq('complete')
        expect(f('#grade_container label')).to include_text('(0 / 0)')
      end

      it 'should display pass/fail correctly when total points possible is changed', priority: "1", test_id: 419289 do
        @assignment.update_attributes(points_possible: 1)
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
        let_speedgrader_load
        expect(Speedgrader.grade_input['value']).to eq('complete')
        expect(f('#grade_container label')).to include_text('(1 / 1)')
      end
    end

    context 'Using a rubric saves grades' do
      before :once do
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
      end

      before :each do
        user_session(@teacher)
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
        f('button.toggle_full_rubric').click
        [f('#rating_rat1'), f('#rating_rat5')].each(&:click)
        f('button.save_rubric_button').click
        wait_for_ajax_requests
      end

      it 'in speedgrader', priority: "1", test_id: 164016 do
        expect(Speedgrader.grade_input).to have_value '15'
        expect(f('#grading span.rubric_total')).to include_text '15'
      end

      it 'in assignment page ', priority: "1", test_id: 217611 do
        get "/courses/#{@course.id}/grades/#{@students[0].id}"
        f("#submission_#{@assignment.id}  i.icon-rubric").click

        expect(f('#criterion_crit1 span.criterion_rating_points')).to include_text '10'
        expect(f('#criterion_crit2 span.criterion_rating_points')).to include_text '5'
      end

      it 'in submissions page', priority: "1", test_id: 217612 do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@students[0].id}"
        f('a.assess_submission_link').click
        wait_for_animations

        expect(f('#criterion_crit1 input.criterion_points')).to have_value '10'
        expect(f('#criterion_crit2 input.criterion_points')).to have_value '5'

        replace_content f('#criterion_crit1 input.criterion_points'), '5'
        scroll_into_view('button.save_rubric_button')
        f('button.save_rubric_button').click

        el = f("#student_grading_#{@assignment.id}")
        expect(el).to have_value '10'
      end
    end

    context 'Using a rubric to grade' do
      it 'should display correct grades for student', priority: "1", test_id: 164205 do
        course_with_student_logged_in(active_all: true)
        rubric_model
        @assignment = @course.assignments.create!(name: 'assignment with rubric', points_possible: 10)
        @association = @rubric.associate_with(
          @assignment,
          @course,
          purpose: 'grading',
          use_for_grading: true
        )
        @submission = Submission.create!(
          user: @student,
          assignment: @assignment,
          submission_type: "online_text_entry",
          has_rubric_assessment: true
        )
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
        expect(f('#rating_rat2 .points')).to include_text('5')
      end
    end
  end

  context 'assignment group' do
    it 'should update grades for all students in group', priority: "1", test_id: 164017 do
      skip "Skipped because this spec fails if not run in foreground\nThis is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
      init_course_with_students 5
      user_session(@teacher)
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
        Speedgrader.grade_input.send_keys scores[i]
      end

      get "/courses/#{@course.id}/gradebook"
      cells = ff('#gradebook_grid .container_1 .slick-cell')

      # For whatever reason, this spec fails occasionally.
      # Expected "10"
      # Got "-"

      expect(cells[0]).to include_text '10'
      expect(cells[3]).to include_text '10'
      expect(cells[6]).to include_text '10'
      expect(cells[9]).to include_text '5'
      expect(cells[12]).to include_text '7'
    end
  end

  context 'grade by question' do
    before(:once) do
      init_course_with_students
      @teacher.preferences[:enable_speedgrader_grade_by_question] = true
      @teacher.save!
    end

    let_once(:quiz) { seed_quiz_with_submission(6) }

    before(:each) do
      user_session(@teacher)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{quiz.assignment_id}"
    end

    it 'displays question navigation bar when setting is enabled', priority: "1", test_id: 164019 do
      driver.switch_to.frame f('#speedgrader_iframe')
      expect(f('header.quiz-header')).to include_text quiz.title
      expect(f('#quiz-nav-inner-wrapper')).to be_displayed
      nav = ff('.quiz-nav-li')
      expect(nav).to have_size 24
    end

    it 'scrolls nav bar and to questions', priority: "1", test_id: 164020 do
      skip_if_chrome('broken')

      driver.switch_to.frame f('#speedgrader_iframe')
      wrapper = f('#quiz-nav-inner-wrapper')

      # check scrolling
      first_left = wrapper.css_value('left').to_f

      f('#nav-link-next').click
      second_left = wrapper.css_value('left').to_f
      expect(first_left).to be > second_left

      # check anchors
      anchors = ff('#quiz-nav-inner-wrapper li a')
      data_id = anchors[1].attribute 'data-id'
      anchors[1].click
      expect(f("#question_#{data_id}")).to have_class 'selected_single_question'
    end

    it 'updates scores', priority: "1", test_id: 164021 do
      driver.switch_to.frame f('#speedgrader_iframe')
      list = ff('#questions .user_points input')
      replace_content list[1], "1", :tab_out => true
      replace_content f('#fudge_points_entry'), "7", :tab_out => true

      expect_new_page_load {f('button.update-scores').click}
      expect(f('#after_fudge_points_total')).to include_text '8'
    end
  end

  context 'Student drop-down' do
    before :once do
      init_course_with_students 3
      @assignment = create_assignment_with_type('letter_grade')
    end

    before :each do
      user_session(@teacher)
      # see first student
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    end

    after :each do
      clear_local_storage
    end

    let(:next_) {'.next'}
    let(:previous) {'.prev'}

    it 'selects the first student' do
      expect(Speedgrader.selected_student).to include_text(@students[0].name)
    end

    it 'has working next and previous arrows ', priority: "1", test_id: 164018 do
      # click next to second student
      expect(cycle_students_correctly(next_)).to be

      # click next to third student
      expect(cycle_students_correctly(next_)).to be

      # go back to the first student
      expect(cycle_students_correctly(previous)).to be
    end

    it 'arrows wrap around to start when you reach the last student', priority: "1", test_id: 272512 do
      # click next to second student
      expect(cycle_students_correctly(next_)).to be

      # click next to third student
      expect(cycle_students_correctly(next_)).to be

      # wrap around to the first student
      expect(cycle_students_correctly(next_)).to be
    end

    it 'list all students', priority: "1", test_id: 164206 do
      validate_speedgrader_student_list
    end

    it 'list alias when hide student name is selected', priority: "2", test_id: 164208 do
      Speedgrader.click_settings_link
      Speedgrader.select_hide_student_names

      expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }

      validate_speedgrader_student_list
    end

    # speedgrader student dropdown shows assignment submission status symbols next to student names
    it 'has symbols indicating assignment submission status', priority: "1", test_id: 283502 do
      # grade 2 out of 3 assignments; student3 wont be submitting and wont be graded as well
      @assignment.grade_student(@students[0], grade: 15, grader: @teacher)
      @assignment.grade_student(@students[1], grade: 10, grader: @teacher)

      # resubmit only as student_2

      Timecop.travel(1.hour.from_now) do
        @assignment.submit_homework(
          @students[1],
          submission_type: 'online_text_entry',
          body: 're-submitting!'
        )

        refresh_page
        wait_for_ajaximations

        Speedgrader.click_students_dropdown
        student_options = Speedgrader.student_dropdown_menu.find_elements(tag_name:'li')

        graded = ["graded","resubmitted","not_submitted"]
        (0..2).each{|num| expect(student_options[num]).to have_class(graded[num])}
      end
    end
  end

  context 'submissions' do
    let(:resubmit_with_text) do
      @assignment_for_course.submit_homework(
        @student_in_course, submission_type: 'online_text_entry', body: 'hello!'
      )
    end

    # set up course, users and an assignment
    before(:once) do
      course_with_teacher(active_all:true)
      @student_in_course = User.create!
      @course.enroll_student(@student_in_course, enrollment_state: 'active')
      @assignment_for_course = @course.assignments.create!(
        title: 'Assignment A',
        submission_types: 'online_text_entry,online_upload'
      )
    end

    def submit_with_attachment
      @file_attachment = attachment_model(:content_type => 'application/pdf', :context => @student_in_course)
      @submission_for_student = @assignment_for_course.submit_homework(
        @student_in_course,
        submission_type: 'online_upload',
        attachments: [@file_attachment]
      )
    end

    it 'deleted comment is not visible', priority: "1", test_id: 961674 do
      submit_with_attachment
      @comment_text = "First comment"
      @comment = @submission_for_student.add_comment(author: @teacher, comment: @comment_text)

      # page object
      submission_detail = SubmissionDetails.new

      # student can see the new comment
      user_session(@student_in_course)
      submission_detail.visit_as_student(@course.id, @assignment_for_course.id, @student_in_course.id)
      expect(submission_detail.comment_text_by_id(@comment.id)).to eq @comment_text

      @comment.destroy

      # student cannot see the deleted comment
      submission_detail.visit_as_student(@course.id, @assignment_for_course.id, @student_in_course.id)
      expect(submission_detail.comment_list_div).not_to contain_css("#submission_comment_#{@comment.id}")
    end

    it 'should display the correct file submission in the right sidebar', priority: "1", test_id: 525188 do
      submit_with_attachment
      user_session(@teacher)

      Speedgrader.visit(@course.id, @assignment_for_course.id)
      expect(Speedgrader.submission_file_name.text).to eq @attachment.filename
    end

    it 'should display submissions in order in the submission dropdown', priority: "1", test_id: 525189 do
      Timecop.freeze(1.hour.ago) { submit_with_attachment }
      resubmit_with_text
      user_session(@teacher)

      Speedgrader.visit(@course.id, @assignment_for_course.id)
      Speedgrader.click_submissions_to_view
      Speedgrader.select_option_submission_to_view('0')
      expect(Speedgrader.submission_file_name.text).to eq @attachment.filename
    end
  end

  context 'speedgrader nav bar' do
    # set up course, users and assignment
    let(:test_course) { course_factory() }
    let(:teacher)     { user_factory(active_all: true) }
    let(:student)     { user_factory(active_all: true) }
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

  context "closed grading periods" do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)

      account = @course.root_account
      account.enable_feature! :multiple_grading_periods

      gpg = GradingPeriodGroup.new
      gpg.account_id = account
      gpg.save!
      gpg.grading_periods.create! start_date: 3.years.ago,
                                  end_date: 1.year.ago,
                                  close_date: 1.week.ago,
                                  title: "closed grading period"
      term = @course.enrollment_term
      term.update_attribute :grading_period_group, gpg

      @assignment = @course.assignments.create! name: "aaa", due_at: 2.years.ago
    end

    before(:each) do
      user_session(@teacher)
    end

    it "disables grading" do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f("#grade_container input")["readonly"]).to eq "true"
      expect(f("#closed_gp_notice")).to be_displayed
    end
  end

  context "mute/unmute dialogs" do
    before(:once) do
      init_course_with_students

      @assignment = @course.assignments.create!(
        grading_type: 'points',
        points_possible: 10
      )
    end

    before(:each) do
      user_session(@teacher)
    end

    it "shows dialog when attempting to mute and mutes" do
      @assignment.update_attributes(muted: false)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      f('#mute_link').click
      expect(f('#mute_dialog').attribute('style')).not_to include('display: none')
      f('button.btn-mute').click
      @assignment.reload
      expect(@assignment.muted?).to be true
    end

    it "shows dialog when attempting to unmute and unmutes" do
      @assignment.update_attributes(muted: true)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"
      f('#mute_link').click
      expect(f('#unmute_dialog').attribute('style')).not_to include('display: none')
      f('button.btn-unmute').click
      @assignment.reload
      expect(@assignment.muted?).to be false
    end

  end

  private

  def grader_speedgrader_assignment(grade1, grade2, clear_grade=true)
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#"

    let_speedgrader_load
    expect(Speedgrader.grade_input).to have_value grade1
    Speedgrader.click_next_student_btn
    expect(Speedgrader.grade_input).to have_value grade2

    clear_grade_and_validate if clear_grade
  end

  def create_assignment_type_and_grade(assignment_type, grade1, grade2)
    @assignment = create_assignment_with_type(assignment_type)
    @assignment.grade_student @students[0], grade: grade1, grader: @teacher
    @assignment.grade_student @students[1], grade: grade2, grader: @teacher
  end

  def validate_speedgrader_student_list
    Speedgrader.click_students_dropdown
    (0..2).each{|num| expect(Speedgrader.student_dropdown_menu).to include_text(@students[num].name)}
  end
end
