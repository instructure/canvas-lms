#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../pages/mgp_page'

describe "grading periods account page" do
  include_context "in-process server selenium tests"

  context 'with grading periods' do
    let(:grading_standards_page) { GradingStandards::MultipleGradingPeriods.new }
    let(:backend_group_helper) { Factories::GradingPeriodGroupHelper.new }
    let(:backend_period_helper) { Factories::GradingPeriodHelper.new }

    before do
      admin_logged_in
    end

    it "adds grading period set", test_id: 2528622, priority: "1" do
      grading_standards_page.visit(Account.default.id)
      grading_standards_page.add_grading_period_set(name: "Set Name!", term: "Default Term")
      expect(grading_standards_page.grading_period_set_displayed?("Set Name!")).to eq(true)
      expect(grading_standards_page.add_grading_period_link_displayed?).to eq(true)
    end

    it "enable wieghted grading on grading period set", test_id: 3035964, priority: "1" do
      grading_standards_page.visit(Account.default.id)
      grading_standards_page.add_grading_period_set(name: "Set Name!", term: "Default Term", weighted: true)
      expect(grading_standards_page.weight_field_in_grading_period?).to eq(true)
    end

    it "enable show total column on grading period set", test_id: 3104470, priority: "1" do
      grading_standards_page.visit(Account.default.id)
      grading_standards_page.add_grading_period_set(name: "Set Name!", show_total: true)
      expect(grading_standards_page.show_total_checked?).to eq("true")
    end

    it "deletes grading period set", test_id: 2528621, priority: "1" do
      skip_if_safari(:alert)
      set = backend_group_helper.create_for_account(Account.default)
      grading_standards_page.visit(Account.default.id)
      grading_standards_page.delete_first_grading_period_set(false)
      expect(grading_standards_page.grading_period_set_displayed?(set.title)).to eq(true)
      grading_standards_page.delete_first_grading_period_set(true)
      expect(grading_standards_page.grading_periods_tab).not_to contain_css(grading_standards_page.grading_period_set_title_css)
    end

    it "edits grading period set", test_id: 2528628, priority: "1" do
      backend_group_helper.create_for_account(Account.default)
      grading_standards_page.visit(Account.default.id)
      grading_standards_page.edit_first_grading_period_set("Edited Title")
      expect(grading_standards_page.grading_period_set_displayed?("Edited Title")).to eq(true)
    end

    it "adds grading period", test_id: 2528648, priority: "1" do
      backend_group_helper.create_for_account(Account.default)
      grading_standards_page.visit(Account.default.id)
      grading_standards_page.add_grading_period("New Period")
      expect(grading_standards_page.grading_period_displayed?("New Period")).to eq(true)
    end

    it "edits grading period", test_id: 2528655, priority: "1" do
      backend_period_helper.create_with_group_for_account(Account.default, title: "New Period")
      grading_standards_page.visit(Account.default.id)
      grading_standards_page.edit_first_grading_period("Edited Title")
      expect(grading_standards_page.grading_period_displayed?("Edited Title")).to eq(true)
    end

    it "deletes grading period", test_id: 2528647, priority: "1" do
      backend_period_helper.create_with_group_for_account(Account.default, title: "New Period")
      grading_standards_page.visit(Account.default.id)
      grading_standards_page.expand_first_set
      grading_standards_page.delete_first_grading_period(false)
      expect(grading_standards_page.grading_period_displayed?("New Period")).to eq(true)
      grading_standards_page.delete_first_grading_period(true)
      expect(grading_standards_page.grading_period_list).not_to contain_css(grading_standards_page.period_css)
    end

    it "defaults close date to end date", test_id: 2887215, priority: "1" do
      backend_period_helper.create_with_group_for_account(Account.default, title: "New Period")
      grading_standards_page.visit(Account.default.id)
      grading_standards_page.expand_first_set
      grading_standards_page.open_grading_period_form
      expect(grading_standards_page.close_date_value).to eq(grading_standards_page.end_date_value)
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

        grading_standards_page.visit(Account.default.id)
      end

      it "term dropdown filters grading period sets", test_id: 2528643, priority: "1" do
        grading_standards_page.select_term_filter(term_name_1)
        expect(grading_standards_page.grading_period_set_displayed?(group_name_1)).to eq(true)
        expect(grading_standards_page.grading_period_set_displayed?(group_name_2)).to eq(false)

        grading_standards_page.select_term_filter(term_name_2)
        expect(grading_standards_page.grading_period_set_displayed?(group_name_2)).to eq(true)
        expect(grading_standards_page.grading_period_set_displayed?(group_name_1)).to eq(false)

        grading_standards_page.select_term_filter("All Terms")
        expect(grading_standards_page.grading_period_set_displayed?(group_name_1)).to eq(true)
        expect(grading_standards_page.grading_period_set_displayed?(group_name_2)).to eq(true)
      end

      it "search grading periods", test_id: 2528642, priority: "1" do
        grading_standards_page.visit(Account.default.id)
        grading_standards_page.search_grading_periods("another")
        expect(grading_standards_page.grading_period_set_displayed?(group_name_1)).to eq(false)
        expect(grading_standards_page.grading_period_set_displayed?(group_name_2)).to eq(true)
      end
    end
  end
end

