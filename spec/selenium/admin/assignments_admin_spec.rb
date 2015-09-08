require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "assignments" do
  include_context "in-process server selenium tests"

  context "as an admin" do
    before do
      @student = user_with_pseudonym(:active_user => true)
      course_with_student(:active_all => true, :user => @student)
      assignment_model(:course => @course, :submission_types => 'online_upload', :title => 'Assignment 1')
      site_admin_logged_in
    end

    it "should not show google docs tab for masquerading admin" do
      PluginSetting.create!(:name => 'google_docs', :settings => {})
      get "/users/#{@student.id}/masquerade"
      expect_new_page_load { f('.masquerade_button').click }

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      f('.submit_assignment_link').click
      expect(ff('#submit_google_doc_form')).to be_empty

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "should show the submit button if admin is enrolled as student" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      expect(f('.submit_assignment_link')).to be_nil

      @course.enroll_student(@admin, :enrollment_state => 'active')

      refresh_page
      wait_for_ajaximations
      expect(f('.submit_assignment_link')).to be_displayed
    end
  end
end
