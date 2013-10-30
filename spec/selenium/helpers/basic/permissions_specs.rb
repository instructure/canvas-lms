shared_examples_for "permission tests" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_admin_logged_in
  end

  def select_enable(permission_name, role_name)
    permission_button = fj("[data-permission_name='#{permission_name}'].[data-role_name='#{role_name}']")
    permission_button.find_element(:css, "a").click
    wait_for_ajaximations
    options = permission_button.find_elements(:css, ".dropdown-menu label")
    options[0].click # 0 is Enable

    wait_for_ajaximations #Every select needs to wait for for the request to finish
  end

  def select_enable_and_lock(permission_name, role_name)
    permission_button = fj("[data-permission_name='#{permission_name}'].[data-role_name='#{role_name}']")
    permission_button.find_element(:css, "a").click
    wait_for_ajaximations
    options = permission_button.find_elements(:css, ".dropdown-menu label")
    options[1].click # 1 is enabled and locked

    wait_for_ajaximations
  end

  def select_disable(permission_name, role_name)
    permission_button = fj("[data-permission_name='#{permission_name}'].[data-role_name='#{role_name}']")
    permission_button.find_element(:css, "a").click
    wait_for_ajaximations
    options = permission_button.find_elements(:css, ".dropdown-menu label")
    debugger
    options[2].click # 2 is Disabled

    wait_for_ajaximations
  end

  def select_disable_and_lock(permission_name, role_name)
    permission_button = fj("[data-permission_name='#{permission_name}'].[data-role_name='#{role_name}']")
    permission_button.find_element(:css, "a").click
    wait_for_ajaximations
    options = permission_button.find_elements(:css, ".dropdown-menu label")
    options[3].click # 3 is Disabled and locked

    wait_for_ajaximations
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

  describe "Adding new roles" do
    before do
      get url
    end

    it "adds a new account role" do
      role_name = "an account role"

      f("#account_role_link").click
      f('#account-roles-tab .new-role a.dropdown-toggle').click
      f('#account-roles-tab .new-role form input').send_keys(role_name)
      f('#account-roles-tab .new-role button').click
      wait_for_ajaximations

      f('#account-roles-tab').should include_text(role_name)
    end

    it "adds a new course role" do
      role_name = "a course role"

      f("#course_role_link").click
      f('#course-roles-tab .new-role a.dropdown-toggle').click
      f('#course-roles-tab .new-role form input').send_keys(role_name)
      f('#course-roles-tab .new-role button').click
      wait_for_ajaximations

      f('#course-roles-tab').should include_text(role_name)
    end
  end

  describe "Removing roles" do
    context "when deleting account roles" do
      let!(:role_name) { "delete this account role" }

      before do
        add_new_account_role role_name
        get url
      end

      it "deletes a role" do
        f("#account_role_link").click
        f(".roleHeader a").click
        driver.switch_to.alert.accept
        wait_for_ajaximations

        f('#account-roles-tab').should_not include_text(role_name)
      end
    end

    context "when deleting course roles" do
      let!(:role_name) { "delete this course role" }

      before do
        add_new_course_role role_name
        get url
      end

      it "deletes a role" do
        f("#course_role_link").click
        f(".roleHeader a").click
        driver.switch_to.alert.accept
        wait_for_ajaximations

        f('#course-roles-tab').should_not include_text(role_name)
      end
    end
  end

  describe "Managing roles" do
    context "when managing account roles" do
      let!(:role_name) { "TestAcccountRole" }
      let!(:permission_name) { "read_sis" } # Everyone should have this permission
      let!(:role) { add_new_account_role role_name }

      before do
        get url
        f("#account_role_link").click
      end

      it "enables a permission" do
        select_enable(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.find_by_enrollment_type(role.name)
          role_override.enabled.should be_true
          role_override.locked.should be_false
        end
      end

      it "locks and enables a permission" do
        select_enable_and_lock(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.find_by_enrollment_type(role.name)
          role_override.enabled.should be_true
          role_override.locked.should be_true
        end
      end

      it "disables a permission" do
        select_disable(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.find_by_enrollment_type(role.name)
          role_override.enabled.should be_false
          role_override.locked.should be_false
        end
      end

      it "locks and disables a permission" do
        select_disable_and_lock(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.find_by_enrollment_type(role.name)
          role_override.enabled.should be_false
          role_override.locked.should be_true
        end
      end

      it "sets a permission to default"
      it "sets a permission to default and locked"
    end

    context "when managing course roles" do
      let!(:role_name) { "TestCourseRole" }
      let!(:permission_name) { "read_sis" } # Everyone should have this permission
      let!(:role) { add_new_course_role role_name }

      before do
        f("#course_role_link").click
        get url
      end

      it "enables a permission" do
        select_enable(permission_name, role_name)

        keep_trying_until do

          role_override = RoleOverride.find_by_enrollment_type(role.name)
          role_override.enabled.should be_true
          role_override.locked.should be_false
        end
      end

      it "locks and enables a permission" do
        select_enable_and_lock(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.find_by_enrollment_type(role.name)
          role_override.enabled.should be_true
          role_override.locked.should be_true
        end
      end

      it "disables a permission" do
        select_disable(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.find_by_enrollment_type(role.name)
          role_override.enabled.should be_false
          role_override.locked.should be_false
        end
      end

      it "locks and disables a permission" do
        select_disable_and_lock(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.find_by_enrollment_type(role.name)
          role_override.enabled.should be_false
          role_override.locked.should be_true
        end
      end

      it "sets a permission to default"
      it "sets a permission to default and locked"
    end
  end
end
