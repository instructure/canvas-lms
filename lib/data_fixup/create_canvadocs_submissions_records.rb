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

module DataFixup::CreateCanvadocsSubmissionsRecords

  def self.run
    Shackles.activate(:slave) do
      %w(canvadocs crocodoc_documents).each do |table|
        association = table.singularize
        column = "#{association}_id"
        AttachmentAssociation
        .joins(attachment: association)
        .where(context_type: "Submission")
        .select("attachment_associations.context_id AS submission_id, #{table}.id AS #{column}")
        .find_in_batches do |chunk|
          canvadocs_submissions = chunk.map do |aa|
            {:submission_id => aa.submission_id,
             column         => aa[column]}
          end
          Shackles.activate(:master) do
            CanvadocsSubmission.bulk_insert canvadocs_submissions
          end
        end
      end
    end
  end

end
