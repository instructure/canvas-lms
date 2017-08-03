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
require 'spec_helper'
require_dependency "canvas/dynamic_settings"
require 'imperium/testing' # Not loaded by default

module Canvas
  class DynamicSettings
    RSpec.describe Cache do
      before do
        Cache.reset!
      end

      describe '.fallback_fetch(key)' do
        it 'must return the stored value even if expired' do
          Cache.fetch('foobar', ttl: 2.seconds) do
            42
          end
          Timecop.travel(1.minute.from_now) do
            expect(Cache.fallback_fetch('foobar')).to eq 42
          end
        end
      end

      describe '.fetch(key, ttl: nil)' do
        it 'must return the value returned by the supplied block' do
          val = Cache.fetch('foobar') do
            42
          end
          expect(val).to eq 42
        end

        it 'must capture the return value from the block in the store' do
          Cache.fetch('foobar') do
            42
          end
          expect(Cache.store).to include 'foobar' => Cache::Value.new(42)
        end

        it 'must return the stored value rather than calling the block again on future calls' do
          Cache.fetch('foobar') do
            42
          end
          val = Cache.fetch('foobar') do
            51
          end
          expect(val).to eq 42
        end

        it 'must call the block again when the ttl has elapsed' do
          called = false
          Cache.fetch('foobar', ttl: 5.minutes) do
            42
          end

          Timecop.travel(10.minutes.from_now) do
            Cache.fetch('foobar', ttl: 5.minutes) do
              called = true
            end

            expect(called).to eq true
          end
        end

        it 'must not cache not found responses' do
          Cache.fetch('foobar', ttl: 5.minutes) do
            Imperium::Testing.kv_not_found_response
          end
          expect(Cache.store).to be_empty
        end

        it 'must update the TTL on the cached value if it was previously nil' do
          Cache.insert('foo', 'bar')
          Cache.fetch('foo', ttl: 3.minutes)
          expect(Cache.store['foo'].expiration_time).to_not be_nil
        end
      end

      describe '.reset!' do
        it 'must clear the stored values' do
          described_class.store['foo/bar'] = 'value'
          described_class.reset!
          expect(described_class.store).to be_empty
        end
      end
    end
  end
end
