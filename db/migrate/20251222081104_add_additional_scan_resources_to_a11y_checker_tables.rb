# frozen_string_literal: true

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

class AddAdditionalScanResourcesToA11yCheckerTables < ActiveRecord::Migration[7.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_reference :accessibility_resource_scans,
                  :discussion_topic,
                  if_not_exists: true,
                  foreign_key: true,
                  index: {
                    algorithm: :concurrently,
                    if_not_exists: true,
                    where: "discussion_topic_id IS NOT NULL"
                  }

    add_reference :accessibility_issues,
                  :discussion_topic,
                  if_not_exists: true,
                  foreign_key: true,
                  index: {
                    algorithm: :concurrently,
                    if_not_exists: true,
                    where: "discussion_topic_id IS NOT NULL"
                  }

    add_reference :accessibility_resource_scans,
                  :announcement,
                  if_not_exists: true,
                  foreign_key: { to_table: :discussion_topics },
                  index: {
                    algorithm: :concurrently,
                    if_not_exists: true,
                    where: "announcement_id IS NOT NULL"
                  }

    add_reference :accessibility_issues,
                  :announcement,
                  if_not_exists: true,
                  foreign_key: { to_table: :discussion_topics },
                  index: {
                    algorithm: :concurrently,
                    if_not_exists: true,
                    where: "announcement_id IS NOT NULL"
                  }

    add_column :accessibility_resource_scans, :is_syllabus, :boolean, default: false, null: false, if_not_exists: true
    add_column :accessibility_issues, :is_syllabus, :boolean, default: false, null: false, if_not_exists: true
  end

  def down
    remove_column :accessibility_issues, :is_syllabus, if_exists: true
    remove_column :accessibility_resource_scans, :is_syllabus, if_exists: true

    remove_reference :accessibility_issues, :announcement, if_exists: true
    remove_reference :accessibility_resource_scans, :announcement, if_exists: true

    remove_reference :accessibility_issues, :discussion_topic, if_exists: true
    remove_reference :accessibility_resource_scans, :discussion_topic, if_exists: true
  end
end
