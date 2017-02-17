class MessageMigration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_index :conversation_message_participants, [:conversation_participant_id, :conversation_message_id], :name => :index_cmp_on_cpi_and_cmi
    add_index :inbox_items, [:asset_type, :asset_id]

    # for bringing over attachments and tracking deleted inbox_items
    # the other new columns get removed at the end of the migration, we'll keep this one for now
    # in case we need to track/fix any issues post migration
    add_column :conversation_messages, :context_message_id, :integer, :limit => 8

    return if Rails.env.test?

    unless connection.adapter_name =~ /postgres/
      $stderr.puts "don't know how to migrate conversation data for #{connection.adapter_name}!"
      return
    end

    # for grouping messages into conversations
    #   private: list of participant ids <= 2
    #   group: root_context_message_id + list of participant ids (if the list changes, it's a different conversation)
    add_column :conversations, :migration_signature, :text

    # helper column for merging into existing private conversations
    add_column :conversations, :tmp_private_hash, :string

    # from context_message, will get rolled up into conversation_participant
    add_column :conversation_message_participants, :unread, :boolean

    execute <<-SQL
      CREATE TEMPORARY TABLE __migrated_messages AS
      SELECT
        id,
        user_id AS author_id,
        created_at,
        CASE WHEN subject IS NULL OR LOWER(SUBSTR(subject, 1, 4)) = 're: ' THEN body ELSE subject || #{connection.quote("\n\n")} || body END AS body,
        COALESCE(root_context_message_id, id) AS root_context_message_id,
        media_comment_id,
        media_comment_type,
        '::TEXT' AS signature
      FROM
        #{connection.quote_table_name('context_messages')}
    SQL
    execute "CREATE INDEX index__migrated_messages_on_id ON __migrated_messages (id)"

    execute <<-SQL
      CREATE TEMPORARY TABLE __migrated_message_participants AS
      SELECT DISTINCT
        context_message_id AS migrated_message_id,
        user_id
      FROM
        #{connection.quote_table_name('context_message_participants')}
    SQL
    execute "CREATE INDEX index_mmp_on_message_id ON __migrated_message_participants (migrated_message_id)"

    execute <<-SQL
      CREATE TEMPORARY TABLE __migrated_message_participant_strings AS
      SELECT migrated_message_id, STRING_AGG(user_id::TEXT, ',') AS participants, COUNT(DISTINCT user_id) <= 2 AS private
      FROM (
        SELECT DISTINCT migrated_message_id, user_id
        FROM __migrated_message_participants
        ORDER BY migrated_message_id, user_id
      ) p
      GROUP BY migrated_message_id
    SQL
    execute "CREATE INDEX index_mmps_on_migrated_message_id ON __migrated_message_participant_strings (migrated_message_id)"

    execute <<-SQL
      UPDATE __migrated_messages
      SET signature = CASE WHEN private THEN '' ELSE root_context_message_id || ':' END || participants
      FROM __migrated_message_participant_strings
      WHERE migrated_message_id = __migrated_messages.id
    SQL
    execute "CREATE INDEX index___migrated_messages_on_signature ON __migrated_messages (signature)"

    execute <<-SQL
      INSERT INTO #{Conversation.quoted_table_name}(migration_signature, has_attachments, has_media_objects)
      SELECT DISTINCT signature, FALSE, FALSE
      FROM __migrated_messages
    SQL
    add_index :conversations, :migration_signature

    Conversation.where("migration_signature ~ E'^[0-9]+(,[0-9]+)?$'").find_each(:batch_size => 10000) do |conversation|
      conversation.update_attribute :tmp_private_hash, Digest::SHA1.hexdigest(conversation.migration_signature)
    end
    add_index :conversations, :tmp_private_hash

    # in case any private conversations already exist...
    update <<-SQL
      UPDATE #{Conversation.quoted_table_name}
      SET migration_signature = c2.migration_signature
      FROM #{Conversation.quoted_table_name} c2
      WHERE conversations.private_hash = c2.tmp_private_hash
    SQL
    execute <<-SQL
      CREATE TEMPORARY TABLE __existing_private_conversations AS
      SELECT private_hash FROM #{Conversation.quoted_table_name} WHERE private_hash IS NOT NULL
    SQL
    delete <<-SQL
      DELETE FROM #{Conversation.quoted_table_name} WHERE tmp_private_hash IN (SELECT private_hash FROM __existing_private_conversations)
    SQL

    # create participants for any group conversations or *new* private conversations
    remove_index :conversation_participants, :column => [:user_id, :last_message_at]
    add_index :conversation_participants, :user_id # temporary for better insert speeds (and to prevent people hitting new messaging from killing the db)
    subquery = "SELECT DISTINCT ON (signature) signature, id FROM __migrated_messages ORDER BY signature, id DESC"
    execute <<-SQL
      INSERT INTO #{ConversationParticipant.quoted_table_name}(conversation_id, user_id, subscribed, workflow_state, has_attachments, has_media_objects)
      SELECT c.id, mp.user_id, TRUE, 'read', FALSE, FALSE
      FROM __migrated_message_participants mp,
        (#{subquery}) AS m,
        #{Conversation.quoted_table_name} c
      WHERE migrated_message_id = m.id
        AND migration_signature = signature
        AND private_hash IS NULL
    SQL
    # make sure new private conversations have their hash set
    update <<-SQL
      UPDATE #{Conversation.quoted_table_name}
      SET private_hash = tmp_private_hash
      WHERE tmp_private_hash IS NOT NULL
    SQL

    execute <<-SQL
      INSERT INTO #{ConversationMessage.quoted_table_name}(conversation_id, author_id, created_at, generated, body, media_comment_id, media_comment_type, context_message_id)
      SELECT
        conversations.id,
        author_id,
        created_at,
        FALSE,
        body,
        media_comment_id,
        media_comment_type,
        __migrated_messages.id
      FROM
        __migrated_messages, #{Conversation.quoted_table_name}
      WHERE
        signature = migration_signature
    SQL


    # make messages visible to users
    execute <<-SQL
      INSERT INTO #{ConversationMessageParticipant.quoted_table_name}(conversation_message_id, conversation_participant_id, unread)
      SELECT
        cm.id,
        cp.id,
        ii.workflow_state = 'unread'
      FROM
        #{ConversationMessage.quoted_table_name} cm,
        #{ConversationParticipant.quoted_table_name} cp,
        #{connection.quote_table_name('inbox_items')} ii
      WHERE
        cm.conversation_id = cp.conversation_id
        AND ii.asset_id = cm.context_message_id
        AND ii.asset_type = 'ContextMessage'
        AND ii.user_id = cp.user_id
        AND ii.workflow_state <> 'deleted'
    SQL

    # make sure senders can see their sent items (they don't normally get an inbox_item, unless explicitly added as a recipient)
    execute <<-SQL
      INSERT INTO #{ConversationMessageParticipant.quoted_table_name}(conversation_message_id, conversation_participant_id, unread)
      SELECT
        cm.id,
        cp.id,
        FALSE
      FROM
        #{ConversationMessage.quoted_table_name} cm
      INNER JOIN
        #{ConversationParticipant.quoted_table_name} cp ON cm.conversation_id = cp.conversation_id AND cm.author_id = cp.user_id
      LEFT JOIN
        #{ConversationMessageParticipant.quoted_table_name} existing ON existing.conversation_message_id = cm.id AND existing.conversation_participant_id = cp.id
      WHERE
        cm.context_message_id IS NOT NULL
        AND existing.id IS NULL
    SQL

    # hide inbox_items from the users
    update "UPDATE #{connection.quote_table_name('inbox_items')} SET workflow_state = 'retired' WHERE asset_type IN ('ContextMessage', 'SubmissionComment') AND workflow_state = 'read'"
    update "UPDATE #{connection.quote_table_name('inbox_items')} SET workflow_state = 'retired_unread' WHERE asset_type IN ('ContextMessage', 'SubmissionComment') AND workflow_state = 'unread'"


    update <<-SQL
      UPDATE #{ConversationParticipant.quoted_table_name}
      SET workflow_state = 'unread'
      WHERE EXISTS (SELECT 1 FROM #{ConversationMessageParticipant.quoted_table_name} WHERE conversation_participants.id = conversation_participant_id AND unread LIMIT 1)
    SQL


    # attachments
    update <<-SQL
      UPDATE #{Attachment.quoted_table_name}
      SET context_id = conversation_messages.id, context_type = 'ConversationMessage'
      FROM #{ConversationMessage.quoted_table_name}
      WHERE attachments.context_type = 'ContextMessage' AND conversation_messages.context_message_id = attachments.context_id
    SQL

    update <<-SQL
      UPDATE #{ConversationParticipant.quoted_table_name}
      SET has_attachments = TRUE
      WHERE id IN (
        SELECT conversation_participant_id
        FROM #{ConversationMessageParticipant.quoted_table_name} cmp, #{Attachment.quoted_table_name} a
        WHERE
          a.context_type = 'ConversationMessage'
          AND a.context_id = conversation_message_id
      )
    SQL

    update <<-SQL
      UPDATE #{Conversation.quoted_table_name}
      SET has_attachments = TRUE
      WHERE id IN (
        SELECT conversation_id
        FROM #{ConversationMessage.quoted_table_name} cm, #{Attachment.quoted_table_name} a
        WHERE
          a.context_type = 'ConversationMessage'
          AND a.context_id = cm.id
      )
    SQL


    # audio comments
    update <<-SQL
      UPDATE #{ConversationParticipant.quoted_table_name}
      SET has_media_objects = TRUE
      WHERE id IN (
        SELECT conversation_participant_id
        FROM #{ConversationMessageParticipant.quoted_table_name} cmp, #{ConversationMessage.quoted_table_name} cm
        WHERE cmp.conversation_message_id = cm.id AND media_comment_id IS NOT NULL
      )
    SQL

    update <<-SQL
      UPDATE #{Conversation.quoted_table_name}
      SET has_media_objects = TRUE
      WHERE id IN (
        SELECT conversation_id
        FROM #{ConversationMessage.quoted_table_name}
        WHERE media_comment_id IS NOT NULL
      )
    SQL

    # cached stats
    execute <<-SQL
      CREATE TEMPORARY TABLE __migrated_conversation_stats AS
      SELECT
        conversation_participant_id,
        COUNT(*) AS message_count,
        MAX(cm.created_at) AS last_message_at,
        MAX(CASE WHEN cm.author_id = cp.user_id THEN cm.created_at ELSE NULL END) AS last_authored_at
      FROM #{ConversationMessageParticipant.quoted_table_name} cmp, #{ConversationMessage.quoted_table_name} cm, #{ConversationParticipant.quoted_table_name} cp
      WHERE conversation_message_id = cm.id AND conversation_participant_id = cp.id
      GROUP BY conversation_participant_id
    SQL
    execute "CREATE INDEX index_mcs_on_cpi ON __migrated_conversation_stats (conversation_participant_id)"

    update <<-SQL
      UPDATE #{ConversationParticipant.quoted_table_name}
      SET message_count = __migrated_conversation_stats.message_count,
        last_message_at = __migrated_conversation_stats.last_message_at,
        last_authored_at = __migrated_conversation_stats.last_authored_at
      'FROM __migrated_conversation_stats'
      WHERE conversation_participants.id = conversation_participant_id
    SQL
    add_index :conversation_participants, [:user_id, :last_message_at]
    remove_index :conversation_participants, :column => :user_id

    execute <<-SQL
      UPDATE #{User.quoted_table_name}
      SET unread_conversations_count = (SELECT COUNT(*) FROM #{ConversationParticipant.quoted_table_name} WHERE workflow_state = 'unread' AND user_id = users.id)
    SQL

    remove_column :conversations, :migration_signature
    remove_column :conversations, :tmp_private_hash
    remove_column :conversation_message_participants, :unread

    execute "DROP TABLE __migrated_messages"
    execute "DROP TABLE __migrated_message_participants"
    execute "DROP TABLE __migrated_message_participant_strings"
    execute "DROP TABLE __existing_private_conversations"
    execute "DROP TABLE __migrated_conversation_stats"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
