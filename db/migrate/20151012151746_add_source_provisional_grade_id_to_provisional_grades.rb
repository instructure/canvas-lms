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

class AddSourceProvisionalGradeIdToProvisionalGrades < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :moderated_grading_provisional_grades, :source_provisional_grade_id, :integer, :limit => 8
    add_foreign_key :moderated_grading_provisional_grades, :moderated_grading_provisional_grades,
                    :column => :source_provisional_grade_id, :name => 'provisional_grades_source_provisional_grade_fk'
  end
end
