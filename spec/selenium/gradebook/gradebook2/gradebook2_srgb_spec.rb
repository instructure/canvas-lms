require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/gradebook2_srgb_common'

describe "Screenreader Gradebook" do
  include_context 'in-process server selenium tests'
  include_context 'gradebook_components'
  include_context 'srgb_components'
  include_context 'reusable_course'
  include Gradebook2Common
  include Gradebook2SRGBCommon

  let(:srgb) {"/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"}

  it 'can select a student', priority: "1", test_id: 163994 do
    init_course_with_students 2
    @course.assignment_groups.create! name: 'Group 1'
    @course.assignment_groups.create! name: 'Group 2'
    a1 = @course.assignments.create!(
      title: 'Test 1',
      points_possible: 20,
      assignment_group: @course.assignment_groups[0]
    )
    a2 = @course.assignments.create!(
      title: 'Test 2',
      points_possible: 20,
      assignment_group: @course.assignment_groups[1]
    )

    grades = ['15', '12', '11', '3']

    a1.grade_student @students[0], grade: grades[0]
    a1.grade_student @students[1], grade: grades[1]
    a2.grade_student @students[0], grade: grades[2]
    a2.grade_student @students[1], grade: grades[3]

    get srgb
    wait_for_ajaximations

    expect(get_options('#student_select').map(&:text)).to eq ['No Student Selected', @students[0].name, @students[1].name]
    click_option '#student_select', @students[0].name
    expect(ff('#student_information .assignment-group-grade .points').map(&:text)).to eq ["(#{grades[0]} / 20)", "(#{grades[2]} / 20)"]
    click_option '#student_select', @students[1].name
    expect(ff('#student_information .assignment-group-grade .points').map(&:text)).to eq ["(#{grades[1]} / 20)", "(#{grades[3]} / 20)"]
  end

  it 'can select a student using buttons', priority: "1", test_id: 163997 do
    init_course_with_students 3
    get srgb

    before = f('.student_navigation button.previous_object')
    after = f('.student_navigation button.next_object')

    # first student
    expect(before.attribute 'disabled').to be_truthy
    after.click
    expect(f('#student_information .student_selection').text).to eq @students[0].name

    # second student
    after.click
    expect(f('#student_information .student_selection').text).to eq @students[1].name

    # third student
    after.click
    expect(after.attribute 'disabled').to be_truthy
    expect(f('#student_information .student_selection').text).to eq @students[2].name
    expect(before).to eq driver.switch_to.active_element

    # click twice to go back to first student
    before.click
    before.click
    expect(f('#student_information .student_selection').text).to eq @students[0].name
    expect(after).to eq driver.switch_to.active_element
  end

  it 'can select an assignment', priority: "1", test_id: 163998 do
    a1 = basic_setup
    a2 = @course.assignments.create!(
      title: 'Test 2',
      points_possible: 20,
    )

    a1.grade_student @students[0], grade: 14
    get srgb

    expect(get_options('#assignment_select').map(&:text)).to eq ['No Assignment Selected', a1.name, a2.name]
    click_option '#assignment_select', a1.name
    expect(f('#assignment_information .assignment_selection').text).to eq a1.name
    expect(f('#assignment_information').text).to include 'Online text entry'
  end

  it 'displays/removes warning message for resubmitted assignments', priority: "1", test_id: 164000 do
    skip "Skipped because this spec fails if not run in foreground\n"\
      "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
    assignment = basic_setup
    user_session @students[0]
    assignment.submit_homework @students[0], submission_type: 'online_text_entry', body: 'Hello!'

    user_session @teacher
    assignment.grade_student @students[0], grade: 12

    user_session @students[0]
    assignment.submit_homework @students[0], submission_type: 'online_text_entry', body: 'Hello again!'

    user_session @teacher
    get srgb
    click_option '#assignment_select', assignment.name
    click_option '#student_select', @students[0].name
    expect(f('p.resubmitted')).to be_displayed

    replace_content f('#student_and_assignment_grade'), "15\t"
    wait_for_ajaximations
    expect(f("#content")).not_to contain_css('p.resubmitted')
  end

  it 'grades match default gradebook grades', priority: "1", test_id: 163994 do
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

    get srgb
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', a1.name
    expect(f('#student_and_assignment_grade')).to have_value grades[0]
    expect(f('#student_information .total-grade').text).to eq "75% (#{grades[0]} / 20 points)"

    click_option '#assignment_select', a2.name
    f('#student_and_assignment_grade').clear
    f('#student_and_assignment_grade').send_keys grades[1], :return
    get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=2"
    expect(f('.canvas_1 .slick-row .slick-cell:nth-of-type(2)').text).to eq grades[1]
  end

  it 'can mute assignments', priority: "1", test_id: 164001 do
    assignment = basic_setup
    get srgb

    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    f('#assignment_muted_check').click
    wait_for_ajaximations
    fj('.ui-dialog:visible [data-action="mute"]').click
    wait_for_ajaximations

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    expect(f('.student_assignment.editable')).to have_attribute('data-muted', 'true')

    get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=2"
    expect(fj('.slick-header-columns .slick-header-column:eq(2) a')).to have_class 'muted'
  end

  it 'can unmute assignments', priority: "1", test_id: 288859 do
    assignment = basic_setup
    assignment.mute!

    get srgb
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    f('#assignment_muted_check').click
    wait_for_ajaximations
    fj('.ui-dialog:visible [data-action="unmute"]').click
    wait_for_ajaximations

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    expect(f('.student_assignment.editable')).to have_attribute('data-muted', 'false')

    get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=2"
    expect(fj('.slick-header-columns .slick-header-column:eq(2) a')).to_not have_class 'muted'
  end

  it 'can message students who... ', priority: "1", test_id: 164002 do
    basic_setup
    get srgb

    click_option '#assignment_select', 'Test 1'
    f('#message_students').click
    wait_for_ajaximations
    expect(f('#message_students_dialog')).to be_displayed

    f('#body').send_keys 'Hello!'
    fj('.ui-dialog:visible button.send_button').click
    wait_for_ajaximations
    expect(f('#message_students_dialog')).to_not be_displayed
  end

  it 'has total graded submission', priority: "1", test_id: 615686 do
    assignment = basic_setup 2

    assignment.grade_student @students[0], grade: 15
    assignment.grade_student @students[1], grade: 5
    get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=2"
    f('a.assignment_header_drop').click
    ff('.gradebook-header-menu a').find{|a| a.text == "Assignment Details"}.click

    data = [
      'Average Score: 10',
      'High Score: 15',
      'Low Score: 5',
      'Total Graded Submissions: 2 submissions'
    ]
    expect(f('#assignment-details-dialog-stats-table').text.split /\n/).to eq data

    get srgb
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    expect(f('#assignment_information p:nth-of-type(2)').text).to eq 'Graded submissions: 2'
    expect(ff('#assignment_information table td').map(&:text)).to eq ['20', '10', '15', '5']
  end

  context 'Group Weights' do
    before(:each) do
      enroll_teacher_and_students
      assignment_1
      assignment_5
      user_session(teacher)
      get "/courses/#{test_course.id}/gradebook/change_gradebook_version?version=srgb"
    end

    it 'should display the group weighting dialog with group weights disabled', priority: "1", test_id: 163995 do
      group_weights_button.click
      expect(f("#assignment_group_weights_dialog table[style='opacity: 0.5;']")).to be_truthy
    end

    it 'should correctly sync group weight settings between srgb and gb2', priority: "1", test_id: 588913 do
      turn_on_group_weights

      # go back to gb2 to verify settings stuck
      get "/courses/#{test_course.id}/gradebook/change_gradebook_version?version=2"
      gradebook_settings_cog.click
      group_weights_menu.click

      expect(f("#assignment_group_weights_dialog table[style='opacity: 1;']")).to be_truthy
    end
  end

  context "as a teacher" do
    before(:each) do
      gradebook_data_setup
    end

    it "switches to srgb", priority: "1", test_id: 615682 do
      get "/courses/#{@course.id}/gradebook"
      f("#change_gradebook_version_link_holder").click
      expect(f("#not_right_side")).to include_text("Gradebook: Individual View")
      refresh_page
      expect(f("#not_right_side")).to include_text("Gradebook: Individual View")
      f(".span12 a").click
      expect(f("#change_gradebook_version_link_holder")).to be_displayed
    end

    it "shows sections in drop-down", priority: "1", test_id: 615680 do
      sections=[]
      2.times do |i|
        sections << @course.course_sections.create!(:name => "other section #{i}")
      end

      get srgb

      ui_options = Selenium::WebDriver::Support::Select.new(f("#section_select")).options().map { |option| option.text}
      sections.each do |section|
        expect(ui_options.include? section[:name]).to be_truthy
      end
    end

    it "should focus on accessible elements when setting default grades", priority: "1", test_id: 209991 do
      get srgb
      select_assignment(@second_assignment)

      # When the modal opens the close button should have focus
      default_grade.click
      focused_classes = driver.execute_script('return document.activeElement.classList')
      expect(focused_classes).to include("ui-dialog-titlebar-close")

      # When the modal closes
      # by setting a grade the "set default grade" button should have focus
      f(".button_type_submit").click
      accept_alert
      check_element_has_focus(f "#set_default_grade")

      # by the close button the "set default grade" button should have focus
      f("#set_default_grade").click
      fj('.ui-icon-closethick:visible').click
      check_element_has_focus(f "#set_default_grade")
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

      let!(:get_screenreader_gradebook) do
        get srgb
      end
      # The Download Submission button should be displayed for online_upload,
      # online_text_entry, online_url, and online_quiz assignments. It should
      # not be displayed for any other types.
      it "is displayed for online assignments" do
        click_option '#assignment_select', 'second assignment'

        expect(f("#submissions_download_button")).to be_present
      end

      it "is not displayed for assignments which are not submitted online" do
        click_option '#assignment_select', @assignment.name

        expect(f("#content")).not_to contain_css("#submissions_download_button")
      end

      it "is displayed for assignments which allow both online and non-online submittion" do
        click_option '#assignment_select', 'assignment three'

        expect(f("#submissions_download_button")).to be_present
      end
    end
  end
end
