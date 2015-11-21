require_relative '../../spec_helper.rb'

describe AccountAuthorizationConfig::OpenIDConnect do

  describe '#unique_id' do
    it 'decodes jwt and extracts subject attribute' do
      connect = described_class.new
      payload = { sub: "some-login-attribute" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      uid = connect.unique_id(stub(params: {'id_token' => id_token}))
      expect(uid).to eq("some-login-attribute")
    end
  end

end
