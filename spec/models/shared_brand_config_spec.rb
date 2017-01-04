require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SharedBrandConfig, type: :model do
  describe "policy" do
    subject {Account.default.shared_brand_configs.new}
    it "does NOT allow unauthorized users to delete/modify" do
      expect(subject.check_policy(User.new)).to be_empty
    end

    it "DOES allow authorized users to delete/modify" do
      expect(subject.check_policy(account_admin_user)).to eq([:create, :update, :delete])
    end
  end
end
