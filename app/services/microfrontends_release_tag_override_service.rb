# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# This service manages session-based overrides for microfrontend release tags.
# It allows developers to test specific versions of microfrontends without
# changing global configuration.
class MicrofrontendsReleaseTagOverrideService
  SESSION_KEY = :microfrontend_overrides

  def initialize(session)
    @session = session
  end

  # Set an override for a specific app
  # @param app [String] The app identifier
  # @param assets_url [String] The URL to override with
  def set_override(app:, assets_url:)
    return unless @session

    @session[SESSION_KEY] ||= {}
    @session[SESSION_KEY][app] = assets_url
  end

  def get_override(app)
    return nil unless @session && @session[SESSION_KEY]

    @session[SESSION_KEY][app]
  end

  def clear_overrides
    return unless @session

    @session.delete(SESSION_KEY)
  end

  def overrides_summary
    return {} unless @session && @session[SESSION_KEY]

    @session[SESSION_KEY].dup
  end

  def overrides_active?
    return false unless @session

    @session[SESSION_KEY].present?
  end
end
