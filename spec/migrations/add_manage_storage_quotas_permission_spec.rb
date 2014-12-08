require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20130326210659_add_manage_storage_quotas_permission.rb'

describe "AddManageRubricsPermission" do
  it "will copy role overrides for the new permission" do
    @account = account_model(:parent_account => Account.default)
    role1 = custom_account_role('CanManageAccountStuff', :account => @account)
    role2 = custom_account_role('TotallyCannot', :account => @account)
    @account.role_overrides.create! :permission => 'manage_account_settings', :enabled => true, :role => role1
    @account.role_overrides.create! :permission => 'manage_account_settings', :enabled => false, :role => role2
    
    AddManageStorageQuotasPermission.up
    
    new_permissions = @account.role_overrides.where(:permission => 'manage_storage_quotas')
    expect(new_permissions.where(:role_id => role1.id).map(&:enabled)).to eq [true]
    expect(new_permissions.where(:role_id => role2.id).map(&:enabled)).to eq [false]
  end
end
