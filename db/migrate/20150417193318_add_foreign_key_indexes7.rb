#
# Copyright (C) 2015 - present Instructure, Inc.
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

class AddForeignKeyIndexes7 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :quiz_question_regrades, :quiz_question_id, name: 'index_qqr_on_qq_id', algorithm: :concurrently
    add_index :learning_outcome_groups, :root_learning_outcome_group_id, where: "root_learning_outcome_group_id IS NOT NULL", algorithm: :concurrently
    add_index :learning_outcome_results, :content_tag_id, algorithm: :concurrently
  end
end
