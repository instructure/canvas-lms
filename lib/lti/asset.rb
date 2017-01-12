module Lti
  class Asset

    def self.opaque_identifier_for(asset)
      shard = asset.shard
      shard.activate do
        lti_context_id = context_id_for(asset, shard)
        set_asset_context_id(asset, lti_context_id)
      end
    end

    private

    def self.set_asset_context_id(asset, context_id)
      lti_context_id = context_id
      if asset.respond_to?('lti_context_id')
        global_context_id = global_context_id_for(asset)
        if asset.new_record?
          asset.lti_context_id = global_context_id
        else
          asset.reload unless asset.lti_context_id?
          unless asset.lti_context_id
            asset.lti_context_id = global_context_id
            asset.save!
          end
          lti_context_id = asset.lti_context_id
        end
      end
      lti_context_id
    end

    def self.context_id_for(asset, shard = nil)
      shard ||= asset.shard
      str = asset.asset_string.to_s
      raise "Empty value" if str.blank?
      Canvas::Security.hmac_sha1(str, shard.settings[:encryption_key])
    end

    def self.global_context_id_for(asset)
      str = asset.global_asset_string.to_s
      raise "Empty value" if str.blank?
      Canvas::Security.hmac_sha1(str, asset.shard.settings[:encryption_key])
    end

  end
end
