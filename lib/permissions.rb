# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module Permissions
  # canvas-lms proper, plugins, etc. call Permissions.register to add
  # permissions to the system. all registrations must happen during app init;
  # once the app is running, particularly after the first call to
  # Permissions.retrieve, the registry will be frozen and further registrations
  # will be ignored.
  #
  # can take a hash of permission(s). example:
  #
  # Permissions.register({
  #   permission1: {
  #     key: value
  #     ...
  #   },
  #   permission2: {
  #     key: value
  #     ...
  #   },
  #   ...
  #
  def self.register(permissions = {})
    @permissions ||= {}

    if @permissions.frozen?
      raise "Cannot register permissions after the application has been fully initialized"
    elsif permissions.is_a?(Hash)
      permissions.each do |key, value|
        if @permissions.key?(key)
          Rails.logger.warn("Duplicate permission detected: #{key}")
          next
        else
          @permissions[key] = value
        end
      end
    else
      raise "Permissions.register must be called with a hash of permission(s)"
    end
  end

  # Return the list of registered permissions.
  #
  # Ensure that the permissions registry hash is frozen after the application
  # has been fully initialized, so that no further registrations can happen.
  # see: config/initializers/permissions_registry.rb
  def self.retrieve
    @permissions ||= {}

    @permissions
  end
end
