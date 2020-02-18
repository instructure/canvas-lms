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

class AddForeignKeys10 < ActiveRecord::Migration[4.2]
  # this used to be post deploy, but now we need to modify a constraint in a
  # predeploy so a new database will have the contrainte before it is attempted
  # to be modified.
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :learning_outcome_results, :users, delay_validation: true
    add_foreign_key_if_not_exists :media_objects, :users, delay_validation: true
    add_foreign_key_if_not_exists :page_comments, :users, delay_validation: true
    add_foreign_key_if_not_exists :page_views, :users, column: :real_user_id, delay_validation: true
    add_foreign_key_if_not_exists :page_views, :users, delay_validation: true
    add_foreign_key_if_not_exists :pseudonyms, :users, delay_validation: true
    add_foreign_key_if_not_exists :quiz_submissions, :users, delay_validation: true
    add_foreign_key_if_not_exists :rubric_assessments, :users, column: :assessor_id, delay_validation: true
    add_foreign_key_if_not_exists :rubric_assessments, :users, delay_validation: true
    add_foreign_key_if_not_exists :rubrics, :users, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :learning_outcome_results, :users
    remove_foreign_key_if_exists :media_objects, :users
    remove_foreign_key_if_exists :page_comments, :users
    remove_foreign_key_if_exists :page_views, column: :real_user_id
    remove_foreign_key_if_exists :page_views, :users
    remove_foreign_key_if_exists :pseudonyms, :users
    remove_foreign_key_if_exists :quiz_submissions, :users
    remove_foreign_key_if_exists :rubric_assessments, column: :assessor_id
    remove_foreign_key_if_exists :rubric_assessments, :users
    remove_foreign_key_if_exists :rubrics, :users
  end
end
