class AddRoleIdColumns < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :predeploy

  def up
    # add role id columns
    add_column :account_users, :role_id, :integer, :limit => 8
    add_column :account_notification_roles, :role_id, :integer, :limit => 8
    add_column :enrollments, :role_id, :integer, :limit => 8
    add_column :role_overrides, :role_id, :integer, :limit => 8

    add_foreign_key :account_users, :roles
    add_foreign_key :account_notification_roles, :roles
    add_foreign_key :enrollments, :roles
    add_foreign_key :role_overrides, :roles

    # populate built-in roles
    change_column_null :roles, :account_id, true
    remove_index :roles, :name => 'index_roles_unique_account_name'

    Role.ensure_built_in_roles!

    if connection.adapter_name == 'PostgreSQL'

      add_index :roles, [:account_id, :name], :unique => true, :name => "index_roles_unique_account_name_where_active", :where => "workflow_state = 'active'"

      # de-duplicate roles in same account chain into their parents
      delete_duplicate_roles_sql = "
        UPDATE roles SET workflow_state = 'deleted' WHERE roles.workflow_state = 'active' AND EXISTS (
          SELECT id FROM roles AS other_role WHERE roles.id <> other_role.id AND roles.name = other_role.name AND
          roles.root_account_id = other_role.root_account_id AND other_role.workflow_state = 'active' AND other_role.account_id IN (
            WITH RECURSIVE t AS (
              SELECT * FROM accounts WHERE id=roles.account_id
              UNION
              SELECT accounts.* FROM accounts INNER JOIN t ON accounts.id=t.parent_account_id
            )
            SELECT id FROM t
          ) LIMIT 1
        )"
      Role.connection.update(delete_duplicate_roles_sql)

      # create triggers to handle things until the postdeploy runs
      create_trigger("account_user_after_insert_set_role_id__tr", :generated => true).
          on("account_users").
          after(:insert).
          where("NEW.role_id IS NULL") do
        <<-SQL_ACTIONS
            UPDATE account_users
            SET role_id = (
              SELECT id FROM roles WHERE roles.name = NEW.membership_type AND (
                roles.workflow_state = 'built_in' OR (
                  roles.workflow_state = 'active' AND (
                    roles.account_id = NEW.account_id OR
                    roles.account_id IN (
                      WITH RECURSIVE t AS (
                        SELECT * FROM accounts WHERE id=NEW.account_id
                        UNION
                        SELECT accounts.* FROM accounts INNER JOIN t ON accounts.id=t.parent_account_id
                      )
                      SELECT id FROM t
                    )
                  )
                )
              ) LIMIT 1
            ) WHERE id = NEW.id
        SQL_ACTIONS
      end

      create_trigger("account_notification_role_after_insert_set_role_id__tr", :generated => true).
          on("account_notification_roles").
          after(:insert).
          where("NEW.role_id IS NULL") do
        <<-SQL_ACTIONS
            UPDATE account_notification_roles
            SET role_id = (
              SELECT id FROM roles WHERE roles.name = NEW.role_type AND (
                roles.workflow_state = 'built_in' OR (
                  roles.workflow_state = 'active' AND (
                    roles.account_id = (SELECT account_id FROM account_notifications WHERE id=NEW.account_notification_id LIMIT 1) OR
                    roles.account_id IN (
                      WITH RECURSIVE t AS (
                        SELECT * FROM accounts WHERE id=(SELECT account_id FROM account_notifications WHERE id=NEW.account_notification_id LIMIT 1)
                        UNION
                        SELECT accounts.* FROM accounts INNER JOIN t ON accounts.id=t.parent_account_id
                      )
                      SELECT id FROM t
                    )
                  )
                )
              ) LIMIT 1
            ) WHERE id = NEW.id
        SQL_ACTIONS
      end

      create_trigger("enrollment_after_insert_set_role_id_if_role_name__tr", :generated => true).
          on("enrollments").
          after(:insert).
          where("NEW.role_id IS NULL AND NEW.role_name IS NOT NULL") do
        <<-SQL_ACTIONS
            UPDATE enrollments
            SET role_id = (
              SELECT id FROM roles WHERE roles.name = NEW.role_name AND (
                roles.workflow_state = 'built_in' OR (
                  roles.workflow_state = 'active' AND (
                    roles.account_id = (SELECT account_id FROM courses WHERE id=NEW.course_id LIMIT 1) OR
                    roles.account_id IN (
                      WITH RECURSIVE t AS (
                        SELECT * FROM accounts WHERE id=(SELECT account_id FROM courses WHERE id=NEW.course_id LIMIT 1)
                        UNION
                        SELECT accounts.* FROM accounts INNER JOIN t ON accounts.id=t.parent_account_id
                      )
                      SELECT id FROM t
                    )
                  )
                )
              ) LIMIT 1
            ) WHERE id = NEW.id
        SQL_ACTIONS
      end

      create_trigger("enrollment_after_insert_set_role_id_if_no_role_name__tr", :generated => true).
          on("enrollments").
          after(:insert).
          where("NEW.role_id IS NULL AND NEW.role_name IS NULL") do
        <<-SQL_ACTIONS
            UPDATE enrollments
            SET role_id = (SELECT id FROM roles WHERE roles.workflow_state = 'built_in' AND roles.name = NEW.type LIMIT 1)
            WHERE id = NEW.id
        SQL_ACTIONS
      end

      create_trigger("role_override_after_insert_set_role_id__tr", :generated => true).
          on("role_overrides").
          after(:insert).
          where("NEW.role_id IS NULL AND NEW.context_type = 'Account'") do
        <<-SQL_ACTIONS
            UPDATE role_overrides
            SET role_id = (
              SELECT id FROM roles WHERE roles.name = NEW.enrollment_type AND (
                roles.workflow_state = 'built_in' OR (
                  roles.workflow_state = 'active' AND (
                    roles.account_id = NEW.context_id OR
                    roles.account_id IN (
                      WITH RECURSIVE t AS (
                        SELECT * FROM accounts WHERE id=NEW.context_id
                        UNION
                        SELECT accounts.* FROM accounts INNER JOIN t ON accounts.id=t.parent_account_id
                      )
                      SELECT id FROM t
                    )
                  )
                )
              ) LIMIT 1
            ) WHERE id = NEW.id
        SQL_ACTIONS
      end
    end

    # Populate the role_ids for account_users and role_overrides (and enrollments with custom role_names)
    # It would be nice to do all the enrollments now but it'll be easier to do as a delayed job later
    Role.built_in_account_roles.each do |role|
      while AccountUser.where("role_id IS NULL AND membership_type = ?", role.name).limit(1000).update_all(:role_id => role.id) > 0; end
    end

    Role.built_in_roles.each do |role|
      while AccountNotificationRole.where("role_id IS NULL AND role_type = ?", role.name).limit(1000).update_all(:role_id => role.id) > 0; end
      while RoleOverride.where("role_id IS NULL AND enrollment_type = ?", role.name).limit(1000).update_all(:role_id => role.id) > 0; end
    end

    applicable_account_ids = {} # includes ids for self and all sub_accounts
    Role.active.for_accounts.find_each do |role|
      applicable_account_ids[role.account_id] ||= Account.sub_account_ids_recursive(role.account_id) + [role.account_id]
      while AccountNotificationRole.where("role_id IS NULL AND role_type = ? AND (SELECT account_id FROM
         account_notifications WHERE id = account_notification_roles.account_notification_id LIMIT 1) IN (?)", role.name,
                              applicable_account_ids[role.account_id]).limit(1000).update_all(:role_id => role.id) > 0; end
      while AccountUser.where("role_id IS NULL AND membership_type = ? AND account_id IN (?)", role.name,
                              applicable_account_ids[role.account_id]).limit(1000).update_all(:role_id => role.id) > 0; end
      while RoleOverride.where("role_id IS NULL AND enrollment_type = ? AND context_type = ? AND context_id IN (?)", role.name, 'Account',
                              applicable_account_ids[role.account_id]).limit(1000).update_all(:role_id => role.id) > 0; end
    end

    course_ids = {}
    Role.active.for_courses.find_each do |role|
      applicable_account_ids[role.account_id] ||= Account.sub_account_ids_recursive(role.account_id) + [role.account_id]
      course_ids[role.account_id] ||= Course.where(:account_id => applicable_account_ids[role.account_id]).pluck(:id)

      course_ids[role.account_id].each_slice(100) do |course_ids_slice|
        while Enrollment.where("role_id IS NULL AND role_name = ? AND course_id IN (?)", role.name,
                               course_ids_slice).limit(1000).update_all(:role_id => role.id) > 0; end
      end

      while AccountNotificationRole.where("role_id IS NULL AND role_type = ? AND (SELECT account_id FROM
         account_notifications WHERE id = account_notification_roles.account_notification_id LIMIT 1) IN (?)", role.name,
                              applicable_account_ids[role.account_id]).limit(1000).update_all(:role_id => role.id) > 0; end
      while RoleOverride.where("role_id IS NULL AND enrollment_type = ? AND context_type = ? AND context_id IN (?)", role.name, 'Account',
                               applicable_account_ids[role.account_id]).limit(1000).update_all(:role_id => role.id) > 0; end
    end

    while AccountNotificationRole.where("role_id IS NULL AND role_type <> 'NilEnrollment'").limit(1000).update_all(:role_id => Role.get_built_in_role(Role::NULL_ROLE_TYPE).id) > 0; end
  end

  def down
    if connection.adapter_name == 'PostgreSQL'
      remove_index :roles, :name => 'index_roles_unique_account_name_where_active'

      drop_trigger("account_user_after_insert_set_role_id__tr", "account_users", :generated => true)
      drop_trigger("account_notification_role_after_insert_set_role_id__tr", "account_notification_roles", :generated => true)
      drop_trigger("enrollment_after_insert_set_role_id_if_role_name__tr", "enrollments", :generated => true)
      drop_trigger("enrollment_after_insert_set_role_id_if_no_role_name__tr", "enrollments", :generated => true)
      drop_trigger("role_override_after_insert_set_role_id__tr", "role_overrides", :generated => true)
    end

    Role.for_accounts.find_each do |role|
      while AccountNotificationRole.where("role_type IS NULL AND role_id = ?", role.id).limit(1000).update_all(:role_type => role.name) > 0; end
      while AccountUser.where("membership_type IS NULL AND role_id = ?", role.id).limit(1000).update_all(:membership_type => role.name) > 0; end
      while RoleOverride.where("enrollment_type IS NULL AND role_id = ?", role.id).limit(1000).update_all(:enrollment_type => role.name) > 0; end
    end

    Role.for_courses.find_each do |role|
      while AccountNotificationRole.where("role_type IS NULL AND role_id = ?", role.id).limit(1000).update_all(:role_type => role.name) > 0; end
      while RoleOverride.where("enrollment_type IS NULL AND role_id = ?", role.id).limit(1000).update_all(:enrollment_type => role.name) > 0; end

      unless role.built_in?
        while Enrollment.where("role_name IS NULL AND role_id = ?", role.id).limit(1000).update_all(:role_name => role.name) > 0; end
      end
    end

    while AccountNotificationRole.where("role_type IS NULL").limit(1000).update_all(:role_type => "NilEnrollment") > 0; end

    remove_column :account_users, :role_id
    remove_column :account_notification_roles, :role_id
    remove_column :enrollments, :role_id
    remove_column :role_overrides, :role_id

    Role.where(:workflow_state => "built_in").delete_all

    add_index :roles, [:account_id, :name], :unique => true, :name => "index_roles_unique_account_name"

    change_column_null :roles, :account_id, false
    change_column :account_users, :membership_type, :string, :default => "AccountAdmin"
  end
end
