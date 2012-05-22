#
# Copyright (C) 2012 Instructure, Inc.
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
  include TextHelper

  attr_accessible :plaintext_message, :message, :discussion_topic, :user, :parent, :attachment, :parent_entry
  attr_readonly :discussion_topic_id, :user_id, :parent_id
  has_many :discussion_subentries, :class_name => 'DiscussionEntry', :foreign_key => "parent_id", :order => :created_at
  has_many :unordered_discussion_subentries, :class_name => 'DiscussionEntry', :foreign_key => "parent_id"
  has_many :flattened_discussion_subentries, :class_name => 'DiscussionEntry', :foreign_key => "root_entry_id"
  has_many :discussion_entry_participants
  belongs_to :discussion_topic, :touch => true
  # null if a root entry
  belongs_to :parent_entry, :class_name => 'DiscussionEntry', :foreign_key => :parent_id
  # also null if a root entry
  belongs_to :root_entry, :class_name => 'DiscussionEntry', :foreign_key => :root_entry_id
  belongs_to :user
  belongs_to :attachment
  belongs_to :editor, :class_name => 'User'
  has_one :external_feed_entry, :as => :asset

  before_create :infer_root_entry_id
  after_save :update_discussion
  after_save :context_module_action_later
  after_create :create_participants
  validates_length_of :message, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_presence_of :discussion_topic_id
  before_validation_on_create :set_depth
  validate_on_create :validate_depth

  sanitize_field :message, Instructure::SanitizeField::SANITIZE

  has_a_broadcast_policy
  attr_accessor :new_record_header

  workflow do
    state :active
    state :deleted
  end

  on_create_send_to_inboxes do
    if self.context && self.context.respond_to?(:available?) && self.context.available?
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
    p.to { posters - [user] }
    p.whenever { |record|
      record.just_created && record.active?
    }
  end

  on_create_send_to_streams do
    if self.root_entry_id.nil?
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

  # The maximum discussion entry threading depth that is allowed
  def self.max_depth
    Setting.get_cached('discussion_entry_max_depth', '50').to_i
  end

  def set_depth
    self.depth ||= (self.parent_entry.try(:depth) || 0) + 1
  end

  def validate_depth
    if !self.depth || self.depth > self.class.max_depth
      errors.add_to_base("Maximum entry depth reached")
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
      entry.parent_entry = self
      entry.user = user
      entry.save!
      entry
    end
  end

  def posters
    self.discussion_topic.posters rescue [self.user]
  end

  def plaintext_message=(val)
    self.message = format_message(val).first
  end

  def truncated_message(length=nil)
    plaintext_message(length)
  end

  def summary(length=150)
    strip_and_truncate(message, :max_length => length)
  end

  def plaintext_message(length=250)
    truncate_html(self.message, :max_length => length)
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now
    save!
    update_topic_submission
  end

  def update_discussion
    if %w(workflow_state message attachment_id editor_id).any? { |a| self.changed.include?(a) }
      self.discussion_topic.touch
      connection.after_transaction_commit { self.discussion_topic.update_materialized_view }
    end
  end

  def update_topic_submission
    if self.discussion_topic.for_assignment?
      entries = self.discussion_topic.discussion_entries.scoped(:conditions => {:user_id => self.user_id, :workflow_state => 'active'})
      submission = self.discussion_topic.assignment.submissions.scoped(:conditions => {:user_id => self.user_id}).first
      if entries.any?
        submission_date = entries.scoped(:order => 'created_at').first.created_at
        if submission_date > self.created_at
          submission.submitted_at = submission_date
          submission.save!
        end
      else
        submission.workflow_state = 'unsubmitted'
        submission.submission_type = nil
        submission.submitted_at = nil
        submission.save!
      end
    end
  end

  named_scope :active, :conditions => ['discussion_entries.workflow_state != ?', 'deleted']
  named_scope :deleted, :conditions => ['discussion_entries.workflow_state = ?', 'deleted']

  def user_name
    self.user.name rescue t :default_user_name, "User Name"
  end

  def infer_root_entry_id
    # don't allow parent ids for flat discussions
    self.parent_entry = nil if self.discussion_topic.discussion_type == DiscussionTopic::DiscussionTypes::FLAT
    
    # only allow non-root parents for threaded discussions
    unless self.discussion_topic.try(:threaded?)
      self.parent_entry = parent_entry.try(:root_entry) || parent_entry
    end
    self.root_entry_id = parent_entry.try(:root_entry_id) || parent_entry.try(:id)
  end
  protected :infer_root_entry_id

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

    given { |user| self.user && self.user == user && !self.discussion_topic.locked? }
    can :delete

    given { |user, session| self.cached_context_grants_right?(user, session, :read_forum) }
    can :read

    given { |user, session| self.cached_context_grants_right?(user, session, :post_to_forum) && !self.discussion_topic.locked? }
    can :reply and can :create and can :read

    given { |user, session| self.cached_context_grants_right?(user, session, :post_to_forum) }
    can :read

    given { |user, session| self.discussion_topic.context.respond_to?(:allow_student_forum_attachments) && self.discussion_topic.context.allow_student_forum_attachments && self.cached_context_grants_right?(user, session, :post_to_forum) && !self.discussion_topic.locked?  }
    can :attach

    given { |user, session| !self.discussion_topic.root_topic_id && self.cached_context_grants_right?(user, session, :moderate_forum) && !self.discussion_topic.locked? }
    can :update and can :delete and can :reply and can :create and can :read and can :attach

    given { |user, session| !self.discussion_topic.root_topic_id && self.cached_context_grants_right?(user, session, :moderate_forum) }
    can :update and can :delete and can :read

    given { |user, session| self.discussion_topic.root_topic && self.discussion_topic.root_topic.cached_context_grants_right?(user, session, :moderate_forum) && !self.discussion_topic.locked? }
    can :update and can :delete and can :reply and can :create and can :read and can :attach

    given { |user, session| self.discussion_topic.root_topic && self.discussion_topic.root_topic.cached_context_grants_right?(user, session, :moderate_forum) }
    can :update and can :delete and can :read

    given { |user, session| self.discussion_topic.context.respond_to?(:collection) && self.discussion_topic.context.collection.grants_right?(user, session, :read) }
    can :read

    given { |user, session| self.discussion_topic.context.respond_to?(:collection) && self.discussion_topic.context.collection.grants_right?(user, session, :comment) }
    can :create
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
    {:conditions => ['discussion_entries.root_entry_id IS NULL AND discussion_entries.discussion_topic_id IN (?)', topic_ids]}
  }
  named_scope :all_for_topics, lambda { |topics|
    topic_ids = topics.map{ |t| t.is_a?(DiscussionTopic) ? t.id : t }
    {:conditions => ['discussion_entries.discussion_topic_id IN (?)', topic_ids]}
  }
  named_scope :newest_first, :order => 'discussion_entries.created_at DESC'

  def to_atom(opts={})
    author_name = self.user.present? ? self.user.name : t('atom_no_author', "No Author")
    Atom::Entry.new do |entry|
      subject = [self.discussion_topic.title]
      subject << self.discussion_topic.context.name if opts[:include_context]
      if parent_id
        entry.title = t "#subject_reply_to", "Re: %{subject}", :subject => subject.to_sentence
      else
        entry.title = subject.to_sentence
      end
      entry.authors  << Atom::Person.new(:name => author_name)
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
    dup.parent_id = context.merge_mapped_id("discussion_entry_#{self.parent_id}")
    dup.attachment_id = context.merge_mapped_id(self.attachment)
    if !dup.attachment_id && self.attachment
      attachment = self.attachment.clone_for(context)
      attachment.folder_id = nil
      attachment.save!
      context.map_merge(self.attachment, attachment)
      context.warn_merge_result(t :file_added_warning, "Added file \"%{file_path}\" which is needed for an entry in the topic \"%{discussion_topic_title}\"", :file_path => "%{attachment.folder.full_name}/#{attachment.display_name}", :discussion_topic_title => self.discussion_topic.title)
      dup.attachment_id = attachment.id
    end
    dup.message = context.migrate_content_links(self.message, self.context) if options[:migrate]
    dup
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
    self.send_later_if_production(:context_module_action)
  end
  protected :context_module_action_later

  def context_module_action
    if self.discussion_topic && self.user
      self.discussion_topic.context_module_action(user, :contributed)
    end
  end

  def create_participants
    transaction do
      dtp_conditions = sanitize_sql(["discussion_topic_id = ?", self.discussion_topic_id])
      dtp_conditions = sanitize_sql(["discussion_topic_id = ? AND user_id <> ?", self.discussion_topic_id, self.user_id]) if self.user
      DiscussionTopicParticipant.update_all("unread_entry_count = unread_entry_count + 1", dtp_conditions)

      if self.user
        my_entry_participant = self.discussion_entry_participants.create(:user => self.user, :workflow_state => "read")

        topic_participant = self.discussion_topic.discussion_topic_participants.find_by_user_id(self.user.id)
        if topic_participant.blank?
          new_count = self.discussion_topic.unread_count(self.user) - 1
          topic_participant = self.discussion_topic.discussion_topic_participants.create(:user => self.user,
                                                                                         :unread_entry_count => new_count,
                                                                                         :workflow_state => "unread")
        end
      end
    end
  end

  attr_accessor :current_user
  def read_state(current_user = nil)
    current_user ||= self.current_user
    return "read" unless current_user # default for logged out users
    uid = current_user.is_a?(User) ? current_user.id : current_user
    discussion_entry_participants.find_by_user_id(uid).try(:workflow_state) || "unread"
  end

  def read?(current_user = nil)
    read_state(current_user) == "read"
  end

  def unread?(current_user = nil)
    !read?(current_user)
  end

  def change_read_state(new_state, current_user = nil)
    current_user ||= self.current_user
    return nil unless current_user

    if new_state != self.read_state(current_user)
      entry_participant = self.update_or_create_participant(:current_user => current_user, :new_state => new_state)
      if entry_participant.present? && entry_participant.valid?
        self.discussion_topic.update_or_create_participant(:current_user => current_user, :offset => (new_state == "unread" ? 1 : -1))
      end
      entry_participant
    else
      true
    end
  end

  def update_or_create_participant(opts={})
    current_user = opts[:current_user] || self.current_user
    return nil unless current_user

    entry_participant = nil
    DiscussionEntry.uncached do
      DiscussionEntry.unique_constraint_retry do
        entry_participant = self.discussion_entry_participants.find(:first, :conditions => ['user_id = ?', current_user.id])
        entry_participant ||= self.discussion_entry_participants.build(:user => current_user, :workflow_state => "unread")
        entry_participant.workflow_state = opts[:new_state] if opts[:new_state]
        entry_participant.save
      end
    end
    entry_participant
  end
end
