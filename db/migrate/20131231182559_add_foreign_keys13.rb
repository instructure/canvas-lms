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

class AddForeignKeys13 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :external_feed_entries, :external_feeds, delay_validation: true
    # clear bad data first
    DelayedMessage.where("communication_channel_id IS NOT NULL AND NOT EXISTS (?)", CommunicationChannel.where("communication_channel_id=communication_channels.id")).delete_all
    NotificationPolicy.where("communication_channel_id IS NOT NULL AND NOT EXISTS (?)", CommunicationChannel.where("communication_channel_id=communication_channels.id")).delete_all
    add_foreign_key_if_not_exists :notification_policies, :communication_channels, delay_validation: true
    WebConferenceParticipant.where("NOT EXISTS (?)", WebConference.where("web_conference_id=web_conferences.id")).delete_all
    add_foreign_key_if_not_exists :web_conference_participants, :web_conferences, delay_validation: true
    add_foreign_key_if_not_exists :pseudonyms, :accounts, delay_validation: true
    add_foreign_key_if_not_exists :assessment_requests, :submissions, column: :asset_id, delay_validation: true
    add_foreign_key_if_not_exists :content_migrations, :attachments, column: :exported_attachment_id, delay_validation: true
    add_foreign_key_if_not_exists :content_migrations, :attachments, column: :overview_attachment_id, delay_validation: true
    add_foreign_key_if_not_exists :context_module_progressions, :context_modules, delay_validation: true
    DiscussionEntry.where("attachment_id IS NOT NULL AND NOT EXISTS (?)", Attachment.where("attachment_id=attachments.id")).update_all(attachment_id: nil)
    add_foreign_key_if_not_exists :discussion_entries, :attachments, delay_validation: true
    add_foreign_key_if_not_exists :discussion_entries, :discussion_topics, delay_validation: true
    add_foreign_key_if_not_exists :discussion_entry_participants, :discussion_entries, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :external_feed_entries, :external_feeds
    remove_foreign_key_if_exists :notification_policies, :communication_channels
    remove_foreign_key_if_exists :web_conference_participants, :web_conferences
    remove_foreign_key_if_exists :pseudonyms, :accounts
    remove_foreign_key_if_exists :assessment_requests, column: :asset_id
    remove_foreign_key_if_exists :content_migrations, column: :exported_attachment_id
    remove_foreign_key_if_exists :content_migrations, column: :overview_attachment_id
    remove_foreign_key_if_exists :context_module_progressions, :context_modules
    remove_foreign_key_if_exists :discussion_entries, :attachments
    remove_foreign_key_if_exists :discussion_entries, :discussion_topics
    remove_foreign_key_if_exists :discussion_entry_participants, :discussion_entries
  end
end
