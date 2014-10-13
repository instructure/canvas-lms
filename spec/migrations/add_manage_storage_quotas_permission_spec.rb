require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20130326210659_add_manage_storage_quotas_permission.rb'

describe "AddManageRubricsPermission" do
  it "will copy role overrides for the new permission" do
    @account = account_model(:parent_account => Account.default)
    @account.role_overrides.create! :permission => 'manage_account_settings', :enabled => true, :enrollment_type => 'CanManageAccountStuff'
    @account.role_overrides.create! :permission => 'manage_account_settings', :enabled => false, :enrollment_type => 'TotallyCannot'
    
    AddManageStorageQuotasPermission.up
    
    new_permissions = @account.role_overrides.where(:permission => 'manage_storage_quotas') 
    expect(new_permissions.where(:enrollment_type => 'CanManageAccountStuff').map(&:enabled)).to eq [true]
    expect(new_permissions.where(:enrollment_type => 'TotallyCannot').map(&:enabled)).to eq [false]
  end
end
