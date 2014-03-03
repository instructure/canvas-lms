require "spec_helper"

describe CanvasBreachMitigation::MaskingSecrets do
  before do
    Rails = double("Rails").as_null_object unless defined? Rails
  end

  let(:masking_secrets) { CanvasBreachMitigation::MaskingSecrets }

  describe ".masked_authenticity_token" do
    it "puts :_csrf_token into the supplied session" do
      session = {}
      masking_secrets.masked_authenticity_token(session)
      session[:_csrf_token].should_not be_nil
    end

    it "returns a byte string" do
      masking_secrets.masked_authenticity_token({}).should_not be nil
    end
  end

  describe ".valid_authenticity_token?" do
    let(:session) do
      # Seed a session with a :_csrf_token
      Hash.new.tap do |session|
        masking_secrets.masked_authenticity_token(session)
      end
    end

    it "returns true for a valid unmasked token" do
      valid_unmasked = session[:_csrf_token]
      masking_secrets.valid_authenticity_token?(session, valid_unmasked).should == true
    end

    it "returns false for an invalid unmasked token" do
      masking_secrets.valid_authenticity_token?(session, SecureRandom.base64(32)).should == false
    end

    it "returns true for a valid masked token" do
      valid_masked = masking_secrets.masked_authenticity_token(session)
      masking_secrets.valid_authenticity_token?(session, valid_masked).should == true
    end

    it "returns false for an invalid masked token" do
      masking_secrets.valid_authenticity_token?(session, SecureRandom.base64(64)).should == false
    end

    it "returns false for a token of the wrong length" do
      masking_secrets.valid_authenticity_token?(session, SecureRandom.base64(2)).should == false
    end
  end
end