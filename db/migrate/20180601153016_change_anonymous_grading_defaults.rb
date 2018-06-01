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

class ChangeAnonymousGradingDefaults < ActiveRecord::Migration[5.0]
  tag :predeploy

  def self.up
    change_column_default :assignments, :grader_comments_visible_to_graders, true
    change_column_default :assignments, :grader_names_visible_to_final_grader, true
  end

  def self.down
    change_column_default :assignments, :grader_comments_visible_to_graders, false
    change_column_default :assignments, :grader_names_visible_to_final_grader, false
  end
end
