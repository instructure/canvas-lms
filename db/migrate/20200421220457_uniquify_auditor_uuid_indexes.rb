#
# Copyright (C) 2020 - present Instructure, Inc.
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
class UniquifyAuditorUuidIndexes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  tag :postdeploy

  def up
    add_index :auditor_authentication_records, :uuid, name: 'index_auth_audits_on_unique_uuid', unique: true, algorithm: :concurrently, if_not_exists: true
    add_index :auditor_course_records, :uuid, name: 'index_course_audits_on_unique_uuid', unique: true, algorithm: :concurrently, if_not_exists: true
    add_index :auditor_grade_change_records, :uuid, name: 'index_grade_audits_on_unique_uuid', unique: true, algorithm: :concurrently, if_not_exists: true
    remove_index :auditor_authentication_records, name: 'index_auditor_authentication_records_on_uuid'
    remove_index :auditor_course_records, name: 'index_auditor_course_records_on_uuid'
    remove_index :auditor_grade_change_records, name: 'index_auditor_grade_change_records_on_uuid'
  end

  def down
    add_index :auditor_authentication_records, :uuid, algorithm: :concurrently, if_not_exists: true
    add_index :auditor_course_records, :uuid, algorithm: :concurrently, if_not_exists: true
    add_index :auditor_grade_change_records, :uuid, algorithm: :concurrently, if_not_exists: true
    remove_index :auditor_authentication_records, name: 'index_auth_audits_on_unique_uuid'
    remove_index :auditor_course_records, name: 'index_course_audits_on_unique_uuid'
    remove_index :auditor_grade_change_records, name: 'index_grade_audits_on_unique_uuid'
  end
end
