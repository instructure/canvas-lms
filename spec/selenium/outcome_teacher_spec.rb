require File.expand_path(File.dirname(__FILE__) + '/helpers/outcome_common')

describe "outcomes as a teacher" do
  include_examples "in-process server selenium tests"
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

    context "find/import dialog" do
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
      wait_for_ajaximations
      keep_trying_until do
        expect(ff(".outcome-level li").first).to have_class("outcome-group")
        expect(ff(".outcome-level li").last).to have_class("outcome-link")
      end
    end

    it "should display 20 initial groups" do
      num = 21
      course_bulk_outcome_groups_course(num, num)
      get outcome_url
      wait_for_ajaximations
      keep_trying_until { expect(ff(".outcome-group").count).to eq 20 }
    end

    it "should display 20 initial associated outcomes in nested group" do
      num = 21
      course_bulk_outcome_groups_course(num, num)
      get outcome_url
      ff(".outcome-group")[0].click
      wait_for_ajaximations
      keep_trying_until { expect(ff(".outcome-link").length).to eq 20 }
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
      wait_for_ajaximations

      fj('.outcomes-sidebar .outcome-link').click
      wait_for_ajaximations

      f(".move_button").click()
      wait_for_ajaximations

      # should show modal tree
      expect(fj('.ui-dialog-titlebar span').text).to eq "Where would you like to move first new outcome?"
      expect(ffj('.ui-dialog-content').length).to eq 1

      # move the outcome
      fj('.treeLabel').click
      wait_for_ajaximations
      ff('[role=treeitem] a span')[1].click
      wait_for_ajaximations
      fj('.form-controls .btn-primary').click
      wait_for_ajaximations

      keep_trying_until do
        message = f('.ic-flash-success').text
        expect(message).to include "Successfully moved #{outcome.title} to #{group.title}"
      end


      # check for proper updates in outcome group columns on page
      fj('.outcomes-sidebar .outcome-level:first li').click
      wait_for_ajaximations
      expect(ffj('.outcomes-sidebar .outcome-level:first li').length).to eq 1
      expect(ffj('.outcomes-sidebar .outcome-level:last li').length).to eq 1

      # confirm move in db
      expect(LearningOutcomeGroup.where(id: @outcome_group).first.child_outcome_links.first.content.id).to eq @outcome.id

      #confirm that error appears if moving into parent group it already belongs to
      fj('.outcomes-sidebar .outcome-link').click
      wait_for_ajaximations
      f(".move_button").click()
      wait_for_ajaximations

      fj('.treeLabel').click
      wait_for_ajaximations

      ff('[role=treeitem] a span')[1].click
      fj('.form-controls .btn-primary').click
      wait_for_ajaximations

      expect(f('.ic-flash-error').text).to include "first new outcome is already located in new outcome group"
    end

    it "should move a learning outcome group via tree modal" do
      group1 = outcome_group_model
      group2 = outcome_group_model
      get outcome_url
      wait_for_ajaximations

      fj('.outcomes-sidebar .outcome-group:last').click
      wait_for_ajaximations

      # bring up modal
      f(".move_button").click()
      wait_for_ajaximations

      # should show modal tree
      expect(fj('.ui-dialog-titlebar span').text).to eq "Where would you like to move new outcome group?"
      expect(ffj('.ui-dialog-content').length).to eq 1

      # move the outcome group
      fj('.treeLabel').click
      wait_for_ajaximations
      ff('[role=treeitem] a span')[1].click
      wait_for_ajaximations
      fj('.form-controls .btn-primary').click
      wait_for_ajaximations

      keep_trying_until do
        message = f('.ic-flash-success').text
        expect(message).to include "Successfully moved #{group1.title} to #{group2.title}"
      end

      # check for proper updates in outcome group columns on page
      fj('.outcomes-sidebar .outcome-level:first li').click
      wait_for_ajaximations
      expect(ffj('.outcomes-sidebar .outcome-level:first li').length).to eq 1
      expect(ffj('.outcomes-sidebar .outcome-level:last li').length).to eq 1

      # confirm move in db
      expect(LearningOutcomeGroup.where(id: group2.id).first.child_outcome_groups.first.id).to eq group1.id

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