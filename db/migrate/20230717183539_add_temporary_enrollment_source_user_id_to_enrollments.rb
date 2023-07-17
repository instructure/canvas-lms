# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class AddTemporaryEnrollmentSourceUserIdToEnrollments < ActiveRecord::Migration[7.0]
  include MigrationHelpers::AddColumnAndFk

  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column_and_fk :enrollments, :temporary_enrollment_source_user_id, :users, if_not_exists: true
    add_index :enrollments,
              %i[temporary_enrollment_source_user_id user_id type role_id course_section_id],
              where: "temporary_enrollment_source_user_id IS NOT NULL",
              name: "index_enrollments_on_temp_enrollment_user_type_role_section",
              unique: true,
              if_not_exists: true,
              algorithm: :concurrently
  end

  def down
    remove_index :enrollments,
                 name: "index_enrollments_on_temp_enrollment_user_type_role_section",
                 if_exists: true
    remove_column :enrollments, :temporary_enrollment_source_user_id
  end
end
