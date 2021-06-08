# frozen_string_literal: true

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
require 'dynamic_settings'

module Canvas
  # temporary shim rather than replacing all callsites at once
  # TODO: remove references to DynamicSettings through the Canvas module
  # individually, and then remove this file.
  DynamicSettings = ::DynamicSettings

  module DynamicSettingsInitializer
    # this is expected to be invoked from application.rb
    # as an initializer so that consul-based settings are available
    # before we start bootstrapping other things in the app.
    def self.bootstrap!
      settings = ConfigFile.load("consul")
      if settings.present?
        begin
          ::DynamicSettings.config = settings
        rescue Diplomat::KeyNotFound
          Rails.logger.warn("INITIALIZATION: can't reach consul, attempts to load DynamicSettings will fail")
        end
      end

      # these used to be in an initializer, but initializing this
      # library in 2 places seems like a recipe for confusion, so
      # config/initializers/consul.rb got moved in here
      handle_fallbacks = -> do
        # dumps the whole cache, even if it's a shared local redis,
        # and removes any local data loaded from yml on disk as a fallback.
        # (will reload if still present on disk)
        ::DynamicSettings.on_reload!
      end
      handle_fallbacks.call
      Canvas::Reloader.on_reload(&handle_fallbacks)
      # dependency injection stuff from when
      # this got pulled out into a local gem
      ::DynamicSettings.cache = LocalCache
      ::DynamicSettings.fallback_recovery_lambda = ->(e){ Canvas::Errors.capture_exception(:consul, e, :warn) }
      ::DynamicSettings.logger = Rails.logger
    end
  end
end
