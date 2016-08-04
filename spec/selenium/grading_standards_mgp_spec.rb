require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/multiple_grading_periods_common')

describe "multiple grading periods account page" do
  include_context "in-process server selenium tests"
  include MultipleGradingPeriods::AccountPage
  include_context "account_page_components"

  context 'with mgp enabled' do

    before(:each) do
      admin_logged_in
      Account.default.enable_feature!(:multiple_grading_periods)
    end

    it "adds grading period set", test_id: 2528622, priority: "1" do
      visit_account_grading_standards(Account.default.id)
      add_grading_period_set("Set Name!", "Default Term")
      expect(find_set("Set Name!")).to be_displayed
      expect(add_grading_period_link).to be_displayed
    end

    it "deletes grading period set", test_id: 2528621, priority: "1" do
      group = backend_group_helper.create_for_account(Account.default)
      visit_account_grading_standards(Account.default.id)
      delete_first_grading_period_set(false)
      expect(find_set(group.title)).to be_displayed
      delete_first_grading_period_set(true)
      expect(grading_periods_tab).not_to contain_css(grading_period_set_title_css)
    end

    it "edits grading period set", test_id: 2528628, priority: "1" do
      backend_group_helper.create_for_account(Account.default)
      visit_account_grading_standards(Account.default.id)
      edit_first_grading_period_set("Edited Title")
      expect(find_set("Edited Title")).to be_displayed
    end

    it "adds grading period", test_id: 2528648, priority: "1" do
      backend_group_helper.create_for_account(Account.default)
      visit_account_grading_standards(Account.default.id)
      add_grading_period("New Period")
      expect(find_period("New Period")).to be_displayed
    end

    it "edits grading period", test_id: 2528655, priority: "1" do
      backend_period_helper.create_with_group_for_account(Account.default, title: "New Period")
      visit_account_grading_standards(Account.default.id)
      edit_first_grading_period("Edited Title")
      expect(find_period("Edited Title")).to be_displayed
    end

    it "deletes grading period", test_id: 2528647, priority: "1" do
      backend_period_helper.create_with_group_for_account(Account.default, title: "New Period")
      visit_account_grading_standards(Account.default.id)
      delete_first_grading_period(false)
      expect(find_period("New Period")).to be_displayed
      delete_first_grading_period(true)
      expect(grading_period_list).not_to contain_css(period_css)
    end

    context "with populated data" do
      group_name_1 = "Group 1"
      group_name_2 = "Group 2"
      term_name_1 = "First Term"
      term_name_2 = "Second Term"
      period_name_1 = "A Grading Period"
      period_name_2 = "Another Grading Period"

      before(:each) do
        group1 = backend_group_helper.create_for_account_with_term(Account.default, term_name_1, group_name_1)
        group2 = backend_group_helper.create_for_account_with_term(Account.default, term_name_2, group_name_2)
        backend_period_helper.create_for_group(group1, title: period_name_1)
        backend_period_helper.create_for_group(group2, title: period_name_2)

        visit_account_grading_standards(Account.default.id)
      end

      it "term dropdown filters grading period sets", test_id: 2528643, priority: "1" do
        select_term_filter(term_name_1)
        expect(find_set(group_name_1)).to be_displayed
        expect(find_set(group_name_2)).to be nil

        select_term_filter(term_name_2)
        expect(find_set(group_name_2)).to be_displayed
        expect(find_set(group_name_1)).to be nil

        select_term_filter("All Terms")
        expect(find_set(group_name_1)).to be_displayed
        expect(find_set(group_name_2)).to be_displayed
      end

      it "search grading periods", test_id: 2528642, priority: "1" do
        visit_account_grading_standards(Account.default.id)
        search_grading_periods("another")
        expect(find_set(group_name_1)).to be nil
        expect(find_set(group_name_2)).to be_displayed
      end
    end
  end
end

