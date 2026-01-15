# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
module DataFixup::MoveAttachmentAssociationsToReplacedAttachments
  def self.run
    Attachment.where.not(replacement_attachment_id: nil)
              .where(file_state: "deleted")
              .where("EXISTS (SELECT 1 FROM #{AttachmentAssociation.quoted_table_name} WHERE attachment_id = #{Attachment.quoted_table_name}.id)")
              .find_in_batches do |replaced_attachments|
                attachment_ids = replaced_attachments.map(&:id)

                AttachmentAssociation.where(attachment_id: attachment_ids).in_batches do |batch|
                  batch.update_all(
                    "attachment_id = (
            WITH RECURSIVE replacement_chain AS (
              SELECT id, replacement_attachment_id, 0 as depth
              FROM #{Attachment.quoted_table_name}
              WHERE id = #{AttachmentAssociation.quoted_table_name}.attachment_id

              UNION ALL

              SELECT a.id, a.replacement_attachment_id, rc.depth + 1
              FROM #{Attachment.quoted_table_name} a
              INNER JOIN replacement_chain rc ON a.id = rc.replacement_attachment_id
              WHERE rc.replacement_attachment_id IS NOT NULL
                AND rc.depth < 50  -- Safety limit to prevent infinite loops
            )
            SELECT id
            FROM replacement_chain
            ORDER BY depth DESC
            LIMIT 1
          )"
                  )
                end
    end
  end
end
