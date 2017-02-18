#
# Copyright (C) 2014 Instructure, Inc.
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

require 'spec_helper'

describe EventStream do
  before(:each) do
    EventStream.current_shard_lookup = nil
    EventStream.get_index_ids_lookup = nil
  end

  after do
    EventStream.current_shard_lookup = nil
    EventStream.get_index_ids_lookup = nil
  end

  describe '.current_shard' do
    it 'returns the current shard' do
      shard = double('shard')
      EventStream.current_shard_lookup = -> { shard }

      expect(EventStream.current_shard).to eq shard
    end

    it 'returns nil if lookup not set' do
      expect(EventStream.current_shard).to eq nil
    end
  end

  describe '.get_index_ids' do
    let(:index) do
      index = double('index')
      allow(index).to receive(:id_column).and_return(:id)
      index
    end
    let(:index_ids) { (1..10).to_a }
    let(:index_rows) do
      index_ids.map do |i|
        { id: i }
      end
    end

    it 'returns the index ids' do
      EventStream.get_index_ids_lookup = lambda { |index, rows|
        rows.map{ |row| row[index.id_column] + 1}
      }

      expect(EventStream.get_index_ids(index, index_rows)).to eq (2..11).to_a
    end

    it 'returns id_column if lookup not set' do
      expect(EventStream.get_index_ids(index, index_rows)).to eq index_ids
    end
  end
end
