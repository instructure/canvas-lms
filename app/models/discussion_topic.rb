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

class DiscussionTopic < ActiveRecord::Base
  
  include Workflow
  include SendToStream
  include HasContentTags
  include CopyAuthorizedLinks
  
  attr_accessible :title, :message, :user, :delayed_post_at, :assignment, 
    :plaintext_message, :podcast_enabled, :podcast_has_student_posts, 
    :require_initial_post

  attr_readonly :context_id, :context_type, :user_id

  has_many :discussion_entries, :order => :created_at, :dependent => :destroy
  has_many :root_discussion_entries, :class_name => 'DiscussionEntry', :include => [:user], :conditions => ['discussion_entries.parent_id = ? AND discussion_entries.workflow_state != ?', 0, 'deleted']
  has_one :context_module_tag, :as => :content, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND workflow_state != ?', 'context_module', 'deleted'], :include => {:context_module => [:content_tags, :context_module_progressions]}
  has_one :external_feed_entry, :as => :asset
  belongs_to :external_feed
  
  belongs_to :context, :polymorphic => true
  belongs_to :cloned_item
  belongs_to :attachment
  belongs_to :assignment
  belongs_to :editor, :class_name => 'User'
  belongs_to :old_assignment, :class_name => 'Assignment'
  belongs_to :root_topic, :class_name => 'DiscussionTopic'
  has_many :child_topics, :class_name => 'DiscussionTopic', :foreign_key => :root_topic_id, :dependent => :destroy
  belongs_to :user
  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_length_of :message, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true
  
  sanitize_field :message, Instructure::SanitizeField::SANITIZE
  copy_authorized_links(:message) { [self.context, nil] }
  acts_as_list :scope => :context
  
  before_create :initialize_last_reply_at
  before_save :default_values
  before_save :set_schedule_delayed_post
  after_save :update_assignment
  after_save :update_subtopics
  after_save :touch_context
  after_save :schedule_delayed_post
  
  def default_values
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}"
    self.title ||= t '#discussion_topic.default_title', "No Title"
    @content_changed = self.message_changed? || self.title_changed?
    if self.assignment_id != self.assignment_id_was
      @old_assignment_id = self.assignment_id_was
    end
    if self.assignment_id
      self.assignment_id = nil unless (self.assignment && self.assignment.context == self.context) || (self.root_topic && self.root_topic.assignment_id == self.assignment_id)
      self.old_assignment_id = self.assignment_id if self.assignment_id
      if self.assignment && self.assignment.submission_types == 'discussion_topic' && self.assignment.has_group_category?
        self.subtopics_refreshed_at ||= Time.parse("Jan 1 2000")
      end
    end
  end
  protected :default_values
  
  def set_schedule_delayed_post
    @should_schedule_delayed_post = self.delayed_post_at_changed?
    true
  end
  
  def schedule_delayed_post
    self.send_at(self.delayed_post_at, :try_posting_delayed) if @should_schedule_delayed_post
  end
  
  def update_subtopics
    if self.assignment && self.assignment.submission_types == 'discussion_topic' && self.assignment.has_group_category?
      send_later :refresh_subtopics
    end
  end
  
  def refresh_subtopics
    category = self.assignment && self.assignment.group_category
    return unless category && self.context && self.context.respond_to?(:groups)
    category.groups.active.map do |group|
      topic = group.discussion_topics.active.find_or_initialize_by_root_topic_id(self.id)
      topic.message = self.message
      topic.title = "#{self.title} - #{group.name}"
      topic.assignment_id = self.assignment_id
      topic.user_id = self.user_id
      topic.save
      topic
    end
  end
  
  attr_accessor :saved_by
  def update_assignment
    if !self.assignment_id && @old_assignment_id && self.context_module_tag
      self.context_module_tag.confirm_valid_module_requirements
    end
    if @old_assignment_id
      Assignment.update_all({:workflow_state => 'deleted', :updated_at => Time.now.utc}, {:id => @old_assignment_id, :context_id => self.context_id, :context_type => self.context_type, :submission_types => 'discussion_topic'})
      ContentTag.delete_for(Assignment.find(@old_assignment_id)) if @old_assignment_id
    elsif self.assignment && @saved_by != :assignment
      self.assignment.title = self.title
      self.assignment.description = self.message
      self.assignment.submission_types = "discussion_topic"
      self.assignment.saved_by = :discussion_topic
      self.assignment.workflow_state = 'available' if self.assignment.deleted?
      self.assignment.save
    end

    # make sure that if the topic has a new assignment (either by going from
    # ungraded to graded, or from one assignment to another; we ignore the
    # transition from graded to ungraded) we acknowledge that the users that
    # have posted have contributed to the topic
    if self.assignment_id && self.assignment_id != @old_assignment_id
      posters.each{ |user| self.context_module_action(user, :contributed) }
    end
  end
  protected :update_assignment
  
  def restore_old_assignment
    return nil unless self.old_assignment && self.old_assignment.deleted?
    self.old_assignment.workflow_state = 'available'
    self.old_assignment.saved_by = :discussion_topic
    self.old_assignment.save(false)
    self.old_assignment
  end

  def is_announcement; false end
  
  def root_topic?
    !self.root_topic_id && self.assignment_id && self.assignment.has_group_category?
  end
  
  def discussion_subentries
    self.root_discussion_entries
  end
  
  def discussion_subentry_count
    discussion_subentries.count
  end

  def for_assignment?
    self.assignment && self.assignment.submission_types =~ /discussion_topic/
  end
  
  def for_group_assignment?
    self.for_assignment? && self.context == self.assignment.context && self.assignment.has_group_category?
  end
  
  def plaintext_message=(val)
    self.extend TextHelper
    self.message = format_message(strip_tags(val)).first
  end
  
  def plaintext_message
    self.extend TextHelper
    truncate_html(self.message, :max_length => 250)
  end

  def self.search(query)
    find(:all, :conditions => wildcard('title', 'message', query))
  end
  
  named_scope :recent, lambda{
    {:conditions => ['discussion_topics.last_reply_at > ?', 2.weeks.ago], :order => 'discussion_topics.last_reply_at DESC'}
  }
  named_scope :only_discussion_topics, lambda {
    {:conditions => ['discussion_topics.type IS NULL'] }
  }
  named_scope :for_subtopic_refreshing, lambda {
    {:conditions => ['discussion_topics.subtopics_refreshed_at IS NOT NULL AND discussion_topics.subtopics_refreshed_at < discussion_topics.updated_at'], :order => 'discussion_topics.subtopics_refreshed_at' }
  }
  named_scope :for_delayed_posting, lambda {
    {:conditions => ['discussion_topics.workflow_state = ? AND discussion_topics.delayed_post_at < ?', 'post_delayed', Time.now.utc], :order => 'discussion_topics.delayed_post_at'}
  }
  named_scope :active, :conditions => ['discussion_topics.workflow_state != ?', 'deleted']
  named_scope :for_context_codes, lambda {|codes|
    {:conditions => ['discussion_topics.context_code IN (?)', codes] }
  }
  
  named_scope :before, lambda {|date|
    {:conditions => ['discussion_topics.created_at < ?', date]}
  }
  
  def try_posting_delayed
    if self.post_delayed? && Time.now >= self.delayed_post_at
      self.delayed_post
    end
  end
  
  workflow do
    state :active do
      event :lock, :transitions_to => :locked do
        raise "cannot lock before due date" if self.assignment.try(:due_at) && self.assignment.due_at < Time.now
      end
    end
    state :post_delayed do
      event :delayed_post, :transitions_to => :active do
        @delayed_just_posted = true
        self.last_reply_at = Time.now
        self.posted_at = Time.now
      end
    end
    state :locked do
      event :unlock, :transitions_to => :active
    end
    state :deleted
  end
  
  def should_send_to_stream
    if self.delayed_post_at && self.delayed_post_at > Time.now
      false
    elsif self.cloned_item_id
      false
    elsif self.assignment && self.root_topic_id && self.assignment.has_group_category?
      false
    elsif self.assignment && self.assignment.submission_types == 'discussion_topic' && (!self.assignment.due_at || self.assignment.due_at > 1.week.from_now)
      false
    else
      true
    end
  end
  
  on_create_send_to_streams do
    if should_send_to_stream
      self.active_participants
    end
  end
  
  on_update_send_to_streams do
    if should_send_to_stream && (@delayed_just_posted || @content_changed || changed_state(:active, :post_delayed))
      self.active_participants
    end
  end
  
  def require_initial_post?
    self.require_initial_post || (self.root_topic && self.root_topic.require_initial_post)
  end
  
  def user_ids_who_have_posted_and_admins
    ids = DiscussionEntry.active.scoped(:select => "distinct user_id").find_all_by_discussion_topic_id(self.id).map(&:user_id)
    ids += self.context.admin_enrollments.scoped(:select => 'user_id').map(&:user_id) if self.context.respond_to?(:admin_enrollments)
    ids
  end
  memoize :user_ids_who_have_posted_and_admins
  
  def user_can_see_posts?(user, session=nil)
    return false unless user
    !self.require_initial_post || self.grants_right?(user, session, :update) || user_ids_who_have_posted_and_admins.member?(user.id) 
  end
  
  def reply_from(opts)
    user = opts[:user]
    message = opts[:text].strip
    self.extend TextHelper
    message = format_message(message).first
    user = nil unless user && self.context.users.include?(user)
    if !user
      raise "Only context participants may reply to messages"
    elsif !message || message.empty?
      raise "Message body cannot be blank"
    else
      DiscussionEntry.create!({
        :message => message,
        :discussion_topic => self,
        :user => user,
      })
    end
  end
  
  alias_method :destroy!, :destroy
  def destroy
    ContentTag.delete_for(self)
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now
    self.save
    if self.for_assignment?
      self.assignment.destroy unless self.assignment.deleted?
    end
  end
  
  def restore
    self.workflow_state = 'active'
    self.save
    if self.for_assignment?
      self.assignment.restore(:discussion_topic)
    end
  end
  
  def self.find_or_create_for_new_context(new_context, old_context, old_id)
    res = new_context.discussion_topics.active.find_by_cloned_item_id(old_context.discussion_topics.find_by_id(old_id).cloned_item_id || 0) rescue nil
    res = nil if res && !res.cloned_item_id
    if !res
      old = old_context.discussion_topics.active.find_by_id(old_id)
      res = old.clone_for(new_context) if old
      res.save if res
    end
    res
  end

  def unlink_from(type)
    @saved_by = type
    if self.discussion_entries.empty?
      self.assignment = nil
      self.destroy
    else
      self.assignment = nil
      self.save
    end
    self.child_topics.each{|t| t.unlink_from(:assignment) }
  end
  
  def self.per_page
    10
  end
  
  def initialize_last_reply_at
    self.posted_at ||= Time.now
    self.last_reply_at = Time.now
  end

  set_policy do
    given { |user| self.user && self.user == user && !self.locked? }
    can :update and can :reply and can :read
    
    given { |user| self.user && self.user == user }
    can :read

    given { |user| self.user && self.user == user and self.discussion_entries.active.empty? && !self.locked? && !self.root_topic_id }
    can :delete
    
    given { |user, session| (self.active? || self.locked?) && self.cached_context_grants_right?(user, session, :read) }#
    can :read
    
    given { |user, session| self.active? && self.cached_context_grants_right?(user, session, :post_to_forum) }#students.include?(user) }
    can :reply and can :read

    given { |user, session| (self.active? || self.locked?) && self.cached_context_grants_right?(user, session, :post_to_forum) }#students.include?(user) }
    can :read

    given { |user, session| self.cached_context_grants_right?(user, session, :post_to_forum) and not self.is_announcement }
    can :create
    
    given { |user, session| self.context.respond_to?(:allow_student_forum_attachments) && self.context.allow_student_forum_attachments && self.cached_context_grants_right?(user, session, :post_to_forum) }# students.find_by_id(user) }
    can :attach
    
    given { |user, session| !self.root_topic_id && self.cached_context_grants_right?(user, session, :moderate_forum) && !self.locked? }
    can :update and can :delete and can :create and can :read and can :attach

    # Moderators can still modify content even in locked topics (*especially* unlocking them), but can't create new content
    given { |user, session| !self.root_topic_id && self.cached_context_grants_right?(user, session, :moderate_forum) }
    can :update and can :delete and can :read

    given { |user, session| self.root_topic && self.root_topic.grants_right?(user, session, :update) }
    can :update
    
    given { |user, session| self.root_topic && self.root_topic.grants_right?(user, session, :delete) }
    can :delete
  end

  def discussion_topic_id
    self.id
  end
  
  def discussion_topic
    self
  end
  
  def to_atom(opts={})
    prefix = [self.is_announcement ? t('#titles.announcement', "Announcement") : t('#titles.discussion', "Discussion")]
    prefix << self.context.name if opts[:include_context]
    Atom::Entry.new do |entry|
      entry.title     = [before_label(prefix.to_sentence), self.title].join(" ")
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/discussion_topics/#{self.feed_code}"
      entry.links    << Atom::Link.new(:rel => 'alternate', 
                                    :href => "http://#{HostUrl.context_host(self.context)}/#{context_url_prefix}/discussion_topics/#{self.id}")
      entry.content   = Atom::Content::Html.new(self.message || "")
    end
  end
  
  def context_prefix
    context_url_prefix
  end
  
  def context_module_action(user, action, points=nil)
    self.context_module_tag.context_module_action(user, action, points) if self.context_module_tag
    if self.for_assignment?
      self.assignment.context_module_tag.context_module_action(user, action, points) if self.assignment.context_module_tag
      self.ensure_submission(user) if self.assignment.context.students.include?(user) && action == :contributed
    end
  end

  def ensure_submission(user)
    submission = Submission.find_by_assignment_id_and_user_id(self.assignment_id, user.id)
    return if submission && submission.submission_type == 'discussion_topic'
    self.assignment.submit_homework(user, :submission_type => 'discussion_topic')
  end

  has_a_broadcast_policy

  set_broadcast_policy do |p|
    p.dispatch :new_discussion_topic
    p.to { active_participants - [user] }
    p.whenever { |record|
      record.context.available? and
      ((record.just_created and not record.post_delayed?) || record.changed_state(:active, :post_delayed))
    }
  end
  
  def delay_posting=(val); end
  def set_assignment=(val); end
  
  def participants
    ([self.user] + context.participants).uniq.select{|u| u}
  end
  
  def active_participants
    if !self.context.available? && self.context.respond_to?(:participating_admins)
      self.context.participating_admins
    else
      self.participants
    end
  end
  
  def posters
    users = self.discussion_entries.find(:all, :include => [:user]).map(&:user)
    users << self.user
    users.uniq
  end

  def user_name
    self.user.name rescue t '#discussion_topic.default_user_name', "User Name"
  end
  
  def locked_for?(user=nil, opts={})
    @locks ||= {}
    return false if opts[:check_policies] && self.grants_right?(user, nil, :update)
    @locks[user ? user.id : 0] ||= Rails.cache.fetch(locked_cache_key(user), :expires_in => 1.minute) do
      locked = false
      if (self.delayed_post_at && self.delayed_post_at > Time.now)
        locked = {:asset_string => self.asset_string, :unlock_at => self.delayed_post_at}
      elsif (self.assignment && l = self.assignment.locked_for?(user, opts))
        locked = l
      elsif (self.could_be_locked && self.context_module_tag && !self.context_module_tag.available_for?(user, opts[:deep_check_if_needed]))
        locked = {:asset_string => self.asset_string, :context_module => self.context_module_tag.context_module.attributes}
      elsif (self.root_topic && l = self.root_topic.locked_for?(user, opts))
        locked = l
      end
      locked
    end
  end
    
  attr_accessor :clone_updated
  attr_accessor :assignment_clone_updated
  def clone_for(context, dup=nil, options={})
    options[:migrate] = true if options[:migrate] == nil
    if !self.cloned_item && !self.new_record?
      self.cloned_item ||= ClonedItem.create(:original_item => self)
      self.save!
    end
    existing = context.discussion_topics.active.find_by_id(self.id)
    existing ||= context.discussion_topics.active.find_by_cloned_item_id(self.cloned_item_id || 0)
    return existing if existing && !options[:overwrite]
    if context.merge_mapped_id(self.assignment)
      dup ||= context.discussion_topics.find_by_assignment_id(context.merge_mapped_id(self.assignment))
    end
    dup ||= DiscussionTopic.new
    dup = existing if existing && options[:overwrite]
    self.attributes.delete_if{|k,v| [:id, :assignment_id, :attachment_id, :root_topic_id].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.assignment_id = context.merge_mapped_id(self.assignment)
    if !dup.assignment_id && self.assignment_id && self.assignment && !options[:cloning_for_assignment]
      new_assignment = self.assignment.clone_for(context, nil, :cloning_for_topic=>true)
      assignment_clone_updated = new_assignment.clone_updated
      new_assignment.save_without_broadcasting!
      context.map_merge(self.assignment, new_assignment)
      dup.assignment_id = new_assignment.id
    end
    if !dup.attachment_id && self.attachment
      attachment = self.attachment.clone_for(context)
      attachment.folder_id = nil
      attachment.save_without_broadcasting!
      context.map_merge(self.attachment, attachment)
      context.warn_merge_result("Added file \"#{attachment.folder.full_name}/#{attachment.display_name}\" which is needed for the topic \"#{self.title}\"")
      dup.attachment_id = attachment.id
    end
    dup.context = context
    dup.message = context.migrate_content_links(self.message, self.context) if options[:migrate]
    dup.saved_by = :assignment if options[:cloning_for_assignment]
    dup.save_without_broadcasting!
    context.log_merge_result("Discussion \"#{dup.title}\" created")
    if options[:include_entries]
      self.discussion_entries.sort_by{|e| e.created_at }.each do |entry|
        dup_entry = entry.clone_for(context, nil, :migrate => options[:migrate])
        dup_entry.parent_id = context.merge_mapped_id("discussion_entry_#{entry.parent_id}") || 0
        dup_entry.discussion_topic_id = dup.id
        dup_entry.save!
        context.map_merge(entry, dup_entry)
        dup_entry
      end
      context.log_merge_result("Included #{dup.discussion_entries.length} entries for the topic \"#{dup.title}\"")
    end
    context.may_have_links_to_migrate(dup)
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
  end

  def self.process_migration(data, migration)
    announcements = data['announcements'] ? data['announcements']: []
    to_import = migration.to_import 'announcements'
    announcements.each do |event|
      if event['migration_id'] && (!to_import || to_import[event['migration_id']])
        event[:type] = 'announcement'
        begin
          import_from_migration(event, migration.context)
        rescue
          migration.add_warning("Couldn't import the announcement \"#{event[:title]}\"", $!)
        end
      end
    end

    topics = data['discussion_topics'] ? data['discussion_topics']: []
    topics_to_import = migration.to_import 'topics'
    topic_entries_to_import = migration.to_import 'topic_entries'
      topics.each do |topic|
        context = Group.find_by_context_id_and_context_type_and_migration_id(migration.context.id, migration.context.class.to_s, topic['group_id']) if topic['group_id'] 
        context ||= migration.context
        if context
          if topic['migration_id'] && (!topics_to_import || topics_to_import[topic['migration_id']])
            begin
              import_from_migration(topic.merge({:topic_entries_to_import => topic_entries_to_import}), context)
            rescue
              migration.add_warning("Couldn't import the topic \"#{topic[:title]}\"", $!)
            end
          end
        end
      end
  end
  
  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:topics_to_import] && !hash[:topics_to_import][hash[:migration_id]]
    hash[:skip_replies] = true if hash[:migration_id] && hash[:topic_entries_to_import] && !hash[:topic_entries_to_import][hash[:migration_id]]
    item ||= find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, hash[:id])
    item ||= find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, hash[:migration_id]) if hash[:migration_id]
    if hash[:type] =~ /announcement/i
      item ||= context.announcements.new
    else
      item ||= context.discussion_topics.new
    end
    item.migration_id = hash[:migration_id]
    item.title = hash[:title]
    item.message = ImportedHtmlConverter.convert(hash[:description] || hash[:text], context)
    item.message = t('#discussion_topic.empty_message', "No message") if item.message.blank?
    item.posted_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:posted_at]) if hash[:posted_at]
    item.delayed_post_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:delayed_post_at]) if hash[:delayed_post_at]
    item.delayed_post_at ||= Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:start_date]) if hash[:start_date]
    item.position = hash[:position] if hash[:position]
    if hash[:attachment_migration_id]
      item.attachment = context.attachments.find_by_migration_id(hash[:attachment_migration_id])
    end
    if hash[:external_feed_migration_id]
      item.external_feed = context.external_feeds.find_by_migration_id(hash[:external_feed_migration_id])
    end
    if hash[:attachment_ids] && !hash[:attachment_ids].empty?
      item.message += Attachment.attachment_list_from_migration(context, hash[:attachment_ids])
    end

    if hash[:assignment]
      assignment = Assignment.import_from_migration(hash[:assignment], context)
      item.assignment = assignment
    elsif grading = hash[:grading]
      assignment = Assignment.import_from_migration({
        :grading => grading,
        :migration_id => hash[:migration_id],
        :submission_format => "discussion_topic",
        :due_date=>hash[:due_date] || hash[:grading][:due_date],
        :title => grading[:title]
      }, context)
      item.assignment = assignment
    end
    item.save_without_broadcasting!
    context.migration_results << "" if hash[:peer_rating_type] && hash[:peer_rating_types] != "none" if context.respond_to?(:migration_results)
    context.migration_results << "" if hash[:peer_rating_type] && hash[:peer_rating_types] != "none" if context.respond_to?(:migration_results)
    hash[:messages] ||= hash[:posts]
    if !hash[:skip_replies] and item.discussion_entries.count == 0
      (hash[:messages] || hash[:posts] || []).each do |message|
        DiscussionEntry.import_from_migration(message, context, nil, item, item)
      end
    end
    context.imported_migration_items << item if context.respond_to?(:imported_migration_items) && context.imported_migration_items
    item
  end
  
  def self.podcast_elements(messages, context)
    attachment_ids = []
    media_object_ids = []
    messages_hash = {}
    messages.each do |message|
      txt = (message.message || "")
      attachment_matches = txt.scan(/\/#{context.class.to_s.pluralize.underscore}\/#{context.id}\/files\/(\d+)\/download/)
      attachment_ids += (attachment_matches || []).map{|m| m[0] }
      media_object_matches = txt.scan(/media_comment_([0-9a-z_]+)/)
      media_object_ids += (media_object_matches || []).map{|m| m[0] }
      (attachment_ids + media_object_ids).each do |id|
        messages_hash[id] ||= message
      end
    end
    media_object_ids = media_object_ids.uniq.compact
    attachment_ids = attachment_ids.uniq.compact
    attachments = attachment_ids.empty? ? [] : context.attachments.active.find_all_by_id(attachment_ids).compact
    attachments = attachments.select{|a| a.content_type && a.content_type.match(/(video|audio)/) }
    attachments.each do |attachment|
      attachment.podcast_associated_asset = messages_hash[attachment.id]
    end
    media_objects = media_object_ids.empty? ? [] : MediaObject.find_all_by_media_id(media_object_ids)
    media_objects += media_object_ids.map{|id| MediaObject.new(:media_id => id) }
    media_objects = media_objects.once_per(&:media_id)
    media_objects = media_objects.map do |media_object|
      if media_object.new_record?
        media_object.context = context
        media_object.user_id = messages_hash[media_object.media_id].user_id rescue nil
        media_object.root_account_id = context.root_account_id rescue nil
        media_object.save
      elsif media_object.deleted? || media_object.context != context
        media_object = nil
      end
      if media_object.try(:podcast_format_details)
        media_object.podcast_associated_asset = messages_hash[media_object.media_id]
      end
      media_object
    end
    to_podcast(attachments + media_objects.compact)
  end

  def self.to_podcast(elements, opts={})
    require 'rss/2.0'
    elements.map do |elem|
      asset = elem.podcast_associated_asset
      next unless asset
      item = RSS::Rss::Channel::Item.new
      item.title = before_label((asset.title rescue "")) + elem.name
      link = nil
      if asset.is_a?(DiscussionTopic)
        link = "http://#{HostUrl.context_host(asset.context)}/#{asset.context_url_prefix}/discussion_topics/#{asset.id}"
      elsif asset.is_a?(DiscussionEntry)
        link = "http://#{HostUrl.context_host(asset.context)}/#{asset.context_url_prefix}/discussion_topics/#{asset.discussion_topic_id}"
      end
      
      item.link = link
      item.guid = RSS::Rss::Channel::Item::Guid.new
      item.pubDate = elem.updated_at.utc
      item.description = asset ? asset.message : elem.name
      item.enclosure
      if elem.is_a?(Attachment)
        item.guid.content = link + "/#{elem.uuid}"
        item.enclosure = RSS::Rss::Channel::Item::Enclosure.new("http://#{HostUrl.context_host(elem.context)}/#{elem.context_url_prefix}/files/#{elem.id}/download.#{}?verifier=#{elem.uuid}", elem.size, elem.content_type)
      elsif elem.is_a?(MediaObject)
        item.guid.content = link + "/#{elem.media_id}"
        details = elem.podcast_format_details
        content_type = 'video/mpeg'
        content_type = 'audio/mpeg' if elem.media_type == 'audio'
        size = details[:size].to_i.kilobytes
        item.enclosure = RSS::Rss::Channel::Item::Enclosure.new("http://#{HostUrl.context_host(elem.context)}/#{elem.context_url_prefix}/media_download.#{details[:fileExt]}?entryId=#{elem.media_id}&redirect=1", size, content_type)
      end
      item
    end
  end
end
