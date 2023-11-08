# frozen_string_literal: true

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
    def self.opaque_identifier_for(asset, context: nil)
      return if asset.blank?

      shard = asset.shard
      shard.activate do
        lti_context_id = context_id_for(asset, shard)
        set_asset_context_id(asset, lti_context_id, context:)
      end
    end

    def self.set_asset_context_id(asset, lti_context_id, context: nil)
      if asset.respond_to?(:lti_context_id)
        global_context_id = global_context_id_for(asset)
        if asset.new_record?
          asset.lti_context_id = global_context_id
        elsif asset.lti_context_id?
          lti_context_id = (old_id = old_id_for_user_in_context(asset, context)) ? old_id : asset.lti_context_id
        else
          GuardRail.activate(:primary) { asset.reload }
          unless asset.lti_context_id
            asset.lti_context_id = global_context_id
            GuardRail.activate(:primary) do
              asset.save!
            rescue ActiveRecord::RecordNotUnique => e
              raise e unless /index_.+_on_lti_context_id/.match?(e.message)

              conflicting_asset = asset.class.where(lti_context_id: asset.lti_context_id).first
              raise e unless conflicting_asset.present?

              if conflicting_asset.workflow_state == "deleted" && conflicting_asset.canonical?
                conflicting_asset.update_attribute(:lti_context_id, nil)
              else
                asset.lti_context_id = SecureRandom.uuid
              end
              retry
            end
          end
          lti_context_id = asset.lti_context_id
        end
      end
      lti_context_id
    end

    def self.old_id_for_user_in_context(asset, context)
      if asset.is_a?(User) && context
        context.shard.activate do
          if asset.association(:past_lti_ids).loaded?
            asset.past_lti_ids.find do |id|
              id.context_id == context.id && id.context_type == context.class_name
            end&.user_lti_context_id
          else
            asset.past_lti_ids.shard(context.shard).where(context:).pluck(:user_lti_context_id).first
          end
        end
      end
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
