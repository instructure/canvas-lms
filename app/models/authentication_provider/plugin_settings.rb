#
# Copyright (C) 2015 - present Instructure, Inc.
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

module AuthenticationProvider::PluginSettings
  module ClassMethods
    def singleton?
      true
    end
  end

  module PrependedClassMethods
    def globally_configured?
      ::Canvas::Plugin.find(plugin).enabled?
    end

    def recognized_params
      if globally_configured?
        super
      else
        @plugin_settings + super
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
      @plugin_settings = settings_hash.keys

      # use an anonymous module so we can prepend and always call super,
      # regardless of if the method is actually defined on this class,
      # or a parent
      mod = Module.new
      settings_hash.each do |(accessor, setting)|
        mod.module_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{accessor}
            self.class.globally_configured? ? settings_from_plugin[#{setting.inspect}] : super
          end
        RUBY
      end

      prepend mod
    end
  end

  def self.included(klass)
    klass.instance_variable_set(:@recognized_params, klass.recognized_params)
    klass.singleton_class.prepend(PrependedClassMethods)
    klass.singleton_class.include(ClassMethods)
    klass.cattr_accessor(:plugin)
  end

  def settings_from_plugin
    ::Canvas::Plugin.find(self.class.plugin).settings
  end
end
