# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/outcome_common')

describe "account admin outcomes" do
  include_context "in-process server selenium tests"
  include OutcomeCommon

  let(:outcome_url) { "/accounts/#{Account.default.id}/outcomes" }
  let(:who_to_login) { 'admin' }
  let(:account) { Account.default }
  describe "course outcomes" do
    before(:each) do
      RoleOverride.create!(:context => account, :permission => 'manage_courses',
        :role => admin_role, :enabled => false) # should not manage_courses permission
      course_with_admin_logged_in
    end

    it "should be able to manage course rubrics" do
      get "/courses/#{@course.id}/outcomes"
      expect_new_page_load do
        f('#popoverMenu button').click
        f('[data-reactid*="manage-rubrics"]').click
      end

      expect(f('.add_rubric_link')).to be_displayed
    end

    context "create/edit/delete outcomes" do

      it "should create a learning outcome with a new rating (root level)", priority: "1", test_id: 250229 do
        should_create_a_learning_outcome_with_a_new_rating_root_level
      end

      it "should create a learning outcome (nested)", priority: "1", test_id: 250230 do
        should_create_a_learning_outcome_nested
      end

      it "should edit a learning outcome and delete a rating", priority: "1", test_id: 250231 do
        should_edit_a_learning_outcome_and_delete_a_rating
      end

      it "should delete a learning outcome", priority: "1", test_id: 250232 do
        should_delete_a_learning_outcome
      end

      it "should validate decaying average_range", priority: "2", test_id: 250235 do
        should_validate_decaying_average_range
      end

      it "should validate n mastery_range", priority: "2", test_id: 250236 do
        should_validate_n_mastery_range
      end
    end

    context "create/edit/delete outcome groups" do

      it "should create an outcome group (root level)", priority: "2", test_id: 56016 do
        should_create_an_outcome_group_root_level
      end

      it "should create an outcome group (nested)", priority: "2", test_id: 250237 do
        should_create_an_outcome_group_nested
      end

      it "should edit an outcome group", priority: "2", test_id: 114335 do
        should_edit_an_outcome_group
      end

      it "should delete an outcome group", priority: "2", test_id: 250238 do
        should_delete_an_outcome_group
      end
    end

    context "outcome groups" do
      let(:ten) { 10 }

      before(:each) do
        setup_fake_state_data(ten)
        open_outcomes_find
        click_on_state_standards
      end

      it "should expand/collapse outcome groups", priority: "2", test_id: 114338 do
        import_state_standart_into_account

        back_button = f(".go_back")
        expand_child_folders(ten, back_button)

        # collapse back to the root folder by repeatedly clicking on |Back| (upper left)
        ten.downto(1) do |i|
          outcome_group = ffj(".outcome-level:visible .outcome-group .ellipsis")[i - 1]
          expect(outcome_group.text).to eq "Level #{i}"
          back_button.click
        end
      end
    end

    describe "find/import dialog" do
      it "should not allow importing top level groups", priority: "2", test_id: 250239 do
        get outcome_url
        wait_for_ajaximations

        f('.find_outcome').click
        wait_for_ajaximations
        groups = ff('.outcome-group')
        expect(groups.size).to eq 2
        groups.each do |g|
          g.click
          expect(f('.ui-dialog-buttonpane .btn-primary')).not_to be_displayed
        end
      end
    end

    private

    def setup_fake_state_data(counter)
      root_group = LearningOutcomeGroup.global_root_outcome_group
      1.upto(counter) do |og|
        root_group = root_group.child_outcome_groups.create!(:title => "Level #{og}")
      end
      Setting.set(AcademicBenchmark.common_core_setting_key, root_group.id.to_s)
    end

    def open_outcomes_find
      get outcome_url
      wait_for_ajaximations
      f('.find_outcome').click
      wait_for_ajaximations
    end

    def click_on_state_standards
      top_level_groups = ff(".outcome-level .outcome-group")
      expect(top_level_groups.count).to eq 3
      top_level_groups[1].click
      wait_for_ajaximations
    end

    def import_state_standart_into_account
      ffj(".outcome-level:last .outcome-group .ellipsis").first.click
      f(".btn-primary").click
      expect(driver.switch_to.alert).not_to be nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
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
