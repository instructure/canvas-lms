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

module DataFixup
  module FixMediaRecordingSubmissionTypes
    def self.run
      date = Date.strptime(Setting.get('media_recording_type_bad_date', '03/08/2013'), '%m/%d/%Y')
      Assignment.where("updated_at > ? AND submission_types LIKE '%online_media_recording%'", date).find_each do |assign|
        assign.submission_types = assign.submission_types.gsub('online_media_recording', 'media_recording')
        assign.save!
      end
    end
  end
end
