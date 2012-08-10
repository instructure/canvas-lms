shared_examples_for "permission tests" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_admin_logged_in
  end

  def has_default_permission?(permission, enrollment_type)
    default_permissions = Permissions.retrieve
    default_permissions[permission][:true_for].include?(enrollment_type)
  end

  def get_updated_role(permission, enrollment_type)
    RoleOverride.first(:conditions => {:permission => permission.to_s, :enrollment_type => enrollment_type})
  end

  def get_checkbox(permission, selector, enrollment_type)
    row = nil
    permissions = ff("#permissions-table tr > th")
    permissions.each do |elem|
      if (elem.text.include? permission)
        row = elem.find_element(:xpath, "..")
        break
      end
    end
    #enrollment type is the number corresponding to the role i.e. Student = 0, Ta = 1, Teacher = 2...
    row.find_elements(:css, selector)[enrollment_type]
  end

  def checkbox_verifier(permission, enrollment_type, disable_permission = false, locked = false)
    selector = locked ? ".lock" : ".six-checkbox"
    #get the element we need
    check_box = get_checkbox(permission, selector, enrollment_type)
    #we iterate according to the permission event
    iterate = disable_permission ? 2 : 1
    iterate.times { check_box.click }
    f(".save_permissions_changes").click
    wait_for_ajax_requests
    check_box = get_checkbox(permission, selector, enrollment_type)
    if (locked)
      check_box.find_element(:xpath, "..").find_element(:css, "input").should have_value("true")
    else
      if (disable_permission)
        check_box.find_element(:css, "input").should have_value("unchecked")
      else
        check_box.find_element(:css, "input").should have_value("checked")
      end
    end
  end

  def permissions_verifier(opts, default_permitted = false, disable_permission = false, locked = false)
    if (default_permitted)
      has_default_permission?(opts.keys[0], opts.values[0]).should be_true
    else
      has_default_permission?(opts.keys[0], opts.values[0]).should be_false
    end
    role = get_updated_role(opts.keys[0], opts.values[0])
    role.should be_present
    if (disable_permission)
      role.enabled.should be_false
    else
      if (!locked)
        role.enabled.should be_true
      end
    end
    if (locked)
      role.locked.should be_true
    else
      role.locked.should be_false
    end
  end

  describe "new role permissions" do
    before (:each) do
      get url
    end

    def add_new_role(role)
      f(".add_new_role").send_keys(role)
      f("#add_new_role_button").click
      wait_for_ajax_requests
      account.reload
      account.membership_types.should include(role)
      f("#permissions-table tr").should include_text(role)
    end

    it "should add a new account role type" do
      role = "New Role"
      add_new_role(role)
    end

    it "should delete an added role" do
      role = "New Role"
      add_new_role(role)
      f(".remove_role_link").click
      driver.switch_to.alert.accept
      wait_for_ajax_requests
      account.reload
      account.membership_types.should_not include(role)
      f("#permissions-table tr").should_not include_text(role)
    end

    it "should enable manage permissions of new role" do
      role = "New Role"
      add_new_role(role)
      checkbox_verifier("Manage permissions", 1)
      opts = {:manage_role_overrides => role}
      permissions_verifier(opts)
    end

    it "should disable manage permissions of new role" do
      role = "New Role"
      add_new_role(role)
      checkbox_verifier("Manage permissions", 1, true)
      opts = {:manage_role_overrides => role}
      permissions_verifier(opts, false, true)
    end

    it "should lock manage permissions of new role" do
      role = "New Role"
      add_new_role(role)
      checkbox_verifier("Manage permissions", 1, false, true)
      opts = {:manage_role_overrides => role}
      permissions_verifier(opts, false, false, true)
    end
  end
end