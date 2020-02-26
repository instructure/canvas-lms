#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_dependency "canvas/vault"

module Canvas
  describe Vault do
    include WebMock::API

    let(:token){ 'canvas_token' }
    let(:token_path){ '/path/to/token' }
    let(:addr) { 'http://vault:8200' }
    let(:addr_path) { '/path/to/addr' }
    let(:static_config) { 
      {
      token: token,
      addr: addr,
      kv_mount: 'app-canvas'
    } }
    let(:path_config) { 
      {
      token_path: token_path,
      addr_path: addr_path,
      kv_mount: 'app-canvas'
    } }

    before do
      LocalCache.clear
      WebMock.disable_net_connect!
    end

    after do
      WebMock.enable_net_connect!
    end

    describe '.api_client' do
      context 'Static config' do
        it 'Constructs a client using the address and path from the config' do
          allow(described_class).to receive(:config).and_return(static_config)

          expect(described_class.api_client.address).to eq(addr)
          expect(described_class.api_client.token).to eq(token)
        end
      end

      context 'Path config' do
        it 'Constructs a client using the address and path from the config' do
          allow(described_class).to receive(:config).and_return(path_config)

          allow(File).to receive(:read).with(token_path).and_return(token + '_frompath')
          allow(File).to receive(:read).with(addr_path).and_return(addr + '_frompath')
          expect(described_class.api_client.address).to eq(addr + '_frompath')
          expect(described_class.api_client.token).to eq(token + '_frompath')
        end
      end
    end

    describe '.read' do
      it 'Caches the read' do
        allow(described_class).to receive(:config).and_return(static_config)
        stub = stub_request(:get, "#{addr}/v1/test/path").
          to_return(status: 200, body: {
          data: {
            foo: 'bar'
          },
          lease_duration: 3600,
        }.to_json, headers: { 'content-type': 'application/json' })

        expect(described_class.read('test/path')).to eq({ foo: 'bar' })
        expect(stub).to have_been_requested.times(1)
        # uses the cache
        expect(described_class.read('test/path')).to eq({ foo: 'bar' })
        expect(stub).to have_been_requested.times(1)
      end


      it 'Caches the read for less than the lease_duration' do
        allow(described_class).to receive(:config).and_return(static_config)
        stub = stub_request(:get, "#{addr}/v1/test/path").
          to_return(status: 200, body: {
          data: {
            foo: 'bar'
          },
          lease_duration: 3600,
        }.to_json, headers: { 'content-type': 'application/json' })

        expect(described_class.read('test/path')).to eq({ foo: 'bar' })
        expect(stub).to have_been_requested.times(1)
        # does not use the cache
        Timecop.travel(Time.zone.now + 3600.seconds) do
          expect(described_class.read('test/path')).to eq({ foo: 'bar' })
          expect(stub).to have_been_requested.times(2)
        end
      end

      it 'Uses the cache if vault is unavailible' do
        allow(described_class).to receive(:config).and_return(static_config)
        stub = stub_request(:get, "#{addr}/v1/test/path").
          to_return(status: 200, body: {
          data: {
            foo: 'bar'
          },
          lease_duration: 3600,
        }.to_json, headers: { 'content-type': 'application/json' })

        expect(described_class.read('test/path')).to eq({ foo: 'bar' })
        expect(stub).to have_been_requested.times(1)
        # restub to return an error now
        stub_request(:get, "#{addr}/v1/test/path").to_return(status: 500, body: 'error')
        Timecop.travel(Time.zone.now + 3600.seconds) do
          expect(described_class.read('test/path')).to eq({ foo: 'bar' })
        end
      end


    end
  end
end
