require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20130215164701_add_manage_rubrics_permission.rb'

describe "AddManageRubricsPermission" do
  it "will copy role overrides for the new permission" do
    accounts = []
    4.times do
      accounts << account_model(:parent_account => Account.default)
    end

    roles = ['TeacherEnrollment', 'TaEnrollment', 'AccountAdmin', 'AccountMembership'].map{|n| Role.get_built_in_role(n)}
    bool = true

    role_overrides = []
    accounts.each do |account|
      roles.each do |role|
        role_overrides << RoleOverride.create!(:context => account, :permission => 'manage_grades',
          :role => role, :enabled => bool)
        bool = !bool
      end
    end

    AddManageRubricsPermission.up

    new_role_overrides = RoleOverride.find(:all, :conditions => {:permission => 'manage_rubrics'})

    expect(role_overrides.count).to eq new_role_overrides.count
    role_overrides.each do |old_role_override|
      new_role_override = new_role_overrides.find{|ro|
        ro.context_id == old_role_override.context_id &&
        ro.context_type == old_role_override.context_type &&
        ro.role_id == old_role_override.role_id
      }
      expect(new_role_override).not_to be_nil

      expect(new_role_override.attributes.delete_if{|k,v| [:id, :permission, :created_at, :updated_at].include?(k.to_sym)}).to eq(
        old_role_override.attributes.delete_if{|k,v| [:id, :permission, :created_at, :updated_at].include?(k.to_sym)}
      )
    end

  end
end
