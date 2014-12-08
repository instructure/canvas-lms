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

      it "should create a learning outcome with a new rating (root level)" do
        should_create_a_learning_outcome_with_a_new_rating_root_level
      end

      it "should create a learning outcome (nested)" do
        should_create_a_learning_outcome_nested
      end

      it "should edit a learning outcome and delete a rating" do
        skip('193')
        should_edit_a_learning_outcome_and_delete_a_rating
      end

      it "should delete a learning outcome" do
        should_delete_a_learning_outcome
      end

      it "should validate mastery points" do
        should_validate_mastery_points
      end
    end

    context "create/edit/delete outcome groups" do

      it "should create an outcome group (root level)" do
        should_create_an_outcome_group_root_level
      end

      it "should create a learning outcome with a new rating (nested)" do
        should_create_a_learning_outcome_with_a_new_rating_nested
      end

      it "should edit an outcome group" do
        should_edit_an_outcome_group
      end

      it "should delete an outcome group" do
        should_delete_an_outcome_group
      end
    end

    describe "find/import dialog" do
      it "should not allow importing top level groups" do
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
