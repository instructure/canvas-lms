require "spec_helper"

describe CanvasBreachMitigation::MaskingSecrets do
  before do
    Rails = double("Rails").as_null_object unless defined? Rails
  end

  let(:masking_secrets) { CanvasBreachMitigation::MaskingSecrets }

  describe ".csrf_token" do
    it "puts :_csrf_token into the supplied object" do
      hash = {}
      masking_secrets.masked_authenticity_token(hash)
      hash['_csrf_token'].should_not be_nil
    end

    it "returns a byte string" do
      masking_secrets.masked_authenticity_token({}).should_not be nil
    end
  end

  describe ".valid_authenticity_token?" do
    let(:cookies) do
      # Seed a "cookie jar" with a :_csrf_token
      Hash.new.tap do |cookies|
        masking_secrets.masked_authenticity_token(cookies)
      end
    end

    let(:session) do
      Hash.new
    end

    it "returns true for a valid unmasked token" do
      valid_unmasked = cookies['_csrf_token']
      masking_secrets.valid_authenticity_token?(session, cookies, valid_unmasked).should == true
    end

    it "returns false for an invalid unmasked token" do
      masking_secrets.valid_authenticity_token?(session, cookies, SecureRandom.base64(32)).should == false
    end

    it "returns true for a valid masked token" do
      valid_masked = masking_secrets.masked_authenticity_token(cookies)
      masking_secrets.valid_authenticity_token?(session, cookies, valid_masked).should == true
    end

    it "returns false for an invalid masked token" do
      masking_secrets.valid_authenticity_token?(session, cookies, SecureRandom.base64(64)).should == false
    end

    it "returns false for a token of the wrong length" do
      masking_secrets.valid_authenticity_token?(session, cookies, SecureRandom.base64(2)).should == false
    end

    it "returns true if the session is still set instead of the cookies" do
      cookies.delete('_csrf_token')

      session[:_csrf_token] = SecureRandom.base64(32)
      one_time_pad = SecureRandom.random_bytes(32)

      encrypted_csrf_token = masking_secrets.send(:xor_byte_strings, one_time_pad, Base64.strict_decode64(session[:_csrf_token]))
      masked_token = one_time_pad + encrypted_csrf_token
      encoded_masked_token = Base64.strict_encode64(masked_token)

      masking_secrets.valid_authenticity_token?(session, cookies, encoded_masked_token).should == true
    end
  end
end