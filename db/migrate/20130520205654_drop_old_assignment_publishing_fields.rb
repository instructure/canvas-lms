#
# Copyright (C) 2013 - present Instructure, Inc.
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

class DropOldAssignmentPublishingFields < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :courses, :publish_grades_immediately
    remove_column :assignments, :previously_published
    remove_column :submissions, :changed_since_publish
  end

  def self.down
    add_column :courses, :publish_grades_immediately, :boolean
    add_column :assignments, :previously_published, :boolean
    add_column :submissions, :changed_since_publish, :boolean
  end
end
