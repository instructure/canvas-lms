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

class ModifySubmissionAndQuizSubmissionUserForeignKeyConstraint < ActiveRecord::Migration[5.0]
  tag :predeploy

  def up
    if connection.send(:postgresql_version) >= 90400
      alter_constraint(:submissions, find_foreign_key(:submissions, :users), new_name: 'fk_rails_8d85741475', deferrable: true)
      alter_constraint(:quiz_submissions, find_foreign_key(:quiz_submissions, :users), new_name: 'fk_rails_04850db4b4', deferrable: true)
    else
      remove_foreign_key_if_exists :quiz_submissions, :users
      add_foreign_key :quiz_submissions, :users, deferrable: true, delay_validation: true
      remove_foreign_key_if_exists :submissions, :users
      add_foreign_key :submissions, :users, deferrable: true, delay_validation: true
    end
  end

  def down
    if connection.send(:postgresql_version) >= 90400
      alter_constraint(:submissions, 'fk_rails_8d85741475', deferrable: false)
      alter_constraint(:quiz_submissions, 'fk_rails_04850db4b4', deferrable: false)
    else
      remove_foreign_key_if_exists :quiz_submissions, :users
      add_foreign_key :quiz_submissions, :users, deferrable: false, delay_validation: true
      remove_foreign_key_if_exists :submissions, :users
      add_foreign_key :submissions, :users, deferrable: false, delay_validation: true
    end
  end
end
