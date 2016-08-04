require File.expand_path(File.dirname(__FILE__) + '/../common')

module Gradebook2Common
  shared_context 'gradebook_components' do
    let(:gradebook_settings_cog) { f('#gradebook_settings') }
    let(:group_weights_menu) { f('[aria-controls="assignment_group_weights_dialog"]') }
    let(:show_notes) { fj('li a:contains("Show Notes Column")') }
    let(:hide_notes) { f(".hide") }
  end
  shared_context 'reusable_course' do
    let(:test_course) { course(active_course: true) }
    let(:teacher)     { user(active_all: true) }
    let(:student)     { user(active_all: true) }
    let(:concluded_student) { user(name: 'Stewie Griffin', active_all: true) }
    let(:observer)    { user(active_all: true) }
    let(:enroll_teacher_and_students) do
      test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active')
      test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active')
      test_course.enroll_user(concluded_student, 'StudentEnrollment', enrollment_state: 'completed')
    end
    let(:assignment_group_1) { test_course.assignment_groups.create! name: 'Group 1' }
    let(:assignment_group_2) { test_course.assignment_groups.create! name: 'Group 2' }
    let(:assignment_1) do
      test_course.assignments.create!(
        title: 'Points Assignment',
        grading_type: 'points',
        points_possible: 10,
        submission_types: 'online_text_entry',
        due_at: 2.days.ago,
        assignment_group: assignment_group_1
      )
    end
    let(:assignment_2) do
      test_course.assignments.create!(
        title: 'Percent Assignment',
        grading_type: 'percent',
        points_possible: 10,
      )
    end
    let(:assignment_3) do
      test_course.assignments.create!(
        title: 'Complete/Incomplete Assignment',
        grading_type: 'pass_fail',
        points_possible: 10
      )
    end
    let(:assignment_4) do
      test_course.assignments.create!(
        title: 'Letter Grade Assignment',
        grading_type: 'letter_grade',
        points_possible: 10
      )
    end
    let(:assignment_5) do
      test_course.assignments.create!(
        title: 'Zero Points Possible',
        grading_type: 'points',
        points_possible: 0,
        assignment_group: assignment_group_2
      )
    end
    let(:student_submission) do
      assignment_1.submit_homework(
        student,
        submission_type: 'online_text_entry',
        body: 'Hello!'
      )
    end
  end
  def init_course_with_students(num = 1)
    course_with_teacher_logged_in

    @students = []
    (1..num).each do |i|
      student = User.create!(:name => "Student_#{i}")
      student.register!

      e1 = @course.enroll_student(student)
      e1.workflow_state = 'active'
      e1.save!
      @course.reload

      @students.push student
    end
  end

  def set_default_grade(cell_index, points = "5")
    open_assignment_options(cell_index)
    f('[data-action="setDefaultGrade"]').click
    dialog = find_with_jquery('.ui-dialog:visible')
    f('.grading_value').send_keys(points)
    submit_dialog(dialog, '.ui-button')
    accept_alert
  end

  def toggle_muting(assignment)
    find_with_jquery(".gradebook-header-drop[data-assignment-id='#{assignment.id}']").click
    find_with_jquery('[data-action="toggleMuting"]').click
    find_with_jquery('.ui-dialog-buttonpane [data-action$="mute"]:visible').click
    wait_for_ajaximations
  end

  def open_assignment_options(cell_index)
    assignment_cell = ffj('#gradebook_grid .container_1 .slick-header-column')[cell_index]
    driver.action.move_to(assignment_cell).perform
    trigger = assignment_cell.find_element(:css, '.gradebook-header-drop')
    trigger.click
    expect(fj("##{trigger['aria-owns']}")).to be_displayed
  end

  def find_slick_cells(row_index, element)
    grid = element
    rows = grid.find_elements(:css, '.slick-row')
    row_cells = rows[row_index].find_elements(:css, '.slick-cell')
    row_cells
  end

  def edit_grade(cell, grade)
    hover_and_click cell
    grade_input = fj("#{cell} .grade")
    set_value(grade_input, grade)
    grade_input.send_keys(:return)
    wait_for_ajaximations
  end

  def open_comment_dialog(x=0, y=0)
    cell = f("#gradebook_grid .container_1 .slick-row:nth-child(#{y+1}) .slick-cell:nth-child(#{x+1})")
    hover cell
    fj('.gradebook-cell-comment:visible', cell).click
    # the dialog fetches the comments async after it displays and then innerHTMLs the whole
    # thing again once it has fetched them from the server, completely replacing it
    wait_for_ajax_requests
    fj('.submission_details_dialog:visible')
  end

  def final_score_for_row(row)
    grade_grid = f('#gradebook_grid .container_1')
    cells = find_slick_cells(row, grade_grid)
    cells[4].find_element(:css, '.percentage').text
  end

  def switch_to_section(section=nil)
    section = section.id if section.is_a?(CourseSection)
    section ||= ""
    fj('.section-select-button:visible').click
    expect(fj('.section-select-menu:visible')).to be_displayed
    fj("label[for='section_option_#{section}']").click
    wait_for_ajaximations
  end

  def conclude_and_unconclude_course
    # conclude course
    @course.complete!
    @user.reload
    @user.cached_current_enrollments
    @enrollment.reload

    # un-conclude course
    @enrollment.workflow_state = 'active'
    @enrollment.save!
    @course.reload
  end

  def gradebook_data_setup(opts={})
    assignment_setup_defaults
    assignment_setup(opts)
  end

  def data_setup_as_observer
    user_with_pseudonym
    course_with_observer_logged_in user: @user
    @course.observers=[@observer]
    assignment_setup_defaults
    assignment_setup
    @all_students.each {|s| s.observers=[@observer]}
  end

  def assignment_setup_defaults
    @assignment_1_points = "10"
    @assignment_2_points = "5"
    @assignment_3_points = "50"
    @attendance_points = "15"

    @student_name_1 = "student 1"
    @student_name_2 = "student 2"
    @student_name_3 = "student 3"

    @student_1_total_ignoring_ungraded = "100%"
    @student_2_total_ignoring_ungraded = "66.67%"
    @student_3_total_ignoring_ungraded = "66.67%"
    @student_1_total_treating_ungraded_as_zeros = "18.75%"
    @student_2_total_treating_ungraded_as_zeros = "12.5%"
    @student_3_total_treating_ungraded_as_zeros = "12.5%"
    @default_password = "qwerty"
  end

  def assignment_setup(opts={})
    course_with_teacher_logged_in(opts)
    @course.grading_standard_enabled = true
    @course.save!
    @course.reload

    # add first student
    @student_1 = User.create!(:name => @student_name_1)
    @student_1.register!
    @student_1.pseudonyms.create!(:unique_id => "nobody1@example.com", :password => @default_password, :password_confirmation => @default_password)

    e1 = @course.enroll_student(@student_1)
    e1.workflow_state = 'active'
    e1.save!
    @course.reload

    # add second student
    @other_section = @course.course_sections.create(:name => "the other section")
    @student_2 = User.create!(:name => @student_name_2)
    @student_2.register!
    @student_2.pseudonyms.create!(:unique_id => "nobody2@example.com", :password => @default_password, :password_confirmation => @default_password)
    e2 = @course.enroll_student(@student_2, :section => @other_section)

    e2.workflow_state = 'active'
    e2.save!
    @course.reload

    # add third student
    @student_3 = User.create!(:name => @student_name_3)
    @student_3.register!
    @student_3.pseudonyms.create!(:unique_id => "nobody3@example.com", :password => @default_password, :password_confirmation => @default_password)
    e3 = @course.enroll_student(@student_3)
    e3.workflow_state = 'active'
    e3.save!
    @course.reload

    @all_students = [@student_1, @student_2, @student_3]

    # first assignment data
    @group = @course.assignment_groups.create!(:name => 'first assignment group', :group_weight => 100)
    @first_assignment = assignment_model({
                                             :course => @course,
                                             :name => 'A name that would not reasonably fit in the header cell which should have some limit set',
                                             :due_at => nil,
                                             :points_possible => @assignment_1_points,
                                             :submission_types => 'online_text_entry,online_upload',
                                             :assignment_group => @group
                                         })
    rubric_model
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
    @assignment.reload
    @submission = @assignment.submit_homework(@student_1, :body => 'student 1 submission assignment 1')
    @assignment.grade_student(@student_1, :grade => 10)
    @submission.score = 10
    @submission.save!

    # second student submission for assignment 1
    @student_2_submission = @assignment.submit_homework(@student_2, :body => 'student 2 submission assignment 1')
    @assignment.grade_student(@student_2, :grade => 5)
    @student_2_submission.score = 5
    @submission.save!

    # third student submission for assignment 1
    @student_3_submission = @assignment.submit_homework(@student_3, :body => 'student 3 submission assignment 1')
    @assignment.grade_student(@student_3, :grade => 5)
    @student_3_submission.score = 5
    @submission.save!

    # second assignment data
    @second_assignment = assignment_model({
                                              :course => @course,
                                              :name => 'second assignment',
                                              :due_at => nil,
                                              :points_possible => @assignment_2_points,
                                              :submission_types => 'online_text_entry',
                                              :assignment_group => @group
                                          })
    @second_association = @rubric.associate_with(@second_assignment, @course, :purpose => 'grading')

    # all students get a 5 on assignment 2
    @all_students.each do |s|
      submission = @second_assignment.submit_homework(s, :body => "#{s.name} submission assignment 2")
      @second_assignment.grade_student(s, :grade => 5)
      submission.save!
    end

    # third assignment data
    due_date = Time.zone.now + 1.day
    @third_assignment = assignment_model({
                                             :course => @course,
                                             :name => 'assignment three',
                                             :due_at => due_date,
                                             :points_possible => @assignment_3_points,
                                             :submission_types => 'online_text_entry',
                                             :assignment_group => @group
                                         })
    @third_association = @rubric.associate_with(@third_assignment, @course, :purpose => 'grading')

    # attendance assignment
    @attendance_assignment = assignment_model({
                                                  :course => @course,
                                                  :name => 'attendance assignment',
                                                  :title => 'attendance assignment',
                                                  :due_at => nil,
                                                  :points_possible => @attendance_points,
                                                  :submission_types => 'attendance',
                                                  :assignment_group => @group,
                                              })

    @ungraded_assignment = @course.assignments.create!(
      :title => 'not-graded assignment',
      :submission_types => 'not_graded',
      :assignment_group => @group
    )
  end

  def get_group_points
    ff('div.assignment-points-possible')
  end

  def check_group_points(expected_weight_text)
    2..3.each do |i|
      expect(get_group_points[i].text).to eq expected_weight_text[i-2] + ' of grade'
    end
  end

  def set_group_weight(assignment_group, weight_number, enable_scheme: false)
    f('#gradebook_settings').click
    f('[aria-controls="assignment_group_weights_dialog"]').click

    dialog = f('#assignment_group_weights_dialog')
    expect(dialog).to be_displayed

    if enable_scheme
      group_check = dialog.find_element(:id, 'group_weighting_scheme')
      group_check.click
    end
    expect(is_checked('#group_weighting_scheme')).to be_truthy
    group_weight_input = f("#assignment_group_#{assignment_group.id}_weight")
    set_value(group_weight_input, "")
    set_value(group_weight_input, weight_number)
    fj('.ui-button:contains("Save")').click
    wait_for_ajaximations
    expect(@course.reload.group_weighting_scheme).to eq 'percent'
  end

  def disable_group_weight
    f('#gradebook_settings').click
    f('[aria-controls="assignment_group_weights_dialog"]').click

    dialog = f('#assignment_group_weights_dialog')
    expect(dialog).to be_displayed

    group_check = dialog.find_element(:id, 'group_weighting_scheme')
    group_check.click
    expect(is_checked('#group_weighting_scheme')).to be_falsey
    fj('.ui-button:contains("Save")').click
    refresh_page
  end

  def validate_group_weight_text(assignment_groups, weight_numbers)
    assignment_groups.each_with_index do |ag, i|
      heading = fj(".slick-column-name:contains('#{ag.name}') .assignment-points-possible")
      expect(heading).to include_text("#{weight_numbers[i]}% of grade")
    end
  end

  def validate_group_weight(assignment_group, weight_number)
    expect(assignment_group.reload.group_weight).to eq weight_number
  end
end
