require_relative '../../../spec_helper'

module Canvas::Security
  describe ServicesJwt do
    include_context "JWT setup"

    def build_wrapped_token(user_id)
      crypted_token = ServicesJwt.generate({ sub: user_id }, false)
      payload = {
        iss: "some other service",
        user_token: crypted_token
      }
      wrapper_token = Canvas::Security.create_jwt(payload, nil, fake_signing_secret)
      # because it will come over base64 encoded from any other service
      Canvas::Security.base64_encode(wrapper_token)
    end

    it "has secrets accessors" do
      expect(ServicesJwt.encryption_secret).to eq(fake_encryption_secret)
      expect(ServicesJwt.signing_secret).to eq(fake_signing_secret)
    end

    describe "#initialize" do
      it "throws an error for nil token string" do
        expect{ ServicesJwt.new(nil) }.to raise_error(ArgumentError)
      end
    end

    describe "#wrapper_token" do
      let(:user_id){ 42 }

      it "is the body of the wrapper token if wrapped" do
        base64_encoded_wrapper = build_wrapped_token(user_id)
        jwt = ServicesJwt.new(base64_encoded_wrapper)
        expect(jwt.wrapper_token[:iss]).to eq("some other service")
      end

      it "is an empty hash if an unwrapped token" do
        original_token = ServicesJwt.generate(sub: user_id)
        jwt = ServicesJwt.new(original_token, false)
        expect(jwt.wrapper_token).to eq({})
      end
    end

    describe "#user_global_id" do

      it "can get the user_id out of a wrapped issued token" do
        user_id = 42
        base64_encoded_wrapper = build_wrapped_token(user_id)
        jwt = ServicesJwt.new(base64_encoded_wrapper)
        expect(jwt.user_global_id).to eq(user_id)
      end
    end

    describe "initialization" do
      after{ Timecop.return }
      let(:jwt_string){ ServicesJwt.generate(sub: 1) }

      it "uses SecureRandom for generating the JWT" do
        SecureRandom.stubs(uuid: "some-secure-random-string")
        jwt = ServicesJwt.new(jwt_string, false)
        expect(jwt.id).to eq("some-secure-random-string")
      end

      it "expires in an hour" do
        Timecop.freeze(Time.utc(2013,3,13,9,12))
        jwt = ServicesJwt.new(jwt_string, false)
        expect(jwt.expires_at).to eq(1363169520)
      end

      describe "via .generate" do

        let(:base64_regex) do
          %r{^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$}
        end

        let(:jwt_string){ ServicesJwt.generate(sub: 1) }

        it "builds an encoded token out" do
          expect(jwt_string).to match(base64_regex)
        end

        it "can return just the encrypted token without base64 encoding" do
          jwt = ServicesJwt.generate({ sub: 1 }, false)
          expect(jwt).to_not match(base64_regex)
        end

        it "allows the introduction of arbitrary data" do
          jwt = ServicesJwt.generate(sub: 2, foo: "bar")
          decoded_crypted_token = Canvas::Security.base64_decode(jwt)
          decrypted_token_body = Canvas::Security.decrypt_services_jwt(decoded_crypted_token)
          expect(decrypted_token_body[:foo]).to eq("bar")
        end

        it "errors if you try to pass data without a sub entry" do
          expect{ ServicesJwt.generate(foo: "bar", bang: "baz") }.
            to raise_error(ArgumentError)
        end

      end
    end
  end
end
