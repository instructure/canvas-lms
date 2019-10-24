#
# Copyright (C) 2019 - present Instructure, Inc.
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
#

class CreateAccountPronouns < ActiveRecord::Migration[5.2]
  tag :predeploy
  def change
    create_table :account_pronouns do |t|
      t.belongs_to :account, foreign_key: true, limit: 8, index: true
      t.string :pronoun, null: false
      t.timestamps
      t.string :workflow_state
    end
    AccountPronoun.reset_column_information
    AccountPronoun.create_defaults
  end
end
