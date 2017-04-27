#
# Copyright (C) 2013 - present Instructure, Inc.
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

class MakeSisIdsUnique < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :accounts, [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true, algorithm: :concurrently
    add_index :accounts, :root_account_id, algorithm: :concurrently
    add_index :courses, [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true, algorithm: :concurrently
    add_index :course_sections, [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true, algorithm: :concurrently
    add_index :enrollment_terms, [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true, algorithm: :concurrently
    add_index :enrollment_terms, :root_account_id, algorithm: :concurrently
    remove_index :pseudonyms, name: 'index_pseudonyms_on_unique_id'
    add_index :pseudonyms, [:sis_user_id, :account_id], where: "sis_user_id IS NOT NULL", unique: true, algorithm: :concurrently
    add_index :pseudonyms, :account_id, algorithm: :concurrently
    add_index :groups, [:sis_source_id, :root_account_id], where: "sis_source_id IS NOT NULL", unique: true, algorithm: :concurrently

    remove_index :accounts, :sis_source_id
    remove_index :accounts, [:root_account_id, :sis_source_id]
    remove_index :courses, :sis_source_id
    remove_index :course_sections, [:root_account_id, :sis_source_id]
    remove_index :enrollment_terms, :sis_source_id
    remove_index :enrollment_terms, [:root_account_id, :sis_source_id]
    remove_index :pseudonyms, :sis_user_id
  end

  def self.down
    add_index :accounts, :sis_source_id, algorithm: :concurrently
    add_index :accounts, [:root_account_id, :sis_source_id], algorithm: :concurrently
    add_index :courses, :sis_source_id, algorithm: :concurrently
    add_index :course_sections, [:root_account_id, :sis_source_id], algorithm: :concurrently
    add_index :enrollment_terms, :sis_source_id, algorithm: :concurrently
    add_index :enrollment_terms, [:root_account_id, :sis_source_id], algorithm: :concurrently
    add_index :pseudonyms, :sis_user_id, algorithm: :concurrently

    remove_index :accounts, [:sis_source_id, :root_account_id]
    remove_index :accounts, :root_account_id
    remove_index :courses, [:sis_source_id, :root_account_id]
    remove_index :course_sections, [:sis_source_id, :root_account_id]
    remove_index :enrollment_terms, [:sis_source_id, :root_account_id]
    remove_index :enrollment_terms, :root_account_id
    remove_index :pseudonyms, [:unique_id, :account_id]
    remove_index :pseudonyms, [:sis_user_id, :account_id]
    remove_index :pseudonyms, :account_id
    remove_index :groups, [:sis_source_id, :root_account_id]
  end
end
