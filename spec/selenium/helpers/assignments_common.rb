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

