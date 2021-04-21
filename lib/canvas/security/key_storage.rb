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

module Canvas::Security
  class KeyStorage
    PAST = 'jwk-past.json'.freeze
    PRESENT = 'jwk-present.json'.freeze
    FUTURE = 'jwk-future.json'.freeze
    MAX_CACHE_AGE = 10.days.to_i
    MIN_ROTATION_PERIOD = 1.hour

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
        return if (Time.zone.now - Time.zone.parse(keys.dig(FUTURE, 'kid'))) < min_rotation_period.to_i

        kvs = {
          PAST => keys[PRESENT].to_json,
          PRESENT => keys[FUTURE].to_json,
          FUTURE => KeyStorage.new_key
        }
        consul_proxy.set_keys(kvs, global: true)
      end
      Canvas::DynamicSettings.reset_cache!
    end

    # Retrieve the public keys in JWK format
    #
    # @return [Array] The array of public keys in JWK format
    def public_keyset
      retrieve_keys.values.map do |private_jwk|
        public_jwk = private_jwk.to_key.public_key.to_jwk
        public_jwk.merge(private_jwk.select{|k,_| %w(alg use kid).include?(k) })
      end
    end

    # Retrieve the present key
    #
    # @return [JSON::JWK] the present private key
    def present_key
      get_key(PRESENT)
    end

    def max_cache_age
      self.class.max_cache_age
    end

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
      @consul_proxy ||= Canvas::DynamicSettings.kv_proxy(@prefix, tree: :store)
    end

    def self.max_cache_age
      Setting.get('public_jwk_cache_age_in_seconds', MAX_CACHE_AGE)
    end

    def self.new_key
      Canvas::Security::RSAKeyPair.new.to_jwk.to_json
    end
  end
end
