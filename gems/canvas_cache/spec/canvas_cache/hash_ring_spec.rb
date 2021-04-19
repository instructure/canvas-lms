# frozen_string_literal: true

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
require 'spec_helper'

describe CanvasCache::HashRing do
  describe "consistent hashing" do
    it "doesn't change the position of everything with the addition of a node" do
      node_klass = Class.new do
        def initialize(name)
          @name = name
        end

        def id
          @name
        end
      end
      ring = CanvasCache::HashRing.new(["node1", "node2", "node3"].map{|n| node_klass.new(n) })
      keys = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"]
      mapping_1 = keys.map{|k| ring.get_node(k) }
      ring.add_node(node_klass.new("node4"))
      mapping_2 = keys.map{|k| ring.get_node(k) }
      stable_nodes = mapping_1.each_with_index.select{|node, i| mapping_2[i] == node }
      # at least half the keys don't change nodes
      expect(stable_nodes.count > (keys.count / 2)).to be_truthy
    end
  end
end
