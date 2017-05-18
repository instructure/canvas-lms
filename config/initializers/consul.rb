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

module ConsulInitializer
  def self.configure_with(settings_hash, logger=Rails.logger)
    if settings_hash.present?
      begin
        Canvas::DynamicSettings.config = settings_hash
      rescue Imperium::UnableToConnectError
        logger.warn("INITIALIZATION: can't reach consul, attempts to load DynamicSettings will fail")
      end
    end
  end

  def self.fallback_to(settings_hash)
    if settings_hash.present?
      Canvas::DynamicSettings.fallback_data = settings_hash.with_indifferent_access
    end
  end

end

Rails.configuration.to_prepare do
  settings = ConfigFile.load("consul")
  ConsulInitializer.configure_with(settings)
  fallback_settings = ConfigFile.load("dynamic_settings")
  ConsulInitializer.fallback_to(fallback_settings)
end

Canvas::Reloader.on_reload do
  Canvas::DynamicSettings.reset_cache!
end
