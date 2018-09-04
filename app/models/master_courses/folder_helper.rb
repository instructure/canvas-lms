#
# Copyright (C) 2017 - present Instructure, Inc.
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

class MasterCourses::FolderHelper
  def self.cache_key(child_course)
    ["locked_folder_ids_for_master_courses", Shard.global_id_for(child_course)].cache_key
  end

  def self.recalculate_locked_folders(child_course)
    Rails.cache.delete(cache_key(child_course))
    locked_folder_ids_for_course(child_course) # preload the cache
  end

  def self.locked_folder_ids_for_course(child_course)
    child_course.shard.activate do
      Rails.cache.fetch(cache_key(child_course)) do
        folder_id_restriction_pairs = child_course.attachments.not_deleted.
          where("#{Attachment.table_name}.migration_id IS NOT NULL AND
            #{Attachment.table_name}.migration_id LIKE ?", "#{MasterCourses::MIGRATION_ID_PREFIX}%").
          joins("INNER JOIN #{MasterCourses::MasterContentTag.quoted_table_name} ON
            #{Attachment.table_name}.migration_id=#{MasterCourses::MasterContentTag.table_name}.migration_id").
          distinct.pluck(:folder_id, :restrictions)

        locked_folder_ids = Set.new
        folder_id_restriction_pairs.each do |folder_id, restrictions|
          locked_folder_ids << folder_id if restrictions.present? # treat folder as locked if any part is locked
        end

        if locked_folder_ids.any?
          # now find all parents for locked folders
          all_ids = Folder.connection.select_values(<<-SQL)
            WITH RECURSIVE t AS (
              SELECT id, parent_folder_id FROM #{Folder.quoted_table_name} WHERE id IN (#{locked_folder_ids.to_a.sort.join(",")})
              UNION
              SELECT folders.id, folders.parent_folder_id FROM #{Folder.quoted_table_name} INNER JOIN t ON folders.id=t.parent_folder_id
            )
            SELECT DISTINCT id FROM t
          SQL
          all_ids.map(&:to_i)
        else
          []
        end
      end
    end
  end

  def self.update_folder_names_and_states(child_course, content_export)
    cutoff_time = content_export.master_migration&.master_template&.last_export_completed_at
    return unless cutoff_time

    updated_folders = content_export.context.folders.where('updated_at>?', cutoff_time).where.not(cloned_item_id: nil)
    updated_folders.each do |source_folder|
      dest_folder = child_course.folders.active.where(cloned_item_id: source_folder.cloned_item_id).take
      if dest_folder && [:name, :workflow_state, :locked, :lock_at, :unlock_at].any?{|attr| dest_folder.send(attr) != source_folder.send(attr)}
        [:name, :workflow_state, :locked, :lock_at, :unlock_at].each do |attr|
          dest_folder.send("#{attr}=", source_folder.send(attr))
        end
        dest_folder.save!
      end
    end
  end
end
