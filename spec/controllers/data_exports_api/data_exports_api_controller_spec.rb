require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe DataExportsApi::DataExportsApiController do
  def json_body
    JSON.parse(response.body.split(';').last)
  end

  describe "POST" do
    before(:each) do
      account_admin_user(:account => account_model)
    end

    it "should authenticate against account" do
      post :create, :format => "json", :account_id => Account.default.id
      assert_status(401)
    end

    it "should check against manage_data_export permissions" do
      user_session(account_admin_user_with_role_changes(:account_id => @account.id, :role_changes => {:manage_data_exports => false}))
      post :create, :format => "json", :account_id => @account.id
      assert_status(401)
    end

    it "should create a new data export" do
      user_session(@user)
      expect { post :create, :format => "json", :account_id => @account.id }.to change(DataExportsApi::DataExport.for(@account), :count).by 1
    end
  end

  describe "GET" do
    before(:each) do
      account_admin_user(:account => account_model)
      @dd = DataExportsApi::DataExport.for(@account).build(user: @user)
      @dd.save!
    end

    it "should retrieve existing data export" do
      user_session(@user)
      get "show", :format => "json", :account_id => @account.id, :id => @dd.id
      response.should be_success 
      r = json_body["data_exports"].first
      r["id"].should == @dd.id
      r["user"]["id"].should == @user.id
      r["account"]["id"].should == @account.id
    end

    it "should retrieve all data exports for an account" do
      user_session(@user)
      @dd2 = DataExportsApi::DataExport.for(@account).build(user: @user)
      @dd2.save!
      get "index", :format => "json", :account_id => @account.id
      json_body["data_exports"].map {|j| j["id"] }.sort.should == [@dd.id, @dd2.id]
    end
  end

  describe "DELETE" do
    before(:each) do
      account_admin_user(:account => account_model)
      @dd = DataExportsApi::DataExport.for(@account).build(user: @user)
      @dd.save!
    end

    it "should cancel data export" do
      user_session(@user)
      delete "cancel", :format => "json", :account_id => @account.id, :id => @dd.id
      assert_status(204)
      @dd.reload.workflow_state.should == "cancelled"
    end
  end
end
