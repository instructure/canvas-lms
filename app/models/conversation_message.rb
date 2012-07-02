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
  include ActionController::UrlWriter
  include SendToStream
  include SimpleTags::ReaderInstanceMethods

  belongs_to :conversation
  belongs_to :author, :class_name => 'User'
  belongs_to :context, :polymorphic => true
  has_many :conversation_message_participants
  has_many :attachment_associations, :as => :context
  has_many :attachments, :through => :attachment_associations, :order => 'attachments.created_at, attachments.id'
  belongs_to :asset, :polymorphic => true, :types => :submission # TODO: move media comments into this
  delegate :participants, :to => :conversation
  delegate :subscribed_participants, :to => :conversation
  attr_accessible

  named_scope :human, :conditions => "NOT generated"
  named_scope :with_attachments, :conditions => "attachment_ids <> '' OR has_attachments" # TODO: simplify post-migration
  named_scope :with_media_comments, :conditions => "media_comment_id IS NOT NULL OR has_media_objects" # TODO: simplify post-migration
  named_scope :by_user, lambda { |user_or_id|
    user_or_id = user_or_id.id if user_or_id.is_a?(User)
    {:conditions => {:author_id => user_or_id}}
  }
  def self.preload_latest(conversation_participants, author_id=nil)
    return unless conversation_participants.present?
    base_conditions = sanitize_sql([
      "conversation_id IN (?) AND conversation_participant_id in (?) AND NOT generated",
      conversation_participants.map(&:conversation_id),
      conversation_participants.map(&:id)
    ])
    base_conditions << sanitize_sql([" AND author_id = ?", author_id]) if author_id

    # limit it for non-postgres so we can reduce the amount of extra data we
    # crunch in ruby (generally none, unless a conversation has multiple
    # most-recent messages, i.e. same created_at)
    unless connection.adapter_name == 'PostgreSQL'
      base_conditions << <<-SQL
        AND conversation_messages.created_at = (
          SELECT MAX(created_at)
          FROM conversation_messages cm2
          JOIN conversation_message_participants cmp2 ON cm2.id = conversation_message_id
          WHERE cm2.conversation_id = conversation_messages.conversation_id
            AND #{base_conditions}
        )
      SQL
    end

    ret = distinct_on('conversation_participant_id',
      :select => "conversation_messages.*, conversation_participant_id, conversation_message_participants.tags",
      :joins => 'JOIN conversation_message_participants ON conversation_messages.id = conversation_message_id',
      :conditions => base_conditions,
      :order => 'conversation_participant_id, created_at DESC'
    )
    map = Hash[ret.map{ |m| [m.conversation_participant_id.to_i, m]}]
    if author_id
      conversation_participants.each{ |cp| cp.last_authored_message = map[cp.id] }
    else
      conversation_participants.each{ |cp| cp.last_message = map[cp.id] }
    end
  end

  validates_length_of :body, :maximum => maximum_text_length

  has_a_broadcast_policy
  set_broadcast_policy do |p|
    p.dispatch :conversation_message
    p.to { self.recipients }
    p.whenever {|record| (record.just_created || @re_send_message) && !record.generated && !record.submission}

    p.dispatch :added_to_conversation
    p.to { self.new_recipients }
    p.whenever {|record| (record.just_created || @re_send_message) && record.generated && record.event_data[:event_type] == :users_added}
  end

  on_create_send_to_streams do
    self.recipients unless submission # we still render them w/ the conversation in the stream item, we just don't cause it to jump to the top
  end

  before_save :infer_values
  before_destroy :delete_from_participants

  def infer_values
    self.media_comment_id = nil if self.media_comment_id && self.media_comment_id.strip.empty?
    if self.media_comment_id && self.media_comment_id_changed?
      @media_comment = MediaObject.by_media_id(self.media_comment_id).first
      self.media_comment_id = nil unless @media_comment
      self.media_comment_type = @media_comment.media_type if @media_comment
    end
    self.media_comment_type = nil unless self.media_comment_id
    self.has_attachments = attachment_ids.present? || forwarded_messages.any?(&:has_attachments?)
    self.has_media_objects = media_comment_id.present? || forwarded_messages.any?(&:has_media_objects?)
    true
  end

  # override AR association magic 
  def attachment_ids
    read_attribute :attachment_ids
  end

  def attachment_ids=(ids)
    self.attachments = author.conversation_attachments_folder.attachments.find_all_by_id(ids.map(&:to_i))
    write_attribute(:attachment_ids, attachments.map(&:id).join(','))
  end

  def delete_from_participants
    conversation.conversation_participants.each do |p|
      p.remove_messages(self) # ensures cached stuff gets updated, etc.
    end
  end

  # TODO: remove once data has been migrated
  def has_attachments?
    ret = read_attribute(:has_attachments)
    return ret unless ret.nil?
    attachment_ids.present? || forwarded_messages.any?(&:has_attachments?)
  end

  # TODO: remove once data has been migrated
  def has_media_objects?
    ret = read_attribute(:has_media_objects)
    return ret unless ret.nil?
    media_comment_id.present? || forwarded_messages.any?(&:has_media_objects?)
  end

  def media_comment
    if !@media_comment && self.media_comment_id
      @media_comment = MediaObject.by_media_id(self.media_comment_id).first
    end
    @media_comment
  end

  def media_comment=(media_comment)
    self.media_comment_id = media_comment.media_id
    self.media_comment_type = media_comment.media_type
    @media_comment = media_comment
  end

  def recipients
    self.subscribed_participants.reject{ |u| u.id == self.author_id }
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
      user_names = User.find_all_by_id(event_data[:user_ids], :order => "id").map(&:short_name)
      EventFormatter.users_added(author.short_name, user_names)
    end
  end

  def generate_user_note
    return unless recipients.size == 1
    recipient = recipients.first
    return unless recipient.grants_right?(author, :create_user_notes) && recipient.associated_accounts.any?{|a| a.enable_user_notes }

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

  def root_account_id
    context_id if context_type == 'Account'
  end

  def reply_from(opts)
    conversation.reply_from(opts.merge(:root_account_id => self.root_account_id))
  end

  def forwarded_messages
    @forwarded_messages ||= forwarded_message_ids && self.class.send(:with_exclusive_scope){ self.class.find_all_by_id(forwarded_message_ids.split(','), :order => 'created_at DESC')} || []
  end

  def all_forwarded_messages
    forwarded_messages.inject([]) { |result, message|
      result << message
      result.concat(message.all_forwarded_messages)
    }
  end

  def forwardable?
    submission.nil?
  end

  def as_json(options = {})
    super(:only => [:id, :created_at, :body, :generated, :author_id])['conversation_message'].merge({
      'forwarded_messages' => forwarded_messages,
      'attachments' => attachments,
      'media_comment' => media_comment
    })
  end

  def to_atom(opts={})
    extend ApplicationHelper
    extend ConversationsHelper

    title = ERB::Util.h(truncate_text(self.body, :max_words => 8, :max_length => 80))

    # build content, should be:
    # message body
    # [list of attachments]
    # -----
    # context
    content = "<div>#{ERB::Util.h(self.body)}</div>"
    if !self.attachments.empty?
      content += "<ul>"
      self.attachments.each do |attachment|
        href = file_download_url(attachment, :verifier => attachment.uuid,
                                             :download => '1',
                                             :download_frd => '1',
                                             :host => HostUrl.context_host(self.context))
        content += "<li><a href='#{href}'>#{ERB::Util.h(attachment.display_name)}</a></li>"
      end
      content += "</ul>"
    end

    content += opts[:additional_content] if opts[:additional_content]

    Atom::Entry.new do |entry|
      entry.title     = title
      entry.authors  << Atom::Person.new(:name => self.author.name)
      entry.updated   = self.created_at.utc
      entry.published = self.created_at.utc
      entry.id        = "tag:#{HostUrl.context_host(self.context)},#{self.created_at.strftime("%Y-%m-%d")}:/conversations/#{self.feed_code}"
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                       :href => "http://#{HostUrl.context_host(self.context)}/conversations/#{self.conversation.id}")
      self.attachments.each do |attachment|
        entry.links  << Atom::Link.new(:rel => 'enclosure',
                                       :href => file_download_url(attachment, :verifier => attachment.uuid,
                                                                              :download => '1',
                                                                              :download_frd => '1',
                                                                              :host => HostUrl.context_host(self.context)))
      end
      entry.content   = Atom::Content::Html.new(content)
    end
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

