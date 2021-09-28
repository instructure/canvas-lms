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
  # once the app is running (particularly, after the first call to
  # Permissions.retrieve) the registry will be frozen and further registrations
  # will be ignored.
  #
  # can take one permission or a hash of permissions. examples:
  #
  # Permissions.register :permission1,
  #   :key => value,
  #   ...
  #
  # Permissions.register({
  #   :permission2 => {
  #     :key => value
  #     ...
  #   },
  #   :permission3 => {
  #     :key => value
  #     ...
  #   },
  #   ...
  #
  def self.register(name_or_hash, data={})
    @permissions ||= {}
    if name_or_hash.is_a?(Hash)
      raise ArgumentError unless data.empty?
      @permissions.merge!(name_or_hash)
    else
      raise ArgumentError if data.empty?
      @permissions.merge!(name_or_hash => data)
    end
  end

  # Return the list of registered permissions.
  def self.retrieve
    @permissions ||= {}
    @permissions.freeze unless @permissions.frozen?
    @permissions
  end
end
