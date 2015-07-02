require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/grading_schemes_common')

describe "sub account grading schemes" do
  include_examples "in-process server selenium tests"

  let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
  let(:url) { "/accounts/#{account.id}/grading_standards" }

  before (:each) do
    course_with_admin_logged_in
    get url
  end

  context "without Multiple Grading Periods" do

    describe "grading schemes" do

      it "should add a grading scheme", priority: 1, test_id: 163992 do
        should_add_a_grading_scheme

      end

      it "should edit a grading scheme", priority: 1, test_id: 210075 do
        should_edit_a_grading_scheme(account, url)
      end

      it "should delete a grading scheme", priority: 1, test_id: 210111 do
        should_delete_a_grading_scheme(account, url)
      end
    end


    describe "grading scheme items" do

      before(:each) do
        create_simple_standard_and_edit(account, url)
      end

      it "should add a grading scheme item", priority: 1, test_id: 210113 do
        should_add_a_grading_scheme_item
      end

      it "should edit a grading scheme item", priority: 1, test_id: 210114 do
        should_edit_a_grading_scheme_item
      end

      it "should delete a grading scheme item", priority: 1, test_id: 210115 do
        should_delete_a_grading_scheme_item
      end
    end
  end

  context "with Multiple Grading Periods enabled" do

    it "should contain a tab for grading schemes and grading periods", priority: 1, test_id:202306  do
      should_contain_a_tab_for_grading_schemes_and_periods(url)
    end
  end
end
