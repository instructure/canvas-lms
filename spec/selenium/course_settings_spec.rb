require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course settings" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in :limit_privileges_to_course_section => false
    @account = @course.account
  end

  it "should show unused tabs to teachers" do
    get "/courses/#{@course.id}/settings"
    wait_for_ajaximations
    expect(ff("#section-tabs .section.section-tab-hidden").count).to be > 0
  end

  describe "course details" do
    def test_select_standard_for(context)
      grading_standard_for context
      get "/courses/#{@course.id}/settings"

      f('.grading_standard_checkbox').click unless is_checked('.grading_standard_checkbox')
      f('.edit_letter_grades_link').click
      f('.find_grading_standard_link').click
      wait_for_ajaximations

      fj('.grading_standard_select:visible a').click
      fj('button.select_grading_standard_link:visible').click
      f('.done_button').click
      submit_form('#course_form')
      wait_for_ajaximations

      @course.reload
      expect(@course.grading_standard).to eq(@standard)
    end

    it 'should show the correct course status when published' do
      get "/courses/#{@course.id}/settings"
      expect(f('#course-status').text).to eq 'Course is Published'
    end

    it 'should show the correct course status when unpublished' do
      @course.workflow_state = 'claimed'
      @course.save!
      get "/courses/#{@course.id}/settings"
      expect(f('#course-status').text).to eq 'Course is Unpublished'
    end

    it "should show the correct status with a tooltip when published and graded submissions" do
      course_with_student_submissions({submission_points: true})
      get "/courses/#{@course.id}/settings"
      course_status = f('#course-status')
      expect(course_status.text).to eq 'Course is Published'
      expect(course_status).to have_attribute('title', 'You cannot unpublish this course if there are graded student submissions')
    end

    it "should allow selection of existing course grading standard" do
      test_select_standard_for @course
    end

    it "should allow selection of existing account grading standard" do
      test_select_standard_for @course.root_account
    end

    it "should toggle more options correctly" do
      more_options_text = 'more options'
      fewer_options_text = 'fewer options'
      get "/courses/#{@course.id}/settings"

      more_options_link = f('.course_form_more_options_link')
      expect(more_options_link.text).to eq more_options_text
      more_options_link.click
      extra_options = f('.course_form_more_options')
      expect(extra_options).to be_displayed
      expect(more_options_link.text).to eq fewer_options_text
      more_options_link.click
      wait_for_ajaximations
      expect(extra_options).not_to be_displayed
      expect(more_options_link.text).to eq more_options_text
    end

    it "should show the self enrollment code and url once enabled" do
      a = Account.default
      a.courses << @course
      a.settings[:self_enrollment] = 'manually_created'
      a.save!
      get "/courses/#{@course.id}/settings"
      f('.course_form_more_options_link').click
      wait_for_ajaximations
      f('#course_self_enrollment').click
      wait_for_ajaximations
      submit_form('#course_form')
      wait_for_ajaximations

      code = @course.reload.self_enrollment_code
      expect(code).not_to be_nil
      message = f('.self_enrollment_message')
      expect(message.text).to include(code)
      expect(message.text).not_to include('self_enrollment_code')
    end
  end

  describe "course items" do

    it "should change course details" do
      course_name = 'new course name'
      course_code = 'new course-101'
      locale_text = 'English (US)'
      time_zone_value = 'Central Time (US & Canada)'

      get "/courses/#{@course.id}/settings"

      course_form = f('#course_form')
      name_input = course_form.find_element(:id, 'course_name')
      replace_content(name_input, course_name)
      code_input = course_form.find_element(:id, 'course_course_code')
      replace_content(code_input, course_code)
      click_option('#course_locale', locale_text)
      click_option('#course_time_zone', time_zone_value, :value)
      f('.course_form_more_options_link').click
      wait_for_ajaximations
      expect(f('.course_form_more_options')).to be_displayed
      submit_form(course_form)
      wait_for_ajaximations

      @course.reload
      expect(@course.name).to eq course_name
      expect(@course.course_code).to eq course_code
      expect(@course.locale).to eq 'en'
      expect(@course.time_zone.name).to eq time_zone_value
    end

    it "should add a section" do
      section_name = 'new section'
      get "/courses/#{@course.id}/settings#tab-sections"

      section_input = nil
      keep_trying_until do
        section_input = f('#course_section_name')
        expect(section_input).to be_displayed
      end
      replace_content(section_input, section_name)
      submit_form('#add_section_form')
      wait_for_ajaximations
      new_section = ff('#sections > .section')[1]
      expect(new_section).to include_text(section_name)
    end

    it "should delete a section" do
      add_section('Delete Section')
      get "/courses/#{@course.id}/settings#tab-sections"

      keep_trying_until do
        body = f('body')
        expect(body).to include_text('Delete Section')
      end

      f('.delete_section_link').click
      keep_trying_until do
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        true
      end
      wait_for_ajaximations
      expect(ff('#sections > .section').count).to eq 1
    end

    it "should edit a section" do
      edit_text = 'Section Edit Text'
      add_section('Edit Section')
      get "/courses/#{@course.id}/settings#tab-sections"

      keep_trying_until do
        body = f('body')
        expect(body).to include_text('Edit Section')
      end

      f('.edit_section_link').click
      section_input = f('#course_section_name_edit')
      keep_trying_until { expect(section_input).to be_displayed }
      replace_content(section_input, edit_text)
      section_input.send_keys(:return)
      wait_for_ajaximations
      expect(ff('#sections > .section')[0]).to include_text(edit_text)
    end

    it "should move a nav item to disabled" do
      skip('fragile')
      get "/courses/#{@course.id}/settings#tab-navigation"

      keep_trying_until do
        body = f('body')
        expect(body).to include_text('Drag and drop items to reorder them in the course navigation.')
      end
      disabled_div = f('#nav_disabled_list')
      announcements_nav = f('#nav_edit_tab_id_14')
      driver.action.click_and_hold(announcements_nav).
          move_to(disabled_div).
          release(disabled_div).
          perform
      keep_trying_until { expect(f('#nav_disabled_list')).to include_text(announcements_nav.text) }
    end
  end

  context "right sidebar" do
    it "should allow entering student view from the right sidebar" do
      @fake_student = @course.student_view_student
      get "/courses/#{@course.id}/settings"
      f(".student_view_button").click
      wait_for_ajaximations
      expect(f("#identity .user_name")).to include_text @fake_student.name
    end

    it "should allow leaving student view" do
      enter_student_view
      stop_link = f("#masquerade_bar .leave_student_view")
      expect(stop_link).to include_text "Leave Student View"
      stop_link.click
      wait_for_ajaximations
      expect(f("#identity .user_name")).to include_text @teacher.name
    end

    it "should allow resetting student view" do
      @fake_student_before = @course.student_view_student
      enter_student_view
      reset_link = f("#masquerade_bar .reset_test_student")
      expect(reset_link).to include_text "Reset Student"
      reset_link.click
      wait_for_ajaximations
      @fake_student_after = @course.student_view_student
      expect(@fake_student_before.id).not_to eq @fake_student_after.id
    end

    it "should not include student view student in the statistics count" do
      @fake_student = @course.student_view_student
      get "/courses/#{@course.id}/settings"
      expect(fj('.summary tr:nth(0)').text).to match /Students:\s*None/
    end

    it "should show the count of custom role enrollments" do
      teacher_role = custom_teacher_role("teach")
      student_role = custom_student_role("weirdo")
      custom_ta_role("taaaa")
      course_with_student(:course => @course, :role => student_role)
      course_with_teacher(:course => @course, :role => teacher_role)
      get "/courses/#{@course.id}/settings"
      expect(fj('.summary tr:nth(1)').text).to match /weirdo:\s*1/
      expect(fj('.summary tr:nth(3)').text).to match /teach:\s*1/
      expect(fj('.summary tr:nth(5)').text).to match /taaaa:\s*None/
    end
  end
end
