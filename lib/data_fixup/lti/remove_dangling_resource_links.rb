# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module DataFixup::Lti::RemoveDanglingResourceLinks
  def self.run
    # An edge case bug in LTI 1.1 to 1.3 migration meant that 1.1 assignments
    # associated with a tool in the root account were picked for migration
    # even when the 1.3 tool was installed in a subaccount, and had no access
    # to/ownership of the assignment. This made the LineItem creation fail, and
    # the assignment was left in a half-migrated state with only a ResourceLink
    # and no LineItem. Upon launch/subsequent migrations, this caused an error when
    # it tried to recreate the ResourceLink.
    # Removing these dangling ResourceLinks effectively "resets" the half-migrated
    # assignments to a pre-migrated state, which is desired since these assignments
    # weren't supposed to be migrated anyways, and later correct migrations will
    # succeed.
    # Hard-deleting these links is safe because they are created without extra data like
    # url or custom parameters, and will be recreated in the exact same state in later
    # migrations.
    Lti::ResourceLink
      .where(context_type: "Assignment")
      .where.missing(:line_items)
      # can't directly use in_batches with .missing (nullable outer join)
      .find_ids_in_batches do |ids|
        Lti::ResourceLink.where(id: ids).delete_all # hard-delete
      end
  end
end
