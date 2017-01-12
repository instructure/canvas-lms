#
# Copyright (C) 2013 Instructure, Inc.
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
#

require 'saml2'

class AccountAuthorizationConfig::SAML::InCommon < AccountAuthorizationConfig::SAML::MetadataRefresher
  URN = 'urn:mace:incommon'.freeze

  class << self
    def metadata
      if Canvas.redis_enabled?
        deflated = Canvas.redis.get('incommon_metadata')
        existing_data = Zlib::Inflate.inflate(deflated) if deflated
      end
      new_data = refresh_if_necessary('incommon', endpoint, force_fetch: !existing_data)
      validate_and_parse_metadata(new_data || existing_data)
    end

    def refresh_providers(shard_scope: Shard.in_current_region, providers: nil)
      providers ||= AccountAuthorizationConfig::SAML.active.
          where(metadata_uri: URN).shard(shard_scope)

      # don't even bother checking InCommon if no one is using it
      # (but a multi-shard environment probably is, and it's expensive
      # to check them all, so just check InCommon)
      return if Shard.count <= 1 && !providers.exists?

      new_data = refresh_if_necessary('incommon', endpoint)
      # no changes; don't bother with the hard work
      return unless new_data

      metadata = validate_and_parse_metadata(new_data)

      providers.each do |provider|
        entity = metadata[provider.idp_entity_id]

        unless entity
          ::Canvas::Errors.capture_exception(:incommon,
            "Entity #{provider.idp_entity_id} not found in InCommon metadata")
          next
        end

        begin
          provider.populate_from_metadata(entity)
          provider.save! if provider.changed?
        rescue => e
          ::Canvas::Errors.capture_exception(:incommon, e)
        end
      end
    end

    def endpoint
      Setting.get('incommon_metadata_url', 'http://md.incommon.org/InCommon/InCommon-metadata.xml')
    end

    private

    def validate_and_parse_metadata(xml)
      entities = SAML2::Entity.parse(xml)
      raise "Expected a group of entities" unless entities.is_a?(SAML2::Entity::Group)
      raise "Invalid XML" unless entities.valid_schema?
      unless entities.valid_until && entities.valid_until > Time.now.utc
        raise "Problem with validUntil: #{entities.valid_until}"
      end
      raise "Not signed!" unless entities.signed?
      unless entities.valid_signature?(cert: Rails.root.join("config/saml/inc-md-cert.pem").read)
        raise "Invalid signature!"
      end

      entities.index_by(&:entity_id)
    end

    def refresh_if_necessary(*args)
      result = super
      # save the new data if there is any
      if Canvas.redis_enabled? && result
        Canvas.redis.set('incommon_metadata', Zlib::Deflate.deflate(result, 9))
      end
      result
    end
  end
end
