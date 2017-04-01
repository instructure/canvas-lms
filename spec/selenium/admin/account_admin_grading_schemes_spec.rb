require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/grading_schemes_common')

describe "account admin grading schemes" do
  include_context "in-process server selenium tests"
  include GradingSchemesCommon

  let(:account) { Account.default }
  let(:url) { "/accounts/#{Account.default.id}/grading_standards" }

  before do
    course_with_admin_logged_in
    get url
    f('#react_grading_tabs a[href="#grading-standards-tab"]').click
  end

  describe "grading schemes" do

    it "should add a grading scheme", priority: "1", test_id: 163992 do
      should_add_a_grading_scheme
    end

    it "should edit a grading scheme", priority: "1", test_id: 210075 do
      should_edit_a_grading_scheme(account, url)
    end

    it "should delete a grading scheme", priority: "1", test_id: 210111 do
      should_delete_a_grading_scheme(account, url)
    end
  end

  describe "grading scheme items" do

    before do
      create_simple_standard_and_edit(account, url)
    end

    it "should add a grading scheme item", priority: "1", test_id: 210113 do
      should_add_a_grading_scheme_item
    end

    it "should edit a grading scheme item", priority: "1", test_id: 210114 do
      should_edit_a_grading_scheme_item
    end

    it "should delete a grading scheme item", priority: "1", test_id: 210115 do
      should_delete_a_grading_scheme_item
    end

    it "should not update when invalid scheme input is given", priority: "1", test_id: 238161 do
      should_not_update_invalid_grading_scheme_input
    end
  end
end

describe "course grading schemes as account admin" do
  include_context "in-process server selenium tests"
  include GradingSchemesCommon

  before do
    course_with_admin_logged_in
    simple_grading_standard(@course.account)
  end

  it "disallows editing but links to the account grading standards page" do
    get "/courses/#{@course.id}/grading_standards"
    expect(f("#grading_standard_#{@standard.id} a.cannot-manage-notification")).to be_displayed
  end
end
