#
# Copyright (C) 2018 - present Instructure, Inc.
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
module Lti
  class KeyStorage
    PAST = 'jwk-past.json'.freeze
    PRESENT = 'jwk-present.json'.freeze
    FUTURE = 'jwk-future.json'.freeze
    LTI_KEYS = 'lti-keys'.freeze
    class << self
      # Retrieve the keys in JSON format
      #
      # @return [Hash] The hash of past, present, and future key
      def retrieve_keys
        { PAST => get_key(PAST), PRESENT => get_key(PRESENT), FUTURE => get_key(FUTURE) }
      end

      # Rotate the keys
      #   The present key becomes the past key; the future key becomes
      #   present; and a newly generated key becomes the future one
      def rotate_keys
        keys = retrieve_keys
        if keys.values.compact.blank?
          initialize_keys
        else
          kvs = {
            PAST => keys[PRESENT].to_json,
            PRESENT => keys[FUTURE].to_json,
            FUTURE => new_key
          }
          consul_proxy.set_keys(kvs, global: true)
        end
        Canvas::DynamicSettings.reset_cache!
      end

      # Retrieve the public keys in JWK format
      #
      # @return [Hash] The hash of public key in JWK format
      def public_keyset
        retrieve_keys.values.map do |private_jwk|
          public_jwk = private_jwk.to_key.public_key.to_jwk
          public_jwk.merge(private_jwk.select{|k,_| %w(alg use kid).include?(k) })
        end
      end

      private

      def initialize_keys
        if retrieve_keys.values.compact.blank?
          kvs = {
            PAST => new_key,
            PRESENT => new_key,
            FUTURE => new_key
          }
          consul_proxy.set_keys(kvs, global: true)
        end
      end

      def get_key(key)
        value = consul_proxy[key]
        JSON::JWK.new(JSON.parse(value)) if value.present?
      end

      def consul_proxy
        Canvas::DynamicSettings.kv_proxy(LTI_KEYS, tree: :store)
      end

      def new_key
        Lti::RSAKeyPair.new.to_jwk.to_json
      end
    end
  end
end
