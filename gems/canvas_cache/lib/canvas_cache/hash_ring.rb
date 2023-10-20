# frozen_string_literal: true

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

require "redis/hash_ring"
require "zlib"

# see https://github.com/redis/redis-rb/pull/739

module CanvasCache
  class HashRing < ::Redis::HashRing
    def initialize(nodes = [], replicas = POINTS_PER_SERVER, digest = nil)
      replicas ||= POINTS_PER_SERVER
      digest ||= Zlib.method(:crc32)
      digest = Digest.const_get(digest, false) if digest.is_a?(String) || digest.is_a?(Symbol)
      digest = digest.method(:digest) if digest.is_a?(Class)
      @digest = digest

      super(nodes, replicas)
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
      result[ring[sorted_keys.last]] = max - last
      result.map { |k, v| [k, v.to_f / max] }.sort_by(&:last).to_h
    end

    def hash_for(key)
      @digest.call(key)
    end
    alias_method :server_hash_for, :hash_for

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
