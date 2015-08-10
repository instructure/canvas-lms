def save_and_reload_changes(grading_standard)
  f('.save_button').click
  wait_for_ajaximations
  grading_standard.reload
end

def simple_grading_standard(context)
  @standard = context.grading_standards.create!(
    :title => "My Grading Standard",
    :standard_data => {
      "scheme_0" => {:name => "A", :value => "90"},
      "scheme_1" => {:name => "B", :value => "80"},
      "scheme_2" => {:name => "C", :value => "70"}
  })
end

def should_add_a_grading_scheme(options = {name: "new grading standard"})
  new_standard_name = options[:name]
  f('.add_standard_link').click
  expect(f('.add_standard_link')).to have_class('disabled')
  replace_content(f('.scheme_name'), new_standard_name)
  f('.save_button').click
  wait_for_ajax_requests
  @new_grading_standard = GradingStandard.last
  expect(@new_grading_standard.title).to eq new_standard_name
  expect(f("#grading_standard_#{@new_grading_standard.id}")).to be_displayed
end

def should_edit_a_grading_scheme(context, url)
  edit_name = 'edited grading scheme'
  simple_grading_standard(context)
  grading_standard = GradingStandard.last
  get url
  f('.edit_grading_standard_link').click
  replace_content(f('.scheme_name'), edit_name)
  save_and_reload_changes(grading_standard)
  expect(grading_standard.title).to eq edit_name
  expect(fj(".title span:eq(1)").text).to eq edit_name #fj to avoid selenium caching
end

def should_delete_a_grading_scheme(context, url)
  simple_grading_standard(context)
  get url
  f('.delete_grading_standard_link').click
  driver.switch_to.alert.accept
  wait_for_ajaximations
  expect(GradingStandard.last.workflow_state).to eq 'deleted'
end

def create_simple_standard_and_edit(context, url)
  simple_grading_standard(context)
  @grading_standard = GradingStandard.last
  get url
  f('.edit_grading_standard_link').click
end

def should_add_a_grading_scheme_item
  data_count = @grading_standard.data.count
  grading_standard_row = f('.grading_standard_row')
  driver.action.move_to(grading_standard_row).perform
  f('.insert_grading_standard_link').click
  replace_content(ff('.standard_name')[1], 'Z')
  replace_content(ff('.standard_value')[1], '88')
  save_and_reload_changes(@grading_standard)
  expect(@grading_standard.data.count).to eq data_count + 1
  expect(@grading_standard.data[1][0]).to eq 'Z'
  # TODO: check for change in upper limit of next row item
end


def grading_standard_rows
  ff('.grading_standard_row')
end

def should_edit_a_grading_scheme_item
  replace_content(grading_standard_rows[0].find_element(:css, '.standard_name'), 'F')
  save_and_reload_changes(@grading_standard)
  expect(@grading_standard.data[0][0]).to eq 'F'
  # TODO: check that changing lower limit changes upper limit of next row item
end

def should_not_update_invalid_grading_scheme_input
  replace_content(grading_standard_rows[1].find_element(:css, '.standard_value'), '90')
  save_and_reload_changes(@grading_standard)
  expect(f("#invalid_standard_message_#{@grading_standard.id}")).to be_displayed
  expect(@grading_standard.data[1][1]).to eq 0.8
end

def should_delete_a_grading_scheme_item
  data_count = @grading_standard.data.count
  grading_standard_rows[0].find_element(:css, '.delete_row_link').click
  wait_for_ajaximations
  save_and_reload_changes(@grading_standard)
  expect(@grading_standard.data.count).to eq data_count - 1
  expect(@grading_standard.data[0][0]).to eq 'B'
  # TODO: check that changing upped limit of next row item changes to lower limit of line above
end

def should_contain_a_tab_for_grading_schemes_and_periods(url)
  @course.root_account.allow_feature!(:multiple_grading_periods)
  @course.account.enable_feature!(:multiple_grading_periods)
  get url
  expect(f(".grading_periods_tab")).to be_displayed
  f(".grading_periods_tab").click
  expect(f(".new-grading-period")).to be_displayed

  expect(f(".grading_standards_tab")).to be_displayed
  f(".grading_standards_tab").click
  expect(f(".add_standard_link")).to be_displayed
end
