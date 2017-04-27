#
# Copyright (C) 2015 - present Instructure, Inc.
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

module DataFixup::RemoveDuplicateCanvadocsSubmissions
  def self.run
    %w[crocodoc_document_id canvadoc_id].each do |column|
      duplicates = CanvadocsSubmission.
        select("#{column}, submission_id").
        group("#{column}, submission_id").
        having("count(*) > 1")

      duplicates.find_each do |dup|
        scope = CanvadocsSubmission.where(
          column => dup[column],
          submission_id: dup.submission_id
        )
        keeper = scope.first
        scope.where("id <> ?", keeper.id).delete_all
      end
    end
  end
end
