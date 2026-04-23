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

class AddArchivedIndexesToInstitutionalTags < ActiveRecord::Migration[8.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    # Load archived categories per account
    add_index :institutional_tag_categories,
              :root_account_id,
              where: "workflow_state = 'deleted'",
              name: "idx_inst_tag_categories_archived",
              algorithm: :concurrently,
              if_not_exists: true

    # Load archived tags per account
    add_index :institutional_tags,
              :root_account_id,
              where: "workflow_state = 'deleted'",
              name: "idx_institutional_tags_archived",
              algorithm: :concurrently,
              if_not_exists: true

    # Load archived tags per category (cascade-archive lookup)
    add_index :institutional_tags,
              :category_id,
              where: "workflow_state = 'deleted'",
              name: "idx_institutional_tags_category_archived",
              algorithm: :concurrently,
              if_not_exists: true

    # Cascade-archive: find active associations for a tag being archived
    add_index :institutional_tag_associations,
              :institutional_tag_id,
              where: "workflow_state = 'active'",
              name: "idx_inst_tag_assoc_tag_active",
              algorithm: :concurrently,
              if_not_exists: true

    # Load archived associations per course
    add_index :institutional_tag_associations,
              :course_id,
              where: "course_id IS NOT NULL AND workflow_state = 'deleted'",
              name: "idx_inst_tag_assoc_course_archived",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
