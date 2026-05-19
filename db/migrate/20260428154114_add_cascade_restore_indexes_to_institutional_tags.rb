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
#

class AddCascadeRestoreIndexesToInstitutionalTags < ActiveRecord::Migration[8.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    # Cascade-restore: find associations deleted at the same instant as a tag
    add_index :institutional_tag_associations,
              %i[institutional_tag_id updated_at],
              where: "workflow_state = 'deleted'",
              name: "idx_inst_tag_assoc_tag_archived_updated_at",
              algorithm: :concurrently,
              if_not_exists: true

    # Cascade-restore: find tags deleted at the same instant as a category
    add_index :institutional_tags,
              %i[category_id updated_at],
              where: "workflow_state = 'deleted'",
              name: "idx_inst_tags_category_archived_updated_at",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
