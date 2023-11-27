# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module PandataEvents
  def self.credentials
    @credentials ||= Rails.application.credentials.pandata_creds&.with_indifferent_access || {}
  end

  def self.config
    @config ||= DynamicSettings.find("pandata/events", service: "canvas")
  end

  def self.endpoint
    @endpoint ||= config[:url]
  end

  # Whether or not PandataEvents is enabled for Canvas purposes,
  # since it's always available for specific dev keys
  # in UsersController#pandata_events_token
  def self.enabled?
    !!config[:enabled_for_canvas]
  end
end
