module HmacHelper
  # returns parsed json after verification
  def extract_blob(hmac, json, expected_values = {})
    unless Canvas::Security.verify_hmac_sha1(hmac, json)
      raise Error.new("signature doesn't match.")
    end

    blob = JSON.parse(json)

    expected_values.each { |k, v|
      raise Error.new("invalid value for #{k}") if blob[k] != v
    }

    blob
  end

  class Error < StandardError; end
end
