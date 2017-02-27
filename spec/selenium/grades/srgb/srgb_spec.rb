#
# Copyright (C) 2014 - 2017 Instructure, Inc.
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
#

require_relative '../../helpers/gradebook_common'
require_relative '../page_objects/srgb_page'
require_relative '../page_objects/grading_curve_page'

describe "Screenreader Gradebook" do
  include_context 'in-process server selenium tests'
  include_context 'gradebook_components'
  include_context 'reusable_course'
  include GradebookCommon

  let(:default_gradebook) { "/courses/#{@course.id}/gradebook/change_gradebook_version?version=2" }
  let(:button_type_submit) { f('.button_type_submit') }
  let(:arrange_assignments) { f('#arrange_assignments') }

  let(:assign1_default_points) {1}
  let(:assignment_default_points) {20}
  let(:grading_value) { f('.grading_value') }
  let(:gradebook_cell_css) { '.gradebook-cell' }
  let(:view_grading_history) { f("a[href='/courses/#{@course.id}/gradebook/history']") }

  def active_element
    driver.switch_to.active_element
  end

  def basic_percent_setup(num=1)
    init_course_with_students num
    user_session(@teacher)
    @course.assignments.create!(
      title: 'Test 1',
      submission_types: 'online_text_entry',
      points_possible: 20,
      grading_type: 'percent'
    )
  end

  def basic_point_setup(num=1)
    init_course_with_students num
    user_session(@teacher)
    @curve_assignment = @course.assignments.create!(
      title: 'Test 1',
      submission_types: 'online_text_entry',
      points_possible: 20,
      grading_type: 'points'
    )
  end

  def simple_setup(student_number = 2)
    init_course_with_students student_number
    user_session(@teacher)
    @course.assignment_groups.create! name: 'Group 1'
    @course.assignment_groups.create! name: 'Group 2'
    @assign1 = @course.assignments.create!(
      title: 'Test 1',
      points_possible: assignment_default_points,
      assignment_group: @course.assignment_groups[0]
    )
    @assign2 = @course.assignments.create!(
      title: 'Test 2',
      points_possible: assignment_default_points,
      assignment_group: @course.assignment_groups[1]
    )

    @grade_array = ['15', '12', '11', '3']
  end

  def simple_grade
    @assign1.grade_student(@students[0], grade: @grade_array[0], grader: @teacher)
    @assign1.grade_student(@students[1], grade: @grade_array[1], grader: @teacher)
    @assign2.grade_student(@students[0], grade: @grade_array[2], grader: @teacher)
    @assign2.grade_student(@students[1], grade: @grade_array[3], grader: @teacher)
  end

  it 'can select a student', priority: '1', test_id: 163994 do
    simple_setup
    simple_grade
    SRGB.visit(@course.id)

    student_dropdown_options = ['No Student Selected', @students[0].name, @students[1].name]
    expect(get_options('#student_select').map(&:text)).to eq student_dropdown_options

    click_option '#student_select', @students[0].name
    assignment_points = ["(#{@grade_array[0]} / 20)", "(#{@grade_array[2]} / 20)"]
    expect(ff('#student_information .assignment-group-grade .points').map(&:text)).to eq assignment_points

    click_option '#student_select', @students[1].name
    assignment_points = ["(#{@grade_array[1]} / 20)", "(#{@grade_array[3]} / 20)"]
    expect(ff('#student_information .assignment-group-grade .points').map(&:text)).to eq assignment_points
  end

  it 'can select a student using buttons', priority: '1', test_id: 163997 do
    init_course_with_students 3
    user_session(@teacher)
    SRGB.visit(@course.id)

    # first student
    expect(SRGB.previous_student.attribute('disabled')).to be_truthy
    SRGB.next_student.click
    expect(f('#student_information .student_selection')).to include_text @students[0].name

    # second student
    SRGB.next_student.click
    expect(f('#student_information .student_selection')).to include_text @students[1].name

    # third student
    SRGB.next_student.click
    expect(SRGB.next_student.attribute('disabled')).to be_truthy
    expect(f('#student_information .student_selection')).to include_text @students[2].name
    expect(SRGB.previous_student).to eq driver.switch_to.active_element

    # click twice to go back to first student
    SRGB.previous_student.click
    SRGB.previous_student.click
    expect(f('#student_information .student_selection')).to include_text @students[0].name
    expect(SRGB.next_student).to eq driver.switch_to.active_element
  end

  it 'can select an assignment using buttons', priority: '2', test_id: 615707 do
    simple_setup
    SRGB.visit(@course.id)
    SRGB.select_student(@students[0])
    SRGB.select_assignment(@assign1)

    expect(SRGB.previous_assignment.attribute('disabled')).to be_truthy
    expect(SRGB.next_assignment.attribute('disabled')).not_to be_truthy

    SRGB.next_assignment.click
    expect(SRGB.previous_assignment.attribute('disabled')).not_to be_truthy
    expect(SRGB.next_assignment.attribute('disabled')).to be_truthy

    SRGB.previous_assignment.click
    expect(SRGB.previous_assignment.attribute('disabled')).to be_truthy
  end

  it 'links to assignment show page', priority: '2', test_id: 615684 do
    simple_setup
    simple_grade
    @submission = @assign1.submit_homework(@students[0], body: 'student submission')
    SRGB.visit(@course.id)
    SRGB.select_student(@students[0])
    SRGB.select_assignment(@assign1)
    SRGB.assignment_link.click

    expect(driver.current_url).to include("/courses/#{@course.id}/assignments/#{@assign1.id}")
  end

  it 'sets default grade', priority: '2', test_id: 615689 do
    num_of_students = 2
    simple_setup(num_of_students)
    SRGB.visit(@course.id)
    SRGB.select_student(@students[0])
    SRGB.select_assignment(@assign1)

    SRGB.default_grade.click
    replace_content(grading_value, assign1_default_points)
    button_type_submit.click

    get default_gradebook
    grade = gradebook_column_array(gradebook_cell_css)
    expect(grade.count assign1_default_points.to_s).to eq(num_of_students)
  end

  it 'can select an assignment', priority: '1', test_id: 163998 do
    a1 = basic_percent_setup
    a2 = @course.assignments.create!(
      title: 'Test 2',
      points_possible: 20,
    )

    a1.grade_student(@students[0], grade: 14, grader: @teacher)
    SRGB.visit(@course.id)

    expect(get_options('#assignment_select').map(&:text)).to eq ['No Assignment Selected', a1.name, a2.name]
    click_option '#assignment_select', a1.name
    expect(f('#assignment_information .assignment_selection')).to include_text a1.name
    expect(f('#assignment_information')).to include_text 'Online text entry'
  end

  it 'displays/removes warning message for resubmitted assignments', priority: '1', test_id: 164000 do
    skip "Skipped because this spec fails if not run in foreground\n"\
      "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
    assignment = basic_percent_setup
    user_session @students[0]
    assignment.submit_homework @students[0], submission_type: 'online_text_entry', body: 'Hello!'

    user_session @teacher
    assignment.grade_student(@students[0], grade: 12, grader: @teacher)

    user_session @students[0]
    assignment.submit_homework @students[0], submission_type: 'online_text_entry', body: 'Hello again!'

    user_session @teacher
    SRGB.visit(@course.id)
    click_option '#assignment_select', assignment.name
    click_option '#student_select', @students[0].name
    expect(f('p.resubmitted')).to be_displayed

    replace_content f('#student_and_assignment_grade'), "15\t"
    expect(f("#content")).not_to contain_css('p.resubmitted')
  end

  it 'grades match default gradebook grades', priority: '1', test_id: 163994 do
    skip "Skipped because this spec fails if not run in foreground\n"\
      "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
    a1 = basic_percent_setup
    a2 = @course.assignments.create!(
      title: 'Test 2',
      points_possible: 20
    )

    grades = [15, 12]

    get "/courses/#{@course.id}/gradebook"
    f('.canvas_1 .slick-row .slick-cell').click
    f('.canvas_1 .slick-row .slick-cell .grade').send_keys grades[0], :return

    SRGB.visit(@course.id)
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', a1.name
    expect(f('#student_and_assignment_grade')).to have_value grades[0]
    expect(f('#student_information .total-grade')).to include_text "75% (#{grades[0]} / 20 points)"

    click_option '#assignment_select', a2.name
    f('#student_and_assignment_grade').clear
    f('#student_and_assignment_grade').send_keys grades[1], :return
    get default_gradebook
    expect(f('.canvas_1 .slick-row .slick-cell:nth-of-type(2)')).to include_text grades[1]
  end

  it 'can mute assignments', priority: '1', test_id: 164001 do
    assignment = basic_percent_setup
    SRGB.visit(@course.id)

    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    f('#assignment_muted_check').click
    fj('.ui-dialog:visible [data-action="mute"]').click
    wait_for_ajax_requests

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    expect(f('.student_assignment.editable')).to have_attribute('data-muted', 'true')

    get default_gradebook
    expect(fj('.slick-header-columns .slick-header-column:eq(2) a')).to have_class 'muted'
  end

  it 'can unmute assignments', priority: '1', test_id: 288859 do
    assignment = basic_percent_setup
    assignment.mute!

    SRGB.visit(@course.id)
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    f('#assignment_muted_check').click
    fj('.ui-dialog:visible [data-action="unmute"]').click
    wait_for_ajax_requests

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    expect(f('.student_assignment.editable')).to have_attribute('data-muted', 'false')

    get default_gradebook
    expect(fj('.slick-header-columns .slick-header-column:eq(2) a')).not_to have_class 'muted'
  end

  it 'can message students who... ', priority: '1', test_id: 164002 do
    basic_percent_setup
    SRGB.visit(@course.id)

    click_option '#assignment_select', 'Test 1'
    f('#message_students').click
    expect(f('#message_students_dialog')).to be_displayed

    f('#body').send_keys('Hello!')
    driver.action.send_keys(:tab).perform
    driver.action.send_keys(:enter).perform
    expect(f('#message_students_dialog')).not_to be_displayed
  end

  it 'has total graded submission', priority: '1', test_id: 615686 do
    assignment = basic_percent_setup 2

    assignment.grade_student(@students[0], grade: 15, grader: @teacher)
    assignment.grade_student(@students[1], grade: 5, grader: @teacher)
    get default_gradebook
    f('a.assignment_header_drop').click
    ff('.gradebook-header-menu a').find{|a| a.text == "Assignment Details"}.click

    data = [
      'Average Score: 10',
      'High Score: 15',
      'Low Score: 5',
      'Total Graded Submissions: 2 submissions'
    ]
    expect(f('#assignment-details-dialog-stats-table').text.split(/\n/)).to eq data

    SRGB.visit(@course.id)
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    expect(f('#assignment_information p:nth-of-type(2)')).to include_text 'Graded submissions: 2'
    expect(ff('#assignment_information table td').map(&:text)).to eq ['20', '10', '15', '5']
  end

  context "as a teacher" do
    before(:once) do
      gradebook_data_setup
    end

    before(:each) do
      user_session(@teacher)
    end

    it "switches to srgb", priority: '1', test_id: 615682 do
      get "/courses/#{@course.id}/gradebook"
      f("#change_gradebook_version_link_holder").click
      expect(f("#not_right_side")).to include_text("Gradebook: Individual View")
      refresh_page
      expect(f("#not_right_side")).to include_text("Gradebook: Individual View")
      f(".span12 a").click
      expect(f("#change_gradebook_version_link_holder")).to be_displayed
    end

    it "shows sections in drop-down", priority: '1', test_id: 615680 do
      sections=[]
      2.times do |i|
        sections << @course.course_sections.create!(:name => "other section #{i}")
      end

      SRGB.visit(@course.id)

      ui_options = Selenium::WebDriver::Support::Select.new(f("#section_select")).options().map(&:text)
      sections.each do |section|
        expect(ui_options.include? section[:name]).to be_truthy
      end
    end

    it 'shows history', priority: '2', test_id: 615676 do
      SRGB.visit(@course.id)

      view_grading_history.click
      expect(driver.page_source).to include('Gradebook History')
      expect(driver.current_url).to include('gradebook/history')
    end

    it 'shows all drop down options', priority: '2', test_id: 615702 do
      SRGB.visit(@course.id)
      arrange_assignments.click
      expect(arrange_assignments).to include_text("By Assignment Group and Position\nAlphabetically\nBy Due Date")
    end

    it 'keeps the assignment arrangement choice between reloads' do
      SRGB.visit(@course.id)

      %w/assignment_group alpha due_date/.each do |assignment_order|
        SRGB.sort_assignments_by(assignment_order)
        refresh_page

        expect(SRGB.assignment_sort_order).to eq(assignment_order)
      end
    end

    it "should focus on accessible elements when setting default grades", priority: '1', test_id: 209991 do
      SRGB.visit(@course.id)
      SRGB.select_assignment(@second_assignment)

      # When the modal opens the close button should have focus
      SRGB.default_grade.click
      focused_classes = active_element[:class].split
      expect(focused_classes).to include("ui-dialog-titlebar-close")

      # When the modal closes by setting a grade
      # the "set default grade" button should have focus
      button_type_submit.click
      accept_alert
      check_element_has_focus(SRGB.default_grade)

      # When the modal closes by the close button
      # the "set default grade" button should have focus
      driver.action.send_keys(:enter).perform # to open the modal
      driver.action.send_keys(:enter).perform # to close the modal
      check_element_has_focus(SRGB.default_grade)
    end

    describe "Download Submissions Button" do
      let!(:change_first_assignment_to_media_recording) do
        @first_assignment.submission_types = "media_recording"
        @first_assignment.save
      end

      let!(:change_third_assignment_to_include_media_and_have_submission) do
        @third_assignment.submission_types = "online_text_entry,media_recording"
        @third_assignment.save

        submission = @third_assignment.submit_homework(@student_1, body: "Can you click?")
        submission.save!
      end

      # The Download Submission button should be displayed for online_upload,
      # online_text_entry, online_url, and online_quiz assignments. It should
      # not be displayed for any other types.
      it "is displayed for online assignments" do
        SRGB.visit(@course.id)

        click_option '#assignment_select', 'second assignment'

        expect(f("#submissions_download_button")).to be_present
      end

      it "is not displayed for assignments which are not submitted online" do
        SRGB.visit(@course.id)

        click_option '#assignment_select', @assignment.name

        expect(f("#content")).not_to contain_css("#submissions_download_button")
      end

      it "is displayed for assignments which allow both online and non-online submittion" do
        SRGB.visit(@course.id)
        click_option '#assignment_select', 'assignment three'

        expect(f("#submissions_download_button")).to be_present
      end
    end
  end

  context "curving grades" do
    it "curves grades", priority: '1',test_id: 615690 do
      basic_point_setup 3

      grades = [12,10,11]
      (0..2).each {|num| @curve_assignment.grade_student(@students[num], grade: grades[num], grader: @teacher)}

      SRGB.visit(@course.id)
      SRGB.select_assignment(@curve_assignment)

      SRGB.curve_grade_button.click
      assignment_name = @curve_assignment.name
      # verify that the modal pops up
      curve_form = GradingCurvePage.new
      expect(curve_form.grading_curve_dialog_title.text).to eq "Curve Grade for #{assignment_name}"

      curve_value = "10"
      curve_form.edit_grade_curve(curve_value)
      curve_form.curve_grade_submit
      accept_alert

      assignment_score = SRGB.assignment_scores.text.split(' ')
      # assignment avg score, high score, low score
      scores_as_string = ['13','20','8']
      (0..2).each {|num| expect(assignment_score[num+1]).to eq(scores_as_string[num])}
    end
  end

end
