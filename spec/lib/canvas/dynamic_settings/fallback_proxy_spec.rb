# Copyright (C) 2017 - present Instructure, Inc.
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
require 'spec_helper'
require_dependency "canvas/dynamic_settings"

module Canvas
  class DynamicSettings
    RSpec.describe FallbackProxy do
      let(:fallback_data) do
        {
          foo: 'bar',
          baz: {
            qux: 42
          }
        }
      end

      let(:proxy) { FallbackProxy.new(fallback_data) }

      describe '#initalize' do
        it 'must store an empty hash when initialized with nil' do
          proxy = FallbackProxy.new(nil)
          expect(proxy.data).to eq({})
        end
      end

      describe '#fetch(key, ttl: nil)' do
        it 'must return the value from the data hash' do
          expect(proxy.fetch('foo')).to eq 'bar'
        end

        it 'must return nil when the val' do
          expect(proxy.fetch('nx-key')).to be_nil
        end
      end

      describe '#fetch_object(key, ttl: nil)' do
        it 'must return a thing that squawks like an Imperium::KVGETResponse'
      end

      describe '#for_prefix(key, default_ttl: nil)' do
        it 'must return a new instance populated with the sub hash found at the specified key' do
          new_proxy = proxy.for_prefix('baz')
          expect(new_proxy.data).to eq({qux: 42}.with_indifferent_access)
        end
      end

      describe '#set_keys' do
        it 'merges in a hash' do
          kvs = {foo1: 'bar1', foo2: 'bar2'}
          proxy.set_keys(kvs)
          expect(proxy.data).to include kvs
        end
      end
    end
  end
end
