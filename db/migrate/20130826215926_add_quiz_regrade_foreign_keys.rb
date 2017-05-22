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

class AddQuizRegradeForeignKeys < ActiveRecord::Migration[4.2]
  tag :predeploy
  def self.up
    add_foreign_key_if_not_exists :quiz_regrades, :users
    add_foreign_key_if_not_exists :quiz_regrades, :quizzes

    add_foreign_key_if_not_exists :quiz_regrade_runs, :quiz_regrades

    add_foreign_key_if_not_exists :quiz_question_regrades, :quiz_regrades
    add_foreign_key_if_not_exists :quiz_question_regrades, :quiz_questions
  end

  def self.down
    remove_foreign_key_if_exists :quiz_regrades, :users
    remove_foreign_key_if_exists :quiz_regrades, :quizzes

    remove_foreign_key_if_exists :quiz_regrade_runs, :quiz_regrades

    remove_foreign_key_if_exists :quiz_question_regrades, :quiz_regrades
    remove_foreign_key_if_exists :quiz_question_regrades, :quiz_questions
  end
end
