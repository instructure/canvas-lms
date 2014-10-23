require File.expand_path('../../../spec_helper', File.dirname(__FILE__))

module Canvas::Oauth
  describe Provider do
    let(:provider) { Provider.new('123') }

    def stub_dev_key(key)
      DeveloperKey.stubs(:where).returns(stub(first: key))
    end

    describe 'initialization' do
      it 'retains the client_id' do
        provider.client_id.should == '123'
      end

      it 'defaults the redirect_uri to a blank string' do
        provider.redirect_uri.should == ''
      end

      it 'can override the default redirect_uri' do
        Provider.new('123','456').redirect_uri.should == '456'
      end

    end

    describe '#has_valid_key?' do
      it 'is true when there is a key' do
        stub_dev_key(stub)
        provider.has_valid_key?.should be_true
      end

      it 'is false when there is no key' do
        stub_dev_key(nil)
        provider.has_valid_key?.should be_false
      end
    end

    describe '#client_id_is_valid?' do
      it 'is false for a nil id' do
        Provider.new(nil, '456').client_id_is_valid?.should be_false
      end

      it 'is false for a non-integer' do
        Provider.new('XXXXX', '456').client_id_is_valid?.should be_false
      end

      it 'is true for an integer' do
        Provider.new('123', '456').client_id_is_valid?.should be_true
      end
    end

    describe '#has_valid_redirect?' do
      it 'is true when the redirect url is the OOB uri' do
        provider = Provider.new('123', Provider::OAUTH2_OOB_URI)
        provider.has_valid_redirect?.should be_true
      end

      it 'is true when the redirect url is kosher for the developerKey' do
        stub_dev_key(stub(:redirect_domain_matches? => true))
        provider.has_valid_redirect?.should be_true
      end

      it 'is false otherwise' do
        stub_dev_key(stub(:redirect_domain_matches? => false))
        provider.has_valid_redirect?.should be_false
      end
    end

    describe '#icon_url' do
      it 'delegates to the key' do
        stub_dev_key(stub(:icon_url => 'unique_url'))
        provider.icon_url.should == 'unique_url'
      end
    end

    describe '#key' do
      it 'is nil if there is no client id' do
        Provider.new(nil).key.should be_nil
      end

      it 'delegates to the class level finder on DeveloperKey' do
        key = stub
        stub_dev_key(key)
        provider.key.should == key
      end
    end

    describe 'authorized_token?' do
      let(:developer_key) {DeveloperKey.create!}
      let(:user) {User.create!}

      it 'finds a pre existing token with the same scope' do
        user.access_tokens.create!(:developer_key => developer_key, :scopes => ["#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"], :remember_access => true)
        Provider.new(developer_key.id, "", ['userinfo']).authorized_token?(user).should == true
      end

      it 'ignores tokens unless access is remembered' do
        user.access_tokens.create!(:developer_key => developer_key, :scopes => ["#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"])
        Provider.new(developer_key.id, "", ['userinfo']).authorized_token?(user).should == false
      end

      it 'ignores tokens for out of band requests ' do
        user.access_tokens.create!(:developer_key => developer_key, :scopes => ["#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"], :remember_access => true)
        Provider.new(developer_key.id, Canvas::Oauth::Provider::OAUTH2_OOB_URI, ['userinfo']).authorized_token?(user).should == false
      end
    end

    describe '#app_name' do
      let(:key_attrs) { {:name => 'some app', :user_name => 'some user', :email => 'some email'} }
      let(:key) { stub(key_attrs) }

      it 'prefers the key name' do
        stub_dev_key(key)
        provider.app_name.should == 'some app'
      end

      it 'falls back to the user name' do
        key_attrs[:name] = nil
        stub_dev_key(key)
        provider.app_name.should == 'some user'
      end

      it 'falls back to the email if there is nothing else' do
        key_attrs[:name] = nil
        key_attrs[:user_name] = nil
        stub_dev_key(key)
        provider.app_name.should == 'some email'
      end

      it 'goes to the default app name if there are no pieces of data in the key' do
        key_attrs[:name] = nil
        key_attrs[:user_name] = nil
        key_attrs[:email] = nil
        stub_dev_key(key)
        provider.app_name.should == 'Third-Party Application'
      end
    end

    describe '#session_hash' do

      before { stub_dev_key(stub(:id => 123)) }

      it 'uses the key id for a client id' do
        provider.session_hash[:client_id].should == 123
      end

      it 'passes the redirect_uri through' do
        provider = Provider.new('123', 'some uri')
        provider.session_hash[:redirect_uri].should == 'some uri'
      end

      it 'passes the scope through' do
        provider = Provider.new('123', 'some uri', 'userinfo,full_access')
        provider.session_hash[:scopes].should == 'userinfo,full_access'
      end
    end
  end
end
