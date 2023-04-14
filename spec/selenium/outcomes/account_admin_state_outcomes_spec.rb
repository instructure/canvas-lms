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
  let(:account) { Account.default }
  let(:who_to_login) { "admin" }
  let(:outcome_url) { "/accounts/#{Account.default.id}/outcomes" }

  include_examples "in-process server selenium tests"
  include OutcomeCommon

  describe "state level outcomes" do
    before do
      course_with_admin_logged_in
      @root_account = Account.site_admin
      account_admin_user(account: @root_account, active_all: true)
      @cm = ContentMigration.create(context: @root_account)
      @plugin = Canvas::Plugin.find("academic_benchmark_importer")
      @cm.converter_class = @plugin.settings["converter_class"]
      @cm.migration_settings[:migration_type] = "academic_benchmark_importer"
      @cm.migration_settings[:import_immediately] = true
      @cm.migration_settings[:base_url] = "http://example.com/"
      @cm.user = @user
      @cm.save!

      @level_0_browse = File.join(File.dirname(__FILE__) + "/../../../gems/plugins/academic_benchmark/spec_canvas/fixtures", "api_all_standards_response.json")
      File.open(@level_0_browse, "r") do |file|
        @att = Attachment.create!(filename: "standards.json", display_name: "standards.json", uploaded_data: file, context: @cm)
      end
      @cm.attachment = @att
      @cm.save!
    end

    def import_state_standards_to_account(outcome)
      state_outcome_setup
      goto_state_outcomes
      traverse_nested_outcomes(outcome)
      import_account_level_outcomes
    end

    it "has state standards available for outcomes through find", priority: "2" do
      state_outcome_setup
      goto_state_outcomes
      expect(ffj(".outcome-level:last .outcome-group .ellipsis")[0]).to have_attribute("title", "CCSS.ELA-Literacy.CCRA.R - Reading")
    end

    it "imports state standards to course groups and all nested outcomes", priority: "2" do
      skip_if_safari(:alert)
      import_state_standards_to_account(state_outcome)
      el1 = fj(".outcome-level:first .outcome-group .ellipsis")
      el2 = fj(".outcome-level:last .outcome-link .ellipsis")
      expect(el1).to have_attribute("title", "Craft and Structure")
      expect(el2).to have_attribute("title", "CCSS.ELA-Literacy.CCRA.R.4")
    end

    it "imports a state standard into account level", priority: "2" do
      skip_if_safari(:alert)
      outcome = ["CCSS.ELA-Literacy.CCRA.R - Reading"]
      import_state_standards_to_account(outcome)
      el = fj(".outcome-level:first .outcome-group .ellipsis")
      expect(el).to have_attribute("title", "CCSS.ELA-Literacy.CCRA.R - Reading")
    end

    it "imports account outcomes into course", priority: "1" do
      skip_if_safari(:alert)
      import_state_standards_to_account(state_outcome)
      outcome = ["Default Account", "Craft and Structure"]
      goto_state_outcomes("/courses/#{@course.id}/outcomes")
      traverse_nested_outcomes(outcome)
      import_account_level_outcomes
    end

    it "deletes state standards outcome groups from course listing", priority: "2" do
      skip_if_safari(:alert)
      import_state_standards_to_account(state_outcome)
      f(".ellipsis[title='Craft and Structure']").click
      wait_for_ajaximations

      f(".delete_button").click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      refresh_page
      wait_for_ajaximations
      # validations
      expect(f(".outcomes-sidebar")).not_to contain_jqcss(".outcome-level:first li")
      expect(f(".outcomes-content .title").text).to eq "Setting up Outcomes"
    end

    describe "with improved_outcome_management enabled" do
      require_relative "pages/improved_outcome_management_page"
      include ImprovedOutcomeManagementPage

      before do
        enable_improved_outcomes_management(account)
        @cm.export_content
        run_jobs
      end

      it "imports a state standard into an account via Find modal" do
        goto_improved_state_outcomes
        open_find_modal
        state_standards_tree_button.click
        common_core_standards_tree_button.click
        job_count = Delayed::Job.count
        outcome0_title = nth_find_outcome_modal_item_title(0)
        add_button_nth_find_outcome_modal_item(0).click
        click_done_find_modal

        # ImportOutcomes operations enqueue jobs that will need to be manually processed
        expect(Delayed::Job.count).to eq(job_count + 1)
        run_jobs

        # Verify by titles that the outcomes are imported into current root account
        account_outcomes = LearningOutcome.where(root_account_ids: [account.id])
        expect(account_outcomes[0].short_description).to eq(outcome0_title)
      end

      it "creates an initial outcome in the account level" do
        goto_improved_state_outcomes
        create_outcome("Test Outcome")

        # Verify by titles that the outcomes are imported into current root account
        account_outcomes = LearningOutcome.where(root_account_ids: [account.id])
        expect(account_outcomes[0].short_description).to eq("Test Outcome")
      end

      it "searches across state standards in the Find modal and aligns a result" do
        goto_improved_state_outcomes
        open_find_modal
        state_standards_tree_button.click
        common_core_standards_tree_button.click
        # Searching for the whole string will bring in several results and will make the test longer,
        #  so we're just searching for one very specific thing that will load quickly
        complete_title = "CCSS.ELA-Literacy.CCRA.W.1"
        search_title = "CCRA.W.1"
        search_common_core(search_title)
        wait_for_ajaximations
        job_count = Delayed::Job.count
        wait_for(method: nil, timeout: 2) { find_outcome_modal_items.count == 1 }
        add_button_nth_find_outcome_modal_item(0).click

        # ImportOutcomes operations enqueue jobs that will need to be manually processed
        expect(Delayed::Job.count).to eq(job_count + 1)
        run_jobs
        account_outcomes = LearningOutcome.where(root_account_ids: [account.id])
        expect(account_outcomes[0].short_description).to eq(complete_title)
      end
    end

    describe "state standard pagination" do
      it "does not fail while filtering the common core group", priority: "2" do
        # setup fake state data, so that it has to paginate
        root_group = LearningOutcomeGroup.global_root_outcome_group
        root_group.child_outcome_groups.create!(title: "Fake Common Core")
        11.times { root_group.child_outcome_groups.create!(title: "G is after F") }
        root_group.child_outcome_groups.create!(title: "Z is last")

        # go to the find panel
        get outcome_url
        wait_for_ajaximations
        f(".find_outcome").click
        wait_for_ajaximations

        # click on state standards
        top_level_groups = ff(".outcome-level .outcome-group")
        expect(top_level_groups.count).to eq 2
        top_level_groups[1].click
        wait_for_ajaximations

        # make sure the last one is the Z guy
        last_el = ffj(".outcome-level:last .outcome-group .ellipsis").last
        expect(last_el).to have_attribute("title", "Z is last")
      end
    end
  end
end
