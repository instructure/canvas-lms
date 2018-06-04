#
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

require_relative '../helpers/outcome_common'

describe "outcomes as a teacher" do
  include_context "in-process server selenium tests"
  include OutcomeCommon

  let(:who_to_login) { 'teacher' }
  let(:outcome_url) { "/courses/#{@course.id}/outcomes" }

  def goto_account_default_outcomes
    f('.find_outcome').click
    wait_for_ajaximations
    f(".ellipsis[title='Account Standards']").click
    wait_for_ajaximations
    f(".ellipsis[title='Default Account']").click
    wait_for_ajaximations
  end

  context "account level outcomes" do

    before do
      course_with_teacher_logged_in
      @account = Account.default
      account_outcome(1)
      get outcome_url
      wait_for_ajaximations
      goto_account_default_outcomes
    end

    it "should have account outcomes available for course" do
      expect(f(".ellipsis[title='outcome 0']")).to be_displayed
    end

    it "should add account outcomes to course" do
      f(".ellipsis[title='outcome 0']").click
      import_account_level_outcomes()
      expect(f(".ellipsis[title='outcome 0']")).to be_displayed
    end

    it "should remove account outcomes from course" do
      skip("no delete button when seeding, functionality should be available")
      f(".ellipsis[title='outcome 0']").click
      import_account_level_outcomes()
      f(".ellipsis[title='outcome 0']").click
      wait_for_ajaximations
      msg = "redmine bug on this functionality"
      expect(msg).to eq ""
    end
  end

  context "find/import dialog" do
    before do
      course_with_teacher_logged_in
      @account = Account.default
      account_outcome(1)
    end

    it "should not allow importing top level groups" do
      get outcome_url
      wait_for_ajaximations

      f('.find_outcome').click
      wait_for_ajaximations
      groups = ff('.outcome-group')
      expect(groups.size).to eq 1
      groups.each do |g|
        g.click
        expect(f('.ui-dialog-buttonpane .btn-primary')).not_to be_displayed
      end
    end

    it "should update the selected group when re-opened" do
      group1 = outcome_group_model(title: 'outcome group 1', context: @course)
      group2 = outcome_group_model(title: 'outcome group 2', context: @course)

      get outcome_url
      wait_for_ajaximations

      f(".outcomes-sidebar .outcome-group[data-id = '#{group1.id}']").click
      wait_for_ajaximations

      goto_account_default_outcomes

      f(".ellipsis[title='outcome 0']").click
      wait_for_ajaximations

      f('.ui-dialog-buttonpane .btn-primary').click
      alert = driver.switch_to.alert
      expect(alert.text).to include "outcome group 1"
      alert.dismiss

      f('.ui-dialog-buttonpane .ui-button').click
      f(".outcomes-sidebar .outcome-group[data-id = '#{group2.id}']").click
      wait_for_ajaximations

      goto_account_default_outcomes

      f(".ellipsis[title='outcome 0']").click
      wait_for_ajaximations

      f('.ui-dialog-buttonpane .btn-primary').click
      alert = driver.switch_to.alert
      expect(alert.text).to include "outcome group 2"
      alert.dismiss
    end
  end

  context "bulk groups and outcomes" do
    before(:each) do
      course_with_teacher_logged_in
    end

    it "should load groups and then outcomes" do
      num = 2
      course_bulk_outcome_groups_course(num, num)
      course_outcome(num)
      get outcome_url
      levels = ff(".outcome-level li")
      expect(levels.first).to have_class("outcome-group")
      expect(levels.last).to have_class("outcome-link")
    end

    it "should be able to display 20 groups" do
      num = 20
      course_bulk_outcome_groups_course(num, num)
      get outcome_url
      expect(ff(".outcome-group")).to have_size 20
    end

    it "should be able to display 20 nested outcomes" do
      num = 20
      course_bulk_outcome_groups_course(num, num)
      get outcome_url

      f(".outcome-group").click
      expect(ff(".outcome-link")).to have_size 20
    end

    context "instructions" do
      it "should display outcome instructions" do
        course_bulk_outcome_groups_course(2, 2)
        get outcome_url
        wait_for_ajaximations
        expect(ff('.outcomes-content').first.text).to include "Setting up Outcomes"
      end
    end
  end

  context "moving outcomes tree" do
    before (:each) do
      course_with_teacher_logged_in
      who_to_login == 'teacher' ? @context = @course : @context = account
    end

    it "should alert user if attempting to move with no directory selected" do
      outcome_model
      get outcome_url
      wait_for_ajaximations

      fj('.outcomes-sidebar .outcome-link').click
      wait_for_ajaximations

      # bring up modal
      f(".move_button").click()
      wait_for_ajaximations

      fj('.form-controls .btn-primary').click
      wait_for_ajaximations

      expect(f('.ic-flash-error').text).to include "No directory is selected, please select a directory before clicking 'move'"
    end

    it "should move a learning outcome via tree modal" do
      outcome = outcome_model
      group = outcome_group_model
      get outcome_url
      f('.outcomes-sidebar .outcome-link').click

      f(".move_button").click()

      # should show modal tree
      expect(fj('.ui-dialog-titlebar span').text).to eq "Where would you like to move first new outcome?"
      expect(ffj('.ui-dialog-content').length).to eq 1

      # move the outcome
      f('.treeLabel').click
      expect(ff('[role=treeitem] a span')).to have_size(2)
      ff('[role=treeitem] a span')[1].click
      f('.form-controls .btn-primary').click

      expect_flash_message :success, "Successfully moved #{outcome.title} to #{group.title}"
      dismiss_flash_messages # so they don't interfere with subsequent clicks

      scroll_page_to_top
      # check for proper updates in outcome group columns on page
      fj('.outcomes-sidebar .outcome-level:first a').click
      expect(ffj('.outcomes-sidebar .outcome-level:first li').length).to eq 1
      expect(ffj('.outcomes-sidebar .outcome-level:last li').length).to eq 1

      # confirm move in db
      expect(LearningOutcomeGroup.where(id: @outcome_group).first.child_outcome_links.first.content.id).to eq @outcome.id

      #confirm that error appears if moving into parent group it already belongs to
      f('.outcomes-sidebar .outcome-link').click
      f(".move_button").click()

      f('.treeLabel').click
      wait_for_ajaximations

      ff('[role=treeitem] a span')[1].click
      f('.form-controls .btn-primary').click

      expect(f('.ic-flash-error').text).to include "first new outcome is already located in new outcome group"
    end

    it "should move a learning outcome group via tree modal" do
      group1 = outcome_group_model(title: 'outcome group 1')
      group2 = outcome_group_model(title: 'outcome group 2')
      get outcome_url
      wait_for_ajaximations

      f(".outcomes-sidebar .outcome-group[data-id = '#{group1.id}']").click
      wait_for_ajaximations

      # bring up modal
      f(".move_button").click()
      wait_for_ajaximations

      # should show modal tree
      expect(fj('.ui-dialog-titlebar span').text).to eq "Where would you like to move #{group1.title}?"
      expect(ffj('.ui-dialog-content').length).to eq 1

      # move the outcome group
      f('.treeLabel').click
      wait_for_ajaximations
      f("[role=treeitem][data-id='#{group2.id}'] a span").click
      wait_for_ajaximations
      f('.form-controls .btn-primary').click

      expect_flash_message :success, "Successfully moved #{group1.title} to #{group2.title}"
      dismiss_flash_messages # so they don't interfere with subsequent clicks

      # check for proper updates in outcome group columns on page
      fj('.outcomes-sidebar .outcome-level:first li').click
      wait_for_ajaximations
      expect(ffj('.outcomes-sidebar .outcome-level:first li').length).to eq 1
      expect(ffj('.outcomes-sidebar .outcome-level:last li').length).to eq 1

      # confirm move in db
      group2.reload
      expect(group2.child_outcome_groups.first.id).to eq group1.id

      # check that modal window properly updated
      fj('.outcomes-sidebar .outcome-group').click
      wait_for_ajaximations

      f(".move_button").click()
      wait_for_ajaximations

      fj('.treeLabel').click
      wait_for_ajaximations

      ff('[role=treeitem] a span')[1].click
      wait_for_ajaximations

      expect(ff('[role=treeitem]')[1].find_elements(:class, "treeLabel").length).to eq 2
    end
  end
end
