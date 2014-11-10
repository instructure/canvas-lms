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
      expect(data_exports_json([@de], @user, @session).size).to eq 1
    
      json = data_export_json(@de, @user, @session).symbolize_keys
      expect(json.keys.sort).to eq [:created_at, :id, :workflow_state]
      expect(json[:id]).to eq @de.id
      expect(json[:created_at]).to eq @de.created_at
      expect(json[:workflow_state]).to eq @de.workflow_state
    end
  end

end
