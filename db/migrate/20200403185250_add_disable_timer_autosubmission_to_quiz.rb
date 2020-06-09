#
# Copyright (C) 2018 - present Instructure, Inc.
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

class AddDisableTimerAutosubmissionToQuiz < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :quizzes, :disable_timer_autosubmission, :boolean, if_not_exists: true
    change_column_default(:quizzes, :disable_timer_autosubmission, from: nil, to: false)
    DataFixup::BackfillNulls.run(Quizzes::Quiz, :disable_timer_autosubmission, default_value: false)
    change_column_null(:quizzes, :disable_timer_autosubmission, false)
  end
end
