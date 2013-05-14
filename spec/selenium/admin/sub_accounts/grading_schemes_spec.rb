require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/grading_schemes_common')

describe "sub account grading schemes" do
  it_should_behave_like "in-process server selenium tests"

  let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
  let(:url) { "/accounts/#{account.id}/grading_standards" }

  before (:each) do
    course_with_admin_logged_in
  end

  describe "grading schemes" do

    it "should add a grading scheme" do
      should_add_a_grading_scheme
    end

    it "should edit a grading scheme" do
      should_edit_a_grading_scheme
    end

    it "should delete a grading scheme" do
      should_delete_a_grading_scheme
    end
  end

  describe "grading scheme items" do

    def grading_standard_rows
      ff('.grading_standard_row')
    end

    before (:each) do
      grading_standard_for(account)
      @grading_standard = GradingStandard.last
      get url
      f('.edit_grading_standard_link').click
    end

    it "should add a grading scheme item" do
      should_add_a_grading_scheme_item
    end

    it "should edit a grading scheme item" do
      should_edit_a_grading_scheme_item
    end

    it "should delete a grading scheme item" do
      should_delete_a_grading_scheme_item
    end
  end
end
