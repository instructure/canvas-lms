require "spec_helper"

describe CanvasBreachMitigation::MaskingSecrets do
  before do
    Rails = mock("Rails") unless defined? Rails
  end

  let(:masking_secrets) { CanvasBreachMitigation::MaskingSecrets }

  describe ".csrf_token" do
    it "puts :_csrf_token into the supplied object" do
      hash = {}
      masking_secrets.masked_authenticity_token(hash)
      expect(hash['_csrf_token']).not_to be nil
    end

    it "returns a byte string" do
      expect(masking_secrets.masked_authenticity_token({})).not_to be nil
    end
  end

  describe ".valid_authenticity_token?" do
    let(:unmasked_token) { SecureRandom.base64(32) }
    let(:cookies) { {'_csrf_token' => masking_secrets.masked_token(unmasked_token)} }
    let(:session) { {} }

    it "returns true for a valid masked token" do
      valid_masked = masking_secrets.masked_token(unmasked_token)
      expect(masking_secrets.valid_authenticity_token?(session, cookies, valid_masked)).to be true
    end

    it "returns false for an invalid masked token" do
      expect(masking_secrets.valid_authenticity_token?(session, cookies, SecureRandom.base64(64))).to be false
    end

    it "returns false for a token of the wrong length" do
      expect(masking_secrets.valid_authenticity_token?(session, cookies, SecureRandom.base64(2))).to be false
    end

    it "returns true if the session is still set instead of the cookies" do
      cookies.delete('_csrf_token')
      session[:_csrf_token] = SecureRandom.base64(32)
      encoded_masked_token = masking_secrets.masked_token(Base64.strict_decode64(session[:_csrf_token]))
      expect(masking_secrets.valid_authenticity_token?(session, cookies, encoded_masked_token)).to be true
    end
  end

  describe ".masked_authenticity_token" do
    let(:cookies) { {} }

    it "initializes the _csrf_token cookie" do
      token = masking_secrets.masked_authenticity_token(cookies)
      expect(cookies['_csrf_token'][:value]).to eq token
    end

    it "initializes the _csrf_token cookie without explicit domain by default" do
      masking_secrets.masked_authenticity_token(cookies)
      expect(cookies['_csrf_token']).not_to be_has_key(:domain)
    end

    it "initializes the _csrf_token cookie without explicit httponly by default" do
      masking_secrets.masked_authenticity_token(cookies)
      expect(cookies['_csrf_token']).not_to be_has_key(:httponly)
    end

    it "initializes the _csrf_token cookie without explicit secure by default" do
      masking_secrets.masked_authenticity_token(cookies)
      expect(cookies['_csrf_token']).not_to be_has_key(:secure)
    end

    it "copies domain option to _csrf_token cookie" do
      masking_secrets.masked_authenticity_token(cookies, domain: "domain")
      expect(cookies['_csrf_token'][:domain]).to eq "domain"
    end

    it "copies httponly option to _csrf_token cookie" do
      masking_secrets.masked_authenticity_token(cookies, httponly: true)
      expect(cookies['_csrf_token'][:httponly]).to be true
    end

    it "copies secure option to _csrf_token cookie" do
      masking_secrets.masked_authenticity_token(cookies, secure: true)
      expect(cookies['_csrf_token'][:secure]).to be true
    end

    it "remasks an existing _csrf_token cookie" do
      original_token = masking_secrets.masked_token(SecureRandom.base64(32))
      cookies['_csrf_token'] = original_token
      token = masking_secrets.masked_authenticity_token(cookies)
      expect(token).not_to eq original_token
      expect(cookies['_csrf_token'][:value]).to eq token
      expect(masking_secrets.valid_authenticity_token?({}, {'_csrf_token' => token}, original_token)).to be true
    end
  end
end
