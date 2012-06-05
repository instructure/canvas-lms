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
    Array(yield array)
  end

  def self.with_each_shard
    Array(yield)
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

  def description
    "default"
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
  def shard
    Shard.default
  end

  def global_id
    id
  end

  def self.set_shard_override(&block)
    # pass
  end
end
