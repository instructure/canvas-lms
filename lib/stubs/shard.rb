#
# Copyright (C) 2011 Instructure, Inc.
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

class Shard
  def self.stubbed?
    true
  end

  def self.default
    @default ||= Shard.new
  end

  def self.current
    default
  end

  def self.partition_by_shard(array, partition_proc = nil)
    return [] if array.empty?
    Array(yield array)
  end

  def self.with_each_shard(shards = nil)
    Array(yield)
  end

  def self.shard_for(object)
    default
  end

  def activate
    yield
  end

  def default?
    true
  end

  def settings
    {}
  end

  def id
    "default"
  end

  def self.global_id_for(any_id)
    any_id
  end

  yaml_as "tag:instructure.com,2012:Shard"

  def self.yaml_new(klass, tag, val)
    default
  end

  module RSpec
    def self.included(klass)
      klass.before do
        pending "needs a sharding implementation"
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  class << self
    VALID_FIND_OPTIONS << :shard
  end

  def shard
    Shard.default
  end

  def shard=(new_shard)
    raise ReadOnlyRecord if new_record? && self.shard != new_shard
    new_shard
  end

  def global_id
    id
  end

  def local_id
    id
  end
end

module ActiveRecord::Associations
  %w{HasManyAssociation HasManyThroughAssociation}.each do |klass|
    const_get(klass).class_eval do
      def with_each_shard(*shards_or_options)
        options = shards_or_options.pop if shards_or_options.last.is_a?(Hash)
        scope = self
        scope = self.scoped(options) if options
        scope = yield(scope) if block_given?
        Array(scope)
      end
    end
  end
end
