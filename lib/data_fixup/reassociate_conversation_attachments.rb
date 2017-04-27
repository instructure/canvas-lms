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

module DataFixup::ReassociateConversationAttachments

  def self.run
    conn = ConversationMessage.connection
    cmas = []

    ConversationMessage.transaction do
      conn.execute <<-SQL
        CREATE TEMPORARY TABLE _conversation_message_attachments AS
        SELECT context_id AS conversation_message_id,
          (SELECT author_id FROM #{ConversationMessage.quoted_table_name} WHERE id = a.context_id) AS author_id,
          id AS attachment_id
        FROM #{Attachment.quoted_table_name} a
        WHERE context_type = 'ConversationMessage'
      SQL
      conn.execute("CREATE INDEX _cma_cmid_index ON _conversation_message_attachments(conversation_message_id)")
      conn.execute("CREATE INDEX _cma_aid_index ON _conversation_message_attachments(attachment_id)")
      conn.execute "ANALYZE _conversation_message_attachments" if conn.adapter_name == 'PostgreSQL'
  
      # make sure users w/ conversation attachments have root folders
      conn.execute <<-SQL
        INSERT INTO #{Folder.quoted_table_name}(context_id, context_type, name, full_name, workflow_state)
        SELECT DISTINCT author_id, 'User', 'my files', 'my files', 'visible'
        FROM _conversation_message_attachments
        WHERE NOT EXISTS (SELECT 1 FROM #{Folder.quoted_table_name} WHERE context_id = author_id AND context_type = 'User' AND name = 'my files')
      SQL
  
      # and conversation attachment folders
      conn.execute <<-SQL
        INSERT INTO #{Folder.quoted_table_name}(context_id, context_type, name, full_name, workflow_state, parent_folder_id)
        SELECT DISTINCT author_id, 'User', 'conversation attachments', 'conversation attachments', 'visible', folders.id
        FROM _conversation_message_attachments, #{Folder.quoted_table_name}
        WHERE folders.context_id = author_id AND folders.context_type = 'User'
          AND NOT EXISTS (SELECT 1 FROM #{Folder.quoted_table_name} WHERE context_id = author_id AND context_type = 'User' AND name = 'conversation attachments')
      SQL
  
      conn.execute <<-SQL
        INSERT INTO #{AttachmentAssociation.quoted_table_name}(attachment_id, context_id, context_type)
        SELECT attachment_id, conversation_message_id, 'ConversationMessage'
        FROM _conversation_message_attachments
        WHERE author_id IS NOT NULL
      SQL
      cmas = conn.select_all("SELECT * FROM _conversation_message_attachments WHERE author_id IS NOT NULL")
      conn.execute "DROP TABLE _conversation_message_attachments"
    end

    cmas.group_by{ |r| r['conversation_message_id'] }.each_slice(1000) do |groups|
      conn.update <<-SQL
        UPDATE #{ConversationMessage.quoted_table_name}
        SET attachment_ids = CASE id #{groups.map{ |id, rows| "WHEN #{id} THEN '#{rows.map{ |r| r['attachment_id'] }.join(",")}' "}.join} END
        WHERE id IN (#{groups.map(&:first).join(', ')})
      SQL
    end

    cmas.each_slice(1000) do |rows|
      attachment2user = "CASE attachments.id #{rows.map{ |r| "WHEN #{r['attachment_id']} THEN #{r['author_id']} "}.join} END"
      conn.update <<-SQL
        UPDATE #{Attachment.quoted_table_name}
        SET context_type = 'User',
          context_id = #{attachment2user},
          folder_id = (SELECT f.id FROM #{Folder.quoted_table_name} f WHERE f.name = 'conversation attachments' AND f.context_type = 'User' AND f.context_id = #{attachment2user} LIMIT 1)
        WHERE attachments.id IN (
          #{rows.map{ |r| r['attachment_id'] }.join(', ')}
        )
      SQL
    end
  end
end
