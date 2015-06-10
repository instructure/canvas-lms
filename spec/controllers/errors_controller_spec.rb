require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ErrorsController do
  def authenticate_user!
    user = User.create!
    Account.site_admin.account_users.create!(user: user)
    user_session(user)
  end

  describe 'index' do
    before { authenticate_user! }

    it "should not error" do
      get 'index'
    end
  end

  describe "POST create" do

    def assert_recorded_error(msg = "Thanks for your help!  We'll get right on this")
      expect(flash[:notice]).to eql(msg)
      expect(response).to be_redirect
      expect(response).to redirect_to(root_url)
    end

    it 'creates a new error report' do
      authenticate_user!
      post 'create', {
        error: {
          url: "someurl",
          message: "BigError",
          email: "testerrors42@example.com"
        }
      }
      assert_recorded_error
      expect(ErrorReport.last.email).to eq("testerrors42@example.com")
    end

    it "doesnt need authentication" do
      post 'create', { error: { message: "BigError" } }
      assert_recorded_error
    end

    it "should be successful without data" do
      post 'create'
      assert_recorded_error
    end

    it "is successful with limited data" do
      post 'create', error: {title: 'ugly', message: 'bacon', fried_ham: 'stupid'}
      assert_recorded_error
    end

    it "should not choke on non-integer ids" do
      post 'create', error: {id: 'garbage'}
      assert_recorded_error
      expect(ErrorReport.last.message).not_to eq "Error Report Creation failed"
    end

    it "should not return nil.id if report creation failed" do
      ErrorReport.expects(:where).once.raises("failed!")
      post 'create', format: 'json', error: {id: 1}
      expect(JSON.parse(response.body)).to eq({ 'logged' => true, 'id' => nil })
    end

    it "should not record the user as nil.id if report creation failed" do
      ErrorReport.expects(:where).once.raises("failed!")
      post 'create', error: { id: 1 }
      expect(ErrorReport.last.user_id).to be_nil
    end

    it "should record the user if report creation failed" do
      user = User.create!
      user_session(user)
      ErrorReport.expects(:where).once.raises("failed!")
      post 'create', error: { id: 1 }
      expect(ErrorReport.last.user_id).to eq user.id
    end

  end
end
