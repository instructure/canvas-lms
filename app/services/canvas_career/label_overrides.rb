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

module CanvasCareer
  # This module provides helper methods for dynamically determining label overrides
  # based on whether the context is in horizon/career mode
  module LabelOverrides
    def self.permission_label_overrides(context = nil)
      return {} unless career_mode?(context)

      Constants::Overrides.permission_label_overrides
    end

    def self.enrollment_type_overrides(context = nil)
      return {} unless career_mode?(context)

      Constants::Overrides.enrollment_type_overrides
    end

    def self.career_mode?(context)
      return false unless context.is_a?(Account)

      cached_value = context.instance_variable_get(:@_career_mode)
      return cached_value unless cached_value.nil?

      context.instance_variable_set(:@_career_mode, context.horizon_account?)
    end
  end
end
