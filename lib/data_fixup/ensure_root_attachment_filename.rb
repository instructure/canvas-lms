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

module DataFixup::EnsureRootAttachmentFilename
  def self.run
    Shackles.activate(:slave) do
      Attachment.where(root_attachment_id: nil).
        joins("INNER JOIN #{Attachment.quoted_table_name} child ON attachments.id = child.root_attachment_id AND attachments.filename <> child.filename").
        where.not(workflow_state: 'broken').find_each do |root|
        if Attachment.s3_storage?
          unless root.s3object.exists?
            try_s3_children root
          end
        else
          unless File.exist? root.full_filename
            try_local_children root
          end
        end
      end
      Attachment.where.not(root_attachment_id: nil).
        where.not(filename: nil).where.not(workflow_state: 'broken').find_in_batches do |batch|
        Shackles.activate(:master) do
          Attachment.where(id: batch).update_all(filename: nil)
        end
      end
    end
  end

  def self.try_s3_children(root)
    root.children.where.not(filename: nil).where.not(filename: root.filename).each do |child|
      if child.s3object.exists?
        update_root_from_child(child, root)
        return true
      end
    end
  end

  def self.try_local_children(root)
    root.children.where.not(filename: nil).where.not(filename: root.filename).each do |child|
      if File.exist? child.full_filename
        update_root_from_child(child, root)
        return true
      end
    end
  end

  def self.update_root_from_child(child, root)
    Shackles.activate(:master) do
      root.update_attribute(:filename, child.filename)
    end
  end
end
