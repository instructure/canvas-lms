# frozen_string_literal: true

# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/outcome_common"

describe "account admin outcomes" do
  include_context "in-process server selenium tests"
  include OutcomeCommon

  let(:outcome_url) { "/accounts/#{Account.default.id}/outcomes" }
  let(:who_to_login) { "admin" }
  let(:account) { Account.default }

  describe "course outcomes" do
    before do
      RoleOverride.create!(context: account,
                           permission: "manage_courses",
                           role: admin_role,
                           enabled: false) # should not manage_courses permission
      course_with_admin_logged_in
    end

    context "create/edit/delete outcomes" do
      it "creates a learning outcome with a new rating (root level)", priority: "1" do
        should_create_a_learning_outcome_with_a_new_rating_root_level
      end

      it "creates a learning outcome (nested)", priority: "1" do
        should_create_a_learning_outcome_nested
      end

      it "edits a learning outcome and delete a rating", priority: "1" do
        should_edit_a_learning_outcome_and_delete_a_rating
      end

      it "deletes a learning outcome", priority: "1" do
        skip_if_safari(:alert)
        should_delete_a_learning_outcome
      end

      it "validates decaying average_range", priority: "2" do
        should_validate_decaying_average_range
      end

      it "validates n mastery_range", priority: "2" do
        should_validate_n_mastery_range
      end
    end

    context "create/edit/delete outcome groups" do
      it "creates an outcome group (root level)", priority: "2" do
        should_create_an_outcome_group_root_level
      end

      it "creates an outcome group (nested)", priority: "2" do
        should_create_an_outcome_group_nested
      end

      it "edits an outcome group", priority: "2" do
        should_edit_an_outcome_group
      end

      it "deletes an outcome group", priority: "2" do
        skip_if_safari(:alert)
        should_delete_an_outcome_group
      end
    end

    context "outcome groups" do
      let(:one) { 1 }

      before do
        setup_fake_state_data(one)
        open_outcomes_find
        click_on_state_standards
      end

      it "expand/collapses outcome groups", priority: "2" do
        skip_if_safari(:alert)
        import_state_standart_into_account

        back_button = f(".go_back")
        expand_child_folders(one, back_button)

        # collapse back to the root folder by repeatedly clicking on |Back| (upper left)
        one.downto(1) do |i|
          outcome_group = ffj(".outcome-level:visible .outcome-group .ellipsis")[i - 1]
          expect(outcome_group.text).to eq "Level #{i}"
          back_button.click
        end
      end
    end

    describe "find/import dialog" do
      it "does not allow importing top level groups", priority: "2" do
        get outcome_url
        wait_for_ajaximations

        f(".find_outcome").click
        wait_for_ajaximations
        groups = ff(".outcome-group")
        expect(groups.size).to eq 2
        groups.each do |g|
          g.click
          expect(f(".ui-dialog-buttonpane .btn-primary")).not_to be_displayed
        end
      end
    end

    private

    def setup_fake_state_data(counter)
      root_group = LearningOutcomeGroup.global_root_outcome_group
      1.upto(counter) do |og|
        root_group = root_group.child_outcome_groups.create!(title: "Level #{og}")
      end
    end

    def open_outcomes_find
      get outcome_url
      wait_for_ajaximations
      f(".find_outcome").click
      wait_for_ajaximations
    end

    def click_on_state_standards
      fj(".outcome-level .outcome-group:eq(1)").click
      wait_for_ajaximations
    end

    def import_state_standart_into_account
      ffj(".outcome-level:last .outcome-group .ellipsis").first.click
      f(".ui-dialog-buttonpane .btn-primary").click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      run_jobs
      wait_for_no_such_element { f(".ui-dialog") }
    end

    def expand_child_folders(counter, back_button)
      back_button.click
      expect(back_button).not_to be_displayed
      counter.times do
        outcome_group = ffj(".outcome-level:visible:last .outcome-group .ellipsis")[0]
        outcome_group.click
        wait_for_animations
        expect(back_button).to be_displayed
      end
    end
  end
end
