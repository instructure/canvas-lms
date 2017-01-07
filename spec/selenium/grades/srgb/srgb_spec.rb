require_relative '../../helpers/gradebook2_common'
require_relative '../page_objects/srgb_page'

describe "Screenreader Gradebook" do
  include_context 'in-process server selenium tests'
  include_context 'gradebook_components'
  include_context 'reusable_course'
  include Gradebook2Common

  let(:srgb_page) { SRGB }

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

  def basic_setup(num=1)
    init_course_with_students num
    @course.assignments.create!(
      title: 'Test 1',
      submission_types: 'online_text_entry',
      points_possible: 20,
      grading_type: 'percent'
    )
  end

  def simple_setup(student_number = 2)
    init_course_with_students student_number
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
    srgb_page.visit(@course.id)
    wait_for_ajaximations

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
    srgb_page.visit(@course.id)

    # first student
    expect(srgb_page.previous_student.attribute 'disabled').to be_truthy
    srgb_page.next_student.click
    expect(f('#student_information .student_selection').text).to eq @students[0].name

    # second student
    srgb_page.next_student.click
    expect(f('#student_information .student_selection').text).to eq @students[1].name

    # third student
    srgb_page.next_student.click
    expect(srgb_page.next_student.attribute 'disabled').to be_truthy
    expect(f('#student_information .student_selection').text).to eq @students[2].name
    expect(srgb_page.previous_student).to eq driver.switch_to.active_element

    # click twice to go back to first student
    srgb_page.previous_student.click
    srgb_page.previous_student.click
    expect(f('#student_information .student_selection').text).to eq @students[0].name
    expect(srgb_page.next_student).to eq driver.switch_to.active_element
  end

  it 'can select an assignment using buttons', priority: '2', test_id: 615707 do
    simple_setup
    srgb_page.visit(@course.id)
    srgb_page.select_student(@students[0])
    srgb_page.select_assignment(@assign1)

    expect(srgb_page.previous_assignment.attribute 'disabled').to be_truthy
    expect(srgb_page.next_assignment.attribute 'disabled').not_to be_truthy

    srgb_page.next_assignment.click
    expect(srgb_page.previous_assignment.attribute 'disabled').not_to be_truthy
    expect(srgb_page.next_assignment.attribute 'disabled').to be_truthy

    srgb_page.previous_assignment.click
    expect(srgb_page.previous_assignment.attribute 'disabled').to be_truthy
  end

  it 'links to assignment show page', priority: '2', test_id: 615684 do
    simple_setup
    simple_grade
    @submission = @assign1.submit_homework(@students[0], body: 'student submission')
    srgb_page.visit(@course.id)
    srgb_page.select_student(@students[0])
    srgb_page.select_assignment(@assign1)
    srgb_page.assignment_link.click

    expect(driver.current_url).to include("/courses/#{@course.id}/assignments/#{@assign1.id}")
  end

  it 'sets default grade', priority: '2', test_id: 615689 do
    num_of_students = 2
    simple_setup(num_of_students)
    srgb_page.visit(@course.id)
    srgb_page.select_student(@students[0])
    srgb_page.select_assignment(@assign1)

    srgb_page.default_grade.click
    replace_content(grading_value, assign1_default_points)
    button_type_submit.click

    get default_gradebook
    grade = gradebook_column_array(gradebook_cell_css)
    expect(grade.count assign1_default_points.to_s).to eq(num_of_students)
  end

  it 'can select an assignment', priority: '1', test_id: 163998 do
    a1 = basic_setup
    a2 = @course.assignments.create!(
      title: 'Test 2',
      points_possible: 20,
    )

    a1.grade_student(@students[0], grade: 14, grader: @teacher)
    srgb_page.visit(@course.id)

    expect(get_options('#assignment_select').map(&:text)).to eq ['No Assignment Selected', a1.name, a2.name]
    click_option '#assignment_select', a1.name
    expect(f('#assignment_information .assignment_selection').text).to eq a1.name
    expect(f('#assignment_information').text).to include 'Online text entry'
  end

  it 'displays/removes warning message for resubmitted assignments', priority: '1', test_id: 164000 do
    skip "Skipped because this spec fails if not run in foreground\n"\
      "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
    assignment = basic_setup
    user_session @students[0]
    assignment.submit_homework @students[0], submission_type: 'online_text_entry', body: 'Hello!'

    user_session @teacher
    assignment.grade_student(@students[0], grade: 12, grader: @teacher)

    user_session @students[0]
    assignment.submit_homework @students[0], submission_type: 'online_text_entry', body: 'Hello again!'

    user_session @teacher
    srgb_page.visit(@course.id)
    click_option '#assignment_select', assignment.name
    click_option '#student_select', @students[0].name
    expect(f('p.resubmitted')).to be_displayed

    replace_content f('#student_and_assignment_grade'), "15\t"
    wait_for_ajaximations
    expect(f("#content")).not_to contain_css('p.resubmitted')
  end

  it 'grades match default gradebook grades', priority: '1', test_id: 163994 do
    skip "Skipped because this spec fails if not run in foreground\n"\
      "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
    a1 = basic_setup
    a2 = @course.assignments.create!(
      title: 'Test 2',
      points_possible: 20
    )

    grades = [15, 12]

    get "/courses/#{@course.id}/gradebook"
    f('.canvas_1 .slick-row .slick-cell').click
    f('.canvas_1 .slick-row .slick-cell .grade').send_keys grades[0], :return

    srgb_page.visit(@course.id)
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', a1.name
    expect(f('#student_and_assignment_grade')).to have_value grades[0]
    expect(f('#student_information .total-grade').text).to eq "75% (#{grades[0]} / 20 points)"

    click_option '#assignment_select', a2.name
    f('#student_and_assignment_grade').clear
    f('#student_and_assignment_grade').send_keys grades[1], :return
    get default_gradebook
    expect(f('.canvas_1 .slick-row .slick-cell:nth-of-type(2)').text).to eq grades[1]
  end

  it 'can mute assignments', priority: '1', test_id: 164001 do
    assignment = basic_setup
    srgb_page.visit(@course.id)

    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    f('#assignment_muted_check').click
    wait_for_ajaximations
    fj('.ui-dialog:visible [data-action="mute"]').click
    wait_for_ajaximations

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    expect(f('.student_assignment.editable')).to have_attribute('data-muted', 'true')

    get default_gradebook
    expect(fj('.slick-header-columns .slick-header-column:eq(2) a')).to have_class 'muted'
  end

  it 'can unmute assignments', priority: '1', test_id: 288859 do
    assignment = basic_setup
    assignment.mute!

    srgb_page.visit(@course.id)
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    f('#assignment_muted_check').click
    wait_for_ajaximations
    fj('.ui-dialog:visible [data-action="unmute"]').click
    wait_for_ajaximations

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    expect(f('.student_assignment.editable')).to have_attribute('data-muted', 'false')

    get default_gradebook
    expect(fj('.slick-header-columns .slick-header-column:eq(2) a')).not_to have_class 'muted'
  end

  it 'can message students who... ', priority: '1', test_id: 164002 do
    basic_setup
    srgb_page.visit(@course.id)

    click_option '#assignment_select', 'Test 1'
    f('#message_students').click
    wait_for_ajaximations
    expect(f('#message_students_dialog')).to be_displayed

    f('#body').send_keys('Hello!')
    driver.action.send_keys(:tab).perform
    driver.action.send_keys(:enter).perform
    wait_for_ajaximations
    expect(f('#message_students_dialog')).not_to be_displayed
  end

  it 'has total graded submission', priority: '1', test_id: 615686 do
    assignment = basic_setup 2

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

    srgb_page.visit(@course.id)
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    expect(f('#assignment_information p:nth-of-type(2)').text).to eq 'Graded submissions: 2'
    expect(ff('#assignment_information table td').map(&:text)).to eq ['20', '10', '15', '5']
  end

  context "as a teacher" do
    before(:each) do
      gradebook_data_setup
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

      srgb_page.visit(@course.id)

      ui_options = Selenium::WebDriver::Support::Select.new(f("#section_select")).options().map(&:text)
      sections.each do |section|
        expect(ui_options.include? section[:name]).to be_truthy
      end
    end

    it 'shows history', priority: '2', test_id: 615676 do
      srgb_page.visit(@course.id)

      view_grading_history.click
      expect(driver.page_source).to include('Gradebook History')
      expect(driver.current_url).to include('gradebook/history')
    end

    it 'shows all drop down options', priority: '2', test_id: 615702 do
      srgb_page.visit(@course.id)
      arrange_assignments.click
      expect(arrange_assignments.text).to eq("By Assignment Group and Position\nAlphabetically\nBy Due Date")
    end

    it "should focus on accessible elements when setting default grades", priority: '1', test_id: 209991 do
      srgb_page.visit(@course.id)
      srgb_page.select_assignment(@second_assignment)

      # When the modal opens the close button should have focus
      srgb_page.default_grade.click
      focused_classes = active_element[:class].split
      expect(focused_classes).to include("ui-dialog-titlebar-close")

      # When the modal closes by setting a grade
      # the "set default grade" button should have focus
      button_type_submit.click
      accept_alert
      check_element_has_focus(srgb_page.default_grade)

      # When the modal closes by the close button
      # the "set default grade" button should have focus
      driver.action.send_keys(:enter).perform # to open the modal
      driver.action.send_keys(:enter).perform # to close the modal
      check_element_has_focus(srgb_page.default_grade)
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
        srgb_page.visit(@course.id)

        click_option '#assignment_select', 'second assignment'

        expect(f("#submissions_download_button")).to be_present
      end

      it "is not displayed for assignments which are not submitted online" do
        srgb_page.visit(@course.id)

        click_option '#assignment_select', @assignment.name

        expect(f("#content")).not_to contain_css("#submissions_download_button")
      end

      it "is displayed for assignments which allow both online and non-online submittion" do
        srgb_page.visit(@course.id)
        click_option '#assignment_select', 'assignment three'

        expect(f("#submissions_download_button")).to be_present
      end
    end
  end
end
