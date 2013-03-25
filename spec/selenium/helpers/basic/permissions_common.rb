  def select_enable(permission_name, role_name)
    permission_button = fj("[data-permission_name='#{permission_name}'].[data-role_name='#{role_name}']")
    permission_button.find_element(:css, "a").click
    options = permission_button.find_elements(:css, ".dropdown-menu label")
    options[0].click # 0 is Enable

    wait_for_ajax_requests #Every select needs to wait for for the request to finish
  end

  def select_enable_and_lock(permission_name, role_name)
    permission_button = fj("[data-permission_name='#{permission_name}'].[data-role_name='#{role_name}']")
    permission_button.find_element(:css, "a").click
    options = permission_button.find_elements(:css, ".dropdown-menu label")
    options[1].click # 1 is enabled and locked

    wait_for_ajax_requests
  end

  def select_disable(permission_name, role_name)
    permission_button = fj("[data-permission_name='#{permission_name}'].[data-role_name='#{role_name}']")
    permission_button.find_element(:css, "a").click
    options = permission_button.find_elements(:css, ".dropdown-menu label")
    options[2].click # 2 is Disabled

    wait_for_ajax_requests
  end

  def select_disable_and_lock(permission_name, role_name)
    permission_button = fj("[data-permission_name='#{permission_name}'].[data-role_name='#{role_name}']")
    permission_button.find_element(:css, "a").click
    options = permission_button.find_elements(:css, ".dropdown-menu label")
    options[3].click # 3 is Disabled and locked

    wait_for_ajax_requests
  end

  def add_new_account_role(role_name)
    role = account.roles.build({:name => role_name})
    role.base_role_type = "AccountMembership"
    role.save!
    role
  end

  def add_new_course_role(role_name, role_type = "StudentEnrollment")
    role = account.roles.build({:name => role_name})
    role.base_role_type = role_type
    role.save!
    role
  end
