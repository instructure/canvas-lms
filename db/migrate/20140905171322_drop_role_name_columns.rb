class DropRoleNameColumns < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def up
    if connection.adapter_name == 'PostgreSQL'
      drop_trigger("account_user_after_insert_set_role_id__tr", "account_users", :generated => true)
      drop_trigger("account_notification_role_after_insert_set_role_id__tr", "account_notification_roles", :generated => true)
      drop_trigger("enrollment_after_insert_set_role_id_if_role_name__tr", "enrollments", :generated => true)
      drop_trigger("enrollment_after_insert_set_role_id_if_no_role_name__tr", "enrollments", :generated => true)
      drop_trigger("role_override_after_insert_set_role_id__tr", "role_overrides", :generated => true)
    end

    remove_index :account_notification_roles, :name => 'idx_acount_notification_roles' # yes i'm aware of the typo
    add_index :account_notification_roles,
              [:account_notification_id, :role_id],
              unique: true,
              name: 'index_account_notification_roles_on_role_id',
              algorithm: :concurrently

    remove_index :enrollments, :name => 'index_enrollments_on_user_type_role_section_associated_user'
    remove_index :enrollments, :name => 'index_enrollments_on_user_type_role_section'
    remove_index :enrollments, :name => 'index_enrollments_on_user_type_section_associated_user'

    add_index :enrollments,
              [:user_id, :type, :role_id, :course_section_id, :associated_user_id],
              where: "associated_user_id IS NOT NULL",
              name: 'index_enrollments_on_user_type_role_section_associated_user',
              unique: true,
              algorithm: :concurrently
    add_index :enrollments,
              [:user_id, :type, :role_id, :course_section_id],
              where: "associated_user_id IS NULL ",
              name: 'index_enrollments_on_user_type_role_section',
              unique: true,
              algorithm: :concurrently

    remove_column :account_users, :membership_type
    remove_column :account_notification_roles, :role_type
    remove_column :enrollments, :role_name
    remove_column :role_overrides, :enrollment_type

    Alert.where(:context_type => "Account").find_each do |alert|
      if alert.recipients.is_a?(Array) && alert.recipients.any?{|r| r.is_a?(String)}
        new_recipients = alert.recipients.map do |recipient|
          recipient.is_a?(String) ? {:role_id => alert.context.get_account_role_by_name(recipient).try(:id)} : recipient
        end
        alert.recipients = new_recipients
        alert.save!
      end
    end

    # make sure we didn't leave any nulls, just in case
    while AccountUser.where("role_id IS NULL").limit(1000).update_all(:role_id => Role.get_built_in_role(Role::NULL_ROLE_TYPE).id) > 0; end
    while RoleOverride.where("role_id IS NULL").limit(1000).update_all(:role_id => Role.get_built_in_role(Role::NULL_ROLE_TYPE).id) > 0; end

    change_column_null :account_users, :role_id, false
    change_column_null :role_overrides, :role_id, false

    DataFixup::AddRoleIdToBaseEnrollments.run
  end

  def down
    add_column :account_users, :membership_type, :string
    add_column :account_notification_roles, :role_type, :string
    add_column :enrollments, :role_name, :string
    add_column :role_overrides, :enrollment_type, :string

    remove_index :enrollments, :name => 'index_account_notification_roles_on_role_id'
    add_index :account_notification_roles, [:account_notification_id, :role_type], :unique => true, :name => "idx_acount_notification_roles"

    remove_index :enrollments, :name => 'index_enrollments_on_user_type_role_section_associated_user'
    remove_index :enrollments, :name => 'index_enrollments_on_user_type_role_section'

    add_index :enrollments,
              [:user_id, :type, :role_name, :course_section_id, :associated_user_id],
              where: "associated_user_id IS NOT NULL AND role_name IS NOT NULL",
              name: 'index_enrollments_on_user_type_role_section_associated_user',
              unique: true,
              algorithm: :concurrently
    add_index :enrollments,
              [:user_id, :type, :role_name, :course_section_id],
              where: "role_name IS NOT NULL AND associated_user_id IS NULL ",
              name: 'index_enrollments_on_user_type_role_section',
              unique: true,
              algorithm: :concurrently
    add_index :enrollments,
              [:user_id, :type, :course_section_id, :associated_user_id],
              where: "associated_user_id IS NOT NULL AND role_name IS NULL",
              name: 'index_enrollments_on_user_type_section_associated_user',
              unique: true,
              algorithm: :concurrently

    Alert.where(:context_type => "Account").find_each do |alert|
      if alert.recipients.is_a?(Array) && alert.recipients.any?{|r| r.is_a?(Hash)}
        new_recipients = alert.recipients.map do |recipient|
          recipient.is_a?(Hash) ? Role.get_role_by_id(recipient[:role_id]).name : recipient
        end
        alert.recipients = new_recipients
        alert.save!
      end
    end
  end
end
