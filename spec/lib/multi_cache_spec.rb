#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'lib/multi_cache'

describe MultiCache do
  it "should use the same node for read and write during a fetch" do
    mock_class = Class.new do
      attr_reader :gets, :sets

      def initialize
        @gets = @sets = 0
      end

      def get(*args)
        @gets += 1
        nil
      end

      def set(*args)
        @sets += 1
      end
    end

    nodes = (0..100).map { mock_class.new }
    store = MultiCache.new(nodes)
    store.fetch('a') { 1 }

    # a total of one get and one set
    expect(nodes.map(&:gets).sum).to eq 1
    expect(nodes.map(&:sets).sum).to eq 1
    # each node either got 0 and 0, or 1 and 1
    nodes.each do |node|
      expect(node.gets).to eq node.sets
    end
  end

  it "should delete from _all_ nodes" do
    ring = [double, double]
    expect(ring[0]).to receive(:del).with('key').and_return(true)
    expect(ring[1]).to receive(:del).with('key').and_return(false)

    # TODO remove this when removing the shim from active_support.rb
    expect(ring[0]).to receive(:del).with('rails52:key').and_return(false)
    expect(ring[1]).to receive(:del).with('rails52:key').and_return(false)

    store = MultiCache.new(ring)
    expect(store.delete('key')).to eq true
  end

  it 'allows writing to all nodes' do
    ring = [double, double]
    expect(ring[0]).to receive(:get).once
    expect(ring[0]).to receive(:set).once
    expect(ring[1]).to receive(:get).once
    expect(ring[1]).to receive(:set).once

    store = MultiCache.new(ring)
    generated = 0
    store.fetch('key', node: :all) { generated += 1 }
    expect(generated).to eq 1
  end
end
