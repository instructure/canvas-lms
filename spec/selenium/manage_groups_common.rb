shared_examples_for "manage groups selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  def add_category(course, name, opts={})
    driver.find_element(:css, ".add_category_link").click
    form = driver.find_element(:css, "#add_category_form")

    form.find_element(:css, "input[type=text]").clear
    form.find_element(:css, "input[type=text]").send_keys(name)

    enable_self_signup = form.find_element(:css, "#category_enable_self_signup")
    enable_self_signup.click unless !!enable_self_signup.attribute('checked') == !!opts[:enable_self_signup]

    restrict_self_signup = form.find_element(:css, "#category_restrict_self_signup")
    restrict_self_signup.click unless !!restrict_self_signup.attribute('checked') == !!opts[:restrict_self_signup]

    if opts[:group_count]
      if enable_self_signup.attribute('checked')
        form.find_element(:css, "#category_create_group_count").clear
        form.find_element(:css, "#category_create_group_count").send_keys(opts[:group_count].to_s)
      else
        form.find_element(:css, "#category_split_groups").click
        form.find_element(:css, "#category_split_group_count").clear
        form.find_element(:css, "#category_split_group_count").send_keys(opts[:group_count].to_s)
      end
    elsif enable_self_signup.attribute('checked')
      form.find_element(:css, "#category_create_group_count").clear
    else
      form.find_element(:css, "#category_no_groups").click
    end

    form.submit
    keep_trying_until { find_with_jquery("#add_category_form:visible").should be_nil }

    category = course.group_categories.find_by_name(name)
    category.should_not be_nil
    category
  end

  def edit_category(opts={})
    find_with_jquery(".edit_category_link:visible").click
    form = driver.find_element(:css, "#edit_category_form")

    if opts[:new_name]
      form.find_element(:css, "input[type=text]").clear
      form.find_element(:css, "input[type=text]").send_keys(opts[:new_name])
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

    form.submit
    wait_for_ajaximations
  end
end