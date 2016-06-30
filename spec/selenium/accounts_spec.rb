require File.expand_path(File.dirname(__FILE__) + '/common')

describe "account" do
  include_context "in-process server selenium tests"

  before(:each) do
    course_with_admin_logged_in
  end

  def verify_displayed_term_dates(term, dates)
    dates.each do |en_type, date|
      expect(term.find_element(:css, ".#{en_type}_dates .start_date .show_term").text).to match(/#{date[0]}/)
      expect(term.find_element(:css, ".#{en_type}_dates .end_date .show_term").text).to match(/#{date[1]}/)
    end
  end

  describe "course and term create/update" do

    it "should show Login and Email fields in add user dialog for delegated auth accounts" do
      get "/accounts/#{Account.default.id}/users"
      f(".add_user_link").click
      dialog = f("#add_user_dialog")
      expect(dialog.find_elements(:id, "pseudonym_path").length).to eq 0
      expect(dialog.find_element(:id, "pseudonym_unique_id")).to be_displayed

      Account.default.authentication_providers.create(:auth_type => 'cas')
      Account.default.authentication_providers.first.move_to_bottom
      get "/accounts/#{Account.default.id}/users"
      f(".add_user_link").click
      dialog = f("#add_user_dialog")
      expect(dialog.find_element(:id, "pseudonym_path")).to be_displayed
      expect(dialog.find_element(:id, "pseudonym_unique_id")).to be_displayed
    end

    it "should be able to create a new course" do
      get "/accounts/#{Account.default.id}"
      f('.add_course_link').click
      f('#add_course_form input[type=text]:first-child').send_keys('Test Course')
      f('#course_course_code').send_keys('TEST001')
      submit_dialog_form('#add_course_form')

      wait_for_ajaximations
      expect(f('#add_course_dialog')).not_to be_displayed
      assert_flash_notice_message(/Test Course successfully added/)
    end

    it "should be able to create a new course when no other courses exist" do
      Account.default.courses.each do |c|
        c.course_account_associations.scope.delete_all
        c.enrollments.each(&:destroy_permanently!)
        c.course_sections.scope.delete_all
        c.reload.destroy_permanently!
      end

      get "/accounts/#{Account.default.to_param}"
      f('.add_course_link').click
      expect(f('#add_course_form')).to be_displayed
    end

    it "should be able to add a term" do
      get "/accounts/#{Account.default.id}/terms"
      f(".add_term_link").click
      wait_for_ajaximations

      f("#enrollment_term_name").send_keys("some name")
      f("#enrollment_term_sis_source_id").send_keys("some id")

      f("#term_new .general_dates .start_date .edit_term input").send_keys("2011-07-01")
      f("#term_new .general_dates .end_date .edit_term input").send_keys("2011-07-31")

      submit_form(".enrollment_term_form")
      wait_for_ajaximations

      term = Account.default.enrollment_terms.last
      expect(term.name).to eq "some name"
      expect(term.sis_source_id).to eq "some id"

      expect(term.start_at).to eq Date.parse("2011-07-01")
      expect(term.end_at).to eq Date.parse("2011-07-31")
    end

    it 'general term dates', priority: 1, test_id: 1621631 do
      get "/accounts/#{Account.default.id}/terms"
      term = f("tr.term")
      f('.edit_term_link').click
      f('.editing_term .general_dates .start_date .edit_term input').send_keys("2011-07-01")
      f('.editing_term .general_dates .end_date .edit_term input').send_keys("2011-07-31")
      f("button[type='submit']").click
      expect(term).not_to have_class("editing_term")
      verify_displayed_term_dates(term, {
          :general => ["Jul 1", "Jul 31"],
          :student_enrollment => ["term start", "term end"],
          :teacher_enrollment => ["whenever", "term end"],
          :ta_enrollment => ["whenever", "term end"]
      })
    end

    it 'student enrollment dates', priority: 1, test_id: 1621632 do
      get "/accounts/#{Account.default.id}/terms"
      term = f("tr.term")
      f('.edit_term_link').click
      f('.editing_term .student_enrollment_dates .start_date .edit_term input').send_keys("2011-07-02")
      f('.editing_term .student_enrollment_dates .end_date .edit_term input').send_keys("2011-07-30")
      f("button[type='submit']").click
      expect(term).not_to have_class("editing_term")
      verify_displayed_term_dates(term, {
          :general => ["whenever", "whenever"],
          :student_enrollment => ["Jul 2", "Jul 30"],
          :teacher_enrollment => ["whenever", "term end"],
          :ta_enrollment => ["whenever", "term end"]
      })
    end

    it 'teacher enrollment dates', priority: 1, test_id: 1621633 do
      get "/accounts/#{Account.default.id}/terms"
      term = f("tr.term")
      f('.edit_term_link').click
      f('.editing_term .teacher_enrollment_dates .start_date .edit_term input').send_keys("2011-07-03")
      f('.editing_term .teacher_enrollment_dates .end_date .edit_term input').send_keys("2011-07-29")
      f("button[type='submit']").click
      expect(term).not_to have_class("editing_term")
      verify_displayed_term_dates(term, {
          :general => ["whenever", "whenever"],
          :student_enrollment => ["term start", "term end"],
          :teacher_enrollment => ["Jul 3", "Jul 29"],
          :ta_enrollment => ["whenever", "term end"]
      })
    end

    it 'ta enrollment dates', priority: 1, test_id: 1621934 do
      get "/accounts/#{Account.default.id}/terms"
      term = f("tr.term")
      f('.edit_term_link').click
      f('.editing_term .ta_enrollment_dates .start_date .edit_term input').send_keys("2011-07-04")
      f('.editing_term .ta_enrollment_dates .end_date .edit_term input').send_keys("2011-07-28")
      f("button[type='submit']").click
      expect(term).not_to have_class("editing_term")
      verify_displayed_term_dates(term, {
          :general => ["whenever", "whenever"],
          :student_enrollment => ["term start", "term end"],
          :teacher_enrollment => ["whenever", "term end"],
          :ta_enrollment => ["Jul 4", "Jul 28"]
      })
    end
  end

  describe "user/course search" do
    def submit_input(form_element, input_field_css, input_text, expect_new_page_load = true)
      form_element.find_element(:css, input_field_css).send_keys(input_text)
      go_button = form_element.find_element(:css, 'button')
      if expect_new_page_load
        expect_new_page_load { go_button.click }
      else
        go_button.click
      end
    end

    before(:each) do
      @student_name = 'student@example.com'
      @course_name = 'new course'
      @error_text = 'No Results Found'

      @course = Course.create!(:account => Account.default, :name => @course_name, :course_code => @course_name)
      @course.reload
      student_in_course(:name => @student_name)
      get "/accounts/#{Account.default.id}/courses"
    end

    it "should search for an existing course" do
      find_course_form = f('#new_course')
      submit_input(find_course_form, '#course_name', @course_name)
      expect(f('#breadcrumbs .home + li a')).to include_text(@course_name)
    end

    it "should correctly autocomplete for courses" do
      get "/accounts/#{Account.default.id}"
      f('#course_name').send_keys(@course_name.chop)

      ui_auto_complete = f('.ui-autocomplete')
      expect(ui_auto_complete).to be_displayed

      elements = ff('.ui-autocomplete li:first-child a div')
      expect(elements[0].text).to eq @course_name
      expect(elements[1].text).to eq 'Default Term'
      keep_trying_until do
        driver.execute_script("$('.ui-autocomplete li a').hover().click()")
        expect(driver.current_url).to include("/courses/#{@course.id}")
      end
    end

    it "should search for an existing user" do
      find_user_form = f('#new_user')
      submit_input(find_user_form, '#user_name', @student_name, false)
      wait_for_ajax_requests
      expect(f('.users')).to include_text(@student_name)
    end

    it "should behave correctly when searching for a course that does not exist" do
      find_course_form = f('#new_course')
      submit_input(find_course_form, '#course_name', 'some random course name that will not exist')
      wait_for_ajax_requests
      expect(f('#content')).to include_text(@error_text)
      expect(f('#new_user').find_element(:id, 'user_name').text).to be_empty # verifies bug #5133 is fixed
    end

    it "should behave correctly when searching for a user that does not exist" do
      find_user_form = f('#new_user')
      submit_input(find_user_form, '#user_name', 'this student name will not exist', false)
      expect(f('#content')).to include_text(@error_text)
    end
  end

  describe "user details view" do
    def create_sub_account(name = 'sub_account', parent_account = Account.default)
      Account.create(:name => name, :parent_account => parent_account)
    end

    it "should be able to view user details from parent account" do
      user_non_root = user
      create_sub_account.account_users.create!(user: user_non_root)
      get "/accounts/#{Account.default.id}/users/#{user_non_root.id}"
      # verify user details displayed properly
      expect(f('.accounts .unstyled_list li')).to include_text('sub_account')
    end
  end
end
