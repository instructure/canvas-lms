# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/outcome_common')

describe "account admin outcomes" do
  include_examples "in-process server selenium tests"
  let(:outcome_url) { "/accounts/#{Account.default.id}/outcomes" }
  let(:who_to_login) { 'admin' }
  let(:account) { Account.default }
  describe "course outcomes" do
    before (:each) do
      course_with_admin_logged_in
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

      it "should validate mastery points", priority: "1", test_id: 250233 do
        should_validate_mastery_points
      end

      it "should_validate_calculation_method_dropdown", priority: "2", test_id: 250234 do
        should_validate_calculation_method_dropdown
      end

      it "should validate decaying average", priority: "2", test_id: 250235 do
        should_validate_decaying_average
      end

      it "should validate n mastery", priority: "2", test_id: 250236 do
        should_validate_n_mastery
      end
    end

    context "create/edit/delete outcome groups" do

      it "should create an outcome group (root level)", priority: "2", test_id: 56016 do
        should_create_an_outcome_group_root_level
      end

      it "should create an outcome group (nested)", priority: "2", test_id: 250237 do
        should_create_an_outcome_group_nested
      end

      it "should edit an outcome group", priority: "2", test_id: 114335  do
        should_edit_an_outcome_group
      end

      it "should delete an outcome group", priority: "2", test_id: 250238 do
        should_delete_an_outcome_group
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
  end
end
