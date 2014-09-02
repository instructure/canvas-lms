module Wiziq
  class AuthBase
    require 'openssl'
    require 'base64'

    attr_reader :secret_key, :signature_base

    def initialize(secret_key, signature_base)
      @secret_key = secret_key
      @signature_base = signature_base
    end

    def generate_hmac_digest
      raise "Signature base is not set" if @signature_base.nil?
      hmac_sign = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), CGI::escape(@secret_key), @signature_base)
      hmac_digest = Base64.encode64(hmac_sign)
      hmac_digest.gsub(/\n/, "")
    end
  end
end
