require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'DataFixup::AddRoleOverridesForNewPermission' do
  it "should make new role overrides" do
    RoleOverride.create!(:context => Account.default, :permission => 'moderate_forum',
                         :role => admin_role, :enabled => true)
    DataFixup::AddRoleOverridesForNewPermission.run(:moderate_forum, :moderate_other_stuff)
    ro = RoleOverride.where(:permission => "moderate_other_stuff").first
    expect(ro.context).to eq Account.default
    expect(ro.role).to eq admin_role
    expect(ro.enabled).to be_truthy
  end
end