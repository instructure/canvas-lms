class MasterCourses::FolderLockingHelper
  # couldn't think of an ideal place to put this

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
end
