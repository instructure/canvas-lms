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

require_relative "../../spec_helper"
require_dependency "canvas/dynamic_settings"
require 'imperium/testing' # Not loaded by default

module Canvas
  describe DynamicSettings do
    before do
      @cached_config = DynamicSettings.config
    end

    after do
      begin
        DynamicSettings.config = @cached_config
      rescue Imperium::UnableToConnectError, Imperium::TimeoutError
        # don't fail the test if there is no consul running
      end
      Canvas::DynamicSettings.reset_cache!
      Canvas::DynamicSettings.fallback_data = nil
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

    describe '.fallback_data =' do
      before(:each) do
        @original_fallback = DynamicSettings.fallback_data
      end

      after(:each) do
        DynamicSettings.fallback_data = @original_fallback
      end

      it 'must convert the supplied hash to one with indifferent access' do
        DynamicSettings.fallback_data = {}
        expect(DynamicSettings.fallback_data).to be_a(ActiveSupport::HashWithIndifferentAccess)
      end

      it 'must clear the fallback data when passed nil' do
        DynamicSettings.fallback_data = {}
        DynamicSettings.fallback_data = nil
        expect(DynamicSettings.fallback_data).to be_nil
      end
    end

    describe '.find' do
      before(:each) do
        @original_fallback = DynamicSettings.fallback_data
      end

      after(:each) do
        DynamicSettings.config = nil
        DynamicSettings.fallback_data = @original_fallback
      end

      it 'must return a PrefixProxy when consul is configured' do
        DynamicSettings.config = valid_config
        proxy = DynamicSettings.find('foo')
        expect(proxy).to be_a(DynamicSettings::PrefixProxy)
      end

      it 'must return a FallbackProxy when neither consul or fallback data have been configured' do
        allow(DynamicSettings).to receive(:kv_client).and_return(nil)
        DynamicSettings.fallback_data = nil
        expect(DynamicSettings.find('foo')).to be_a(DynamicSettings::FallbackProxy)
        expect(DynamicSettings.find('foo')['bar']).to eq nil
      end

      it 'must return a FallbackProxy when consul is not configured' do
        allow(DynamicSettings).to receive(:kv_client).and_return(nil)
        DynamicSettings.fallback_data = {'foo' => {bar: 'baz'}}
        proxy = DynamicSettings.find('foo')
        expect(proxy).to be_a(DynamicSettings::FallbackProxy)
      end
    end
  end
end
