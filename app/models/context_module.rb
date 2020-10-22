# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class ContextModule < ActiveRecord::Base
  include Workflow
  include SearchTermHelper
  include DuplicatingObjects
  include LockedFor

  include MasterCourses::Restrictor
  restrict_columns :state, [:workflow_state]

  belongs_to :context, polymorphic: [:course]
  belongs_to :root_account, :class_name => 'Account'
  has_many :context_module_progressions, :dependent => :destroy
  has_many :content_tags, -> { order('content_tags.position, content_tags.title') }, dependent: :destroy
  acts_as_list scope: { context: self, workflow_state: ['active', 'unpublished'] }

  serialize :prerequisites
  serialize :completion_requirements
  before_save :infer_position
  before_save :validate_prerequisites
  before_save :confirm_valid_requirements
  before_save :set_root_account_id

  after_save :touch_context
  after_save :invalidate_progressions
  after_save :relock_warning_check
  after_save :clear_discussion_stream_items
  after_save :send_items_to_stream
  validates_presence_of :workflow_state, :context_id, :context_type
  validates_presence_of :name, :if => :require_presence_of_name
  attr_accessor :require_presence_of_name

  def relock_warning_check
    # if the course is already active and we're adding more stringent requirements
    # then we're going to give the user an option to re-lock students out of the modules
    # otherwise they will be able to continue as before
    @relock_warning = false
    return if self.new_record?

    if self.context.available? && self.active?
      if self.saved_change_to_workflow_state? && self.workflow_state_before_last_save == "unpublished"
        # should trigger when publishing a prerequisite for an already active module
        @relock_warning = true if self.context.context_modules.active.any?{|mod| self.is_prerequisite_for?(mod)}
        # if any of these changed while we were unpublished, then we also need to trigger
        @relock_warning = true if self.prerequisites.any? || self.completion_requirements.any? || self.unlock_at.present?
      end
      if self.saved_change_to_completion_requirements?
        # removing a requirement shouldn't trigger
        @relock_warning = true if (self.completion_requirements.to_a - self.completion_requirements_before_last_save.to_a).present?
      end
      if self.saved_change_to_prerequisites?
        # ditto with removing a prerequisite
        @relock_warning = true if (self.prerequisites.to_a - self.prerequisites_before_last_save.to_a).present?
      end
      if self.saved_change_to_unlock_at?
        # adding a unlock_at date should trigger
        @relock_warning = true if self.unlock_at.present? && self.unlock_at_before_last_save.blank?
      end
    end
  end

  def relock_warning?
    @relock_warning
  end

  def relock_progressions(relocked_modules=[], student_ids=nil)
    return if relocked_modules.include?(self)
    self.class.connection.after_transaction_commit do
      relocked_modules << self
      progression_scope = self.context_module_progressions.where(:current => true).where.not(:workflow_state => 'locked')
      progression_scope = progression_scope.where(:user_id => student_ids) if student_ids

      if progression_scope.update_all(["workflow_state = 'locked', lock_version = lock_version + 1, current = ?", false]) > 0
        delay_if_production(strand: "module_reeval_#{self.global_context_id}").evaluate_all_progressions
      end

      self.context.context_modules.each do |mod|
        mod.relock_progressions(relocked_modules, student_ids) if self.is_prerequisite_for?(mod)
      end
    end
  end

  def invalidate_progressions
    self.class.connection.after_transaction_commit do
      if context_module_progressions.where(current: true).update_all(current: false) > 0
        # don't queue a job unless necessary
        delay_if_production(strand: "module_reeval_#{self.global_context_id}").evaluate_all_progressions
      end
      if @discussion_topics_to_recalculate
        @discussion_topics_to_recalculate.each do |dt|
          dt.delay_if_production(strand: "module_reeval_#{self.global_context_id}").recalculate_context_module_actions!
        end
      end
    end
  end

  def evaluate_all_progressions
    current_column = 'context_module_progressions.current'
    current_scope = context_module_progressions.where("#{current_column} IS NULL OR #{current_column} = ?", false).preload(:user)

    current_scope.find_in_batches(batch_size: 100) do |progressions|
      self.context.cache_item_visibilities_for_user_ids(progressions.map(&:user_id))

      progressions.each do |progression|
        progression.context_module = self
        progression.evaluate!
      end

      self.context.clear_cached_item_visibilities
    end
  end

  def check_for_stale_cache_after_unlocking!
    GuardRail.activate(:primary) {self.touch} if self.unlock_at && self.unlock_at < Time.now && self.updated_at < self.unlock_at
  end

  def is_prerequisite_for?(mod)
    (mod.prerequisites || []).any? {|prereq| prereq[:type] == 'context_module' && prereq[:id] == self.id }
  end

  def self.module_positions(context)
    # Keep a cached hash of all modules for a given context and their
    # respective positions -- used when enforcing valid prerequisites
    # and when generating the list of downstream modules
    Rails.cache.fetch(['module_positions', context].cache_key) do
      hash = {}
      context.context_modules.not_deleted.each{|m| hash[m.id] = m.position || 0 }
      hash
    end
  end

  def remove_completion_requirement(id)
    if completion_requirements.present?
      new_requirements = completion_requirements.delete_if do |requirement|
        requirement[:id] == id
      end

      update_attribute :completion_requirements, new_requirements
    end
  end

  def infer_position
    if !self.position
      positions = ContextModule.module_positions(self.context)
      if max = positions.values.max
        self.position = max + 1
      else
        self.position = 1
      end
    end
    self.position
  end

  def get_potentially_conflicting_titles(title_base)
    ContextModule.not_deleted.where(context_id: self.context_id)
      .starting_with_name(title_base).pluck("name").to_set
  end

  def duplicate_base_model(copy_title)
    ContextModule.new({
      :context_id => self.context_id,
      :context_type => self.context_type,
      :name => copy_title,
      :position => ContextModule.not_deleted.where(context_id: self.context_id).maximum(:position) + 1,
      :completion_requirements => self.completion_requirements,
      :workflow_state => 'unpublished',
      :require_sequential_progress => self.require_sequential_progress,
      :completion_events => self.completion_events,
      :requirement_count => self.requirement_count
    })
  end

  def can_be_duplicated?
    self.content_tags.none? do |content_tag|
      !content_tag.deleted? && content_tag.content_type_class == 'quiz'
    end
  end

  def send_items_to_stream
    if self.saved_change_to_workflow_state? && self.workflow_state == 'active'
      self.content_tags.where(content_type: "DiscussionTopic", workflow_state: 'active').preload(:content).each do |ct|
        ct.content.send_items_to_stream
      end
    end
  end

  def clear_discussion_stream_items
    if self.saved_change_to_workflow_state? &&
      ['active', nil].include?(self.workflow_state_before_last_save) &&
      self.workflow_state == 'unpublished'
      self.content_tags.where(content_type: "DiscussionTopic", workflow_state: 'active').preload(:content).each do |ct|
        ct.content.clear_stream_items
      end
    end
  end

  # This is intended for duplicating a content tag when we are duplicating a module
  # Not intended for duplicating a content tag to keep in the original module
  def duplicate_content_tag_base_model(original_content_tag)
    ContentTag.new(
      :content_id => original_content_tag.content_id,
      :content_type => original_content_tag.content_type,
      :context_id => original_content_tag.context_id,
      :context_type => original_content_tag.context_type,
      :url => original_content_tag.url,
      :new_tab => original_content_tag.new_tab,
      :title => original_content_tag.title,
      :tag_type => original_content_tag.tag_type,
      :position => original_content_tag.position,
      :indent => original_content_tag.indent,
      :learning_outcome_id => original_content_tag.learning_outcome_id,
      :context_code => original_content_tag.context_code,
      :mastery_score => original_content_tag.mastery_score,
      :workflow_state => 'unpublished'
    )
  end
  private :duplicate_content_tag_base_model

  # Intended for taking a content_tag in this module and duplicating it
  # into a new module.  Not intended for duplicating a content tag to be
  # kept in the same module.
  def duplicate_content_tag(original_content_tag)
    new_tag = duplicate_content_tag_base_model(original_content_tag)
    if original_content_tag.content&.respond_to?(:duplicate)
      new_tag.content = original_content_tag.content.duplicate
      # If we have multiple assignments (e.g.) make sure they each get unused titles.
      # A title isn't marked used if the assignment hasn't been saved yet.
      new_tag.content.save!
      new_tag.title = nil
    end
    new_tag
  end
  private :duplicate_content_tag

  def set_root_account_id
    self.root_account_id ||= context&.root_account_id
  end

  def duplicate
    copy_title = get_copy_title(self, t("Copy"), self.name)
    new_module = duplicate_base_model(copy_title)
    living_tags = self.content_tags.select do |content_tag|
      !content_tag.deleted?
    end
    new_module.content_tags = living_tags.map do |content_tag|
      duplicate_content_tag(content_tag)
    end
    new_module
  end

  def validate_prerequisites
    positions = ContextModule.module_positions(self.context)
    @already_confirmed_valid_requirements = false
    prereqs = []
    (self.prerequisites || []).each do |pre|
      if pre[:type] == 'context_module'
        position = positions[pre[:id].to_i] || 0
        prereqs << pre if position && position < (self.position || 0)
      else
        prereqs << pre
      end
    end
    self.prerequisites = prereqs
    self.position
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    ContentTag.where(:context_module_id => self).where.not(:workflow_state => 'deleted').update_all(:workflow_state => 'deleted', :updated_at => self.deleted_at)
    delay_if_production(n_strand: "context_module_update_downstreams", priority: Delayed::LOW_PRIORITY).update_downstreams(self.position)
    save!
    true
  end

  def restore
    if self.workflow_state == 'deleted' && self.deleted_at
      # only restore tags deleted (approximately) when the module was deleted
      # (tags are currently set to exactly deleted_at but older deleted modules used the current time on each tag)
      tags_to_restore = self.content_tags.where(:workflow_state => 'deleted').
        where('updated_at BETWEEN ? AND ?', self.deleted_at - 5.seconds, self.deleted_at + 5.seconds).
        preload(:content)
      tags_to_restore.each do |tag|
        # don't restore the item if the asset has been deleted too
        next if tag.asset_workflow_state == 'deleted'
        # although the module will be restored unpublished, the items should match the asset's published state
        tag.workflow_state = tag.content && tag.sync_workflow_state_to_asset? ? tag.asset_workflow_state : 'unpublished'
        # deal with the possibility that the asset has been renamed after the module was deleted
        tag.title = Context.asset_name(tag.content) if tag.content && tag.sync_title_to_asset_title?
        tag.save
      end
    end
    self.workflow_state = 'unpublished'
    self.save
  end

  def update_downstreams(original_position=nil)
    original_position ||= self.position || 0
    positions = ContextModule.module_positions(self.context).to_a.sort_by{|a| a[1] }
    downstream_ids = positions.select{|a| a[1] > (self.position || 0)}.map{|a| a[0] }
    downstreams = downstream_ids.empty? ? [] : self.context.context_modules.not_deleted.where(id: downstream_ids)
    downstreams.each {|m| m.save_without_touching_context }
  end

  workflow do
    state :active do
      event :unpublish, :transitions_to => :unpublished
    end
    state :unpublished do
      event :publish, :transitions_to => :active
    end
    state :deleted
  end

  scope :active, -> { where(:workflow_state => 'active') }
  scope :unpublished, -> { where(:workflow_state => 'unpublished') }
  scope :not_deleted, -> { where("context_modules.workflow_state<>'deleted'") }
  scope :starting_with_name, lambda { |name|
    where('name ILIKE ?', "#{name}%")
  }
  alias_method :published?, :active?

  def publish_items!
    self.content_tags.each do |tag|
      if tag.unpublished?
        if tag.content_type == 'Attachment'
          tag.content.set_publish_state_for_usage_rights
          tag.content.save!
          tag.publish if tag.content.published?
        else
          tag.publish
        end
      end
      tag.update_asset_workflow_state!
    end
  end

  set_policy do
    given {|user, session| self.context.grants_right?(user, session, :manage_content) }
    can :read and can :create and can :update and can :delete and can :read_as_admin

    given {|user, session| self.context.grants_right?(user, session, :read_as_admin) }
    can :read and can :read_as_admin

    given {|user, session| self.context.grants_right?(user, session, :view_unpublished_items) }
    can :view_unpublished_items

    given {|user, session| self.context.grants_right?(user, session, :read) && self.active? }
    can :read
  end

  def low_level_locked_for?(user, opts={})
    return false if self.grants_right?(user, :read_as_admin)
    available = self.available_for?(user, opts)
    return {object: self, module: self} unless available
    return {object: self, module: self, unlock_at: unlock_at} if to_be_unlocked
    false
  end

  def available_for?(user, opts={})
    return true if self.active? && !self.to_be_unlocked && self.prerequisites.blank? &&
      (self.completion_requirements.empty? || !self.require_sequential_progress)
    if self.grants_right?(user, :read_as_admin)
      return true
    elsif !self.active?
      return false
    elsif self.context.user_has_been_observer?(user)
      return true
    end

    progression = if opts[:user_context_module_progressions]
      opts[:user_context_module_progressions][self.id]
    end
    progression ||= self.find_or_create_progression(user)
    # if the progression is locked, then position in the progression doesn't
    # matter. we're not available.

    tag = opts[:tag]
    avail = progression && !progression.locked? && !locked_for_tag?(tag, progression)
    if !avail && opts[:deep_check_if_needed]
      progression = self.evaluate_for(progression)
      avail = progression && !progression.locked? && !locked_for_tag?(tag, progression)
    end
    avail
  end

  def locked_for_tag?(tag, progression)
    locked = (tag&.context_module_id == self.id && self.require_sequential_progress)
    locked && (progression.current_position &.< tag.position)
  end

  def self.module_names(context)
    Rails.cache.fetch(['module_names', context].cache_key) do
      gather_module_names(context.context_modules.not_deleted)
    end
  end

  def self.active_module_names(context)
    Rails.cache.fetch(['active_module_names', context].cache_key) do
      gather_module_names(context.context_modules.active)
    end
  end

  def self.gather_module_names(scope)
    scope.pluck(:id, :name).each_with_object({}) do |(id, name), names|
      names[id] = name
    end
  end

  def prerequisites
    @prerequisites ||= gather_prerequisites(ContextModule.module_names(self.context))
  end

  def active_prerequisites
    @active_prerequisites ||= gather_prerequisites(ContextModule.active_module_names(self.context))
  end

  def gather_prerequisites(module_names)
    all_prereqs = read_attribute(:prerequisites)
    return [] unless all_prereqs&.any?
    all_prereqs.select{|pre| module_names.key?(pre[:id])}.map{|pre| pre.merge(:name => module_names[pre[:id]])}
  end

  def prerequisites=(prereqs)
    Rails.cache.delete(['module_names', context].cache_key) # ensure the module list is up to date
    if prereqs.is_a?(Array)
      # validate format, skipping invalid ones
      prereqs = prereqs.select do |pre|
        pre.has_key?(:id) && pre.has_key?(:name) && pre[:type] == 'context_module'
      end
    elsif prereqs.is_a?(String)
      res = []
      module_names = ContextModule.module_names(self.context)
      pres = prereqs.split(",")
      pre_regex = /module_(\d+)/
      pres.each do |pre|
        next unless match = pre_regex.match(pre)
        id = match[1].to_i
        if module_names.has_key?(id)
          res << {:id => id, :type => 'context_module', :name => module_names[id]}
        end
      end
      prereqs = res
    else
      prereqs = nil
    end
    @prerequisites = nil
    @active_prerequisites = nil
    write_attribute(:prerequisites, prereqs)
  end

  def completion_requirements=(val)
    if val.is_a?(Array)
      hash = {}
      val.each{|i| hash[i[:id]] = i }
      val = hash
    end
    if val.is_a?(Hash)
      # requirements hash can contain invalid data (e.g. {"none"=>"none"}) from the ui,
      # filter & manipulate the data to something more reasonable
      val = val.map do |id, req|
        if req.is_a?(Hash)
          req[:id] = id unless req[:id]
          req
        end
      end
      val = validate_completion_requirements(val.compact)
    else
      val = nil
    end
    write_attribute(:completion_requirements, val)
  end

  def validate_completion_requirements(requirements)
    requirements = requirements.map do |req|
      new_req = {
        id: req[:id].to_i,
        type: req[:type],
      }
      new_req[:min_score] = req[:min_score].to_f if req[:type] == 'min_score' && req[:min_score]
      new_req
    end

    tags = self.content_tags.not_deleted.index_by(&:id)
    validated_reqs = requirements.select do |req|
      if req[:id] && (tag = tags[req[:id]])
        if %w(must_view must_mark_done must_contribute).include?(req[:type])
          true
        elsif %w(must_submit min_score).include?(req[:type])
          true if tag.scoreable?
        end
      end
    end

    unless self.new_record?
      old_requirements = self.completion_requirements || []
      validated_reqs.each do |req|
        if req[:type] == 'must_contribute' && !old_requirements.detect{|r| r[:id] == req[:id] && r[:type] == req[:type]} # new requirement
          tag = tags[req[:id]]
          if tag.content_type == "DiscussionTopic"
            @discussion_topics_to_recalculate ||= []
            @discussion_topics_to_recalculate << tag.content
          end
        end
      end
    end

    validated_reqs
  end

  def completion_requirements_visible_to(user, opts={})
    valid_ids = content_tags_visible_to(user, opts).map(&:id)
    completion_requirements.select { |cr| valid_ids.include? cr[:id]  }
  end

  def content_tags_visible_to(user, opts={})
    @content_tags_visible_to ||= {}
    @content_tags_visible_to[user.try(:id)] ||= begin
      is_teacher = opts[:is_teacher] != false && self.grants_right?(user, :read_as_admin)
      tags = is_teacher ? cached_not_deleted_tags : cached_active_tags

      if !is_teacher && user
        opts[:is_teacher] = false
        tags = filter_tags_for_da(tags, user, opts)
      end

      # always return an array now because filter_tags_for_da *might* return one
      tags.to_a
    end
  end

  def visibility_for_user(user)
    opts = {}
    opts[:can_read] = self.context.grants_right?(user, :read)
    if opts[:can_read]
      opts[:can_read_as_admin] = self.context.grants_right?(user, :read_as_admin)
    end
    opts
  end

  def filter_tags_for_da(tags, user, opts={})
    filter = Proc.new do |tags, user_ids, course_id, opts|
      visible_item_ids = {}
      tags.select do |tag|
        item_type =
          case tag.content_type
          when 'Assignment'
            :assignment
          when 'DiscussionTopic'
            :discussion
          when 'WikiPage'
            :page
          when *Quizzes::Quiz.class_names
            :quiz
          end
        if item_type
          visible_item_ids[item_type] ||= self.context.visible_item_ids_for_users(item_type, user_ids) # don't load the visibilities if there are no items of that type
          visible_item_ids[item_type].include?(tag.content_id)
        else
          true
        end
      end
    end

    tags = self.shard.activate do
      DifferentiableAssignment.filter(tags, user, self.context, opts) do |tags, user_ids|
        filter.call(tags, user_ids, self.context_id, opts)
      end
    end

    tags
  end

  def reload
    @prerequisites = nil
    @active_prerequisites = nil
    clear_cached_lookups
    super
  end

  def clear_cached_lookups
    @cached_active_tags = nil
    @cached_not_deleted_tags = nil
    @content_tags_visible_to = nil
  end

  def cached_active_tags
    @cached_active_tags ||= begin
      if self.content_tags.loaded?
        # don't reload the preloaded content
        self.content_tags.select{|tag| tag.active?}
      else
        self.content_tags.active.to_a
      end
    end
  end

  def cached_not_deleted_tags
    @cached_not_deleted_tags ||= begin
      if self.content_tags.loaded?
        # don't reload the preloaded content
        self.content_tags.select{|tag| !tag.deleted?}
      else
        self.content_tags.not_deleted.to_a
      end
    end
  end

  def add_item(params, added_item=nil, opts={})
    params[:type] = params[:type].underscore if params[:type]
    position = opts[:position] || (self.content_tags.not_deleted.maximum(:position) || 0) + 1
    position = [position, params[:position].to_i].max if params[:position]
    if params[:type] == "wiki_page" || params[:type] == "page"
      item = opts[:wiki_page] || self.context.wiki_pages.where(id: params[:id]).first
    elsif params[:type] == "attachment" || params[:type] == "file"
      item = opts[:attachment] || self.context.attachments.not_deleted.find_by_id(params[:id])
    elsif params[:type] == "assignment"
      item = opts[:assignment] || self.context.assignments.active.where(id: params[:id]).first
    elsif params[:type] == "discussion_topic" || params[:type] == "discussion"
      item = opts[:discussion_topic] || self.context.discussion_topics.active.where(id: params[:id]).first
    elsif params[:type] == "quiz"
      item = opts[:quiz] || self.context.quizzes.active.where(id: params[:id]).first
    end
    workflow_state = ContentTag.asset_workflow_state(item) if item
    workflow_state ||= 'active'
    if params[:type] == 'external_url'
      title = params[:title]
      added_item ||= self.content_tags.build(:context => self.context)
      added_item.attributes = {
        :url => params[:url],
        :new_tab => params[:new_tab],
        :tag_type => 'context_module',
        :title => title,
        :indent => params[:indent],
        :position => position
      }
      added_item.content_id = 0
      added_item.content_type = 'ExternalUrl'
      added_item.context_module_id = self.id
      added_item.indent = params[:indent] || 0
      added_item.workflow_state = 'unpublished' if added_item.new_record?
      added_item.save
      added_item
    elsif params[:type] == 'context_external_tool' || params[:type] == 'external_tool' || params[:type] == 'lti/message_handler'
      title = params[:title]
      added_item ||= self.content_tags.build(:context => self.context)

      content = if params[:type] == 'lti/message_handler'
                  Lti::MessageHandler.for_context(context).where(id: params[:id]).first
                else
                  ContextExternalTool.find_external_tool(params[:url], self.context, params[:id].to_i) || ContextExternalTool.new.tap { |tool| tool.id = 0 }
                end
      added_item.attributes = {
        content: content,
        :url => params[:url],
        :new_tab => params[:new_tab],
        :tag_type => 'context_module',
        :title => title,
        :indent => params[:indent],
        :position => position
      }
      added_item.context_module_id = self.id
      added_item.indent = params[:indent] || 0
      added_item.workflow_state = 'unpublished' if added_item.new_record?
      added_item.link_settings = params[:link_settings]
      added_item.save
      added_item
    elsif params[:type] == 'context_module_sub_header' || params[:type] == 'sub_header'
      title = params[:title]
      added_item ||= self.content_tags.build(:context => self.context)
      added_item.attributes = {
        :tag_type => 'context_module',
        :title => title,
        :indent => params[:indent],
        :position => position
      }
      added_item.content_id = 0
      added_item.content_type = 'ContextModuleSubHeader'
      added_item.context_module_id = self.id
      added_item.indent = params[:indent] || 0
      added_item.workflow_state = 'unpublished' if added_item.new_record?
      added_item.save
      added_item
    else
      return nil unless item
      title = params[:title] || (item.title rescue item.name)
      added_item ||= self.content_tags.build(:context => context)
      added_item.attributes = {
        :content => item,
        :tag_type => 'context_module',
        :title => title,
        :indent => params[:indent],
        :position => position
      }
      added_item.context_module_id = self.id
      added_item.indent = params[:indent] || 0
      added_item.workflow_state = workflow_state if added_item.new_record?
      added_item.save
      added_item
    end
  end

  # specify a 1-based position to insert the items at; leave nil to append to the end of the module
  # ignores current module item positions in favor of an objective position
  def insert_items(items, start_pos = nil)
    tags = content_tags.not_deleted.select(:id, :position, :content_type, :content_id).to_a
    if start_pos
      start_pos = 1 if start_pos < 1
      next_pos = start_pos
    else
      next_pos = (content_tags.maximum(:position) || 0) + 1
    end

    new_tags = []
    items.each do |item|
      next unless item.is_a?(ActiveRecord::Base)
      next unless %w(Attachment Assignment WikiPage Quizzes::Quiz DiscussionTopic ContextExternalTool).include?(item.class_name)
      item = item.submittable_object if item.is_a?(Assignment) && item.submittable_object
      next if tags.any? { |tag| tag.content_type == item.class_name && tag.content_id == item.id }
      state = item.respond_to?(:published?) && !item.published? ? 'unpublished' : 'active'
      new_tags << self.content_tags.create!(context: self.context, title: Context.asset_name(item), content: item,
                                            tag_type: 'context_module', indent: 0,
                                            position: next_pos, workflow_state: state)
      next_pos += 1
    end

    return unless start_pos

    tag_ids_to_move = {}
    tags_before = start_pos < 2 ? [] : tags[0..start_pos - 2]
    tags_after = start_pos > tags.length ? [] : tags[start_pos - 1..-1]
    (tags_before + new_tags + tags_after).each_with_index do |item, index|
      index_change = index + 1 - item.position
      if index_change != 0
        tag_ids_to_move[index_change] ||= []
        tag_ids_to_move[index_change] << item.id
      end
    end

    tag_ids_to_move.each do |position_change, ids|
      content_tags.where(id: ids).update_all(sanitize_sql(['position = position + ?', position_change]))
    end
  end

  def update_for(user, action, tag, points=nil)
    retry_count = 0
    return nil unless self.context.grants_right?(user, :participate_as_student)
    return nil unless progression = self.evaluate_for(user)
    return nil if progression.locked?

    progression.update_requirement_met!(action, tag, points)
    progression
  end

  def completion_requirement_for(action, tag)
    self.completion_requirements.to_a.find do |requirement|
      next false unless requirement[:id] == tag.local_id

      case requirement[:type]
      when 'must_view'
        action == :read || action == :contributed
      when 'must_mark_done'
        action == :done
      when 'must_contribute'
        action == :contributed
      when 'must_submit'
        action == :scored || action == :submitted
      when 'min_score'
        action == :scored ||
          action == :submitted # to mark progress in the incomplete_requirements (moves from 'unlocked' to 'started')
      else
        false
      end
    end
  end

  def self.requirement_description(req)
    case req[:type]
    when 'must_view'
      t('requirements.must_view', "must view the page")
    when 'must_mark_done'
      t("must mark as done")
    when 'must_contribute'
      t('requirements.must_contribute', "must contribute to the page")
    when 'must_submit'
      t('requirements.must_submit', "must submit the assignment")
    when 'min_score'
      t('requirements.min_score', "must score at least a %{score}", :score => req[:min_score])
    else
      nil
    end
  end

  def confirm_valid_requirements(do_save=false)
    return if @already_confirmed_valid_requirements
    @already_confirmed_valid_requirements = true
    # the write accessor validates for us
    self.completion_requirements = self.completion_requirements || []
    self.save if do_save && self.completion_requirements_changed?
    self.completion_requirements
  end

  def find_or_create_progressions(users)
    users = Array(users)
    users_hash = {}
    users.each{|u| users_hash[u.id] = u }
    progressions = self.context_module_progressions.where(user_id: users)
    progressions_hash = {}
    progressions.each{|p| progressions_hash[p.user_id] = p }
    newbies = users.select{|u| !progressions_hash[u.id] }
    progressions += newbies.map{|u| find_or_create_progression(u) }
    progressions.each{|p| p.user = users_hash[p.user_id] }
    progressions.uniq
  end

  def find_or_create_progression(user)
    return nil unless user
    progression = nil
    self.shard.activate do
      GuardRail.activate(:primary) do
        progression = context_module_progressions.where(user_id: user).first
        if !progression && context.enrollments.except(:preload).where(user_id: user).exists? # check if we should even be creating a progression for this user
          self.class.unique_constraint_retry do |retry_count|
            progression = context_module_progressions.where(user_id: user).first if retry_count > 0
            progression ||= context_module_progressions.create!(user: user)
          end
        end
      end
    end
    progression.context_module = self if progression
    progression
  end

  def evaluate_for(user_or_progression)
    if user_or_progression.is_a?(ContextModuleProgression)
      progression, user = [user_or_progression, user_or_progression.user]
    else
      progression, user = [self.find_or_create_progression(user_or_progression), user_or_progression] if user_or_progression
    end
    return nil unless progression && user

    progression.context_module = self if progression.context_module_id == self.id
    progression.user = user if progression.user_id == user.id

    progression.evaluate!
  end

  def to_be_unlocked
    self.unlock_at && self.unlock_at > Time.now
  end

  def migration_position
    @migration_position_counter ||= 0
    @migration_position_counter = @migration_position_counter + 1
  end
  attr_accessor :item_migration_position

  VALID_COMPLETION_EVENTS = [:publish_final_grade].freeze

  def completion_events
    (read_attribute(:completion_events) || '').split(',').map(&:to_sym)
  end

  def completion_events=(value)
    return write_attribute(:completion_events, nil) unless value
    write_attribute(:completion_events, (value.map(&:to_sym) & VALID_COMPLETION_EVENTS).join(','))
  end

  VALID_COMPLETION_EVENTS.each do |event|
    self.class_eval <<-CODE
      def #{event}=(value)
        if Canvas::Plugin.value_to_boolean(value)
          self.completion_events |= [:#{event}]
        else
          self.completion_events -= [:#{event}]
        end
      end

      def #{event}?
        completion_events.include?(:#{event})
      end
    CODE
  end

  def completion_event_callbacks
    callbacks = []
    if publish_final_grade? && (plugin = Canvas::Plugin.find('grade_export')) && plugin.enabled?
      callbacks << lambda { |user| context.publish_final_grades(user, user.id) }
    end
    callbacks
  end
end
