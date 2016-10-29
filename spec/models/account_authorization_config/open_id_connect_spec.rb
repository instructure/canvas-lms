require_relative '../../spec_helper.rb'

describe AccountAuthorizationConfig::OpenIDConnect do

  describe '#scope_for_options' do
    it 'automatically infers according to requested claims' do
      connect = described_class.new
      connect.federated_attributes = { 'email' => { 'attribute' => 'email' } }
      connect.login_attribute = 'preferred_username'
      expect(connect.send(:scope_for_options)).to eq 'openid profile email'
    end
  end

  describe '#unique_id' do
    it 'decodes jwt and extracts subject attribute' do
      connect = described_class.new
      payload = { sub: "some-login-attribute" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      uid = connect.unique_id(stub(params: {'id_token' => id_token}, options: {}))
      expect(uid).to eq("some-login-attribute")
    end

    it 'requests more attributes if necessary' do
      connect = described_class.new
      connect.userinfo_endpoint = 'moar'
      connect.login_attribute = 'not_in_id_token'
      payload = { sub: "1" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      token = stub(options: {}, params: {'id_token' => id_token})
      token.expects(:get).with('moar').returns(stub(parsed: { 'not_in_id_token' => 'myid', 'sub' => '1' }))
      expect(connect.unique_id(token)).to eq 'myid'
    end

    it "ignores userinfo that doesn't match" do
      connect = described_class.new
      connect.userinfo_endpoint = 'moar'
      connect.login_attribute = 'not_in_id_token'
      payload = { sub: "1" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      token = stub(options: {}, params: {'id_token' => id_token})
      token.expects(:get).with('moar').returns(stub(parsed: { 'not_in_id_token' => 'myid', 'sub' => '2' }))
      expect(connect.unique_id(token)).to be_nil
    end
  end

  describe "#user_logout_url" do
    it "returns the end_session_endpoint" do
      ap = AccountAuthorizationConfig::OpenIDConnect.new(end_session_endpoint: "http://somewhere/logout")
      expect(ap.user_logout_redirect(nil, nil)).to eq "http://somewhere/logout"
    end
  end
end
