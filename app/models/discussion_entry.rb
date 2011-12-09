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

class DiscussionEntry < ActiveRecord::Base
  include Workflow
  include SendToInbox
  include SendToStream
  
  attr_accessible :plaintext_message, :message, :discussion_topic, :user, :parent, :attachment, :parent_entry
  attr_readonly :discussion_topic_id, :user_id, :parent_id
  has_many :discussion_subentries, :class_name => 'DiscussionEntry', :foreign_key => "parent_id", :order => :created_at
  has_many :unordered_discussion_subentries, :class_name => 'DiscussionEntry', :foreign_key => "parent_id"
  belongs_to :discussion_topic
  belongs_to :parent_entry, :class_name => 'DiscussionEntry', :foreign_key => :parent_id
  belongs_to :user
  belongs_to :attachment
  belongs_to :editor, :class_name => 'User'
  has_one :external_feed_entry, :as => :asset
  
  before_create :infer_parent_id
  before_save :infer_defaults
  after_save :touch_parent
  after_save :context_module_action_later
  validates_length_of :message, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_presence_of :discussion_topic_id
  
  sanitize_field :message, Instructure::SanitizeField::SANITIZE
  
  has_a_broadcast_policy
  attr_accessor :new_record_header
  
  workflow do
    state :active
    state :deleted
  end
  
  def infer_defaults
    @message_changed = self.message_changed?
    true
  end
  
  on_create_send_to_inboxes do
    if self.context && self.context.available?
      user_id = nil
      if self.parent_entry
        user_id = self.parent_entry.user_id
      else
        user_id = self.discussion_topic.user_id unless self.discussion_topic.assignment_id
      end
      if user_id && user_id != self.user_id
        {
          :recipients => user_id,
          :subject => t("#subject_reply_to", "Re: %{subject}", :subject => self.discussion_topic.title),
          :html_body => self.message,
          :sender => self.user_id
        }
      end
    end
  end
  
  set_broadcast_policy do |p|
    p.dispatch :new_discussion_entry
    p.to { subscribed_posters - [user] }
    p.whenever { |record| 
      record.just_created && record.active?
    }
  end
  
  on_create_send_to_streams do
    if self.parent_id == 0
      recent_entries = DiscussionEntry.active.find(:all, :select => 'user_id', :conditions => ['discussion_entries.discussion_topic_id=? AND discussion_entries.created_at > ?', self.discussion_topic_id, 2.weeks.ago])
      # If the topic has been going for more than two weeks and it suddenly
      # got "popular" again, move it back up in user streams
      if !self.discussion_topic.for_assignment? && self.created_at && self.created_at > self.discussion_topic.created_at + 2.weeks && recent_entries.select{|e| e.created_at && e.created_at > 24.hours.ago }.length > 10
        self.discussion_topic.active_participants
      # If the topic has beeng going for more than two weeks, only show
      # people who have been participating in the topic
      elsif self.created_at > self.discussion_topic.created_at + 2.weeks
        recent_entries.map(&:user_id).uniq
      else
        self.discussion_topic.active_participants
      end
    else
      []
    end
  end
  
  on_update_send_to_streams do
    if @message_changed
      []
    end
  end
  
  def touch_parent
    if self.parent_id && self.parent_id != 0
      self.discussion_topic.discussion_entries.find_by_id(self.parent_id).touch rescue nil
    else
      self.discussion_topic.touch
    end
  end
  
  def reply_from(opts)
    user = opts[:user]
    message = opts[:html].strip
    user = nil unless user && self.context.users.include?(user)
    if !user
      raise "Only context participants may reply to messages"
    elsif !message || message.empty?
      raise "Message body cannot be blank"
    else
      entry = DiscussionEntry.new(:message => message)
      entry.discussion_topic_id = self.discussion_topic_id
      entry.parent_id = self.parent_id == 0 ? self.id : self.parent_id
      entry.user_id = user.id
      entry.save!
      entry
    end
  end
  
  def subscribed_posters
    []
  end
  
  def posters
    self.discussion_topic.posters rescue [self.user]
  end
  

  def plaintext_message=(val)
    self.extend TextHelper
    self.message = format_message(val).first
  end
  
  def truncated_message(length=nil)
    plaintext_message(length)
  end
  
  def plaintext_message(length=250)
    self.extend TextHelper
    truncate_html(self.message, :max_length => length)
  end
  
  alias_method :destroy!, :destroy
  def destroy
    discussion_subentries.each &:destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now
    save!
  end
  
  named_scope :active, :conditions => ['discussion_entries.workflow_state != ?', 'deleted']
  
  def user_name
    self.user.name rescue t :default_user_name, "User Name"
  end
  
  def infer_parent_id
    parent = self.discussion_topic.discussion_entries.active.find_by_id(self.parent_id) if self.parent_id
    if parent && parent.parent_id == 0
      self.parent_id = parent.id
    elsif parent && parent.parent_id != 0
      self.parent_id = parent.parent_id
    else
      self.parent_id = 0
    end
  end
  protected :infer_parent_id
  
  def update_topic
    if self.discussion_topic
      last_reply_at = [self.discussion_topic.last_reply_at, self.created_at].max
      DiscussionTopic.update_all({:last_reply_at => last_reply_at, :updated_at => Time.now.utc}, {:id => self.discussion_topic_id})
    end
  end
  
  set_policy do
    given { |user| self.user && self.user == user && !self.discussion_topic.locked? }
    can :update and can :reply and can :read

    given { |user| self.user && self.user == user }
    can :read

    given { |user| self.user && self.user == user and self.discussion_subentries.empty? && !self.discussion_topic.locked? }
    can :delete
    
    given { |user, session| self.cached_context_grants_right?(user, session, :read) }#
    can :read
    
    given { |user, session| self.cached_context_grants_right?(user, session, :post_to_forum) && !self.discussion_topic.locked? }# students.find_by_id(user) }
    can :reply and can :create and can :read

    given { |user, session| self.cached_context_grants_right?(user, session, :post_to_forum) }# students.find_by_id(user) }
    can :read

    given { |user, session| self.discussion_topic.context.respond_to?(:allow_student_forum_attachments) && self.discussion_topic.context.allow_student_forum_attachments && self.cached_context_grants_right?(user, session, :post_to_forum) && !self.discussion_topic.locked?  }# students.find_by_id(user) }
    can :attach
    
    given { |user, session| !self.discussion_topic.root_topic_id && self.cached_context_grants_right?(user, session, :moderate_forum) && !self.discussion_topic.locked? }#admins.find_by_id(user) }
    can :update and can :delete and can :reply and can :create and can :read and can :attach

    given { |user, session| !self.discussion_topic.root_topic_id && self.cached_context_grants_right?(user, session, :moderate_forum) }#admins.find_by_id(user) }
    can :update and can :delete and can :read

    given { |user, session| self.discussion_topic.root_topic && self.discussion_topic.root_topic.cached_context_grants_right?(user, session, :moderate_forum) && !self.discussion_topic.locked? }#admins.find_by_id(user) }
    can :update and can :delete and can :reply and can :create and can :read and can :attach

    given { |user, session| self.discussion_topic.root_topic && self.discussion_topic.root_topic.cached_context_grants_right?(user, session, :moderate_forum) }#admins.find_by_id(user) }
    can :update and can :delete and can :read
  end
  
  named_scope :for_user, lambda{|user|
    {:conditions => ['discussion_entries.user_id = ?', (user.is_a?(User) ? user.id : user)], :order => 'discussion_entries.created_at'}
  }
  named_scope :for_users, lambda{|users|
    user_ids = users.map{ |u| u.is_a?(User) ? u.id : u }
    {:conditions => ['discussion_entries.user_id IN (?)', user_ids]}
  }
  named_scope :after, lambda{|date|
    {:conditions => ['created_at > ?', date] }
  }
  named_scope :include_subentries, lambda{
    {:include => discussion_subentries}
  }
  named_scope :top_level_for_topics, lambda {|topics|
    topic_ids = topics.map{ |t| t.is_a?(DiscussionTopic) ? t.id : t }
    {:conditions => ['discussion_entries.parent_id = ? AND discussion_entries.discussion_topic_id IN (?)', 0, topic_ids]}
  }
  named_scope :newest_first, :order => 'discussion_entries.created_at DESC'

  def to_atom(opts={})
    Atom::Entry.new do |entry|
      subject = [self.discussion_topic.title]
      subject << self.discussion_topic.context.name if opts[:include_context]
      if parent_id != 0
        entry.title = t "#subject_reply_to", "Re: %{subject}", :subject => subject.to_sentence
      else
        entry.title = subject.to_sentence
      end
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/discussion_entries/#{self.feed_code}"
      entry.links    << Atom::Link.new(:rel => 'alternate', 
                                    :href => "http://#{HostUrl.context_host(self.discussion_topic.context)}/#{self.discussion_topic.context_prefix}/discussion_topics/#{self.discussion_topic_id}")
      entry.content   = Atom::Content::Html.new(self.message)
    end
  end
  
  def clone_for(context, dup=nil, options={})
    options[:migrate] = true if options[:migrate] == nil
    dup ||= DiscussionEntry.new
    self.attributes.delete_if{|k,v| [:id, :discussion_topic_id, :attachment_id].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.parent_id = context.merge_mapped_id("discussion_entry_#{self.parent_id}") || 0
    dup.attachment_id = context.merge_mapped_id(self.attachment)
    if !dup.attachment_id && self.attachment
      attachment = self.attachment.clone_for(context)
      attachment.folder_id = nil
      attachment.save_without_broadcasting!
      context.map_merge(self.attachment, attachment)
      context.warn_merge_result(t :file_added_warning, "Added file \"%{file_path}\" which is needed for an entry in the topic \"%{discussion_topic_title}\"", :file_path => "%{attachment.folder.full_name}/#{attachment.display_name}", :discussion_topic_title => self.discussion_topic.title)
      dup.attachment_id = attachment.id
    end
    dup.message = context.migrate_content_links(self.message, self.context) if options[:migrate]
    dup
  end

  def self.import_from_migration(hash, context, item, parent, topic)
    hash = hash.with_indifferent_access
    hash[:migration_id] ||= hash[:post_id]
    topic ||= parent.is_a?(DiscussionTopic) ? parent : parent.discussion_topic
    created = Time.at(hash[:date] / 1000).to_s(:db) rescue Time.now.to_s(:db)
    hash[:body] = ImportedHtmlConverter.convert_text(hash[:body], context)
    hash[:body] += "<br/><br/>-#{hash[:author]}" if hash[:author]
    hash[:body] = self.connection.quote hash[:body]
    Sanitize.clean(hash[:body], Instructure::SanitizeField::SANITIZE)
    query = "INSERT INTO discussion_entries (message, discussion_topic_id, parent_id, created_at, updated_at, migration_id)"
    query += " VALUES (#{hash[:body]},#{topic.id},#{parent.id},'#{created}','#{Time.now.to_s(:db)}','#{hash[:migration_id]}')"
    self.connection.execute(query)

    hash[:replies].each do |reply|
      DiscussionEntry.import_from_migration(reply, context, nil, parent, topic)
    end
    nil
  end

  def context
    self.discussion_topic.context
  end
  
  def context_id
    self.discussion_topic.context_id
  end
  
  def context_type
    self.discussion_topic.context_type
  end
  
  def title
    self.discussion_topic.title
  end
  
  def context_module_action_later
    self.send_later(:context_module_action)
  end
  protected :context_module_action_later
  
  def context_module_action
    if self.discussion_topic && self.user
      self.discussion_topic.context_module_action(user, :contributed)
    end
  end
end
