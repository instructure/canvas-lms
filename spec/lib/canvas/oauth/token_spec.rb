require File.expand_path('../../../spec_helper', File.dirname(__FILE__))

module Canvas::Oauth
  describe Token do
    let(:code) { 'code123code' }
    let(:key) { DeveloperKey.create! }
    let(:user) { User.create! }
    let(:token) { Token.new(key, code) }

    def stub_out_cache(client_id = nil, scopes = nil)
      if client_id
        token.stubs(:cached_code_entry =>
                      '{"client_id": ' + client_id.to_s +
                        ', "user": ' + user.id.to_s +
                        (scopes ? ', "scopes": ' + scopes.to_json : '') + '}')
      else
        token.stubs(:cached_code_entry => '{}')
      end
    end

    before { stub_out_cache key.id }

    describe 'initialization' do
      it 'retains the key' do
        token.key.should == key
      end

      it 'retains the code' do
        token.code.should == code
      end
    end

    describe '#is_for_valid_code?' do
      it 'is false when there is no code data' do
        stub_out_cache
        token.is_for_valid_code?.should be_false
      end

      it 'is false when the client id does not match the key id' do
        stub_out_cache (key.id + 1)
        token.is_for_valid_code?.should be_false
      end

      it 'is true otherwise' do
        token.is_for_valid_code?.should be_true
      end
    end

    describe '#client_id' do
      it 'delegates to the parsed json' do
        token.client_id.should == key.id
      end

      it 'is nil when there is no cached entry' do
        stub_out_cache
        token.client_id.should be_nil
      end
    end

    describe '#user' do
      it 'uses the user_id from the redis entry to load a user' do
        token.user.should == user
      end
    end

    describe '#code_data' do
      it 'parses the json from the cache' do
        hash = token.code_data
        hash['client_id'].should == key.id
        hash['user'].should == user.id
      end
    end

    describe '#access_token' do
      let(:scopes) {["#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"]}

      it 'creates a new token if none exists' do
        user.access_tokens.should be_empty
        token.access_token.should be_a AccessToken
        user.access_tokens.reload.size.should == 1
        token.access_token.full_token.should_not be_empty
      end

      it 'creates a scoped access token' do
        stub_out_cache key.id, scopes
        token.access_token.should be_scoped_to scopes
      end

      it 'creates a new token if the scopes do not match' do
        access_token = user.access_tokens.create!(:developer_key => key, :scopes => scopes)
        token.access_token.should be_a AccessToken
        token.access_token.should_not == access_token
      end

      it 'will not return the full token for a userinfo scope' do
        scope = "#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"
        stub_out_cache key.id, [scope]
        token.access_token.full_token.should be_nil
      end

      it 'finds an existing userinfo token if one exists' do
        scope = "#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"
        stub_out_cache key.id, [scope]
        access_token = user.access_tokens.create!(:developer_key => key, :scopes => [scope], :remember_access => true)
        token.access_token.should == access_token
        token.access_token.full_token.should be_nil
      end

      it 'ignores existing token if user did not remember access' do
        scope = "#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"
        stub_out_cache key.id, [scope]
        access_token = user.access_tokens.create!(:developer_key => key, :scopes => [scope])
        token.access_token.should_not == access_token
        token.access_token.full_token.should be_nil
      end

      it 'ignores existing tokens by default' do
        stub_out_cache key.id, scopes
        access_token = user.access_tokens.create!(:developer_key => key, :scopes => scopes)
        token.access_token.should be_a AccessToken
        token.access_token.should_not == access_token
      end
    end

    describe '#as_json' do
      let(:json) { token.as_json }

      it 'includes the access token' do
        json['access_token'].should be_a String
        json['access_token'].should_not be_empty
      end

      it 'grabs the user json as well' do
        json['user'].should == user.as_json(:only => [:id, :name], :include_root => false)
      end

      it 'does not put anything else into the json' do
        json.keys.sort.should == ['access_token', 'user']
      end
    end

    describe '.generate_code_for' do
      let(:code) { "brand_new_code" }
      before { SecureRandom.stubs(:hex => code) }

      it 'returns the new code' do
        Canvas.stubs(:redis => stub(:setex => true))
        Token.generate_code_for(1, 1).should == code
      end

      it 'sets the new data hash into redis with 10 min ttl' do
        redis = Object.new
        code_data = {user: 1, client_id: 1, scopes: nil, purpose: nil, remember_access: nil}
        #should have 10 min (in seconds) ttl passed as second param
        redis.expects(:setex).with('oauth2:brand_new_code', 600, code_data.to_json)
        Canvas.stubs(:redis => redis)
        Token.generate_code_for(1, 1)
      end

      it 'sets the new data hash into redis with 10 sec ttl' do
        redis = Object.new
        code_data = {user: 1, client_id: 1, scopes: nil, purpose: nil, remember_access: nil}
        #should have 10 sec ttl passed as second param with setting
        Setting.set('oath_token_request_timeout', '10')
        redis.expects(:setex).with('oauth2:brand_new_code', 10, code_data.to_json)
        Canvas.stubs(:redis => redis)
        Token.generate_code_for(1, 1)
      end
    end
  end
end
