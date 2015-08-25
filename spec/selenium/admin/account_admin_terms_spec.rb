require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "account admin terms" do
  include_context "in-process server selenium tests"

  def click_term_action_link(term_div, action_link_css)
    term_div.find_element(:css, action_link_css).click
  end

  def validate_term_display(term_div_index = 0, title = 'Default Term', course_count = 1, user_count = 1)
    term_header = ff('.term .header')[term_div_index]
    expect(term_header).to include_text(title)
    expect(term_header).to include_text("#{course_count} Course")
    expect(term_header).to include_text("#{user_count} User")
  end

  before (:each) do
    course_with_admin_logged_in
  end

  context "default term" do
    before (:each) do
      get "/accounts/#{Account.default.id}/terms"
      @default_term = ff('.term')[0]
    end

    it "should validate default term" do
      validate_term_display
    end

    it "should edit default term" do
      edit_term_name = 'edited term title'
      click_term_action_link(@default_term, '.edit_term_link')
      replace_content(f('#enrollment_term_name'), edit_term_name)
      submit_form('.enrollment_term_form')
      wait_for_ajax_requests
      validate_term_display(0, edit_term_name)
    end

    it "should validate that you cannot delete a term with courses in it" do
      expect {
        click_term_action_link(@default_term, '.cant_delete_term_link')
        alert = driver.switch_to.alert
        expect(alert.text).to eq "You can't delete a term that still has classes in it."
        alert.accept
      }.to change(EnrollmentTerm, :count).by(0)
      validate_term_display
    end
  end

  context "not default term" do

    it "should add a new term" do
      new_term_name = 'New Term'
      get "/accounts/#{Account.default.id}/terms"

      expect {
        f('.add_term_link').click
        replace_content(f('#enrollment_term_name'), new_term_name)
        submit_form('.enrollment_term_form')
        wait_for_ajax_requests
      }.to change(EnrollmentTerm, :count).by(1)
      expect(ff('.term .header')[0].text).to eq new_term_name
    end

    it "should delete a term" do
      term_name = "delete term"
      term = @course.root_account.enrollment_terms.create!(:name => term_name)
      get "/accounts/#{Account.default.id}/terms"

      validate_term_display(0, term_name, 0, 0)
      click_term_action_link(ff('.term')[0], '.delete_term_link')
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(EnrollmentTerm.where(name: term_name).first.workflow_state).to eq 'deleted'
      validate_term_display
    end

    it "should cancel term creation and validate nothing was created" do
      get "/accounts/#{Account.default.id}/terms"

      expect {
        f('.add_term_link').click
        replace_content(f('#enrollment_term_name'), 'false add')
        f('.cancel_button').click
      }.to change(EnrollmentTerm, :count).by(0)
      validate_term_display
    end
  end
end