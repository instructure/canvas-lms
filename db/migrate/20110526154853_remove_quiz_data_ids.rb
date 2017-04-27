#
# Copyright (C) 2011 - present Instructure, Inc.
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

# some cloned quiz questions mistakenly have the old question id saved to the data hash, causing issues when trying to edit.
class RemoveQuizDataIds < ActiveRecord::Migration[4.2]
  tag :predeploy

  class QuizQuestionDataMigrationARShim < ActiveRecord::Base
    self.table_name = "quiz_questions"
    serialize :question_data
  end

  def self.up
    QuizQuestionDataMigrationARShim.find_each do |qq|
      data = qq.question_data
      if data.is_a?(Hash) && data[:id].present? && data[:id] != qq.id
        data[:id] = qq.id
        qq.save
      end
    end
  end

  def self.down
  end
end
