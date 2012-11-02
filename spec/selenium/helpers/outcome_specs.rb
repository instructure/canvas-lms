require File.expand_path(File.dirname(__FILE__) + '/../common')

shared_examples_for "outcome tests" do
  it_should_behave_like "in-process server selenium tests"
  before (:each) do
    who_to_login == 'teacher' ? course_with_teacher_logged_in : course_with_admin_logged_in
  end

  describe "create/edit/delete outcomes" do

    it "should create a learning outcome with a new rating (root level)" do
      get outcome_url
      wait_for_ajaximations

      ## when
      # create outcome
      f('.add_outcome_link').click
      outcome_name = 'first new outcome'
      outcome_description = 'new learning outcome'
      replace_content f('.outcomes-content input[name=title]'), outcome_name
      type_in_tiny '.outcomes-content textarea[name=description]', outcome_description
      # add a new rating
      f('.insert_rating').click
      f('input[name="ratings[1][description]"]').send_keys('almost exceeds')
      f('input[name="ratings[1][points]"]').send_keys('4')
      # submit
      f('.submit_button').click
      wait_for_ajaximations

      ## expect
      # should show up in directory browser
      ffj('.outcomes-sidebar .outcome-level:first li.outcome-link').
        detect { |li| li.text == outcome_name }.should_not be_nil
      # should show outcome in main content window
      # title
      f(".outcomes-content .title").text.should == outcome_name
      # description
      f(".outcomes-content .description").text.should == outcome_description
      # ratings
      ratings = ffj('table.criterion .rating')
      ratings.size.should == 4
      ratings.map { |r| r.text }.should == ["Exceeds Expectations\n5 Points",
                                            "almost exceeds\n4 Points",
                                            "Meets Expectations\n3 Points",
                                            "Does Not Meet Expectations\n0 Points"]
      f('table.criterion .total').text.should == "Total Points\n5 Points"
      # db
      LearningOutcome.find_by_short_description(outcome_name).should be_present
    end

    it "should create a learning outcome (nested)" do
      get outcome_url
      wait_for_ajaximations

      ## when
      # create group
      f('.add_outcome_group').click
      group_title = 'my group'
      replace_content f('.outcomes-content input[name=title]'), group_title
      # submit
      f('.submit_button').click
      wait_for_ajaximations

      # create outcome
      f('.add_outcome_link').click
      wait_for_ajaximations
      outcome_name = 'first new outcome'
      replace_content f('.outcomes-content input[name=title]'), outcome_name

      # submit
      f('.submit_button').click
      wait_for_ajaximations

      ## expect
      # should show up in nested directory browser
      ffj('.outcomes-sidebar .outcome-level:eq(1) li.outcome-link').
        detect { |li| li.text == outcome_name }.should_not be_nil
      # should show outcome in main content window
      f(".outcomes-content .title").text.should == outcome_name
      # db
      LearningOutcome.find_by_short_description(outcome_name).should be_present
    end

    it "should edit a learning outcome and delete a rating" do
      edited_title = 'edit outcome'
      who_to_login == 'teacher' ? @context = @course : @context = account
      outcome_model
      get outcome_url
      wait_for_ajaximations
      fj('.outcomes-sidebar .outcome-level:first li').click
      f('.edit_button').click

      ## when
      # edit title
      replace_content f('.outcomes-content input[name=title]'), edited_title
      # delete a rating
      f('.edit_rating').click
      f('.delete_rating_link').click
      # edit a rating
      f('.edit_rating').click
      replace_content f('input[name="ratings[0][points]"]'), '1'
      replace_content f('input[name="mastery_points"]'), '1'
      # submit
      f('.submit_button').click
      wait_for_ajaximations

      ## expect
      # should be edited in directory browser
      ffj('.outcomes-sidebar .outcome-level:first li').detect { |li| li.text == edited_title }.should_not be_nil
      # title
      f(".outcomes-content .title").text.should == edited_title
      # ratings
      ratings = ffj('table.criterion .rating')
      ratings.size.should == 1
      ratings.map { |r| r.text }.should == ["Lame\n1 Points"]
      f('table.criterion .total').text.should == "Total Points\n1 Points"
      # db
      LearningOutcome.find_by_short_description(edited_title).should be_present
    end

    it "should delete a learning outcome" do
      who_to_login == 'teacher' ? @context = @course : @context = account
      outcome_model
      get outcome_url
      wait_for_ajaximations
      fj('.outcomes-sidebar .outcome-level:first li').click

      ## when
      # delete the outcome
      f('.delete_button').click
      driver.switch_to.alert.accept
      wait_for_ajaximations

      ## expect
      # should not be showing on page
      ffj('.outcomes-sidebar .outcome-level:first li').should be_empty
      f('.outcomes-content .title').text.should == 'Setting up Outcomes'
      # db
      LearningOutcome.find_by_id(@outcome.id).workflow_state.should == 'deleted'
      refresh_page # to make sure it was correctly deleted
      ff('.learning_outcome').each { |outcome_element| outcome_element.should_not be_displayed }
    end

    it "should validate mastery points" do
      get outcome_url
      wait_for_ajaximations
      f('.add_outcome_link').click

      ## when
      # not in ratings
      replace_content f('input[name="mastery_points"]'), '-1'
      # submit
      f('.submit_button').click
      wait_for_ajaximations

      ## expect
      f('.error_box').should be_present
    end

  end

  describe "create/edit/delete outcome groups" do

    it "should create an outcome group (root level)" do
      get outcome_url
      wait_for_ajaximations

      ## when
      # create group
      f('.add_outcome_group').click
      group_title = 'my group'
      replace_content f('.outcomes-content input[name=title]'), group_title
      # submit
      f('.submit_button').click
      wait_for_ajaximations

      ## expect
      # should show up in directory browser
      ffj('.outcomes-sidebar .outcome-level:first li').detect { |li| li.text == group_title }.should_not be_nil
      # should show outcome in main content window
      # title
      f(".outcomes-content .title").text.should == group_title
      # db
      LearningOutcomeGroup.find_by_title(group_title).should be_present
    end

    it "should create a learning outcome with a new rating (nested)" do
      get outcome_url
      wait_for_ajaximations

      ## when
      # create group
      f('.add_outcome_group').click
      group_title = 'my group'
      replace_content f('.outcomes-content input[name=title]'), group_title
      # submit
      f('.submit_button').click
      wait_for_ajaximations

      # create nested group
      f('.add_outcome_group').click
      nested_group_title = 'my nested group'
      replace_content f('.outcomes-content input[name=title]'), nested_group_title
      # submit
      f('.submit_button').click
      wait_for_ajaximations

      ## expect
      # should show up in nested directory browser
      ffj('.outcomes-sidebar .outcome-level:eq(1) li.outcome-group').
        detect { |li| li.text == nested_group_title }.should_not be_nil
      # should show group in main content window
      f(".outcomes-content .title").text.should == nested_group_title
      # db
      LearningOutcomeGroup.find_by_title(nested_group_title).should be_present
    end

    it "should edit an outcome group" do
      edited_title = 'edited group'
      who_to_login == 'teacher' ? @context = @course : @context = account
      outcome_group_model
      get outcome_url
      wait_for_ajaximations
      fj('.outcomes-sidebar .outcome-level:first li.outcome-group').click
      f('.edit_button').click

      ## when
      # edit title
      replace_content f('.outcomes-content input[name=title]'), edited_title
      # submit
      f('.submit_button').click
      wait_for_ajaximations

      ## expect
      # should be edited in directory browser
      ffj('.outcomes-sidebar .outcome-level:first li').detect { |li| li.text == edited_title }.should_not be_nil
      # title
      f(".outcomes-content .title").text.should == edited_title
      # db
      LearningOutcomeGroup.find_by_title(edited_title).should be_present
    end

    it "should delete an outcome group" do
      who_to_login == 'teacher' ? @context = @course : @context = account
      outcome_group_model
      get outcome_url
      wait_for_ajaximations
      fj('.outcomes-sidebar .outcome-level:first li.outcome-group').click

      ## when
      # delete the outcome
      f('.delete_button').click
      driver.switch_to.alert.accept
      wait_for_ajaximations

      ## expect
      # should not be showing on page
      ffj('.outcomes-sidebar .outcome-level:first li').should be_empty
      f('.outcomes-content .title').text.should == "Setting up Outcomes"
      # db
      LearningOutcomeGroup.find_by_id(@outcome_group.id).workflow_state.should == 'deleted'
      refresh_page # to make sure it was correctly deleted
      ff('.learning_outcome').each { |outcome_element| outcome_element.should_not be_displayed }
    end

  end
end
