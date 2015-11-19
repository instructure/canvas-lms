require_relative '../../helpers/gradebook2_common'

describe "gradebook2 - permissions" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let(:course) { Course.create! }

  it "should display for users with only :view_all_grades permissions" do
    user_logged_in

    role = custom_account_role('CustomAdmin', :account => Account.default)
    RoleOverride.create!(:role => role,
                         :permission => 'view_all_grades',
                         :context => Account.default,
                         :enabled => true)
    AccountUser.create!(:user => @user,
                        :account => Account.default,
                        :role => role)

    get "/courses/#{course.id}/gradebook2"
    expect(flash_message_present?(:error)).to be_falsey
  end

  it "should display for users with only :manage_grades permissions" do
    user_logged_in
    role = custom_account_role('CustomAdmin', :account => Account.default)
    RoleOverride.create!(:role => role,
                         :permission => 'manage_grades',
                         :context => Account.default,
                         :enabled => true)
    AccountUser.create!(:user => @user,
                        :account => Account.default,
                        :role => role)

    get "/courses/#{course.id}/gradebook2"
    expect(flash_message_present?(:error)).to be_falsey
  end
end