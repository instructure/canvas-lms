shared_examples_for "manage groups selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  def add_category(course, name, opts={})
    driver.find_element(:css, ".add_category_link").click
    form = driver.find_element(:css, "#add_category_form")
    input = form.find_element(:css, "input[type=text]")
    replace_content input, name
    enable_self_signup = form.find_element(:css, "#category_enable_self_signup")
    enable_self_signup.click unless !!enable_self_signup.attribute('checked') == !!opts[:enable_self_signup]

    restrict_self_signup = form.find_element(:css, "#category_restrict_self_signup")
    restrict_self_signup.click unless !!restrict_self_signup.attribute('checked') == !!opts[:restrict_self_signup]
    if opts[:group_count]
      if enable_self_signup.attribute('checked')
        replace_content form.find_element(:css, "#category_create_group_count"), opts[:group_count].to_s
      else
        form.find_element(:css, "#category_split_groups").click
        replace_content form.find_element(:css, "#category_split_group_count"), (opts[:group_count].to_s)
      end
    elsif enable_self_signup.attribute('checked')
      form.find_element(:css, "#category_create_group_count").clear
    else
      form.find_element(:css, "#category_no_groups").click
    end
    submit_form(form)
    keep_trying_until { find_with_jquery("#add_category_form:visible").should be_nil }
    category = course.group_categories.find_by_name(name)
    category.should_not be_nil
    category
  end

  def edit_category(opts={})
    find_with_jquery(".edit_category_link:visible").click
    form = driver.find_element(:css, "#edit_category_form")
    input_box = form.find_element(:css, "input[type=text]")
    if opts[:new_name]
      replace_content input_bopts[:new_name]
    end

    # click only if we're requesting a different state than current; if we're not
    # specifying a state, leave as is
    if opts.has_key?(:enable_self_signup)
      enable_self_signup = form.find_element(:css, "#category_enable_self_signup")
      enable_self_signup.click unless !!enable_self_signup.attribute('checked') == !!opts[:enable_self_signup]
    end

    if opts.has_key?(:restrict_self_signup)
      restrict_self_signup = form.find_element(:css, "#category_restrict_self_signup")
      restrict_self_signup.click unless !!restrict_self_signup.attribute('checked') == !!opts[:restrict_self_signup]
    end
    submit_form(form)
    wait_for_ajaximations
  end

  def groups_student_enrollment(student_count=3, opts={})
    students = []
    student_count.times do |i|
      count = i+1
      student = user_model :name => "student #{count}"
      students.push student
      if (!opts[count.to_s].nil?)
        @course.enroll_student(student, opts[count.to_s])
      else
        @course.enroll_student(student)
      end
    end
    students
  end

  def create_new_set_groups(context, *category_groups)
    category_groups.each_with_index { |cg, i| context.groups.create(:name => "Group #{i}", :group_category => cg) }
  end

  def create_categories(context, i=3)
    categories = []
    i.times { |j| categories.push context.group_categories.create(:name => "Group Category #{j}") }
    categories
  end

  def add_group_to_category(context, name)

    find_with_jquery(".add_group_link:visible").click
    driver.find_element(:css, "#group_name").send_keys(name)
    submit_form("#edit_group_form")
    wait_for_ajaximations
    group = context.groups.find_by_name(name)
    group.should_not be_nil
    group
  end

  def add_groups_in_category (category, i=3)
    groups = []
    i.times { |j| groups.push category.context.groups.create(:name => "group #{j}", :group_category => category) }
    groups
  end

  def simulate_group_drag(user_id, from_group_id, to_group_id)
    from_group = (from_group_id == "blank" ? ".group_blank:visible" : "#group_#{from_group_id}")
    to_group = (to_group_id == "blank" ? ".group_blank:visible" : "#group_#{to_group_id}")
    driver.execute_script(<<-SCRIPT)
        window.contextGroups.moveToGroup(
          $('#{from_group} .user_id_#{user_id}'),
          $('#{to_group}'))
    SCRIPT
  end

end