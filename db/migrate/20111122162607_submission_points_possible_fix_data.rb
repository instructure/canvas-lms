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

class SubmissionPointsPossibleFixData < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    case connection.adapter_name
      when 'PostgreSQL'
        update <<-SQL
          UPDATE #{Quizzes::QuizSubmission.quoted_table_name}
          SET quiz_points_possible = points_possible
          FROM #{Quizzes::Quiz.quoted_table_name}
          WHERE quiz_id = quizzes.id AND quiz_points_possible <> points_possible AND (points_possible < 2147483647 AND quiz_points_possible = CAST(points_possible AS INTEGER) OR points_possible >= 2147483647 AND quiz_points_possible = 2147483647)
        SQL
    end
  end

  def self.down
  end
end
