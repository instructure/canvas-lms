
module AssetSignature
  DELIMITER = '-'

  def self.generate(asset)
    "#{asset.id}#{DELIMITER}#{generate_hmac(asset.class, asset.id)}"
  end

  def self.find_by_signature(klass, signature)

    #TODO: Remove this after the next release cycle
    # it's just here for temporary backwards compatibility
    if signature.to_i.to_s.length == signature.length
      return klass.where(id: signature).first
    end
    ###############################################

    id, hmac = signature.split(DELIMITER, 2)
    return nil unless hmac == generate_hmac(klass, id)
    klass.where(id: id.to_i).first
  end

  private

  def self.generate_hmac(klass, id)
    data = "#{klass.to_s}#{id}"
    Canvas::Security.hmac_sha1(data)[0,8]
  end
end
