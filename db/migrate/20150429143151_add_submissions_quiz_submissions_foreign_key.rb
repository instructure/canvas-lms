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

class AddSubmissionsQuizSubmissionsForeignKey < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    add_index :submissions, :quiz_submission_id, where: "quiz_submission_id IS NOT NULL", algorithm: :concurrently
    add_foreign_key :submissions, :quiz_submissions, delay_validation: true
  end

  def down
    remove_foreign_key :submissions, :quiz_submissions
    remove_index :submissions, :quiz_submission_id
  end
end
