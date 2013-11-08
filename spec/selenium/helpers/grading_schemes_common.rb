def save_and_reload_changes(grading_standard)
  f('.save_button').click
  wait_for_ajax_requests
  grading_standard.reload
end

def should_add_a_grading_scheme
  new_standard_name = 'new grading standard'
  get url
  f('.add_standard_link').click
  f('#grading_standard_new .scheme_name').send_keys(new_standard_name)
  f('.save_button').click
  wait_for_ajax_requests
  new_grading_standard = GradingStandard.last
  new_grading_standard.title.should == new_standard_name
  f("#grading_standard_#{new_grading_standard.id}").should be_displayed
end

def should_edit_a_grading_scheme
  edit_name = 'edited grading scheme'
  grading_standard_for(account)
  get url
  grading_standard = GradingStandard.last

  f('.edit_grading_standard_link').click
  f("#grading_standard_#{grading_standard.id} .scheme_name").send_keys(edit_name)
  save_and_reload_changes(grading_standard)
  grading_standard.title.should == edit_name
  fj("#grading_standard_#{grading_standard.id} .title").text.should == edit_name #fj to avoid selenium caching
end

def should_delete_a_grading_scheme
  grading_standard_for(account)
  get url

  f('.delete_grading_standard_link').click
  driver.switch_to.alert.accept
  wait_for_ajaximations
  GradingStandard.last.workflow_state.should == 'deleted'
end

def should_add_a_grading_scheme_item
  data_count = @grading_standard.data.count
  #grading_standard_rows[1].click
  driver.execute_script("$('.insert_grading_standard_link:eq(2)').hover().click()")

  #ff('.insert_grading_standard_link')[1].click
  replace_content(ff('.editing_box .standard_name')[1], 'F')
  save_and_reload_changes(@grading_standard)
  @grading_standard.data.count.should == data_count + 1
  @grading_standard.data[1][0].should == 'F'
end

def should_edit_a_grading_scheme_item
  replace_content(grading_standard_rows[0].find_element(:css, '.standard_name'), 'F')
  save_and_reload_changes(@grading_standard)
  @grading_standard.data[0][0].should == 'F'
end

def should_delete_a_grading_scheme_item
  data_count = @grading_standard.data.count
  grading_standard_rows[0].find_element(:css, '.delete_row_link').click
  wait_for_ajaximations
  save_and_reload_changes(@grading_standard)
  @grading_standard.data.count.should == data_count - 1
  @grading_standard.data[0][0].should == 'B'
end
