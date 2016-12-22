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

require 'atom'

class ConversationMessage < ActiveRecord::Base
  include HtmlTextHelper

  include Rails.application.routes.url_helpers
  include SendToStream
  include SimpleTags::ReaderInstanceMethods

  belongs_to :conversation
  belongs_to :author, :class_name => 'User'
  belongs_to :context, polymorphic: [:account]
  has_many :conversation_message_participants
  has_many :attachment_associations, :as => :context, :inverse_of => :context
  # we used to attach submission comments to conversations via this asset
  # TODO: remove this column when we're sure we don't want this relation anymore
  belongs_to :asset, polymorphic: [:submission]
  delegate :participants, :to => :conversation
  delegate :subscribed_participants, :to => :conversation

  after_create :generate_user_note!
  after_save :update_attachment_associations

  scope :human, -> { where("NOT generated") }
  scope :with_attachments, -> { where("attachment_ids<>'' OR has_attachments") } # TODO: simplify post-migration
  scope :with_media_comments, -> { where("media_comment_id IS NOT NULL OR has_media_objects") } # TODO: simplify post-migration
  scope :by_user, lambda { |user_or_id| where(:author_id => user_or_id) }

  def self.preload_latest(conversation_participants, author=nil)
    return unless conversation_participants.present?

    Shard.partition_by_shard(conversation_participants, lambda { |cp| cp.conversation_id }) do |shard_participants|
      base_conditions = "(#{shard_participants.map { |cp|
          "(conversation_id=#{cp.conversation_id} AND user_id=#{cp.user_id})" }.join(" OR ")
        }) AND NOT generated
        AND (conversation_message_participants.workflow_state <> 'deleted' OR conversation_message_participants.workflow_state IS NULL)"
      base_conditions << sanitize_sql([" AND author_id = ?", author.id]) if author

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

      Shackles.activate(:slave) do
        ret = where(base_conditions).
          joins("JOIN #{ConversationMessageParticipant.quoted_table_name} ON conversation_messages.id = conversation_message_id").
          select("conversation_messages.*, conversation_participant_id, conversation_message_participants.user_id, conversation_message_participants.tags").
          order('conversation_id DESC, user_id DESC, created_at DESC').
          distinct_on(:conversation_id, :user_id).to_a
        map = Hash[ret.map{ |m| [[m.conversation_id, m.user_id], m]}]
        backmap = Hash[ret.map{ |m| [m.conversation_participant_id, m]}]
        if author
          shard_participants.each{ |cp| cp.last_authored_message = map[[cp.conversation_id, cp.user_id]] || backmap[cp.id] }
        else
          shard_participants.each{ |cp| cp.last_message = map[[cp.conversation_id, cp.user_id]] || backmap[cp.id] }
        end
      end
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

    p.dispatch :conversation_created
    p.to { [self.author] }
    p.whenever {|record| record.cc_author && ((record.just_created || @re_send_message) && !record.generated && !record.submission)}
  end

  on_create_send_to_streams do
    self.recipients unless skip_broadcasts || submission # we still render them w/ the conversation in the stream item, we just don't cause it to jump to the top
  end

  def after_participants_created_broadcast
    conversation_message_participants(true) # reload this association so we get latest data
    skip_broadcasts = false
    @re_send_message = true
    set_broadcast_flags
    broadcast_notifications
    queue_create_stream_items
    generate_user_note!
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
    (read_attribute(:attachment_ids) || "").split(',').map(&:to_i)
  end

  def attachment_ids=(ids)
    ids = author.conversation_attachments_folder.attachments.where(id: ids.map(&:to_i)).pluck(:id) unless ids.empty?
    write_attribute(:attachment_ids, ids.join(','))
  end

  def attachments
    self.attachment_associations.map(&:attachment)
  end

  def update_attachment_associations
    previous_attachment_ids = self.attachment_associations.pluck(:attachment_id)
    deleted_attachment_ids = previous_attachment_ids - attachment_ids
    new_attachment_ids = attachment_ids - previous_attachment_ids
    self.attachment_associations.where(attachment_id: deleted_attachment_ids).find_each do |association|
      association.destroy
    end
    if new_attachment_ids.any?
      author.conversation_attachments_folder.attachments.where(id: new_attachment_ids).find_each do |attachment|
        self.attachment_associations.create!(attachment: attachment)
      end
    end
  end

  def delete_from_participants
    conversation.conversation_participants.each do |p|
      p.delete_messages(self) # ensures cached stuff gets updated, etc.
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
    return [] unless conversation
    subscribed = subscribed_participants.reject{ |u| u.id == self.author_id }.map{|x| x.becomes(User)}
    ActiveRecord::Associations::Preloader.new.preload(conversation_message_participants, :user)
    participants = conversation_message_participants.map(&:user)
    subscribed & participants
  end

  def new_recipients
    return [] unless conversation
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
      user_names = User.where(id: event_data[:user_ids]).order(:id).pluck(:name, :short_name).map{|name, short_name| short_name || name}
      EventFormatter.users_added(author.short_name, user_names)
    end
  end

  attr_accessor :generate_user_note
  def generate_user_note!
    return if skip_broadcasts
    return unless @generate_user_note
    valid_recipients = recipients.select{|recipient| recipient.grants_right?(author, :create_user_notes) && recipient.associated_accounts.any?{|a| a.enable_user_notes }}
    return unless valid_recipients.any?

    valid_recipients = User.where(:id => valid_recipients) # need to reload to get all the attributes needed for User#save
    valid_recipients.each do |recipient|
      title = if conversation.subject
        t(:subject_specified, "Private message: %{subject}", subject: conversation.subject)
      else
        t(:subject, "Private message")
      end
      note = format_message(body).first
      recipient.user_notes.create(:creator => author, :title => title, :note => note)
    end
  end


  attr_accessor :cc_author

  def author_short_name_with_shared_contexts(recipient)
    if conversation.context
      context_names = [conversation.context.name]
    else
      shared_tags = author.conversation_context_codes(false)
      shared_tags &= recipient.conversation_context_codes(false)
      shared_tags &= conversation.tags if conversation.tags.any?

      context_components = shared_tags.map{|t| ActiveRecord::Base.parse_asset_string(t)}
      context_names = Context.names_by_context_types_and_ids(context_components[0,2]).values
    end
    if context_names.empty?
      author.short_name
    else
      "#{author.short_name} (#{context_names.to_sentence})"
    end
  end

  def formatted_body(truncate=nil)
    res = format_message(body).first
    res = truncate_html(res, :max_length => truncate, :words => true) if truncate
    res
  end

  def root_account_id
    context_id if context_type == 'Account'
  end

  def reply_from(opts)
    raise IncomingMail::Errors::UnknownAddress if self.context.try(:root_account).try(:deleted?)
    # It would be nice to have group conversations via e-mail, but if so, we need to make it much more obvious
    # that replies to the e-mail will be sent to multiple recipients.
    recipients = [author]
    conversation.reply_from(opts.merge(:root_account_id => self.root_account_id, :only_users => recipients))
  end

  def forwarded_messages
    @forwarded_messages ||= forwarded_message_ids && self.class.unscoped { self.class.where(id: forwarded_message_ids.split(',')).order('created_at DESC').to_a} || []
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

    title = ERB::Util.h(CanvasTextHelper.truncate_text(self.body, :max_words => 8, :max_length => 80))

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
