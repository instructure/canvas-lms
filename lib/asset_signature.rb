
module AssetSignature
  DELIMITER = '-'

  def self.generate(asset)
    "#{asset.id}#{DELIMITER}#{generate_hmac(asset.class, asset.id)}"
  end

  def self.find_by_signature(klass, signature)
    id, hmac = signature.split(DELIMITER, 2)
    return nil unless Canvas::Security.verify_hmac_sha1(hmac, "#{klass}#{id}", truncate: 8)
    klass.where(id: id.to_i).first
  end

  private

  def self.generate_hmac(klass, id)
    data = "#{klass}#{id}"
    Canvas::Security.hmac_sha1(data)[0,8]
  end
end
