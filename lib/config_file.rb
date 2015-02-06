#
# Copyright (C) 2011-2014 Instructure, Inc.
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


module ConfigFile
  @@yaml_cache = {}

  def self.unstub
    @@yaml_cache = {}
  end

  def self.stub(config_name, value)
    raise "config settings can only be set via config file" unless Rails.env.test?
    @@yaml_cache[config_name] ||= {}
    @@yaml_cache[config_name][Rails.env] = value
  end

  def self.load(config_name, with_rails_env=:current)
    with_rails_env = Rails.env if with_rails_env == :current

    if @@yaml_cache[config_name] # if the config wasn't found it'll try again
      return @@yaml_cache[config_name] if !with_rails_env
      return @@yaml_cache[config_name][with_rails_env]
    end

    config = nil
    path = File.join(Rails.root, 'config', "#{config_name}.yml")
    if File.exists?(path)
      config_string = ERB.new(File.read(path))
      config = YAML.load(config_string.result)

      if config.respond_to?(:with_indifferent_access)
        config = config.with_indifferent_access
      else
        config = nil
      end
    end
    @@yaml_cache[config_name] = config
    config = config[with_rails_env] if config && with_rails_env
    config
  end
end
