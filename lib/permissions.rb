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

require_relative "../app/services/canvas_career/label_overrides"

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
  def self.retrieve(context = nil)
    @permissions ||= {}

    # Apply Canvas Career overrides to individual permissions
    if context
      begin
        label_overrides = CanvasCareer::LabelOverrides.permission_label_overrides(context)
        if label_overrides.any?
          permissions_with_overrides = @permissions.transform_values do |permission_def|
            permission_key = @permissions.key(permission_def)
            override = label_overrides[permission_key] || {}

            if override.any?
              new_permission_def = permission_def.dup
              new_permission_def = new_permission_def.merge(label: override[:label]) if override[:label]
              new_permission_def
            else
              permission_def
            end
          end
          return permissions_with_overrides
        end
      rescue => e
        Rails.logger.warn("Canvas Career permission overrides failed: #{e.message}")
      end
    end

    @permissions
  end

  def self.permission_groups(context = nil)
    base_groups = PERMISSION_GROUPS

    # Apply Canvas Career overrides to permission groups
    if context
      begin
        label_overrides = CanvasCareer::LabelOverrides.permission_label_overrides(context)
        if label_overrides.any?
          group_overrides = {}
          retrieve(context).each do |perm_key, perm_def|
            if perm_def[:group] && (override = label_overrides[perm_key]) && override[:group_label]
              group_key = perm_def[:group]
              group_overrides[group_key] = override[:group_label]
            end
          end

          if group_overrides.any?
            return base_groups.transform_values do |group_info|
              group_key = base_groups.key(group_info)
              if group_overrides[group_key]
                group_info.merge(label: group_overrides[group_key])
              else
                group_info
              end
            end
          end
        end
      rescue => e
        Rails.logger.warn("Canvas Career permission group overrides failed: #{e.message}")
      end
    end

    base_groups
  end

  def self.group_info(group)
    PERMISSION_GROUPS[group]
  end

  def self.group_label(group)
    PERMISSION_GROUPS.dig(group, :label)&.call
  end
end
