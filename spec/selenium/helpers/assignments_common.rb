require File.expand_path(File.dirname(__FILE__) + '/../common')



def build_assignment_with_type(type, opts={})
  if opts[:assignment_group_id]
    assignment_group_id = opts[:assignment_group_id]
  else
    assignment_group = @course.assignment_groups.first!
    assignment_group_id = assignment_group.id
  end

  f("#assignment_group_#{assignment_group_id} .add_assignment").click
  click_option(f("#ag_#{assignment_group_id}_assignment_type"), type)

  if opts[:name]
    f("#ag_#{assignment_group_id}_assignment_name").clear
    f("#ag_#{assignment_group_id}_assignment_name").send_keys opts[:name]
  end
  if opts[:points]
    f("#ag_#{assignment_group_id}_assignment_points").clear
    f("#ag_#{assignment_group_id}_assignment_points").send_keys opts[:points]
  end
  if opts[:due_at]
    f("#ag_#{assignment_group_id}_assignment_due_at").clear
    f("#ag_#{assignment_group_id}_assignment_due_at").send_keys opts[:due_at]
  end
  if opts[:submit]
    fj(".create_assignment:visible").click
    wait_for_ajaximations
  end
  if opts[:more_options]
    fj('.more_options:visible').click
    wait_for_ajaximations
  end
end

def edit_assignment(assignment_id, opts={})
  f("#assignment_#{assignment_id} .al-trigger").click
  f("#assignment_#{assignment_id} .edit_assignment").click

  if opts[:name]
    f("#assign_#{assignment_id}_assignment_name").clear
    f("#assign_#{assignment_id}_assignment_name").send_keys opts[:name]
  end
  if opts[:points]
    f("#assign_#{assignment_id}_assignment_points").clear
    f("#assign_#{assignment_id}_assignment_points").send_keys opts[:points]
  end
  if opts[:due_at]
    f("#assign_#{assignment_id}_assignment_due_at").clear
    f("#assign_#{assignment_id}_assignment_due_at").send_keys opts[:due_at]
  end
  if opts[:submit]
    fj(".create_assignment:visible").click
    wait_for_ajaximations
  end
  if opts[:more_options]
    fj('.more_options:visible').click
    wait_for_ajaximations
  end
end

def edit_assignment_group(assignment_group_id)
  f("#assignment_group_#{assignment_group_id} .al-trigger").click
  f("#assignment_group_#{assignment_group_id} .edit_group").click
  wait_for_ajaximations
end

def delete_assignment_group(assignment_group_id, opts={})
  f("#assignment_group_#{assignment_group_id} .al-trigger").click
  f("#assignment_group_#{assignment_group_id} .delete_group").click
  unless opts[:no_accept]
    accept_alert
    wait_for_ajaximations
  end
end

def submit_assignment_form
  expect_new_page_load { f('.btn-primary[type=submit]').click }
  wait_for_ajaximations
end

def stub_freezer_plugin(frozen_atts = nil)
  frozen_atts ||= {
      "assignment_group_id" => "true"
  }
  PluginSetting.stubs(:settings_for_plugin).returns(frozen_atts)
end

def frozen_assignment(group)
  group ||= @course.assignment_groups.first
  assign = @course.assignments.create!(
      :name => "frozen",
      :due_at => Time.now.utc + 2.days,
      :assignment_group => group,
      :freeze_on_copy => true
  )
  assign.copied = true
  assign.save!
  assign
end

def run_assignment_edit(assignment)
  get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"

  yield

  submit_assignment_form
end

def manually_create_assignment(assignment_title = 'new assignment')
  get "/courses/#{@course.id}/assignments"
  expect_new_page_load { f('.new_assignment').click }
  replace_content(f('#assignment_name'), assignment_title)
end

def click_away_accept_alert
  f('#section-tabs .home').click
  driver.switch_to.alert.accept
end