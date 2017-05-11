#
# Copyright (C) 2012 - present Instructure, Inc.
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
