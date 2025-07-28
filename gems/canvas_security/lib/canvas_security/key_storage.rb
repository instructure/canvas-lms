# frozen_string_literal: true

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

module CanvasSecurity
  class KeyStorage
    PAST = "jwk-past.json"
    PRESENT = "jwk-present.json"
    FUTURE = "jwk-future.json"
    MAX_CACHE_AGE = 10.days.to_i
    MIN_ROTATION_PERIOD = 1.hour

    class << self
      def max_cache_age
        Setting.get("public_jwk_cache_age_in_seconds", MAX_CACHE_AGE)
      end

      def new_key
        CanvasSecurity::RSAKeyPair.new.to_jwk.to_json
      end
    end

    def initialize(prefix)
      @prefix = prefix
    end

    # Retrieve the keys in JSON format
    #
    # @return [Hash] The hash of past, present, and future key
    def retrieve_keys
      { PAST => get_key(PAST), PRESENT => get_key(PRESENT), FUTURE => get_key(FUTURE) }
    end

    # Do not rotate keys unless this much time has passed since last rotation.
    # Prevents accidental multiple rotation if the job to rotate has been
    # enqueued multiple times.
    def min_rotation_period
      MIN_ROTATION_PERIOD
    end

    # Rotate the keys
    #   The present key becomes the past key; the future key becomes
    #   present; and a newly generated key becomes the future one
    def rotate_keys
      keys = retrieve_keys
      if keys.values.compact.blank?
        initialize_keys
      else
        kid_time = CanvasSecurity::JWKKeyPair.time_from_kid(keys.dig(FUTURE, "kid"))
        return if (Time.zone.now - kid_time) < min_rotation_period.to_i

        kvs = {
          PAST => keys[PRESENT].to_json,
          PRESENT => keys[FUTURE].to_json,
          FUTURE => KeyStorage.new_key
        }
        consul_proxy.set_keys(kvs, global: true)
      end
      DynamicSettings.reset_cache!
    end

    # Retrieve the public keys in JWK format
    #
    # @return [Array] The array of public keys in JWK format
    def public_keyset
      JSON::JWK::Set.new(retrieve_keys.values.compact.map do |private_jwk|
        public_jwk = private_jwk.to_key.public_key.to_jwk
        public_jwk.merge(private_jwk.slice("alg", "use", "kid"))
      end)
    end

    # Retrieve the present key
    #
    # @return [JSON::JWK] the present private key
    def present_key
      get_key(PRESENT)
    end

    delegate :max_cache_age, to: :class

    private

    def initialize_keys
      if retrieve_keys.values.compact.blank?
        kvs = {
          PAST => KeyStorage.new_key,
          PRESENT => KeyStorage.new_key,
          FUTURE => KeyStorage.new_key
        }
        consul_proxy.set_keys(kvs, global: true)
      end
    end

    def get_key(key)
      value = consul_proxy[key]
      JSON::JWK.new(JSON.parse(value)) if value.present?
    end

    def consul_proxy
      @consul_proxy ||= DynamicSettings.kv_proxy(@prefix, tree: :store)
    end
  end
end
