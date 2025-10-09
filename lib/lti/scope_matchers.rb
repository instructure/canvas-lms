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

module Lti
  module ScopeMatchers
    # Returns a matcher that requires ALL specified scopes to be present
    def self.all_of(*items)
      ->(match_in) { items.present? && (items - match_in).blank? }
    end

    # Returns a matcher that requires ANY of the specified scopes to be present
    def self.any_of(*items)
      ->(match_in) { items.present? && items.intersect?(match_in) }
    end

    # Returns a matcher that accepts any scopes
    def self.any
      ->(_) { true }
    end

    # Returns a matcher that rejects all scopes
    def self.none
      ->(_) { false }
    end
  end
end
