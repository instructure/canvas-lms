require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ErrorsController do
  before do
    user = User.create!
    Account.site_admin.account_users.create!(user: user)
    user_session(user)
  end

  describe 'index' do
    it "should not error" do
      get 'index'
    end
  end
end
