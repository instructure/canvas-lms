# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

class Mention < ApplicationRecord
  include SendToStream
  include Canvas::SoftDeletable

  belongs_to :user, inverse_of: :mentions
  belongs_to :discussion_entry, inverse_of: :mentions
  belongs_to :root_account, class_name: "Account"
  has_one :discussion_topic, through: :discussion_entry
  delegate :context, to: :discussion_entry
  after_create :log_created_mention_metrics

  has_a_broadcast_policy

  set_broadcast_policy do |p|
    p.dispatch :discussion_mention
    p.to { user }
    p.whenever { |record| record.previously_new_record? && record.active? && user != discussion_entry.user }
    p.data { discussion_entry.course_broadcast_data }
  end

  on_create_send_to_streams do
    user
  end

  def message
    if discussion_entry.active? && discussion_entry.grants_right?(user, :read)
      discussion_entry.message
    else
      I18n.t("Message not included, login to view the message.")
    end
  end

  def reply_from(opts)
    raise IncomingMail::Errors::UnknownAddress if discussion_entry.deleted?

    discussion_entry.reply_from(opts)
  end

  def log_created_mention_metrics
    InstStatsd::Statsd.distributed_increment("discussion_mention.created")
  end
end
