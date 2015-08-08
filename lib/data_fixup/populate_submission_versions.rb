#
# Copyright (C) 2013 Instructure, Inc.
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

module DataFixup::PopulateSubmissionVersions
  def self.run
    Version.where(:versionable_type => 'Submission').
      where("NOT EXISTS (?)", SubmissionVersion.where("version_id=versions.id")).
      find_in_batches do |versions|
      SubmissionVersion.index_versions(versions, ignore_errors: true)
    end
  end
end
