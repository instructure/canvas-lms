# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
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

# Custom (teacher/admin-added) Links (aka "tabs") for Navigation
# Menus. Referenced in the contexts' tabs_available
class NavMenuLink < ActiveRecord::Base
  extend RootAccountResolver
  include Canvas::SoftDeletable
  include CustomValidations

  self.ignored_columns += ["nav_type"]

  resolves_root_account through: :context

  belongs_to :context, polymorphic: %i[account course], separate_columns: true, optional: false

  validates :label, presence: true, length: { maximum: 255 }
  validates :url, presence: true, length: { maximum: 2048 }
  validates_as_url :url

  # See also corresponding Postgres check constraints
  validate :at_least_one_nav_type_enabled
  validate :nav_types_match_context

  def at_least_one_nav_type_enabled
    unless course_nav || account_nav || user_nav
      errors.add(:base, "at least one nav type must be enabled")
    end
  end

  def nav_types_match_context
    if context_type == "Course" && (account_nav || user_nav)
      errors.add(:base, "course-context link can only have course navigation enabled")
    end
  end
end
