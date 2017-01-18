require File.expand_path(File.dirname(__FILE__) + '/../../common')

describe "sub account courses" do
  include_context "in-process server selenium tests"
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:url) { "/accounts/#{account.id}" }

    before (:each) do
      course_with_admin_logged_in
    end

    it "should add a new course", priority: "1", test_id: 263241 do
      course_name = 'course 1'
      course_code = '12345'
      get url

      f(".add_course_link").click
      wait_for_ajaximations
      f("#add_course_form #course_name").send_keys(course_name)
      f("#course_course_code").send_keys(course_code)
      submit_dialog_form("#add_course_form")
      refresh_page # we need to refresh the page so the course shows up
      course = Course.where(name: course_name).first
      expect(course).to be_present
      expect(course.course_code).to eq course_code
      expect(f("#course_#{course.id}")).to be_displayed
      expect(f("#course_#{course.id}")).to include_text(course_name)
    end
  end
