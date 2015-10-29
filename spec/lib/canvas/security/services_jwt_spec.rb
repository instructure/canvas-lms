require_relative '../../../spec_helper'

module Canvas::Security
  describe ServicesJwt do
    include_context "JWT setup"

    describe "#initialize" do
      it "throws an error for nil token string" do
        expect{ ServicesJwt.new(nil) }.to raise_error(ArgumentError)
      end
    end

    describe "#user_global_id" do
      it "can get the user_id out of a wrapped issued token" do
        user_id = 42
        crypted_token = Canvas::Security.create_services_jwt(user_id)
        payload = {
          iss: "some other service",
          user_token: crypted_token
        }
        wrapper_token = Canvas::Security.create_jwt(payload, nil, signing_secret)
        # because it will come over base64 encoded from any other service
        base64_encoded_wrapper = Canvas::Security.base64_encode(wrapper_token)
        jwt = ServicesJwt.new(base64_encoded_wrapper)
        expect(jwt.user_global_id).to eq(user_id)
      end
    end
  end
end
