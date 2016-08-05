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
      expect(set_present?("Set Name!")).to be true
      expect(add_grading_period_link).to be_displayed
    end

    it "deletes grading period set", test_id: 2528621, priority: "1" do
      group = group_helper.create_for_account(Account.default)
      visit_account_grading_standards(Account.default.id)
      delete_first_grading_period_set(false)
      expect(set_present?(group.title)).to be true
      delete_first_grading_period_set(true)
      expect(grading_periods_tab).not_to contain_css(grading_period_set_title_css)
    end

    it "edits grading period set", test_id: 2528628, priority: "1" do
      group_helper.create_for_account(Account.default)
      visit_account_grading_standards(Account.default.id)
      edit_first_grading_period_set("Edited Title")
      expect(set_present?("Edited Title")).to be true
    end

    it "adds grading period", test_id: 2528648, priority: "1" do
      group_helper.create_for_account(Account.default)
      visit_account_grading_standards(Account.default.id)
      add_grading_period("New Period")
      expect(period_present?("New Period")).to be true
    end

    it "edits grading period", test_id: 2528655, priority: "1" do
      period_helper.create_with_group_for_account(Account.default, title: "New Period")
      visit_account_grading_standards(Account.default.id)
      edit_first_grading_period("Edited Title")
      expect(period_present?("Edited Title")).to be true
    end

    context "page functionality" do
      group_name_1 = "Group 1"
      group_name_2 = "Group 2"
      term_name_1 = "First Term"
      term_name_2 = "Second Term"
      period_name_1 = "A Grading Period"
      period_name_2 = "Another Grading Period"

      before(:each) do
        group1 = group_helper.create_for_account_with_term(Account.default, term_name_1, group_name_1)
        group2 = group_helper.create_for_account_with_term(Account.default, term_name_2, group_name_2)
        period_helper.create_for_group(group1, title: period_name_1)
        period_helper.create_for_group(group2, title: period_name_2)

        visit_account_grading_standards(Account.default.id)
      end

      it "term dropdown filters grading period sets", test_id: 2528643, priority: "1" do
        select_term_filter(term_name_1)
        expect(find_set(group_name_1)).to be_displayed
        expect(set_present?(group_name_2)).to be false

        select_term_filter(term_name_2)
        expect(find_set(group_name_2)).to be_displayed
        expect(set_present?(group_name_1)).to be false

        select_term_filter("All Terms")
        expect(find_set(group_name_1)).to be_displayed
        expect(find_set(group_name_2)).to be_displayed
      end
    end
  end
end

