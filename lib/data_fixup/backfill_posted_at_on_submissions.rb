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

module DataFixup::BackfillPostedAtOnSubmissions
  def self.run(start_at, end_at)
    Submission.find_ids_in_ranges(:start_at => start_at, :end_at => end_at) do |min_id, max_id|
      Submission.where(id: min_id..max_id, posted_at: nil).where.not(graded_at: nil).update_all("posted_at = graded_at")
    end
  end
end
