#
# Copyright (C) 2016 - present Instructure, Inc.
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

class AuthenticationProvider::SAML::Federation < AuthenticationProvider::SAML::MetadataRefresher
  class << self
    def metadata
      Shard.default.activate do
        if Canvas.redis_enabled?
          deflated = Canvas.redis.get("#{class_name.downcase}_metadata")
          existing_data = Zlib::Inflate.inflate(deflated) if deflated
        end
        new_data = refresh_if_necessary(class_name.downcase, endpoint, force_fetch: !existing_data)
        validate_and_parse_metadata(new_data || existing_data)
      end
    end

    def refresh_providers(shard_scope: Shard.in_current_region, providers: nil)
      providers ||= AuthenticationProvider::SAML.active.
        where(metadata_uri: self::URN).shard(shard_scope)

      # don't even bother checking the federation if no one is using it
      # (but a multi-shard environment probably is, and it's expensive
      # to check them all, so just check the federation)
      return if Shard.count <= 1 && !providers.exists?

      new_data = Shard.default.activate { refresh_if_necessary(class_name.downcase, endpoint) }
      # no changes; don't bother with the hard work
      return unless new_data

      metadata = validate_and_parse_metadata(new_data)

      providers.each do |provider|
        entity = metadata[provider.idp_entity_id]

        unless entity
          ::Canvas::Errors.capture_exception(:saml_federation,
                                             "Entity #{provider.idp_entity_id} not found in #{class_name} metadata")
          next
        end

        begin
          provider.populate_from_metadata(entity)
          provider.save! if provider.changed?
        rescue => e
          ::Canvas::Errors.capture_exception(:saml_federation, e)
        end
      end
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
      unless entities.valid_signature?(cert: cert)
        raise "Invalid signature!"
      end

      entities.index_by(&:entity_id)
    end

    def refresh_if_necessary(*)
      result = super
      # save the new data if there is any
      if Canvas.redis_enabled? && result
        Canvas.redis.set("#{class_name.downcase}_metadata", Zlib::Deflate.deflate(result, 9))
      end
      result
    end
  end
end

# make sure to force these to eager load, otherwise we may try to iterate
# all federations, but there won't be any
require_dependency 'authentication_provider/saml/in_common'
require_dependency 'authentication_provider/saml/uk_federation'
