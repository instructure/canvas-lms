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
#
class GradebookCsv < ActiveRecord::Base
  belongs_to :course, inverse_of: :gradebook_csvs
  belongs_to :user
  belongs_to :attachment
  belongs_to :progress

  validates :progress, presence: true

  def self.last_successful_export(course:, user:)
    csv = where(course_id: course, user_id: user).first
    return nil if csv.nil? || csv.failed?
    csv
  end

  def failed?
    progress.workflow_state == 'failed'
  end
end
