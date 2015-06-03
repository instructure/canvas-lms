#
# Copyright (C) 2015 Instructure, Inc.
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

module AccountAuthorizationConfig::PluginSettings
  module ClassMethods
    def singleton?
      true
    end

    def globally_configured?
      Canvas::Plugin.find(plugin).enabled?
    end

    def recognized_params
      if globally_configured?
        @recognized_params
      else
        @plugin_settings
      end
    end

    def plugin_settings(*settings)
      settings_hash = {}
      settings.each do |setting|
        if setting.is_a?(Hash)
          settings_hash.merge!(setting)
        else
          settings_hash[setting] = setting
        end
      end
      @plugin_settings = settings_hash.keys + @recognized_params

      # force attribute methods to be created so that we can alias them
      # also rescue nil, cause the db may not exist yet
      self.new rescue nil

      settings_hash.each do |(accessor, setting)|
        super_method = 'super'
        # it's defined directly on the class; we have to alias things around
        unless superclass.public_instance_methods.include?(accessor)
          super_method = "#{accessor}_without_plugin_settings"
          alias_method super_method, accessor
        end

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{accessor}
            self.class.globally_configured? ? settings_from_plugin[#{setting.inspect}] : #{super_method}
          end
        RUBY
      end
    end
  end

  def self.included(klass)
    klass.instance_variable_set(:@recognized_params, klass.recognized_params)
    klass.extend(ClassMethods)
    klass.cattr_accessor(:plugin)
  end

  def settings_from_plugin
    Canvas::Plugin.find(self.class.plugin).settings
  end
end
