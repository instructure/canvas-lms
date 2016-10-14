require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/outcome_common')

describe "sub account outcomes" do
  include_context "in-process server selenium tests"
  include OutcomeCommon

    describe "account outcome specs" do
      let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
      let(:outcome_url) { "/accounts/#{account.id}/outcomes" }
      let(:who_to_login) { 'admin' }

      before(:each) do
        course_with_admin_logged_in
      end

      context "create/edit/delete outcomes" do

        it "should create a learning outcome with a new rating (root level)", priority: "2", test_id: 263461 do
          should_create_a_learning_outcome_with_a_new_rating_root_level
        end

        it "should create a learning outcome (nested)", priority: "2", test_id: 263680 do
          should_create_a_learning_outcome_nested
        end

        it "should edit a learning outcome and delete a rating", priority: "2", test_id: 263681 do
          should_edit_a_learning_outcome_and_delete_a_rating
        end

        it "should delete a learning outcome", priority: "2", test_id: 263682 do
          should_delete_a_learning_outcome
        end

        it "should validate decaying average_range", priority: "2", test_id: 250518 do
          should_validate_decaying_average_range
        end

        it "should validate n mastery_range", priority: "2", test_id: 303714 do
          should_validate_n_mastery_range
        end
      end

      context "create/edit/delete outcome groups" do
        it "should create an outcome group (root level)", priority: "1", test_id: 263902 do
          should_create_an_outcome_group_root_level
        end

        it "should create an outcome group (nested)", priority: "1", test_id: 250521 do
          should_create_an_outcome_group_nested
        end

        it "should edit an outcome group", priority: "1", test_id: 250522 do
          should_edit_an_outcome_group
        end

        it "should delete an outcome group", priority: "1", test_id: 250523 do
          should_delete_an_outcome_group
        end
      end

      describe "find/import dialog" do
        it "should not allow importing top level groups", priority: "1", test_id: 250524 do
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