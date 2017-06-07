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

class TurnitinFix < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    Assignment.record_timestamps = false
    Assignment.where("turnitin_enabled AND EXISTS (?)",
                     Submission.active.where("assignment_id = assignments.id AND turnitin_data IS NOT NULL")).
        find_each do |assignment|
      assignment.turnitin_settings = assignment.turnitin_settings
      assignment.turnitin_settings[:created] = true
      assignment.save
    end
    Assignment.record_timestamps = true
  end

  def self.down
  end
end
