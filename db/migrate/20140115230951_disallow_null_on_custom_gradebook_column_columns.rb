#
# Copyright (C) 2014 - present Instructure, Inc.
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

class DisallowNullOnCustomGradebookColumnColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.allow_null(frd)
    %w(position workflow_state course_id).each { |col|
      change_column_null :custom_gradebook_columns, col, frd
    }

    %w(content user_id custom_gradebook_column_id).each { |col|
      change_column_null :custom_gradebook_column_data, col, frd
    }
  end

  def self.up
    allow_null(false)
  end

  def self.down
    allow_null(true)
  end
end
