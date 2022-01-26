# frozen_string_literal: true

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

require "spec_helper"

describe CanvasSecurity::KeyStorage do
  before do
    @fallback_proxy = DynamicSettings::FallbackProxy.new({
                                                           CanvasSecurity::KeyStorage::PAST => CanvasSecurity::KeyStorage.new_key,
                                                           CanvasSecurity::KeyStorage::PRESENT => CanvasSecurity::KeyStorage.new_key,
                                                           CanvasSecurity::KeyStorage::FUTURE => CanvasSecurity::KeyStorage.new_key
                                                         })

    allow(DynamicSettings).to receive(:kv_proxy).and_return(@fallback_proxy)
    @key_storage = CanvasSecurity::KeyStorage.new("mocked")
  end

  describe "#retrieve_keys_json" do
    it "retrieves valid keys in json format" do
      expect(@key_storage.retrieve_keys.transform_values(&:to_json)).to eq @fallback_proxy.data
    end
  end

  describe "#rotate_keys" do
    let(:keys_before) { @key_storage.retrieve_keys }
    let(:future_kid) { keys_before.dig(CanvasSecurity::KeyStorage::FUTURE, "kid") }
    let(:future_kid_time) { CanvasSecurity::JWKKeyPair.time_from_kid(future_kid) }

    context "when run more than 60 minutes after last run" do
      before do
        allow(CanvasSecurity::JWKKeyPair).to receive(:time_from_kid).and_return(future_kid_time - 61.minutes)
      end

      it "rotates the past key" do
        past = keys_before[CanvasSecurity::KeyStorage::PAST].to_json
        present = keys_before[CanvasSecurity::KeyStorage::PRESENT].to_json
        expect { @key_storage.rotate_keys }.to change { @fallback_proxy.data[CanvasSecurity::KeyStorage::PAST] }
          .from(past).to(present)
      end

      it "rotates the present key" do
        present = keys_before[CanvasSecurity::KeyStorage::PRESENT].to_json
        future = keys_before[CanvasSecurity::KeyStorage::FUTURE].to_json
        expect { @key_storage.rotate_keys }.to change { @fallback_proxy.data[CanvasSecurity::KeyStorage::PRESENT] }
          .from(present).to(future)
      end

      it "rotates the future key" do
        expect { @key_storage.rotate_keys }.to change { @fallback_proxy.data[CanvasSecurity::KeyStorage::FUTURE] }
      end

      it "initialize the keys if no keys are present" do
        @fallback_proxy.data.clear
        @key_storage.rotate_keys
        expect(
          @fallback_proxy.data.values_at(
            CanvasSecurity::KeyStorage::PAST,
            CanvasSecurity::KeyStorage::PRESENT,
            CanvasSecurity::KeyStorage::FUTURE
          )
        ).not_to include nil
      end

      it "resets the cache after setting the keys" do
        expect(DynamicSettings).to receive(:reset_cache!)
        @key_storage.rotate_keys
      end
    end

    context "when run less than 60 minutes after last run" do
      before do
        allow(CanvasSecurity::JWKKeyPair).to receive(:time_from_kid).and_return(future_kid_time - 59.minutes)
      end

      it "does not rotate keys" do
        expect { @key_storage.rotate_keys }.not_to change { @fallback_proxy.data[CanvasSecurity::KeyStorage::PRESENT] }
      end
    end
  end

  describe "#public_keyset" do
    it "retrieve the public keys in JWK format" do
      keys = @key_storage.retrieve_keys
      expect(JSON.parse(@key_storage.public_keyset.as_json.to_json)).to eq(JSON.parse({ keys: [
        select_public_claims(JSON::JWK.new(keys[CanvasSecurity::KeyStorage::PAST])),
        select_public_claims(JSON::JWK.new(keys[CanvasSecurity::KeyStorage::PRESENT])),
        select_public_claims(JSON::JWK.new(keys[CanvasSecurity::KeyStorage::FUTURE]))
      ] }.to_json))
    end
  end

  def select_public_claims(key)
    key.select { |k, _| %w[kty e n kid alg use].include?(k) }
  end
end
