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

class Setting < ActiveRecord::Base
  self.shard_category = :unsharded if self.respond_to?(:shard_category=)

  attr_accessible :name, :value

  @@cache = {}
  @@yaml_cache = {}

  def self.get(name, default)
    if @@cache.has_key?(name)
      @@cache[name]
    else
      @@cache[name] = Setting.find_or_initialize_by_name(name, :value => default).value
    end
  end

  class << self
    alias_method :get_cached, :get
  end

  # Note that after calling this, you should send SIGHUP to all running Canvas processes
  def self.set(name, value)
    @@cache.delete(name)
    s = Setting.find_or_initialize_by_name(name)
    s.value = value
    s.save!
  end
  
  def self.remove(name)
    Setting.find_by_name(name).destroy rescue nil
  end
  
  def self.get_or_set(name, new_val)
    Setting.find_or_create_by_name(name, :value => new_val).value
  end
  
  # this cache doesn't get invalidated by other rails processes, obviously, so
  # use this only for relatively unchanging data

  def self.clear_cache(name)
    @@cache.delete(name)
  end
  
  def self.reset_cache!
    @@cache = {}
    @@yaml_cache = {}
  end
  
  def self.remove(name)
    @@cache.delete(name)
    s = Setting.find_by_name(name)
    s.destroy if s
  end

  # backcompat
  def self.set_config(config_name, value)
    ConfigFile.stub(config_name, value)
  end

  def self.from_config(config_name, with_rails_env=:current)
    ConfigFile.load(config_name, with_rails_env)
  end
end
