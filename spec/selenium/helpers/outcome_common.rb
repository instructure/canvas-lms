require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')


#when 'teacher'; course_with_teacher_logged_in
#when 'student'; course_with_student_logged_in
#when 'admin';   course_with_admin_logged_in


def import_account_level_outcomes
  keep_trying_until do
    f(".btn-primary").click
    driver.switch_to.alert.should_not be nil
    driver.switch_to.alert.accept
    wait_for_ajaximations
    true
  end
end

def traverse_nested_outcomes(outcome)
  #pass an array with each group or outcome in sequence
  outcome.each do |title|
    ffj(".outcome-level:last .outcome-group .ellipsis")[0].should have_attribute("title", title)
    f(".ellipsis[title='#{title}']").click
    wait_for_ajaximations
  end
end

def goto_state_outcomes
  get outcome_url
  wait_for_ajaximations
  f('.find_outcome').click
  wait_for_ajaximations
  ff(".outcome-level .outcome-group").last.click
  wait_for_ajaximations
end

def state_outcome_setup
  @cm.export_content
  run_jobs
  @cm.reload
  @cm.old_warnings_format.should == []
  @cm.migration_settings[:last_error].should be_nil
  @cm.workflow_state.should == 'imported'
end

def context_outcome(context, num_of_outcomes)
  num_of_outcomes.times do |o|
    @outcome_group ||= context.root_outcome_group
    @outcome = context.created_learning_outcomes.create!(:title => "outcome #{o}")
    @outcome.rubric_criterion = valid_outcome_data
    @outcome.save!
    @outcome_group.add_outcome(@outcome)
    @outcome_group.save!
  end
end

def create_bulk_outcomes_groups(context, num_of_groups, num_of_outcomes)
  @root = context.root_outcome_group
  num_of_groups.times do |g|
    @group = context.learning_outcome_groups.create!(:title => "group #{g}")
    num_of_outcomes.times do |o|
      @outcome = context.created_learning_outcomes.create!(:title => "outcome #{o}")
      @group.add_outcome(@outcome)
    end
    @root.adopt_outcome_group(@group)
  end
end

def valid_outcome_data
  {
      :mastery_points => 3,
      :ratings => [
          {:points => 3, :description => "Rockin"},
          {:points => 0, :description => "Lame"}
      ]
  }
end

def course_bulk_outcome_groups_course(num_of_groups, num_of_outcomes)
  create_bulk_outcomes_groups(@course, num_of_groups, num_of_outcomes)
end

def course_bulk_outcome_groups_account(num_of_groups, num_of_outcomes)
  create_bulk_outcomes_groups(@account, num_of_groups, num_of_outcomes)
end

def course_outcome(num_of_outcomes)
  context_outcome(@course, num_of_outcomes)
end

def account_outcome(num_of_outcomes)
  context_outcome(@account, num_of_outcomes)
end

def should_create_a_learning_outcome_with_a_new_rating_root_level
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
  driver.execute_script("$('.submit_button').click()")
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
  LearningOutcome.where(short_description: outcome_name).first.should be_present
end

def should_create_a_learning_outcome_nested
  get outcome_url
  wait_for_ajaximations

  ## when
  # create group
  f('.add_outcome_group').click
  group_title = 'my group'
  replace_content f('.outcomes-content input[name=title]'), group_title
  # submit
  driver.execute_script("$('.submit_button').click()")
  wait_for_ajaximations

  # create outcome
  f('.add_outcome_link').click
  wait_for_ajaximations
  outcome_name = 'first new outcome'
  replace_content(f('.outcomes-content input[name=title]'), outcome_name)

  # submit
  f('.submit_button').click
  wait_for_ajaximations
  refresh_page

  #select group
  f('.outcome-group').click
  wait_for_ajaximations
  #select nested outcome
  f('.outcome-link').click
  wait_for_ajaximations

  ## expect
  # should show up in nested directory browser
  ffj('.outcomes-sidebar .outcome-level:eq(1) li.outcome-link').
      detect { |li| li.text == outcome_name }.should_not be_nil
  # should show outcome in main content window
  f(".outcomes-content .title").text.should == outcome_name
  # db
  LearningOutcome.where(short_description: outcome_name).first.should be_present
end

def should_edit_a_learning_outcome_and_delete_a_rating
  edited_title = 'edit outcome'
  who_to_login == 'teacher' ? @context = @course : @context = account
  outcome_model
  get outcome_url

  fj('.outcomes-sidebar .outcome-level:first li').click
  wait_for_ajaximations
  driver.execute_script("$('.edit_button').click()")

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
  driver.execute_script "$('.submit_button').click()"
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
  LearningOutcome.where(short_description: edited_title).first.should be_present
end

def should_delete_a_learning_outcome
  who_to_login == 'teacher' ? @context = @course : @context = account
  outcome_model
  get outcome_url
  fj('.outcomes-sidebar .outcome-level:first li').click
  wait_for_ajaximations

  ## when
  # delete the outcome
  driver.execute_script("$('.delete_button').click()")
  driver.switch_to.alert.accept
  wait_for_ajaximations

  ## expect
  # should not be showing on page
  ffj('.outcomes-sidebar .outcome-level:first li').should be_empty
  f('.outcomes-content .title').text.should == 'Setting up Outcomes'
  # db
  LearningOutcome.where(id: @outcome).first.workflow_state.should == 'deleted'
  refresh_page # to make sure it was correctly deleted
  ff('.learning_outcome').each { |outcome_element| outcome_element.should_not be_displayed }
end

def should_validate_mastery_points
  get outcome_url
  f('.add_outcome_link').click

  ## when
  # not in ratings
  replace_content f('input[name="mastery_points"]'), '-1'
  # submit
  driver.execute_script("$('.submit_button').click()")
  wait_for_ajaximations

  ## expect
  f('.error_box').should be_present
end

def should_validate_short_description_presence
  get outcome_url
  wait_for_ajaximations
  f('.add_outcome_link').click
  # Submit outcome with an empty title
  f('.outcome_title').clear
  f('.submit_button').click
  wait_for_ajaximations
  fj('.error_text div').text.should == "Cannot be blank"
end

def should_validate_short_description_length
  get outcome_url
  wait_for_ajaximations
  f('.add_outcome_link').click
  content = ('Wee taco banana hello 255 characters exceeded' * 10)
  replace_content f('.outcome_title'), (content)
  f('.submit_button').click
  wait_for_ajaximations
  fj('.error_text').should be_present
end

def should_create_an_outcome_group_root_level
  get outcome_url

  ## when
  # create group
  f('.add_outcome_group').click
  group_title = 'my group'
  replace_content f('.outcomes-content input[name=title]'), group_title
  # submit
  driver.execute_script("$('.submit_button').click()")
  wait_for_ajaximations

  ## expect
  # should show up in directory browser
  ffj('.outcomes-sidebar .outcome-level:first li').detect { |li| li.text == group_title }.should_not be_nil
  # should show outcome in main content window
  # title
  f(".outcomes-content .title").text.should == group_title
  # db
  LearningOutcomeGroup.where(title: group_title).first.should be_present
end

def should_create_a_learning_outcome_with_a_new_rating_nested
  get outcome_url

  ## when
  # create group
  f('.add_outcome_group').click
  group_title = 'my group'
  replace_content f('.outcomes-content input[name=title]'), group_title
  # submit
  driver.execute_script("$('.submit_button').click()")
  wait_for_ajaximations

  # create nested group
  f('.add_outcome_group').click
  nested_group_title = 'my nested group'
  replace_content f('.outcomes-content input[name=title]'), nested_group_title
  # submit
  driver.execute_script("$('.submit_button').click()")
  if !f('.submit_button').nil?
    driver.execute_script("$('.submit_button').click()")
  end
  refresh_page

  #select group
  fj('.outcome-level:eq(0) .outcome-group').click
  wait_for_ajaximations

  #select nested group
  fj('.outcome-level:eq(1) .outcome-group').click
  wait_for_ajaximations

  ## expect
  # should show up in nested directory browser
  ffj('.outcomes-sidebar .outcome-level:eq(1) li.outcome-group').
      detect { |li| li.text == nested_group_title }.should_not be_nil
  # should show group in main content window
  f(".outcomes-content .title").text.should == nested_group_title
  # db
  LearningOutcomeGroup.where(title: nested_group_title).first.should be_present
end

def should_edit_an_outcome_group
  edited_title = 'edited group'
  who_to_login == 'teacher' ? @context = @course : @context = account
  outcome_group_model
  get outcome_url


  fj('.outcomes-sidebar .outcome-level:first li.outcome-group').click
  wait_for_ajaximations

  keep_trying_until do
    driver.execute_script("$('.edit_button').click()")
    fj('.outcomes-content input[name=title]').should be_displayed
  end

  replace_content f('.outcomes-content input[name=title]'), edited_title
  driver.execute_script("$('.submit_button').click()")
  wait_for_ajaximations

  ## expect
  # should be edited in directory browser
  ffj('.outcomes-sidebar .outcome-level:first li').detect { |li| li.text == edited_title }.should_not be_nil
  # title
  f(".outcomes-content .title").text.should == edited_title
  # db
  LearningOutcomeGroup.where(title: edited_title).first.should be_present
end

def should_delete_an_outcome_group
  who_to_login == 'teacher' ? @context = @course : @context = account
  outcome_group_model
  get outcome_url
  fj('.outcomes-sidebar .outcome-level:first li.outcome-group').click
  wait_for_ajaximations
  ## when
  # delete the outcome

  driver.execute_script("$('.delete_button').click()")
  driver.switch_to.alert.accept
  wait_for_ajaximations

  ## expect
  # should not be showing on page
  ffj('.outcomes-sidebar .outcome-level:first li').should be_empty
  fj('.outcomes-content .title').text.should == "Setting up Outcomes"
  # db
  LearningOutcomeGroup.where(id: @outcome_group).first.workflow_state.should == 'deleted'
  refresh_page # to make sure it was correctly deleted
  ffj('.learning_outcome').each { |outcome_element| outcome_element.should_not be_displayed }
end
