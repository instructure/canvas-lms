#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe CanvasQuizStatistics::Util do
  Util = CanvasQuizStatistics::Util

  describe '#deep_symbolize_keys' do
    it 'does nothing on anything but a Hash' do
      expect(Util.deep_symbolize_keys(5)).to eq(5)
      expect(Util.deep_symbolize_keys([])).to eq([])
      expect(Util.deep_symbolize_keys(nil)).to eq(nil)
    end

    it 'should symbolize top-level keys' do
      expect(Util.deep_symbolize_keys({ 'a' => 'b', c: 'd' })).to eq({
        a: 'b',
        c: 'd'
      })
    end

    it 'should symbolize keys of nested hashes' do
      expect(Util.deep_symbolize_keys({
        'e' => {
          'f' => 'g',
          h: 'i'
        }
      })).to eq({
        e: {
          f: 'g',
          h: 'i'
        }
      })
    end

    it 'should symbolize keys of hashes inside arrays' do
      expect(Util.deep_symbolize_keys({
        'e' => [{
          'f' => 'g',
          h: 'i'
        }]
      })).to eq({
        e: [{
          f: 'g',
          h: 'i'
        }]
      })
    end

    it 'should symbolize all sorts of things' do
      expect(Util.deep_symbolize_keys({
        item1: 'value1',
        "item2" => 'value2',
        hash: {
          item3: 'value3',
          "item4" => 'value4'
        },
        'array' => [{
          "item5" => 'value5',
          item6: 'value6'
        }]
      })).to eq({
        item1: 'value1',
        item2: 'value2',
        hash: {
          item3: 'value3',
          item4: 'value4'
        },
        array: [{
          item5: 'value5',
          item6: 'value6'
        }]
      })
    end

    it 'should work with numbers for keys' do
      expect(Util.deep_symbolize_keys({
        "1" => "first",
        "2" => "second"
      })).to eq({
        :"1" => "first",
        :"2" => "second"
      })
    end

    it 'should skip nils and items that cant be symbolized' do
      expect(Util.deep_symbolize_keys({ nil => 'foo' })).to eq({ nil => 'foo' })
    end

    it 'should only munge hashes' do
      expect(Util.deep_symbolize_keys([])).to eq([])
      expect(Util.deep_symbolize_keys([{ 'foo' => 'bar' }])).to eq([{ 'foo' => 'bar' }])
    end
  end
end
