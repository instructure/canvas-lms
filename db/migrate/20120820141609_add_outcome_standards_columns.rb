#
# Copyright (C) 2012 - present Instructure, Inc.
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

class AddOutcomeStandardsColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :learning_outcomes, :vendor_guid, :string
    add_column :learning_outcomes, :low_grade, :string
    add_column :learning_outcomes, :high_grade, :string
    add_index :learning_outcomes, :vendor_guid, :name => "index_learning_outcomes_on_vendor_guid"

    add_column :learning_outcome_groups, :vendor_guid, :string
    add_column :learning_outcome_groups, :low_grade, :string
    add_column :learning_outcome_groups, :high_grade, :string
    add_index :learning_outcome_groups, :vendor_guid, :name => "index_learning_outcome_groups_on_vendor_guid"
  end

  def self.down
    remove_index :learning_outcomes, :name => "index_learning_outcomes_on_vendor_guid"
    remove_column :learning_outcomes, :vendor_guid
    remove_column :learning_outcomes, :low_grade
    remove_column :learning_outcomes, :high_grade

    remove_index :learning_outcome_groups, :name => "index_learning_outcome_groups_on_vendor_guid"
    remove_column :learning_outcome_groups, :vendor_guid
    remove_column :learning_outcome_groups, :low_grade
    remove_column :learning_outcome_groups, :high_grade
  end
end
