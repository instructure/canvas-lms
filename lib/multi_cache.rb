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

class MultiCache < ActiveSupport::Cache::Store
  def self.cache
    if defined?(ActiveSupport::Cache::RedisStore) && Rails.cache.is_a?(ActiveSupport::Cache::RedisStore) &&
        defined?(Redis::DistributedStore) && (store = Rails.cache.instance_variable_get(:@data)).is_a?(Redis::DistributedStore)
      store.instance_variable_get(:@multi_cache) || store.instance_variable_set(:@multi_cache, MultiCache.new(store.ring.nodes))
    else
      Rails.cache
    end
  end

  def initialize(ring)
    @ring = ring
    super()
  end

  def fetch(key, options = nil, &block)
    options ||= {}
    # an option to allow populating all nodes in the ring with the
    # same data
    if options[:node] == :all
      calculated_value = nil
      did_calculate = false
      result = nil
      @ring.each do |node|
        options[:node] = node
        if block
          result = super(key, options) do
            calculated_value = yield unless did_calculate
            did_calculate = true
            calculated_value
          end
        else
          result ||= []
          result << super(key, options)
        end
      end
      result
    else
      # this makes the node "sticky" for read/write
      options[:node] = @ring[rand(@ring.length)]
      super(key, options, &block)
    end
  end

  # for compatibility
  def self.copies(key)
    nil
  end

  def self.fetch(key, options = nil, &block)
    cache.fetch(key, options, &block)
  end

  def self.delete(key, options = nil)
    cache.delete(key, options)
  end

  private
  def write_entry(key, entry, options)
    method = options && options[:unless_exist] ? :setnx : :set
    options[:node].send method, key, entry, options
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError
    false
  end

  def read_entry(key, options)
    entry = options[:node].get key, options
    if entry
      entry.is_a?(ActiveSupport::Cache::Entry) ? entry : ActiveSupport::Cache::Entry.new(entry)
    end
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError
    nil
  end

  def delete_entry(key, options)
    nodes = options[:node] ? [options[:node]] : @ring
    nodes.inject(false) do |result, node|
      begin
        node.del(key) || result
      rescue Errno::ECONNREFUSED, Redis::CannotConnectError
        result
      end
    end
  end
end
