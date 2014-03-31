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
    ff("#section-tabs .section.section-tab-hidden").count.should > 0
  end

  describe "course details" do
    def test_select_standard_for(context)
      grading_standard_for context
      get "/courses/#{@course.id}/settings"

      f('.edit_course_link').click
      wait_for_ajaximations
      f('.grading_standard_checkbox').click unless is_checked('.grading_standard_checkbox')
      f('.edit_letter_grades_link').click
      f('.find_grading_standard_link').click
      wait_for_ajaximations

      fj('.grading_standard_select:visible a').click
      fj('button.select_grading_standard_link:visible').click
      f('.done_button').click
      submit_form('#course_form')
      wait_for_ajaximations

      f('.grading_scheme_set').should include_text @standard.title
    end

    it "should allow selection of existing course grading standard" do
      test_select_standard_for @course
    end

    it "should allow selection of existing account grading standard" do
      test_select_standard_for @course.root_account
    end

    it "should toggle more options correclty" do
      more_options_text = 'more options'
      fewer_options_text = 'fewer options'
      get "/courses/#{@course.id}/settings"

      f('.edit_course_link').click
      more_options_link = f('.course_form_more_options_link')
      more_options_link.text.should == more_options_text
      more_options_link.click
      extra_options = f('.course_form_more_options')
      extra_options.should be_displayed
      more_options_link.text.should == fewer_options_text
      more_options_link.click
      wait_for_ajaximations
      extra_options.should_not be_displayed
      more_options_link.text.should == more_options_text
    end

    it "should show the self enrollment code and url once enabled" do
      a = Account.default
      a.courses << @course
      a.settings[:self_enrollment] = 'manually_created'
      a.save!
      get "/courses/#{@course.id}/settings"
      f('.edit_course_link').click
      wait_for_ajaximations
      f('.course_form_more_options_link').click
      wait_for_ajaximations
      f('#course_self_enrollment').click
      wait_for_ajaximations
      submit_form('#course_form')
      wait_for_ajaximations

      code = @course.reload.self_enrollment_code
      code.should_not be_nil
      message = f('.self_enrollment_message')
      message.text.should include(code)
      message.text.should_not include('self_enrollment_code')
    end
  end

  describe "course items" do

    it "should change course details" do
      course_name = 'new course name'
      course_code = 'new course-101'
      locale_text = 'English'

      get "/courses/#{@course.id}/settings"

      f('.edit_course_link').click
      course_form = f('#course_form')
      name_input = course_form.find_element(:id, 'course_name')
      replace_content(name_input, course_name)
      code_input = course_form.find_element(:id, 'course_course_code')
      replace_content(code_input, course_code)
      click_option('#course_locale', locale_text)
      f('.course_form_more_options_link').click
      wait_for_ajaximations
      f('.course_form_more_options').should be_displayed
      submit_form(course_form)
      wait_for_ajaximations

      f('.course_info').should include_text(course_name)
      f('.course_code').should include_text(course_code)
      f('span.locale').should include_text(locale_text)
    end

    it "should add a section" do
      section_name = 'new section'
      get "/courses/#{@course.id}/settings#tab-sections"

      section_input = f('#course_section_name')
      keep_trying_until { section_input.should be_displayed }
      replace_content(section_input, section_name)
      submit_form('#add_section_form')
      wait_for_ajaximations
      new_section = ff('#sections > .section')[1]
      new_section.should include_text(section_name)
    end

    it "should delete a section" do
      add_section('Delete Section')
      get "/courses/#{@course.id}/settings#tab-sections"

      f('.delete_section_link').click
      keep_trying_until do
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        true
      end
      wait_for_ajaximations
      ff('#sections > .section').count.should == 1
    end

    it "should edit a section" do
      edit_text = 'Section Edit Text'
      add_section('Edit Section')
      get "/courses/#{@course.id}/settings#tab-sections"

      f('.edit_section_link').click
      section_input = f('#course_section_name')
      keep_trying_until { section_input.should be_displayed }
      replace_content(section_input, edit_text)
      section_input.send_keys(:return)
      wait_for_ajaximations
      ff('#sections > .section')[0].should include_text(edit_text)
    end

    it "should move a nav item to disabled" do
      get "/courses/#{@course.id}/settings#tab-navigation"
      disabled_div = f('#nav_disabled_list')
      announcements_nav = f('#nav_edit_tab_id_14')
      driver.action.click_and_hold(announcements_nav).
          move_to(disabled_div).
          release(disabled_div).
          perform
      f('#nav_disabled_list').should include_text(announcements_nav.text)
    end
  end

  context "right sidebar" do
    it "should allow entering student view from the right sidebar", :non_parallel do
      @fake_student = @course.student_view_student
      get "/courses/#{@course.id}/settings"
      f(".student_view_button").click
      wait_for_ajaximations
      f("#identity .user_name").should include_text @fake_student.name
    end

    it "should allow leaving student view" do
      enter_student_view
      stop_link = f("#masquerade_bar .leave_student_view")
      stop_link.should include_text "Leave Student View"
      stop_link.click
      wait_for_ajaximations
      f("#identity .user_name").should include_text @teacher.name
    end

    it "should allow resetting student view" do
      @fake_student_before = @course.student_view_student
      enter_student_view
      reset_link = f("#masquerade_bar .reset_test_student")
      reset_link.should include_text "Reset Student"
      reset_link.click
      wait_for_ajaximations
      @fake_student_after = @course.student_view_student
      @fake_student_before.id.should_not == @fake_student_after.id
    end

    it "should not include student view student in the statistics count" do
      @fake_student = @course.student_view_student
      get "/courses/#{@course.id}/settings"
      fj('.summary tr:nth(0)').text.should match /Students:\s*None/
    end

    it "should show the count of custom role enrollments" do
      custom_teacher_role("teach")
      custom_student_role("weirdo")
      custom_ta_role("taaaa")
      course_with_student(:course => @course, :role_name => "weirdo")
      course_with_teacher(:course => @course, :role_name => "teach")
      get "/courses/#{@course.id}/settings"
      fj('.summary tr:nth(1)').text.should match /weirdo:\s*1/
      fj('.summary tr:nth(3)').text.should match /teach:\s*1/
      fj('.summary tr:nth(5)').text.should match /taaaa:\s*None/
    end
  end
end
