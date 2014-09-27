shared_examples_for "permission tests" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_admin_logged_in
  end

  def select_permission_option(permission_name, role_name, index)
    driver.execute_script("$('td[data-permission_name=\"#{permission_name}\"].[data-role_name=\"#{role_name}\"] a').click()")
    wait_for_ajaximations
    driver.execute_script("$('td[data-permission_name=\"#{permission_name}\"].[data-role_name=\"#{role_name}\"] label')[#{index}].click()")
    wait_for_ajaximations #Every select needs to wait for for the request to finish
  end

  def select_enable(permission_name, role_name)
    select_permission_option(permission_name, role_name, 0) # 0 is Enable
  end

  def select_enable_and_lock(permission_name, role_name)
    select_permission_option(permission_name, role_name, 1) # 1 is enabled and locked
  end

  def select_disable(permission_name, role_name)
    select_permission_option(permission_name, role_name, 2) # 2 is Disabled
  end

  def select_disable_and_lock(permission_name, role_name)
    select_permission_option(permission_name, role_name, 3) # 3 is Disabled and locked
  end

  def select_default(permission_name, role_name)
    select_permission_option(permission_name, role_name, 4) # 3 is Disabled and locked
  end

  def select_default_and_lock(permission_name, role_name)
    select_permission_option(permission_name, role_name, 5) # 3 is Disabled and locked
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
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.enabled.should be_true
          role_override.locked.should be_false
        end
      end

      it "locks and enables a permission" do
        select_enable_and_lock(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.enabled.should be_true
          role_override.locked.should be_true
        end
      end

      it "disables a permission" do
        select_disable(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.enabled.should be_false
          role_override.locked.should be_false
        end
      end

      it "locks and disables a permission" do
        select_disable_and_lock(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.enabled.should be_false
          role_override.locked.should be_true
        end
      end

      it "sets a permission to default" do
        select_disable(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.nil?.should be_false
        end

        select_default(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.nil?.should be_true
        end
      end

      it "sets a permission to default and locked" do
        select_default_and_lock(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.enabled.nil?.should be_true
          role_override.locked.should be_true
        end
      end
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

          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.enabled.should be_true
          role_override.locked.should be_false
        end
      end

      it "locks and enables a permission" do
        select_enable_and_lock(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.enabled.should be_true
          role_override.locked.should be_true
        end
      end

      it "disables a permission" do
        select_disable(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.enabled.should be_false
          role_override.locked.should be_false
        end
      end

      it "locks and disables a permission" do
        select_disable_and_lock(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.enabled.should be_false
          role_override.locked.should be_true
        end
      end

      it "sets a permission to default" do
        select_disable(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.nil?.should be_false
        end

        select_default(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.nil?.should be_true
        end
      end

      it "sets a permission to default and locked" do
        select_default_and_lock(permission_name, role_name)

        keep_trying_until do
          role_override = RoleOverride.where(enrollment_type: role.name).first
          role_override.enabled.nil?.should be_true
          role_override.locked.should be_true
        end
      end
    end
  end
end
