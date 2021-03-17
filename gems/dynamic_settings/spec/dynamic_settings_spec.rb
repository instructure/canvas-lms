# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "spec_helper"

describe DynamicSettings do
  before do
    @cached_config = DynamicSettings.config
    @cached_fallback_data = DynamicSettings.fallback_data
    fake_conf_location = Pathname.new(File.join(File.dirname(__FILE__), 'fixtures'))
    allow(Rails).to receive(:root).and_return(fake_conf_location)
  end

  after do
    begin
      DynamicSettings.config = @cached_config
    rescue Imperium::UnableToConnectError, Imperium::TimeoutError
      # don't fail the test if there is no consul running
      DynamicSettings.logger.debug("failed config reset because no consul")
    end
    DynamicSettings.fallback_data = @cached_fallback_data
    DynamicSettings.reset_cache!
  end

  let(:parent_key){ 'rich-content-service' }
  let(:imperium_read_options){ [:recurse, :stale] }
  let(:kv_client) { DynamicSettings.kv_client }
  let(:valid_config) do
    {
      'host'        =>'consul',
      'port'        => 8500,
      'ssl'         => true,
      'acl_token'   => 'some-long-string',
      'environment' => 'rspec',
    }
  end

  describe ".config=" do
    it "configures imperium when config is set" do
      DynamicSettings.config = valid_config
      expect(Imperium.configuration.url.to_s).to eq("https://consul:8500")
    end

    it 'must pass through timeout settings to the underlying library' do
      DynamicSettings.config = valid_config.merge({
        'connect_timeout' => 1,
        'send_timeout' => 2,
        'receive_timeout' => 3,
      })

      client_config = kv_client.config
      expect(client_config.connect_timeout).to eq 1
      expect(client_config.send_timeout).to eq 2
      expect(client_config.receive_timeout).to eq 3
    end

    it 'must capture the environment name when supplied' do
      DynamicSettings.config = valid_config.merge({
        'environment' => 'foobar'
      })

      expect(DynamicSettings.environment).to eq 'foobar'
    end
  end

  describe ".on_fork!" do
    it "clears any held imperium client" do
      DynamicSettings.config = valid_config
      cur_client = Imperium::KV.default_client
      expect(DynamicSettings.kv_client.object_id).to eq(cur_client.object_id)
      Imperium::KV.reset_default_client
      DynamicSettings.on_fork!
      expect(DynamicSettings.kv_client).to_not be_nil
      expect(DynamicSettings.kv_client.object_id).to_not eq(cur_client.object_id)
    end
  end

  describe '.fallback_data =' do
    it 'must provide indifferent access on resulting proxy' do
      DynamicSettings.fallback_data = {foo: 'bar'}
      proxy = DynamicSettings.root_fallback_proxy
      expect(proxy['foo']).to eq 'bar'
      expect(proxy[:foo]).to eq 'bar'
    end

    it 'must clear the fallback when passed nil' do
      DynamicSettings.fallback_data = {foo: 'bar'}
      DynamicSettings.fallback_data = nil
      proxy = DynamicSettings.root_fallback_proxy
      expect(proxy['foo']).to be_nil
    end
  end

  describe '.find' do
    context "when consul is configured" do
      before do
        DynamicSettings.config = valid_config
      end

      it 'must return a PrefixProxy when consul is configured' do
        proxy = DynamicSettings.find('foo')
        expect(proxy).to be_a(DynamicSettings::PrefixProxy)
      end
    end

    context "when consul is not configured" do
      let(:data) do
        {
          config: {
            canvas: {foo: {bar: 'baz'}},
            frobozz: {some: {thing: 'magic'}}
          },
          private: {
            canvas: {zab: {rab: 'oof'}}
          }
        }
      end

      before do
        DynamicSettings.config = nil
        DynamicSettings.fallback_data = data
      end

      after do
        DynamicSettings.fallback_data = nil
      end

      it 'must return an empty FallbackProxy when fallback data is also unconfigured' do
        DynamicSettings.fallback_data = nil
        expect(DynamicSettings.find('foo')).to be_a(DynamicSettings::FallbackProxy)
        expect(DynamicSettings.find('foo')['bar']).to eq nil
      end

      it 'must return a FallbackProxy with configured fallback data' do
        proxy = DynamicSettings.find('foo', tree: 'config', service: 'canvas')
        expect(proxy).to be_a(DynamicSettings::FallbackProxy)
        expect(proxy[:bar]).to eq 'baz'
      end

      it 'must default the the config tree' do
        proxy = DynamicSettings.find('foo', service: 'canvas')
        expect(proxy['bar']).to eq 'baz'
      end

      it 'must handle an alternate tree' do
        proxy = DynamicSettings.find('zab', tree: 'private', service: 'canvas')
        expect(proxy['rab']).to eq 'oof'
      end

      it 'must default to the canvas service' do
        proxy = DynamicSettings.find('foo', tree: 'config')
        expect(proxy['bar']).to eq 'baz'
      end

      it 'must accept an alternate service' do
        proxy = DynamicSettings.find('some', tree: 'config', service: 'frobozz')
        expect(proxy['thing']).to eq 'magic'
      end

      it 'must ignore a nil prefix' do
        proxy = DynamicSettings.find(tree: 'config', service: 'canvas')
        expect(proxy.for_prefix('foo')['bar']).to eq 'baz'
      end
    end
  end
end
