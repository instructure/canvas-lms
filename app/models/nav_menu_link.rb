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

  resolves_root_account through: :context

  belongs_to :context, polymorphic: %i[account course], separate_columns: true, optional: false

  validates :label, presence: true, length: { maximum: 255 }
  validates :url, presence: true, length: { maximum: 2048 }
  validates_as_url :url
  validates :nav_type, presence: true, inclusion: { in: %w[course account user] }

  # See also corresponding Postgres check constraint
  validate :nav_type_matches_context
  VALID_CONTEXT_NAV_TYPE_PAIRS = Set.new([
                                           %w[Course course],
                                           %w[Account account],
                                           %w[Account user],
                                         ])

  private

  def nav_type_matches_context
    unless VALID_CONTEXT_NAV_TYPE_PAIRS.member?([context_type, nav_type])
      errors.add(:nav_type, "mismatch between context type and nav type")
    end
  end
end
