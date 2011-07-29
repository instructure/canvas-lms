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

class ContextMessage < ActiveRecord::Base
  include Workflow
  include SendToInbox
  include SendToStream
  attr_accessible :context, :user, :body, :subject, :recipients, :root_context_message, :protect_recipients, :media_comment_id, :media_comment_type
  belongs_to :context, :polymorphic => true
  belongs_to :root_context_message, :class_name => 'ContextMessage'
  has_many :attachments, :as => :context, :dependent => :destroy
  has_many :context_message_participants
  has_many :users, :through => :context_message_participants
  has_many :sub_messages, :class_name => 'ContextMessage', :foreign_key => 'root_context_message_id'
  belongs_to :user
  named_scope :for_context_codes, lambda { |context_codes| { :conditions => {:context_code => context_codes} } }
  validates_length_of :body, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  
  serialize :recipients
  serialize :viewed_user_ids
  
  
  before_save :set_defaults, :infer_values
  after_save :set_attachments
  after_save :record_participants
  
  workflow do
    state :active
    state :deleted
  end
  
  on_create_send_to_streams do
    (self.recipients || []).uniq
  end
  
  on_update_send_to_streams do
    if self.recipients && !self.recipients.empty? && !@skip_send_to_stream
      self.recipients
    end
  end
  
  on_create_send_to_inboxes do
    {
      :recipients => self.recipients,
      :subject => self.subject,
      :body => self.body,
      :sender => self.user_id
    }
  end

  
  set_policy do
    given { |user, session| self.cached_context_grants_right?(user, session, :manage_content) }
    can :read and can :update and can :delete and can :create and can :download
    
    given { |user, session| self.cached_context_grants_right?(user, session, :send_messages) }
    can :create
    
    given { |user, session| self.cached_context_grants_right?(user, session, :read) && self.users.include?(user) }
    can :read
  end
  
  def set_defaults
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
    self.viewed_user_ids ||= [self.user_id]
  end
  
  def infer_values
    self.media_comment_id = nil if self.media_comment_id && self.media_comment_id.strip.empty?
    if self.media_comment_id && self.media_comment_id_changed?
      mo = MediaObject.find_by_media_id(self.media_comment_id)
      self.media_comment_id = nil unless mo
    end
    self.media_comment_type = nil unless self.media_comment_id
  end

  def unread?(user)
    !read?(user)
  end
  
  def read(user)
    @skip_send_to_stream = true
    self.viewed_user_ids ||= [self.user_id]
    self.viewed_user_ids << user.id if user
    self.updated_at = Time.now # modifying the array doesn't trigger AR to update this
    transaction do
      if user && (item = user.inbox_items.find_by_asset_id_and_asset_type(self.id, "ContextMessage"))
        item.mark_as_read(false)
      end
      self.save!
    end
  rescue
    false
  end
  
  def read?(user)
    user && viewed_user_ids && viewed_user_ids.include?(user.id)
  end
  
  def record_participants
    sender = self.context_message_participants.find_by_user_id_and_participation_type(self.user_id, 'sender')
    unless sender
      sender = self.context_message_participants.new(:participation_type => 'sender')
      sender.user_id = self.user_id
      sender.save
    end
    recipient_users = self.context.users.select{|u| (self.recipients || []).include?(u.id) }
    return if recipient_users.empty?
    participants_hash = {}
    self.context_message_participants.find_all_by_user_id(recipient_users.map(&:id)).each do |participant|
      participants_hash[participant.user_id] = true
    end
    new_user_ids = []
    recipient_users.each do |user|
      if !participants_hash[user.id]
        new_user_ids << user.id
      end
    end
    add_new_recipients(new_user_ids) unless new_user_ids.empty?
  end
  
  def from_name
    self.user.name
  end
  
  def add_new_recipients(user_ids)
    user_ids.each do |user_id|
      p = self.context_message_participants.find_by_user_id_and_participation_type(user_id, 'recipient')
      p ||= self.context_message_participants.create(:user_id => user_id, :participation_type => 'recipient')
    end
  end
  
  def resend_message!
    @re_send_message = true
    self.save!
    @re_send_message = false
  end
  
  def recipient_users
    res = self.users.reload.uniq
    res -= [self.user] unless (self.recipients || []).include?(self.user_id)
    res
  end
  
  def attachments=(val)
    raise "Context expected when setting attachments for a message" unless self.context
    res = []
    (val || {}).each do |idx, data|
      if data && data != ""
        # This is a bit of funkiness because we have a callback to create a notification
        # as soon as the message is created, but the attachments can't actually be linked to
        # the message until AFTER the context_message is saved
        attachment = Attachment.new(:uploaded_data => data) rescue nil
        res << attachment if attachment
      end
    end
    @attachments_to_set = res
    res
  end
  
  def context_code
    read_attribute(:context_code) || "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  def formatted_body(truncate=nil)
    self.extend TextHelper
    res = format_message(body).first
    res = truncate_html(res, :max_length => truncate, :words => true) if truncate
    res
  end
  
  def reply_from(opts)
    user = opts[:user]
    subject = opts[:subject].strip rescue nil
    subject ||= "Re: #{self.subject.sub(/\ARe: /, "")}"
    message = opts[:text].strip
    user = nil unless user && self.context_message_participants.map(&:user_id).include?(user.id)
    if !user
      raise "Only message participants may reply to messages"
    elsif !message || message.empty?
      raise "Message body cannot be blank"
    else
      ContextMessage.create!({
        :context => self.context,
        :user => user,
        :subject => subject,
        :recipients => "#{self.user_id}",
        :root_context_message_id => self.root_context_message_id || self.id,
        :body => message
      })
    end
  end
  
  # This is a bit of funkiness because we have a callback to create a notification
  # as soon as the message is created, but the attachments can't actually be linked to
  # the message until AFTER the context_message is saved
  def all_attachments
    self.attachments + (@attachments_to_set || [])
  end
  
  def set_attachments
    (@attachments_to_set || []).each do |attachment|
      attachment.context = self
      attachment.save
      attachment.associate_with(self.context) if !attachment.new_record?
    end
  end
  
  def recipients=(val)
    unless self.context
      @pending_recipients = val
      return
    end

    if val.is_a?(String)
      val = val.split(',').map{|u| u.to_i }
    end
    val ||= []
    users = self.context.users.to_a
    val = val.map{|user| user.is_a?(User) ? user : users.find{|u| u.id == user} }.compact
    val = users.select{|u| val.include?(u) }.map{|u| u.id }
    write_attribute(:recipients, val.uniq)
  end

  # @pending_recipients is necessary because self.context may not have been set
  # yet, when recipients and context are both passed in the same attributes
  # hash.
  before_save :set_pending_recipients

  def set_pending_recipients
    if self.context
      # this will silently ignore the recipients= call if self.context never
      # gets set before the record is saved... that's kind of gross, but
      # recipients= doesn't work at all without self.context set.
      self.recipients = @pending_recipients if @pending_recipients
      @pending_recipients = nil
    end
    true
  end

  def recipients
    set_pending_recipients
    read_attribute(:recipients)
  end

  def user_name
    self.user ? self.user.name : t('unknown_user', "Unknown User")
  end
  
  named_scope :after, lambda{|date|
    {:conditions => ['context_messages.created_at > ?', date] }
  }
  named_scope :for_context, lambda{|context|
    {:conditions => ['context_messages.context_id = ? AND context_messages.context_type = ?', context.id, context.class.to_s] }
  }
  named_scope :from_user, lambda{|user|
    {:conditions => ['context_messages.user_id = ?', user.id]}
  }
end
