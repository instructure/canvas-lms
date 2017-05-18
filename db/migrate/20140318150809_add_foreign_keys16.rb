#
# Copyright (C) 2014 - present Instructure, Inc.
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

class AddForeignKeys16 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :pseudonyms, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :accounts, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :enrollment_terms, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :abstract_courses, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :courses, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :course_sections, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :enrollments, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :groups, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :group_memberships, :sis_batches, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :pseudonyms, :sis_batches
    remove_foreign_key_if_exists :accounts, :sis_batches
    remove_foreign_key_if_exists :enrollment_terms, :sis_batches
    remove_foreign_key_if_exists :abstract_courses, :sis_batches
    remove_foreign_key_if_exists :courses, :sis_batches
    remove_foreign_key_if_exists :course_sections, :sis_batches
    remove_foreign_key_if_exists :enrollments, :sis_batches
    remove_foreign_key_if_exists :groups, :sis_batches
    remove_foreign_key_if_exists :group_memberships, :sis_batches
  end
end
