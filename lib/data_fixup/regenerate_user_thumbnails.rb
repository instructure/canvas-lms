module DataFixup::RegenerateUserThumbnails
  def self.run
    profile_pic_ids = nil

    Shackles.activate(:slave) do
      profile_pic_ids = Attachment.connection.select_all <<-SQL
        SELECT DISTINCT at.id FROM #{User.quoted_table_name} AS u
        JOIN #{Attachment.quoted_table_name} AS at ON (at.context_type = 'User' and at.context_id = u.id)
        JOIN #{Folder.quoted_table_name} AS f ON at.folder_id = f.id
        JOIN #{Pseudonym.quoted_table_name} AS p on u.id = p.user_id
        JOIN #{Account.quoted_table_name} AS acc ON p.account_id = acc.id
        WHERE acc.workflow_state <> 'deleted'
          AND u.workflow_state not in ('deleted', 'rejected')
          AND at.file_state <> 'deleted'
          AND f.name = 'profile pictures'
      SQL
    end

    profile_pic_ids = profile_pic_ids.map { |h| h['id'] }
    profile_pic_ids.each do |id|
      begin
        a = Attachment.find(id)
        a.thumbnails.delete_all
        tmp_file = a.create_temp_file
        a.create_or_update_thumbnail(tmp_file, :thumb, '128x128')
        a.save
      rescue
      end
    end
  end
end
