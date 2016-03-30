#
# Copyright (C) 2016 Instructure, Inc.
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

module ConditionalRelease
  class Service
    private_class_method :new

    DEFAULT_CONFIG = {
      enabled: false, # required
      host: nil,      # required
      protocol: nil,  # defaults to Canvas
      configure_defaults_app_path: 'javascripts/edit_defaults.js',
      edit_object_score_ranges_path: 'javascripts/edit_object_score_ranges.js',
    }.freeze

    def self.env_for(context)
      { CONDITIONAL_RELEASE_SERVICE_ENABLED: self.enabled_in_context?(context) }
    end

    def self.reset_config_cache
      @config = nil
    end

    def self.config
      @config ||= DEFAULT_CONFIG.merge(config_file)
    end

    def self.configured?
      !!(config[:enabled] && config[:host])
    end

    def self.enabled_in_context?(context)
      !!(configured? && context.feature_enabled?(:conditional_release))
    end

    def self.configure_defaults_url
      build_url configure_defaults_app_path
    end

    def self.edit_object_score_ranges_url
      build_url edit_object_score_ranges_path
    end

    def self.protocol
      config[:protocol] || HostUrl.protocol
    end

    def self.host
      config[:host]
    end

    def self.configure_defaults_app_path
      config[:configure_defaults_app_path]
    end

    def self.edit_object_score_ranges_path
      config[:edit_object_score_ranges_path]
    end

    class << self
      private
      def config_file
        ConfigFile.load('conditional_release').try(:symbolize_keys) || {}
      end

      def build_url(path)
        "#{protocol}://#{host}/#{path}"
      end
    end
  end

end
