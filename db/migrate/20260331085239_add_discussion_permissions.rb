# frozen_string_literal: true

#
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

class AddDiscussionPermissions < ActiveRecord::Migration[8.0]
  tag :postdeploy

  def up
    DataFixup::AddRoleOverridesForNewPermission
      .delay_if_production(priority: Delayed::LOW_PRIORITY)
      .run(:manage_course_content_edit, :edit_discussion_anonymity)

    DataFixup::AddRoleOverridesForNewPermission
      .delay_if_production(priority: Delayed::LOW_PRIORITY)
      .run(:manage_course_content_edit, :edit_discussion_options)

    DataFixup::AddRoleOverridesForNewPermission
      .delay_if_production(priority: Delayed::LOW_PRIORITY)
      .run(:manage_course_content_edit, :edit_discussion_views)

    DataFixup::AddRoleOverridesForNewPermission
      .delay_if_production(priority: Delayed::LOW_PRIORITY)
      .run(:manage_course_content_edit, :apply_default_discussion_options)
  end
end
