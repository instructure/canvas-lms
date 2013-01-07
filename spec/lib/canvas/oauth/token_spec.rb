require File.expand_path('../../../spec_helper', File.dirname(__FILE__))

module Canvas::Oauth
  describe Token do
    let(:code) { 'code123code' }
    let(:key) { stub(:id => 12) }
    let(:user) { stub(:as_json => '{"userkey": "uservalue"}') }
    let(:token) { Token.new(key, code) }

    def stub_out_cache(client_id = nil)
      if client_id
        token.stubs(:cached_code_entry => '{"client_id": ' + client_id.to_s + ', "user": 1}')
      else
        token.stubs(:cached_code_entry => '{}')
      end
    end

    def stub_user_load
      User.stubs(:find).with(1).returns(user)
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
        stub_out_cache 21
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
        stub_user_load
        token.user.should == user
      end
    end

    describe '#code_data' do
      it 'parses the json from the cache' do
        hash = token.code_data
        hash['client_id'].should == key.id
        hash['user'].should == 1
      end
    end

    describe '#access_token' do
      it 'delegates to the access_tokens collection on the user' do
        stub_user_load
        tokens_collection = Object.new
        access_token = stub
        user.stubs(:access_tokens => tokens_collection)
        tokens_collection.expects(:create!).with(:developer_key => key).returns(access_token)
        token.access_token.should == access_token
      end
    end

    describe '#to_json' do
      let(:json) { token.to_json }

      before do
        stub_user_load
        user.stubs(:access_tokens => stub(:create! => stub(:full_token => 'full_token')))
      end

      it 'includes the access token' do
        json['access_token'].should == 'full_token'
      end

      it 'grabs the user json as well' do
        json['user'].should == user.as_json
      end

      it 'does not put anything else into the json' do
        json.keys.sort.should == ['access_token', 'user']
      end
    end

    describe '.generate_code_for' do
      let(:code) { "brand_new_code" }
      before { ActiveSupport::SecureRandom.stubs(:hex => code) }

      it 'returns the new code' do
        Canvas.stubs(:redis => stub(:setex => true))
        Token.generate_code_for(1, 1).should == code
      end

      it 'sets the new data hash into redis' do
        redis = Object.new
        redis.expects(:setex)
        Canvas.stubs(:redis => redis)
        Token.generate_code_for(1, 1)
      end
    end
  end
end
