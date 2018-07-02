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
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Lti::KeyStorage do
  before do
    @fallback_proxy = Canvas::DynamicSettings::FallbackProxy.new({
      Lti::KeyStorage::PAST => Lti::RSAKeyPair.new.to_jwk.to_json,
      Lti::KeyStorage::PRESENT => Lti::RSAKeyPair.new.to_jwk.to_json,
      Lti::KeyStorage::FUTURE => Lti::RSAKeyPair.new.to_jwk.to_json
    })
    allow(Canvas::DynamicSettings).to receive(:kv_proxy).and_return(@fallback_proxy)
  end

  describe '#retrieve_keys_json' do
    it 'retrieves valid keys in json format' do
      expect(Lti::KeyStorage.retrieve_keys.transform_values(&:to_json)).to eq @fallback_proxy.data
    end
  end

  describe "#rotate_keys" do
    it 'rotates the past key' do
      keys_before = Lti::KeyStorage.retrieve_keys
      past = keys_before[Lti::KeyStorage::PAST].to_json
      present = keys_before[Lti::KeyStorage::PRESENT].to_json
      expect{ Lti::KeyStorage.rotate_keys }.to change{ @fallback_proxy.data[Lti::KeyStorage::PAST] }.
        from(past).to(present)
    end

    it 'rotates the present key' do
      keys_before = Lti::KeyStorage.retrieve_keys
      present = keys_before[Lti::KeyStorage::PRESENT].to_json
      future = keys_before[Lti::KeyStorage::FUTURE].to_json
      expect{ Lti::KeyStorage.rotate_keys }.to change{ @fallback_proxy.data[Lti::KeyStorage::PRESENT] }.
        from(present).to(future)
    end

    it 'rotates the future key' do
      expect{ Lti::KeyStorage.rotate_keys }.to change{ @fallback_proxy.data[Lti::KeyStorage::FUTURE] }
    end

    it 'initialize the keys if no keys are present' do
      @fallback_proxy.data.clear
      Lti::KeyStorage.rotate_keys
      expect(
        @fallback_proxy.data.values_at(
          Lti::KeyStorage::PAST,
          Lti::KeyStorage::PRESENT,
          Lti::KeyStorage::FUTURE
        )
      ).not_to include nil
    end

    it 'resets the cache after setting the keys' do
      expect(Canvas::DynamicSettings).to receive(:reset_cache!)
      Lti::KeyStorage.rotate_keys
    end
  end

  describe "#public_keyset" do
    it 'retrieve the public keys in JWK format' do
      keys = Lti::KeyStorage.retrieve_keys
      expect(Lti::KeyStorage.public_keyset.as_json).to eq([
        select_public_claims(JSON::JWK.new(keys[Lti::KeyStorage::PAST])),
        select_public_claims(JSON::JWK.new(keys[Lti::KeyStorage::PRESENT])),
        select_public_claims(JSON::JWK.new(keys[Lti::KeyStorage::FUTURE]))
      ].as_json)
    end
  end

  def select_public_claims(key)
    key.select{|k,_| %w(kty e n kid alg use).include?(k)}
  end

end
