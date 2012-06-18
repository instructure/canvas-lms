require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "admin permissions" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_admin_logged_in
  end

  def has_default_permission? (permission, enrollment_type)
    default_permissions = Permissions.retrieve
    default_permissions[permission][:true_for].include? enrollment_type
  end

  def get_updated_role (permission, enrollment_type)
    RoleOverride.first(:conditions => {:permission => permission.to_s, :enrollment_type => enrollment_type})
  end

  def get_checkbox (permission, selector, enrollment_type)
    row = nil
    permissions = ff("#permissions-table tr > th")
    permissions.each do |elem|
      if (elem.text.include? permission)
        row = elem.find_element(:xpath, "..")
        break
      end
    end
    #enrollment type is the number corresponding to the role i.e. Student = 0, Ta = 1, Teacher = 2...
    element = row.find_elements(:css, selector)[enrollment_type]
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
      check_box.find_element(:xpath, "..").find_element(:css, "input").should have_value "true"
    else
      if (disable_permission)
        check_box.find_element(:css, "input").should have_value "unchecked"
      else
        check_box.find_element(:css, "input").should have_value "checked"
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

  describe "default role permissions" do
    before (:each) do
      get "/accounts/#{Account.default.id}/permissions"
    end

    it "should enable and then disable read sis data for students" do
      checkbox_verifier("Read SIS data", 0)
      opts = {:read_sis => "StudentEnrollment"}
      permissions_verifier(opts)
      check_box = get_checkbox("Read SIS data", ".six-checkbox", 0)
      check_box.click
      f(".save_permissions_changes").click
      wait_for_ajax_requests
      check_box = get_checkbox("Read SIS data", ".six-checkbox", 0)
      check_box.find_element(:css, "input").should have_value "unchecked"
      permissions_verifier(opts, false, true)
    end

    it "should enable read sis data for TAs" do
      checkbox_verifier("Read SIS data", 1)
      opts = {:read_sis => "TaEnrollment"}
      permissions_verifier(opts)
    end

    it "should lock sis data for students" do
      checkbox_verifier("Read SIS data", 0, false, true)
      opts = {:read_sis => "StudentEnrollment"}
      permissions_verifier(opts, false, false, true)
    end

    it "should check that teachers have default read sis data enabled and then disable it" do
      checkbox_verifier("Read SIS data", 2, true)
      opts= {:read_sis => "TeacherEnrollment"}
      permissions_verifier(opts, true, true)
    end

    it "should not enable read sis data for course designer " do
      has_default_permission?(:read_sis, "DesignerEnrollment").should be_false
      designer = get_checkbox("Read SIS data", ".six-checkbox", 3)
      designer.attribute('title').should include_text "you do not have permission"
      designer.click
      f(".save_permissions_changes").click
      wait_for_ajax_requests
      designer_role = get_updated_role :read_sis, "DesignerEnrollment"
      designer_role.should be_nil
      designer = get_checkbox("Read SIS data", ".six-checkbox", 3)
      designer.find_element(:css, "input").should have_value ""
    end

    it "should enable manage wiki for observer" do
      checkbox_verifier("Manage wiki", 4)
      opts = {:manage_wiki => "ObserverEnrollment"}
      permissions_verifier(opts)
    end

    it "should enable view all grades for designer" do
      checkbox_verifier("View all grades", 3)
      opts = {:view_all_grades => "DesignerEnrollment"}
      permissions_verifier(opts)
    end

    it "should navigate to manage account-level roles" do
      f("#course_level_roles").click
      wait_for_ajax_requests
      f("#content h2").should include_text "Account Permissions"
    end
  end

  describe "new role permissions" do
    before (:each) do
      get "/accounts/#{Account.default.id}/permissions?account_roles=1"
    end

    def add_new_role role
      f(".add_new_role").send_keys(role)
      f("#add_new_role_button").click
      wait_for_ajax_requests
      Account.default.account_membership_types.should include role
      f("#permissions-table tr").should include_text role
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
      Account.default.account_membership_types.should_not include role
      f("#permissions-table tr").should_not include_text role
    end

    it "should enable manage permissions of new role" do
      role = "New Role"
      add_new_role(role)
      checkbox_verifier("Manage permissions", 1)
      opts={:manage_role_overrides => role}
      permissions_verifier(opts)
    end

    it "should disable manage permissions of new role" do
      role = "New Role"
      add_new_role(role)
      checkbox_verifier("Manage permissions", 1, true)
      opts={:manage_role_overrides => role}
      permissions_verifier(opts, false, true)
    end

    it "should lock manage permissions of new role" do
      role = "New Role"
      add_new_role(role)
      checkbox_verifier("Manage permissions", 1, false, true)
      opts={:manage_role_overrides => role}
      permissions_verifier(opts, false, false, true)
    end
  end
end
