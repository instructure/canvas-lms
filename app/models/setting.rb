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
  attr_accessible :name, :value

  @@cache = {}

  def self.get(name, default)
    Setting.find_or_initialize_by_name(name, :value => default).value
  end
  
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
  def self.get_cached(name, default)
    if @@cache.has_key?(name)
      @@cache[name]
    else
      @@cache[name] = self.get(name, default)
    end
  end
  
  def self.clear_cache(name)
    @@cache.delete(name)
  end
  
  def self.reset_cache!
    @@cache = {}
  end
  
  def self.remove(name)
    @@cache.delete(name)
    s = Setting.find_by_name(name)
    s.destroy if s
  end
  
  def self.config_key(config_name, with_rails_env=:current)
    "yaml_config_#{config_name}_#{with_rails_env == :current ? Rails.env : with_rails_env}"
  end

  def self.set_config(config_name, value)
    raise "config settings can only be set via config file" unless Rails.env.test?
    @@cache[config_key(config_name)] = value
  end

  def self.from_config(config_name, with_rails_env=:current)
    key = config_key(config_name, with_rails_env)
    
    return @@cache[key] if @@cache[key] # if the config wasn't found it'll try again
    
    config = nil
    path = File.join(Rails.root, 'config', "#{config_name}.yml")
    if File.exists?(path)
      if Rails.env.test?
        config_string = ERB.new(File.read(path))
        config = YAML.load(config_string.result)
      else
        config = YAML.load_file(path)
      end

      if config.respond_to?(:with_indifferent_access)
        config = config.with_indifferent_access
        config = config[with_rails_env == :current ? Rails.env : with_rails_env] if with_rails_env
      else
        config = nil
      end
    end
    @@cache[key] = config
  end
end
