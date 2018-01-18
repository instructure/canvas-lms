#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Lti
  class Asset
    def self.opaque_identifier_for(asset)
      shard = asset.shard
      shard.activate do
        lti_context_id = context_id_for(asset, shard)
        set_asset_context_id(asset, lti_context_id)
      end
    end

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
