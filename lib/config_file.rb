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

module ConfigFile
  class << self
    def unstub
      @yaml_cache = {}
      @object_cache = {}
    end

    Canvas::Reloader.on_reload do
      ConfigFile.unstub
    end

    def stub(config_name, value)
      raise "config settings can only be set via config file" unless Rails.env.test?
      @yaml_cache[config_name] ||= {}
      @yaml_cache[config_name][Rails.env] = value
    end

    def load(config_name, with_rails_env = ::Rails.env)
      if @yaml_cache.key?(config_name)
        return @yaml_cache[config_name] unless with_rails_env
        return @yaml_cache[config_name]&.[](with_rails_env)
      end

      path = Rails.root.join('config', "#{config_name}.yml")
      if File.exist?(path)
        config_string = ERB.new(File.read(path))
        config = YAML.load(config_string.result)

        config = if config.respond_to?(:with_indifferent_access)
                   config.with_indifferent_access
                 end
      end
      @yaml_cache[config_name] = config
      config = config[with_rails_env] if config && with_rails_env
      config
    end

    # pass a block; the config will be passed to your block, and the return
    # value will be cached, and returned to you.
    def cache_object(config_name, with_rails_env = ::Rails.env)
      object_cache = @object_cache[config_name] ||= {}
      return object_cache[with_rails_env] if object_cache.key?(with_rails_env)
      config = load(config_name, with_rails_env)
      object_cache[with_rails_env] = config && yield(config)
    end
  end
  unstub
end
