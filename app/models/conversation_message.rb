#
# Copyright (C) 2011 Instructure, Inc.
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
#

class ConversationMessage < ActiveRecord::Base
  include SendToStream

  belongs_to :conversation
  belongs_to :author, :class_name => 'User'
  has_many :conversation_message_participants
  has_many :attachments, :as => :context, :order => 'created_at, id'
  delegate :participants, :to => :conversation
  delegate :subscribed_participants, :to => :conversation
  attr_accessible

  named_scope :human, :conditions => "NOT generated"
  named_scope :with_media_comments, :conditions => "media_comment_id IS NOT NULL"

  validates_length_of :body, :maximum => maximum_text_length

  has_a_broadcast_policy
  set_broadcast_policy do |p|
    p.dispatch :conversation_message
    p.to { self.recipients }
    p.whenever {|record| (record.just_created || @re_send_message) && !record.generated}

    p.dispatch :added_to_conversation
    p.to { self.new_recipients }
    p.whenever {|record| (record.just_created || @re_send_message) && record.generated && record.event_data[:event_type] == :users_added}
  end

  on_create_send_to_streams do
    self.recipients
  end
  
  before_save :infer_values
  
  def infer_values
    self.media_comment_id = nil if self.media_comment_id && self.media_comment_id.strip.empty?
    if self.media_comment_id && self.media_comment_id_changed?
      @media_comment = MediaObject.find_by_media_id(self.media_comment_id)
      self.media_comment_id = nil unless @media_comment
      self.media_comment_type = @media_comment.media_type if @media_comment
    end
    self.media_comment_type = nil unless self.media_comment_id
  end

  def has_media_comment?
    !self.media_comment_id.nil?
  end

  def media_comment
    if !@media_comment && self.media_comment_id
      @media_comment = MediaObject.find_by_media_id(self.media_comment_id)
    end
    @media_comment
  end

  def media_comment=(media_comment)
    self.media_comment_id = media_comment.media_id
    self.media_comment_type = media_comment.media_type
    @media_comment = media_comment
  end

  # TODO do this in SQL
  def recipients
    self.subscribed_participants - [self.author]
  end

  def new_recipients
    return [] unless generated? and event_data[:event_type] == :users_added
    recipients.select{ |u| event_data[:user_ids].include?(u.id) }
  end

  # for developer use on console only
  def resend_message!
    @re_send_message = true
    self.save!
    @re_send_message = false
  end

  def body
    if generated?
      format_event_message
    else
      read_attribute(:body)
    end
  end

  def event_data
    return {} unless generated?
    @event_data ||= YAML.load(read_attribute(:body))
  end

  def format_event_message
    case event_data[:event_type]
    when :users_added
      user_names = User.find_all_by_id(event_data[:user_ids]).map(&:short_name)
      EventFormatter.users_added(author.short_name, user_names)
    end
  end

  def generate_user_note
    return unless recipients.size == 1
    recipient = recipients.first
    return unless recipient.grants_right?(author, :create_user_notes)

    self.extend TextHelper
    title = t(:subject, "Private message, %{timestamp}", :timestamp => date_string(created_at))
    note = format_message(body).first
    recipient.user_notes.create(:creator => author, :title => title, :note => note)
  end
  
  def formatted_body(truncate=nil)
    self.extend TextHelper
    res = format_message(body).first
    res = truncate_html(res, :max_length => truncate, :words => true) if truncate
    res
  end

  def reply_from(opts)
    conversation.reply_from(opts)
  end

  def forwarded_messages
    @forwarded_messages ||= forwarded_message_ids && self.class.find_all_by_id(forwarded_message_ids.split(',')) || []
  end

  def as_json(options = {})
    super(options)['conversation_message'].merge({
      'forwarded_messages' => forwarded_messages,
      'attachments' => attachments.map{ |a| a.as_json['attachment'].merge({'uuid' => a.uuid}) },
      'media_comment' => media_comment.as_json['media_object']
    })
  end

  class EventFormatter
    def self.users_added(author_name, user_names)
      I18n.t 'conversation_message.users_added', {
          :one => "%{user} was added to the conversation by %{current_user}",
          :other => "%{list_of_users} were added to the conversation by %{current_user}"
       },
       :count => user_names.size,
       :user => user_names.first,
       :list_of_users => user_names.all?(&:html_safe?) ? user_names.to_sentence.html_safe : user_names.to_sentence,
       :current_user => author_name
    end
  end
end

