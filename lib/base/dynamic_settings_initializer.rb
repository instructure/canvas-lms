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

module DynamicSettingsInitializer
  # this is expected to be invoked from application.rb
  # as an initializer so that consul-based settings are available
  # before we start bootstrapping other things in the app.
  def self.bootstrap!
    # these used to be in an initializer, but initializing this
    # library in 2 places seems like a recipe for confusion, so
    # config/initializers/consul.rb got moved in here
    reloader = lambda do
      settings = ConfigFile.load("consul").dup

      if settings.present?
        settings[:circuit_breaker] = ::DynamicSettings::CircuitBreaker.new(settings[:circuit_breaker_interval])

        begin
          ::DynamicSettings.config = settings
        rescue Diplomat::KeyNotFound, Diplomat::PathNotFound, Diplomat::UnknownStatus
          Rails.logger.warn("INITIALIZATION: can't reach consul, attempts to load DynamicSettings will fail")
        end
      end

      # dumps the whole cache, even if it's a shared local redis,
      # and removes any local data loaded from yml on disk as a fallback.
      # (will reload if still present on disk)
      ::DynamicSettings.on_reload!
    end
    Canvas::Reloader.on_reload(&reloader)
    # dependency injection stuff from when
    # this got pulled out into a local gem
    ::DynamicSettings.cache = LocalCache
    ::DynamicSettings.request_cache = RequestCache
    ::DynamicSettings.fallback_recovery_lambda = ->(e) { Canvas::Errors.capture_exception(:consul, e, :warn) if defined?(Canvas::Errors) }
    ::DynamicSettings.retry_lambda = ->(e) { Canvas::Errors.capture_exception(:consul, e, :warn) if defined?(Canvas::Errors) }
    ::DynamicSettings.logger = Rails.logger
    reloader.call
    reloader
  end
end
