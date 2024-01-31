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

class CreateLmgbOutcomeOrders < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    create_table :user_lmgb_outcome_orderings do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :user, foreign_key: true, null: false
      t.references :course, foreign_key: true, null: false
      t.references :learning_outcome, foreign_key: true, null: false
      t.integer :position, null: false
      t.timestamps
    end
    add_replica_identity "UserLmgbOutcomeOrderings", :root_account_id

    add_index :user_lmgb_outcome_orderings,
              %i[learning_outcome_id user_id course_id],
              unique: true,
              name: "index_user_lmgb_outcome_orderings"
  end
end
