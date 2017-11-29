#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course settings" do
  include_context "in-process server selenium tests"

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
      wait_for_new_page_load(submit_form('#course_form'))

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
      wait_for_new_page_load { submit_form('#course_form') }

      code = @course.reload.self_enrollment_code
      expect(code).not_to be_nil
      # this element _can_ still be on the page if the post hasn't finished yet,
      # so make sure it's been populated before continuing
      wait = Selenium::WebDriver::Wait.new(timeout: 5)
      wait.until do
        el = f('.self_enrollment_message')
        el.present? &&
        el.text != nil &&
        el.text != ""
      end
      message = f('.self_enrollment_message')
      expect(message).to include_text(code)
      expect(message).not_to include_text('self_enrollment_code')
    end

    it "should enable announcement limit if show announcements enabled" do
      get "/courses/#{@course.id}/settings"

      more_options_link = f('.course_form_more_options_link')
      more_options_link.click
      wait_for_ajaximations

      # Show announcements and limit setting elements
      show_announcements_on_home_page = f('#course_show_announcements_on_home_page')
      home_page_announcement_limit = f('#course_home_page_announcement_limit')

      expect(is_checked(show_announcements_on_home_page)).not_to be_truthy
      expect(home_page_announcement_limit).to be_disabled

      show_announcements_on_home_page.click
      expect(home_page_announcement_limit).not_to be_disabled
    end
  end

  describe "course items" do

    def admin_cog(id)
      f(id).find_element(:css, '.admin-links').displayed?
      rescue Selenium::WebDriver::Error::NoSuchElementError
        false
    end

    it 'should not show cog menu for disabling or moving on home nav item' do
      get "/courses/#{@course.id}/settings#tab-navigation"
      expect(admin_cog('#nav_edit_tab_id_0')).to be_falsey
    end

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
      wait_for_new_page_load { submit_form(course_form) }

      @course.reload
      expect(@course.name).to eq course_name
      expect(@course.course_code).to eq course_code
      expect(@course.locale).to eq 'en'
      expect(@course.time_zone.name).to eq time_zone_value
    end

    it "should only allow less resrictive options in Customize visibility" do
       get "/courses/#{@course.id}/settings"
       click_option('#course_course_visibility', 'institution', :value)
       f('#course_custom_course_visibility').click
       expect(ff("select[name*='course[syllabus_visibility_option]']")[0].text).to eq "Institution\nPublic"
       click_option('#course_course_visibility', 'course', :value)
       expect(ff("select[name*='course[syllabus_visibility_option]']")[0].text).to eq "Course\nInstitution\nPublic"
    end

    it "should disable from Course Navigation tab", priority: "1", test_id: 112172 do
      get "/courses/#{@course.id}/settings#tab-navigation"
      ff(".al-trigger")[0].click
      ff(".icon-x")[0].click
      wait_for_ajaximations
      f('#nav_form > p:nth-of-type(2) > button.btn.btn-primary').click
      wait_for_ajaximations
      f('.student_view_button').click
      wait_for_ajaximations
      expect(f("#content")).not_to contain_link("Home")
    end

    describe "move dialog" do
      it "should return focus to cog menu button when disabling an item" do
        get "/courses/#{@course.id}/settings#tab-navigation"
        cog_menu_button = ff(".al-trigger")[2]
        cog_menu_button.click                 # open the menu
        ff(".disable_nav_item_link")[2].click    # click "Disable"
        check_element_has_focus(cog_menu_button)
      end
    end

    it "should add a section" do
      section_name = 'new section'
      get "/courses/#{@course.id}/settings#tab-sections"

      section_input = nil
      section_input = f('#course_section_name')
      expect(section_input).to be_displayed
      replace_content(section_input, section_name)
      submit_form('#add_section_form')
      wait_for_ajaximations
      new_section = ff('#sections > .section')[1]
      expect(new_section).to include_text(section_name)
    end

    it "should delete a section" do
      add_section('Delete Section')
      get "/courses/#{@course.id}/settings#tab-sections"

      body = f('body')
      expect(body).to include_text('Delete Section')

      f('.delete_section_link').click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(ff('#sections > .section').count).to eq 1
    end

    it "should edit a section" do
      edit_text = 'Section Edit Text'
      add_section('Edit Section')
      get "/courses/#{@course.id}/settings#tab-sections"

      body = f('body')
      expect(body).to include_text('Edit Section')

      f('.edit_section_link').click
      section_input = f('#course_section_name_edit')
      expect(section_input).to be_displayed
      replace_content(section_input, edit_text)
      section_input.send_keys(:return)
      wait_for_ajaximations
      expect(ff('#sections > .section')[0]).to include_text(edit_text)
    end

    # TODO reimplement per CNVS-29605, but make sure we're testing at the right level
    it "should move a nav item to disabled"
  end

  context "right sidebar" do
    it "should allow entering student view from the right sidebar" do
      @fake_student = @course.student_view_student
      get "/courses/#{@course.id}/settings"
      f(".student_view_button").click
      expect(displayed_username).to include(@fake_student.name)
    end

    it "should allow leaving student view" do
      enter_student_view
      stop_link = f("#masquerade_bar .leave_student_view")
      expect(stop_link).to include_text "Leave Student View"
      stop_link.click
      expect(displayed_username).to eq(@teacher.name)
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
      student_role.deactivate!
      course_with_teacher(:course => @course, :role => teacher_role)
      get "/courses/#{@course.id}/settings"
      expect(fj('.summary tr:nth(1)').text).to match /weirdo \(inactive\):\s*1/
      expect(fj('.summary tr:nth(3)').text).to match /teach:\s*1/
      expect(fj('.summary tr:nth(5)').text).to match /taaaa:\s*None/
    end
  end

  it "should disable inherited settings if locked by the account" do
    @account.settings[:restrict_student_future_view] = {:locked => true, :value => true}
    @account.save!

    get "/courses/#{@course.id}/settings"

    expect(f('#course_restrict_student_past_view')).not_to be_disabled
    expect(f('#course_restrict_student_future_view')).to be_disabled

    expect(is_checked('#course_restrict_student_future_view')).to be_truthy
  end

  it "should disable editing settings if :manage rights are not granted" do
    user_factory(active_all: true)
    user_session(@user)
    role = custom_account_role('role', :account => @account)
    @account.role_overrides.create!(:permission => 'read_course_content', :role => role, :enabled => true)
    @account.role_overrides.create!(:permission => 'manage_content', :role => role, :enabled => false)
    @course.account.account_users.create!(:user => @user, :role => role)

    get "/courses/#{@course.id}/settings"

    ffj("#tab-details input:visible").each do |input|
      expect(input).to be_disabled
    end
    expect(f("#content")).not_to contain_css(".course_form button[type='submit']")
  end

  it "should let a sub-account admin edit enrollment term" do
    term = Account.default.enrollment_terms.create!(:name => "some term")
    sub_a = Account.default.sub_accounts.create!
    account_admin_user(:active_all => true, :account => sub_a)
    user_session(@admin)

    @course = sub_a.courses.create!
    get "/courses/#{@course.id}/settings"

    click_option('#course_enrollment_term_id', term.name)

    submit_form('#course_form')

    expect(@course.reload.enrollment_term).to eq term
  end

  context "link validator" do
    it "should validate all the links" do
      allow_any_instance_of(CourseLinkValidator).to receive(:reachable_url?).and_return(false) # don't actually ping the links for the specs

      course_with_teacher_logged_in
      attachment_model

      bad_url = "http://www.notarealsitebutitdoesntmattercauseimstubbingitanwyay.com"
      bad_url2 = "/courses/#{@course.id}/file_contents/baaaad"
      html = %{
      <a href="#{bad_url}">Bad absolute link</a>
      <img src="#{bad_url2}">Bad file link</a>
      <img src="/courses/#{@course.id}/file_contents/#{CGI.escape(@attachment.full_display_path)}">Ok file link</a>
      <a href="/courses/#{@course.id}/quizzes">Ok other link</a>
    }

      @course.syllabus_body = html
      @course.save!

      bank = @course.assessment_question_banks.create!(:title => 'bank')
      aq = bank.assessment_questions.create!(:question_data => {'question_name' => 'test question',
        'question_text' => html, 'answers' => [{'id' => 1}, {'id' => 2}]})

      assmnt = @course.assignments.create!(:title => 'assignment', :description => html)
      event = @course.calendar_events.create!(:title => "event", :description => html)
      topic = @course.discussion_topics.create!(:title => "discussion title", :message => html)
      mod = @course.context_modules.create!(:name => "some module")
      tag = mod.add_item(:type => 'external_url', :url => bad_url, :title => 'pls view')
      page = @course.wiki_pages.create!(:title => "wiki", :body => html)
      quiz = @course.quizzes.create!(:title => 'quiz1', :description => html)

      qq = quiz.quiz_questions.create!(:question_data => aq.question_data.merge('question_name' => 'other test question'))

      get "/courses/#{@course.id}/settings"

      expect_new_page_load{ f(".validator_link").click }

      f('#link_validator_wrapper button').click
      wait_for_ajaximations
      run_jobs

      wait_for_ajaximations
      expect(f("#all-results")).to be_displayed

      expect(f("#all-results .alert")).to include_text("Found 17 unresponsive links")

      result_links = ff("#all-results .result a")
      expect(result_links.map{|link| link.text.strip}).to match_array([
        'Course Syllabus',
        aq.question_data[:question_name],
        qq.question_data[:question_name],
        assmnt.title,
        event.title,
        topic.title,
        tag.title,
        quiz.title,
        page.title
      ])
    end

    it "should be able to filter links to unpublished content" do
      course_with_teacher_logged_in

      active = @course.assignments.create!(:title => "blah")
      unpublished = @course.assignments.create!(:title => "blah")
      unpublished.unpublish!
      deleted = @course.assignments.create!(:title => "blah")
      deleted.destroy

      active_link = "/courses/#{@course.id}/assignments/#{active.id}"
      unpublished_link = "/courses/#{@course.id}/assignments/#{unpublished.id}"
      deleted_link = "/courses/#{@course.id}/assignments/#{deleted.id}"

      @course.syllabus_body = %{
        <a href='#{active_link}'>link</a>
        <a href='#{unpublished_link}'>link</a>
        <a href='#{deleted_link}'>link</a>
      }
      @course.save!
      page = @course.wiki_pages.create!(:title => "wikiii", :body => %{<a href='#{unpublished_link}'>link</a>})

      get "/courses/#{@course.id}/link_validator"
      wait_for_ajaximations
      move_to_click('#link_validator_wrapper button')
      wait_for_ajaximations
      run_jobs

      wait_for_ajaximations
      expect(f("#all-results")).to be_displayed

      expect(f("#all-results .alert")).to include_text("Found 3 unresponsive links")
      syllabus_result = ff('#all-results .result').detect{|r| r.text.include?("Course Syllabus")}
      expect(syllabus_result).to include_text(unpublished_link)
      expect(syllabus_result).to include_text(deleted_link)
      page_result = ff('#all-results .result').detect{|r| r.text.include?(page.title)}
      expect(page_result).to include_text(unpublished_link)

      # hide the unpublished results
      move_to_click('label[for=show_unpublished]')
      wait_for_ajaximations

      expect(f("#all-results .alert")).to include_text("Found 1 unresponsive link")
      expect(ff("#all-results .result a").count).to eq 1
      result = f("#all-results .result")
      expect(result).to include_text("Course Syllabus")
      expect(result).to include_text(deleted_link)

      # show them again
      move_to_click('label[for=show_unpublished]')

      expect(f("#all-results .alert")).to include_text("Found 3 unresponsive links")
      page_result = ff('#all-results .result').detect{|r| r.text.include?(page.title)}
      expect(page_result).to include_text(unpublished_link)
    end
  end
end
