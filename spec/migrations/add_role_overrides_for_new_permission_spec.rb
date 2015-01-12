require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'DataFixup::AddRoleOverridesForNewPermission' do
  it "should make new role overrides" do
    RoleOverride.create!(:context => Account.default, :permission => 'moderate_other_stuff',
                         :role => teacher_role, :enabled => false)
    RoleOverride.create!(:context => Account.default, :permission => 'moderate_forum',
                         :role => admin_role, :enabled => true)
    DataFixup::AddRoleOverridesForNewPermission.run(:moderate_forum, :moderate_other_stuff)
    new_ro = RoleOverride.where(:permission => "moderate_other_stuff", :role_id => admin_role.id).first
    expect(new_ro.context).to eq Account.default
    expect(new_ro.role).to eq admin_role
    expect(new_ro.enabled).to be_truthy
    old_ro = RoleOverride.where(:permission => "moderate_other_stuff", :role_id => teacher_role.id).first
    expect(old_ro.enabled).to be_falsey
  end
end