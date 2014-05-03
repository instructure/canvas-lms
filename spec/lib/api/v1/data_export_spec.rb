require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Api::V1::DataExport do
  include Api::V1::DataExport

  describe "#data_export_json" do
    before do
      user_session(account_admin_user(account: Account.default))
      @de = DataExportsApi::DataExport.for(Account.default).new
      @de.user_id = @user.id
      @de.save!
    end

    it "should return data export hash" do
      data_exports_json([@de], @user, @session).size.should == 1
    
      json = data_export_json(@de, @user, @session).symbolize_keys
      json.keys.sort.should == [:created_at, :id, :workflow_state]
      json[:id].should == @de.id
      json[:created_at].should == @de.created_at
      json[:workflow_state].should == @de.workflow_state
    end
  end

end
