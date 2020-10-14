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
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Canvas::Security::KeyStorage do
  before do
    @fallback_proxy = Canvas::DynamicSettings::FallbackProxy.new({
      Canvas::Security::KeyStorage::PAST => Canvas::Security::KeyStorage.new_key,
      Canvas::Security::KeyStorage::PRESENT => Canvas::Security::KeyStorage.new_key,
      Canvas::Security::KeyStorage::FUTURE => Canvas::Security::KeyStorage.new_key
    })

    allow(Canvas::DynamicSettings).to receive(:kv_proxy).and_return(@fallback_proxy)
    @key_storage = Canvas::Security::KeyStorage.new('mocked')
  end

  describe '#retrieve_keys_json' do
    it 'retrieves valid keys in json format' do
      expect(@key_storage.retrieve_keys.transform_values(&:to_json)).to eq @fallback_proxy.data
    end
  end

  describe "#rotate_keys" do
    context 'when run more than min_rotation_period after last run' do 
      before do
        allow(@key_storage).to receive(:min_rotation_period).and_return(0)
      end

      it 'rotates the past key' do
        keys_before = @key_storage.retrieve_keys
        past = keys_before[Canvas::Security::KeyStorage::PAST].to_json
        present = keys_before[Canvas::Security::KeyStorage::PRESENT].to_json
        expect{ @key_storage.rotate_keys }.to change{ @fallback_proxy.data[Canvas::Security::KeyStorage::PAST] }.
          from(past).to(present)
      end

      it 'rotates the present key' do
        keys_before = @key_storage.retrieve_keys
        present = keys_before[Canvas::Security::KeyStorage::PRESENT].to_json
        future = keys_before[Canvas::Security::KeyStorage::FUTURE].to_json
        expect{ @key_storage.rotate_keys }.to change{ @fallback_proxy.data[Canvas::Security::KeyStorage::PRESENT] }.
          from(present).to(future)
      end

      it 'rotates the future key' do
        expect{ @key_storage.rotate_keys }.to change{ @fallback_proxy.data[Canvas::Security::KeyStorage::FUTURE] }
      end

      it 'initialize the keys if no keys are present' do
        @fallback_proxy.data.clear
        @key_storage.rotate_keys
        expect(
          @fallback_proxy.data.values_at(
            Canvas::Security::KeyStorage::PAST,
            Canvas::Security::KeyStorage::PRESENT,
            Canvas::Security::KeyStorage::FUTURE
          )
        ).not_to include nil
      end

      it 'resets the cache after setting the keys' do
        expect(Canvas::DynamicSettings).to receive(:reset_cache!)
        @key_storage.rotate_keys
      end
    end

    it 'only rotates if more than 1 hour has passed since last rotating' do
      keys_before = @key_storage.retrieve_keys
      # We rely on the fact the the kid is the time the key was generated.
      # Double-check that here.
      future_key_time = Time.zone.parse(keys_before[Canvas::Security::KeyStorage::FUTURE]['kid'])
      expect(future_key_time).to be_within(29).of(Time.zone.now)

      Timecop.freeze(future_key_time + 59.minutes) do
        expect { @key_storage.rotate_keys }.not_to change { @fallback_proxy.data[Canvas::Security::KeyStorage::PRESENT] }
      end

      Timecop.freeze(future_key_time + 61.minutes) do
        present = keys_before[Canvas::Security::KeyStorage::PRESENT].to_json
        future = keys_before[Canvas::Security::KeyStorage::FUTURE].to_json
        expect{ @key_storage.rotate_keys }.to change{ @fallback_proxy.data[Canvas::Security::KeyStorage::PRESENT] }.
          from(present).to(future)
      end
    end
  end

  describe "#public_keyset" do
    it 'retrieve the public keys in JWK format' do
      keys = @key_storage.retrieve_keys
      expect(@key_storage.public_keyset.as_json).to eq([
        select_public_claims(JSON::JWK.new(keys[Canvas::Security::KeyStorage::PAST])),
        select_public_claims(JSON::JWK.new(keys[Canvas::Security::KeyStorage::PRESENT])),
        select_public_claims(JSON::JWK.new(keys[Canvas::Security::KeyStorage::FUTURE]))
      ].as_json)
    end
  end

  def select_public_claims(key)
    key.select{|k,_| %w(kty e n kid alg use).include?(k)}
  end

end
