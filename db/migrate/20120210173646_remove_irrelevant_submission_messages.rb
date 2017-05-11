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

class RemoveIrrelevantSubmissionMessages < ActiveRecord::Migration[4.2]
  tag :predeploy

  disable_ddl_transaction!

  def self.up
    # destroy any submission messages where none of the commenters are
    # participants in the conversation. in production, this will remove about
    # 7k rows
    ConversationMessage.where(<<-CONDITIONS).destroy_all
      asset_id IS NOT NULL
      AND id NOT IN (
        SELECT DISTINCT cm.id
        FROM #{ConversationMessage.quoted_table_name} cm,
          #{ConversationParticipant.quoted_table_name} cp,
          #{SubmissionComment.quoted_table_name} sc
        WHERE
          cm.asset_id = sc.submission_id
          AND cp.conversation_id = cm.conversation_id
          AND sc.author_id = cp.user_id
      )
    CONDITIONS
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
