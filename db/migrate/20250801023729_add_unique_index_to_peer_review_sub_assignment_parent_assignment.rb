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

class AddUniqueIndexToPeerReviewSubAssignmentParentAssignment < ActiveRecord::Migration[7.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :assignments,
              :parent_assignment_id,
              unique: true,
              where: "type = 'PeerReviewSubAssignment' AND workflow_state != 'deleted'",
              name: "index_assignments_on_parent_assignment_peer_review_unique",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
