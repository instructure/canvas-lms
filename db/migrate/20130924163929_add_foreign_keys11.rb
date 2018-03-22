#
# Copyright (C) 2013 - present Instructure, Inc.
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

class AddForeignKeys11 < ActiveRecord::Migration[4.2]
  # this used to be post deploy, but now we need to modify a constraint in a
  # predeploy so a new database will have the contrainte before it is attempted
  # to be modified.
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :submission_comment_participants, :users, delay_validation: true
    add_foreign_key_if_not_exists :submission_comments, :users, column: :author_id, delay_validation: true
    add_foreign_key_if_not_exists :submission_comments, :users, column: :recipient_id, delay_validation: true
    add_foreign_key_if_not_exists :submissions, :users, delay_validation: true
    add_foreign_key_if_not_exists :user_notes, :users, column: :created_by_id, delay_validation: true
    add_foreign_key_if_not_exists :user_notes, :users, delay_validation: true
    add_foreign_key_if_not_exists :web_conference_participants, :users, delay_validation: true
    add_foreign_key_if_not_exists :web_conferences, :users, delay_validation: true
    add_foreign_key_if_not_exists :wiki_pages, :users, delay_validation: true
    add_foreign_key_if_not_exists :conversation_messages, :conversations, delay_validation: true
    add_foreign_key_if_not_exists :conversation_message_participants, :conversation_messages, delay_validation: true
    add_foreign_key_if_not_exists :conversation_batches, :conversation_messages, column: :root_conversation_message_id, delay_validation: true
    add_foreign_key_if_not_exists :conversation_batches, :users, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :submission_comment_participants, :users
    remove_foreign_key_if_exists :submission_comments, column: :author_id
    remove_foreign_key_if_exists :submission_comments, column: :recipient_id
    remove_foreign_key_if_exists :submissions, :users
    remove_foreign_key_if_exists :user_notes, column: :created_by_id
    remove_foreign_key_if_exists :user_notes, :users
    remove_foreign_key_if_exists :web_conference_participants, :users
    remove_foreign_key_if_exists :web_conferences, :users
    remove_foreign_key_if_exists :wiki_pages, :users
    remove_foreign_key_if_exists :conversation_messages, :conversations
    remove_foreign_key_if_exists :conversation_message_participants, :conversation_messages
    remove_foreign_key_if_exists :conversation_batches, column: :root_conversation_message_id
    remove_foreign_key_if_exists :conversation_batches, :users
  end
end
