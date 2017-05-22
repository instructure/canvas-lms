#
# Copyright (C) 2016 - present Instructure, Inc.
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

module DataFixup::MoveCanvadocsSubmissionsToAttachmentShard
  def self.run
    CanvadocsSubmission.where(
      "crocodoc_document_id > ? OR canvadoc_id > ?",
      10**13, 10**13
    ).find_each do |cs|
      doc = CrocodocDocument.find(cs.crocodoc_document_id) ||
            Canvadoc.find(cs.canvadoc_id)
      doc.shard.activate do
        col = "#{doc.class_name.underscore}_id"
        CanvadocsSubmission.create submission_id: cs.submission.global_id,
          col => doc.id
      end
      cs.destroy
    end
  end
end
