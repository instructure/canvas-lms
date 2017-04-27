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

class AddLookupIndexToQuizQuestions < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    remove_index :quiz_questions, name: "index_quiz_questions_on_assessment_question_id"
    remove_index :quiz_questions, name: "index_quiz_questions_on_quiz_id"

    # we'll need the composite index when pulling questions out of a bank,
    # otherwise all queries use the quiz_id and would utilize this index
    add_index :quiz_questions, [ :quiz_id, :assessment_question_id ], {
      name: 'idx_qqs_on_quiz_and_aq_ids',
      algorithm: :concurrently
    }
  end

  def down
    add_index :quiz_questions, :assessment_question_id, {
      name: "index_quiz_questions_on_assessment_question_id",
      algorithm: :concurrently
    }

    add_index :quiz_questions, :quiz_id, {
      name: "index_quiz_questions_on_quiz_id",
      algorithm: :concurrently
    }

    remove_index :quiz_questions, :name => 'idx_qqs_on_quiz_and_aq_ids'
  end
end
