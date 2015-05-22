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
        expect(token.key).to eq key
      end

      it 'retains the code' do
        expect(token.code).to eq code
      end
    end

    describe '#is_for_valid_code?' do
      it 'is false when there is no code data' do
        stub_out_cache
        expect(token.is_for_valid_code?).to be_falsey
      end

      it 'is false when the client id does not match the key id' do
        stub_out_cache (key.id + 1)
        expect(token.is_for_valid_code?).to be_falsey
      end

      it 'is true otherwise' do
        expect(token.is_for_valid_code?).to be_truthy
      end
    end

    describe '#client_id' do
      it 'delegates to the parsed json' do
        expect(token.client_id).to eq key.id
      end

      it 'is nil when there is no cached entry' do
        stub_out_cache
        expect(token.client_id).to be_nil
      end
    end

    describe '#user' do
      it 'uses the user_id from the redis entry to load a user' do
        expect(token.user).to eq user
      end
    end

    describe '#code_data' do
      it 'parses the json from the cache' do
        hash = token.code_data
        expect(hash['client_id']).to eq key.id
        expect(hash['user']).to eq user.id
      end
    end

    describe '#access_token' do
      let(:scopes) {["#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"]}

      it 'creates a new token if none exists' do
        expect(user.access_tokens).to be_empty
        expect(token.access_token).to be_a AccessToken
        expect(user.access_tokens.reload.size).to eq 1
        expect(token.access_token.full_token).not_to be_empty
      end

      it 'creates a scoped access token' do
        stub_out_cache key.id, scopes
        expect(token.access_token).to be_scoped_to scopes
      end

      it 'creates a new token if the scopes do not match' do
        access_token = user.access_tokens.create!(:developer_key => key, :scopes => scopes)
        expect(token.access_token).to be_a AccessToken
        expect(token.access_token).not_to eq access_token
      end

      it 'will not return the full token for a userinfo scope' do
        scope = "#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"
        stub_out_cache key.id, [scope]
        expect(token.access_token.full_token).to be_nil
      end

      it 'finds an existing userinfo token if one exists' do
        scope = "#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"
        stub_out_cache key.id, [scope]
        access_token = user.access_tokens.create!(:developer_key => key, :scopes => [scope], :remember_access => true)
        expect(token.access_token).to eq access_token
        expect(token.access_token.full_token).to be_nil
      end

      it 'ignores existing token if user did not remember access' do
        scope = "#{AccessToken::OAUTH2_SCOPE_NAMESPACE}userinfo"
        stub_out_cache key.id, [scope]
        access_token = user.access_tokens.create!(:developer_key => key, :scopes => [scope])
        expect(token.access_token).not_to eq access_token
        expect(token.access_token.full_token).to be_nil
      end

      it 'ignores existing tokens by default' do
        stub_out_cache key.id, scopes
        access_token = user.access_tokens.create!(:developer_key => key, :scopes => scopes)
        expect(token.access_token).to be_a AccessToken
        expect(token.access_token).not_to eq access_token
      end
    end

    describe '#create_access_token_if_needed' do
      it 'deletes existing tokens for the same key when requested' do
        old_token = user.access_tokens.create! :developer_key => key
        token.create_access_token_if_needed(true)
        expect(AccessToken.exists?(old_token.id)).to be(false)
      end

      it 'does not delete existing tokens for the same key when not requested' do
        old_token = user.access_tokens.create! :developer_key => key
        token.create_access_token_if_needed
        expect(AccessToken.exists?(old_token.id)).to be(true)
      end
    end

    describe '#as_json' do
      let(:json) { token.as_json }

      it 'includes the access token' do
        expect(json['access_token']).to be_a String
        expect(json['access_token']).not_to be_empty
      end

      it 'grabs the user json as well' do
        expect(json['user']).to eq user.as_json(:only => [:id, :name], :include_root => false)
      end

      it 'does not put anything else into the json' do
        expect(json.keys.sort).to eq ['access_token', 'user']
      end
    end

    describe '.generate_code_for' do
      let(:code) { "brand_new_code" }
      before { SecureRandom.stubs(:hex => code) }

      it 'returns the new code' do
        Canvas.stubs(:redis => stub(:setex => true))
        expect(Token.generate_code_for(1, 1)).to eq code
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
