#
# Copyright (C) 2016 - present Instructure, Inc.
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

class AddGeneratedQuizQuestionUniquenessIndex < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :quiz_questions, :duplicate_index, :integer
    add_index :quiz_questions, [:assessment_question_id, :quiz_group_id, :duplicate_index],
              name: "index_generated_quiz_questions",
              where: "assessment_question_id IS NOT NULL AND quiz_group_id IS NOT NULL AND workflow_state='generated'",
              unique: true,
              algorithm: :concurrently
  end
end
