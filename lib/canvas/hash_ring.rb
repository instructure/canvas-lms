#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'zlib'

# see https://github.com/redis/redis-rb/pull/739

module Canvas
  class HashRing

    POINTS_PER_SERVER = 160 # this is the default in libmemcached

    attr_reader :ring, :sorted_keys, :replicas, :nodes

    # nodes is a list of objects that have a proper to_s representation.
    # replicas indicates how many virtual points should be used pr. node,
    # replicas are required to improve the distribution.
    # digest is the hash function to use. Either a proc, a class descended from
    # Digest::Base, or a string or symbol name of a class inside the Digest module
    def initialize(nodes=[], replicas=nil, digest=nil)
      @replicas = replicas || POINTS_PER_SERVER
      @ring = {}
      @nodes = []
      @sorted_keys = []
      digest ||= Zlib.method(:crc32)
      digest = Digest.const_get(digest, false) if digest.is_a?(String) || digest.is_a?(Symbol)
      digest = digest.method(:digest) if digest.is_a?(Class)
      @digest = digest
      nodes.each do |node|
        add_node(node)
      end
    end

    def statistics
      result = Hash.new(0)
      last = 0
      last_node = ring[sorted_keys.last]
      sorted_keys.each do |key|
        node = ring[key]
        key_value = unpack(key)
        result[last_node] += key_value - last
        last = key_value
        last_node = node
      end
      # guess the digest length assuming that we're at least halfway through the ring,
      # and therefore the top bit is set
      digest_length = result.values.sum.to_s(2).length
      max = 1 << digest_length
      result[ring[sorted_keys.last]] + max - last
      result.map { |k, v| [k, v.to_f / max] }.sort_by(&:last).to_h
    end

    # Adds a `node` to the hash ring (including a number of replicas).
    def add_node(node)
      @nodes << node
      @replicas.times do |i|
        key = @digest["#{node.id}:#{i}"]
        @ring[key] = node
        @sorted_keys << key
      end
      @sorted_keys.sort!
    end

    def remove_node(node)
      @nodes.reject!{|n| n.id == node.id}
      @replicas.times do |i|
        key = @digest["#{node.id}:#{i}"]
        @ring.delete(key)
        @sorted_keys.reject! {|k| k == key}
      end
    end

    # get the node in the hash ring for this key
    def get_node(key)
      get_node_pos(key)[0]
    end

    def get_node_pos(key)
      return [nil,nil] if @ring.size == 0
      crc = @digest[key]
      idx = HashRing.binary_search(@sorted_keys, crc)
      return [@ring[@sorted_keys[idx]], idx]
    end

    def iter_nodes(key)
      return [nil,nil] if @ring.size == 0
      _, pos = get_node_pos(key)
      @ring.size.times do |n|
        yield @ring[@sorted_keys[(pos+n) % @ring.size]]
      end
    end

    # Find the closest index in HashRing with value <= the given value
    def self.binary_search(ary, value, &block)
      upper = ary.size - 1
      lower = 0
      idx = 0

      while(lower <= upper) do
        idx = (lower + upper) / 2
        comp = ary[idx] <=> value

        if comp == 0
          return idx
        elsif comp > 0
          upper = idx - 1
        else
          lower = idx + 1
        end
      end

      if upper < 0
        upper = ary.size - 1
      end
      return upper
    end

    private

    def unpack(string)
      return string if string.is_a?(Integer)
      result = 0
      string.each_byte do |byte|
        result <<= 8
        result += byte
      end
      result
    end
  end
end
