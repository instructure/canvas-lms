# frozen_string_literal: true

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

class ConversationBatch < ActiveRecord::Base
  include SimpleTags
  include Workflow

  belongs_to :user
  belongs_to :root_conversation_message, class_name: "ConversationMessage"
  belongs_to :context, polymorphic: [:account, :course, { context_group: "Group" }]

  before_save :serialize_conversation_message_ids
  after_create :queue_delivery

  validates :user_id, :workflow_state, :root_conversation_message_id, presence: true
  validates :subject, length: { maximum: maximum_string_length, allow_nil: true }

  scope :in_progress, -> { where(workflow_state: ["created", "sending"]) }

  attr_accessor :mode

  attr_reader :conversations

  def deliver(update_progress = true)
    shard.activate do
      chunk_size = 25

      @conversations = []
      self.user = user_map[user_id]
      existing_conversations = Conversation.find_all_private_conversations(user,
                                                                           recipient_ids.map { |id| user_map[id] },
                                                                           context_type:,
                                                                           context_id:)
      update_attribute :workflow_state, "sending"

      ModelCache.with_cache(conversations: existing_conversations, users: { id: user_map }) do
        should_cc_author = true

        recipient_ids.each_slice(chunk_size) do |ids|
          ids.each do |id|
            is_group = group?
            conversation = user.initiate_conversation([user_map[id]],
                                                      !is_group,
                                                      subject:,
                                                      context_type:,
                                                      context_id:)
            @conversations << conversation
            message = root_conversation_message.clone
            message.generate_user_note = generate_user_note
            conversation.add_message(message, update_for_sender: false, tags:, cc_author: should_cc_author)
            conversation_message_ids << message.id

            should_cc_author = false
          end
          # update it in chunks, not on every message
          save! if update_progress
        end
      end

      update_attribute :workflow_state, "sent"
    end
  rescue
    self.workflow_state = "error"
    save!
  end

  def completion
    # what fraction of the total time we think we'll be waiting for the
    # job to start. this is a bit hand-wavy, but basically we guesstimate
    # the average wait time as being equivalent to sending 20 messages
    job_start_factor = 20.0 / (recipient_ids.size + 20)

    case workflow_state
    when "sent"
      1
    when "created"
      # the first part of the progress bar is while we wait for the job
      # to start. ideally this will just take a couple seconds. if jobs
      # are backed up, we still want to make it seem like we are making
      # headway. every minute we will advance half of the remainder of
      # job_start_factor.
      minutes = (Time.zone.now - created_at).to_i / 60.0
      job_start_factor * (1 - (1 / (2**minutes)))
    else
      # the rest of the progress bar is nice and linear
      job_start_factor + ((1 - job_start_factor) * conversation_message_ids.size / recipient_ids.size)
    end
  end

  attr_writer :user_map

  def user_map
    @user_map ||= shard.activate { User.where(id: recipient_ids + [user_id]).index_by(&:id) }
  end

  def recipient_ids
    @recipient_ids ||= read_attribute(:recipient_ids).split(",").map(&:to_i)
  end

  def recipient_ids=(ids)
    write_attribute(:recipient_ids, ids.join(","))
  end

  def recipient_count
    recipient_ids.size
  end

  def conversation_message_ids
    @conversation_message_ids ||= (read_attribute(:conversation_message_ids) || "").split(",").map(&:to_i)
  end

  def serialize_conversation_message_ids
    write_attribute :conversation_message_ids, conversation_message_ids.join(",")
  end

  def queue_delivery
    sync = (mode != :async)
    delay(synchronous: sync).deliver(!sync)
  end

  workflow do
    state :created
    state :sending
    state :sent
    state :error
  end

  def local_tags
    tags
  end

  def self.created_as_template?(message:)
    message.conversation_id.blank?
  end

  def self.generate(root_message, recipients, mode = :async, options = {})
    batch = new
    batch.mode = mode
    # normally the association would do this for us, but the validation
    # fails beforehand
    root_message.save! if root_message.new_record?
    batch.root_conversation_message = root_message
    batch.user_id = root_message.author_id
    batch.recipient_ids = recipients.map(&:id)
    batch.context_type = options[:context_type]
    batch.context_id = options[:context_id]
    batch.tags = options[:tags]
    batch.subject = options[:subject]
    batch.group = !!options[:group]
    user_map = recipients.index_by(&:id)
    user_map[batch.user_id] = batch.user
    batch.user_map = user_map
    batch.generate_user_note = root_message.generate_user_note
    batch.save!
    batch
  end
end
