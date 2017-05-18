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

class CreateQuizQuestionRegrades < ActiveRecord::Migration[4.2]
  tag :predeploy
  def self.up
    create_table :quiz_question_regrades do |t|
      t.integer :quiz_regrade_id, limit: 8, null: false
      t.integer :quiz_question_id, limit: 8, null: false
      t.string :regrade_option, null: false

      t.timestamps null: true
    end

    add_index :quiz_question_regrades, [:quiz_regrade_id, :quiz_question_id], unique: true, name: 'index_qqr_on_qr_id_and_qq_id'
  end

  def self.down
    drop_table :quiz_question_regrades
  end
end
