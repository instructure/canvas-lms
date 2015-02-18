#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
  attr_accessible :context, :name, :unlock_at, :require_sequential_progress, :completion_requirements, :prerequisites, :publish_final_grade
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course']
  has_many :context_module_progressions, :dependent => :destroy
  has_many :content_tags, :dependent => :destroy, :order => 'content_tags.position, content_tags.title'
  acts_as_list scope: { context: self, workflow_state: ['active', 'unpublished'] }

  EXPORTABLE_ATTRIBUTES = [
    :id, :context_id, :context_type, :name, :position, :prerequisites, :completion_requirements, :created_at, :updated_at, :workflow_state, :deleted_at,
    :unlock_at, :start_at, :end_at, :require_sequential_progress, :cloned_item_id, :completion_events
  ]

  EXPORTABLE_ASSOCIATIONS = [:context, :context_module_prograssions, :content_tags]

  serialize :prerequisites
  serialize :completion_requirements
  before_save :infer_position
  before_save :validate_prerequisites
  before_save :confirm_valid_requirements

  after_save :touch_context
  after_save :invalidate_progressions
  after_save :relock_warning_check
  validates_presence_of :workflow_state, :context_id, :context_type

  def relock_warning_check
    # if the course is already active and we're adding more stringent requirements
    # then we're going to give the user an option to re-lock students out of the modules
    # otherwise they will be able to continue as before
    @relock_warning = false
    return if self.new_record?

    if self.context.available? && self.active?
      if self.workflow_state_changed? && self.workflow_state_was == "unpublished"
        # should trigger when publishing a prerequisite for an already active module
        @relock_warning = true if self.context.context_modules.active.any?{|mod| self.is_prerequisite_for?(mod)}
      end
      if self.completion_requirements_changed?
        # removing a requirement shouldn't trigger
        @relock_warning = true if (self.completion_requirements.to_a - self.completion_requirements_was.to_a).present?
      end
      if self.prerequisites_changed?
        # ditto with removing a prerequisite
        @relock_warning = true if (self.prerequisites.to_a - self.prerequisites_was.to_a).present?
      end
    end
  end

  def relock_warning?
    @relock_warning
  end

  def relock_progressions(relocked_modules=[])
    return if relocked_modules.include?(self)
    connection.after_transaction_commit do
      relocked_modules << self
      self.context_module_progressions.update_all(:workflow_state => "locked")
      self.invalidate_progressions

      self.context.context_modules.each do |mod|
        mod.relock_progressions(relocked_modules) if self.is_prerequisite_for?(mod)
      end
    end
  end

  def invalidate_progressions
    connection.after_transaction_commit do
      context_module_progressions.update_all(current: false)
      send_later_if_production(:evaluate_all_progressions)
    end
  end

  def evaluate_all_progressions
    current_column = 'context_module_progressions.current'
    current_scope = context_module_progressions.where("#{current_column} IS NULL OR #{current_column} = ?", false).includes(:user)

    current_scope.find_in_batches(batch_size: 100) do |progressions|
      cache_visibilities_for_students(progressions.map(&:user_id)) if differentiated_assignments_enabled?

      progressions.each do |progression|
        progression.context_module = self
        progression.evaluate!
      end

      clear_cached_visibilities if differentiated_assignments_enabled?
    end
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

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    ContentTag.where(:context_module_id => self).update_all(:workflow_state => 'deleted', :updated_at => Time.now.utc)
    self.send_later_if_production_enqueue_args(:update_downstreams, { max_attempts: 1, n_strand: "context_module_update_downstreams", priority: Delayed::LOW_PRIORITY }, self.position)
    save!
    true
  end

  def restore
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

  alias_method :published?, :active?

  def publish_items!
    self.content_tags.each do |tag|
      tag.publish if tag.unpublished?
      tag.update_asset_workflow_state!
    end
  end

  set_policy do
    given {|user, session| self.context.grants_right?(user, session, :manage_content) }
    can :read and can :create and can :update and can :delete and can :read_as_admin

    given {|user, session| self.context.grants_right?(user, session, :read_as_admin) }
    can :read_as_admin

    given {|user, session| self.context.grants_right?(user, session, :read) }
    can :read
  end

  def locked_for?(user, opts={})
    return false if self.grants_right?(user, :read_as_admin)
    available = self.available_for?(user, opts)
    return {:asset_string => self.asset_string, :context_module => self.attributes} unless available
    return {:asset_string => self.asset_string, :context_module => self.attributes, :unlock_at => self.unlock_at} if self.to_be_unlocked
    false
  end

  def available_for?(user, opts={})
    return true if self.active? && !self.to_be_unlocked && self.prerequisites.blank? && !self.require_sequential_progress
    if self.grants_right?(user, :read_as_admin)
      return true
    elsif !self.active?
      return false
    elsif self.context.user_has_been_observer?(user)
      return true
    end

    progression = self.evaluate_for(user)
    # if the progression is locked, then position in the progression doesn't
    # matter. we're not available.

    tag = opts[:tag]
    res = progression && !progression.locked?
    if tag && tag.context_module_id == self.id && self.require_sequential_progress
      res = progression && !progression.locked? && progression.current_position && progression.current_position >= tag.position
    end
    if !res && opts[:deep_check_if_needed]
      progression = self.evaluate_for(user)
      if tag && tag.context_module_id == self.id && self.require_sequential_progress
        res = progression && !progression.locked? && progression.current_position && progression.current_position >= tag.position
      end
    end
    res
  end

  def current?
    (self.start_at || self.end_at) && (!self.start_at || Time.now >= self.start_at) && (!self.end_at || Time.now <= self.end_at) rescue true
  end

  def self.module_names(context)
    Rails.cache.fetch(['module_names', context].cache_key) do
      names = {}
      context.context_modules.not_deleted.select([:id, :name]).each do |mod|
        names[mod.id] = mod.name
      end
      names
    end
  end

  def prerequisites=(prereqs)
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
      new_req[:max_score] = req[:max_score].to_f if req[:type] == 'max_score' && req[:max_score]
      new_req
    end

    tags = self.content_tags.not_deleted.index_by(&:id)
    requirements.select do |req|
      if req[:id] && tag = tags[req[:id]]
        if %w(must_view must_contribute).include?(req[:type])
          true
        elsif %w(must_submit min_score max_score).include?(req[:type])
          true if tag.scoreable?
        end
      end
    end
  end

  def completion_requirements_visible_to(user)
    valid_ids = content_tags_visible_to(user).map(&:id)
    completion_requirements.select { |cr| valid_ids.include? cr[:id]  }
  end

  def content_tags_visible_to(user, opts={})
    @content_tags_visible_to ||= {}
    @content_tags_visible_to[user.try(:id)] ||= begin
      is_teacher = opts[:is_teacher] != false && self.grants_right?(user, :read_as_admin)
      tags = is_teacher ? cached_not_deleted_tags : cached_active_tags

      if !is_teacher && differentiated_assignments_enabled? && user
        opts[:is_teacher]= false
        tags = filter_tags_for_da(tags, user, opts)
      end

      tags
    end
  end

  def filter_tags_for_da(tags, user, opts={})
    filter = Proc.new{|tags, user_ids, course_id, opts|
      visible_assignments = opts[:assignment_visibilities] || assignment_visibilities_for_users(user_ids)
      visible_discussions = opts[:discussion_visibilities] || discussion_visibilities_for_users(user_ids)
      visible_quizzes = opts[:quiz_visibilities] || quiz_visibilities_for_users(user_ids)
      tags.select{|tag|
        case tag.content_type;
        when 'Assignment'; visible_assignments.include?(tag.content_id);
        when 'DiscussionTopic'; visible_discussions.include?(tag.content_id);
        when *Quizzes::Quiz.class_names; visible_quizzes.include?(tag.content_id);
        else; true; end
      }
    }

    tags = DifferentiableAssignment.filter(tags, user, self.context, opts) do |tags, user_ids|
      filter.call(tags, user_ids, self.context_id, opts)
    end

    tags
  end

  def reload
    clear_cached_lookups
    super
  end

  def clear_cached_lookups
    @cached_active_tags = nil
    @cached_not_deleted_tags = nil
    @content_tags_visible_to = nil
  end

  def cached_active_tags
    @cached_active_tags ||= self.content_tags.active.reload
  end

  def cached_not_deleted_tags
    @cached_not_deleted_tags ||= self.content_tags.not_deleted.reload
  end

  def add_item(params, added_item=nil, opts={})
    params[:type] = params[:type].underscore if params[:type]
    position = opts[:position] || (self.content_tags.not_deleted.maximum(:position) || 0) + 1
    if params[:type] == "wiki_page" || params[:type] == "page"
      item = opts[:wiki_page] || self.context.wiki.wiki_pages.where(id: params[:id]).first
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
      added_item.workflow_state = 'unpublished'
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
      added_item.workflow_state = 'unpublished'
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
      added_item.workflow_state = 'unpublished'
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
      added_item.workflow_state = workflow_state
      added_item.save
      added_item
    end
  end

  def update_for(user, action, tag, points=nil)
    retry_count = 0
    begin
      return nil unless self.context.users.include?(user)
      return nil unless ContextModuleProgression.prerequisites_satisfied?(user, self)
      return nil unless progression = self.find_or_create_progression(user)

      progression.requirements_met ||= []
      if progression.update_requirement_met(action, tag, points)
        # not sure if this save is necessary
        # leaving it for now as it saves the default requirements_met (set above)
        progression.save!
        progression.send_later_if_production(:evaluate)
      end

      progression

    rescue ActiveRecord::StaleObjectError
      raise if retry_count > 10
      retry_count += 1
      retry
    end
  end

  def completion_requirement_for(action, tag)
    self.completion_requirements.to_a.find do |requirement|
      next false unless requirement[:id] == tag.local_id

      case requirement[:type]
      when 'must_view'
        action == :read || action == :contributed
      when 'must_contribute'
        action == :contributed
      when 'must_submit'
        action == :scored || action == :submitted
      when 'min_score'
        action == :scored
      when 'max_score'
        action == :scored
      else
        false
      end
    end
  end

  def self.requirement_description(req)
    case req[:type]
    when 'must_view'
      t('requirements.must_view', "must view the page")
    when 'must_contribute'
      t('requirements.must_contribute', "must contribute to the page")
    when 'must_submit'
      t('requirements.must_submit', "must submit the assignment")
    when 'min_score'
      t('requirements.min_score', "must score at least a %{score}", :score => req[:min_score])
    when 'max_score'
      t('requirements.max_score', "must score no more than a %{score}", :score => req[:max_score])
    else
      nil
    end
  end

  def active_prerequisites
    return [] unless self.prerequisites.any?
    prereq_ids = self.prerequisites.select{|pre|pre[:type] == 'context_module'}.map{|pre| pre[:id] }
    active_ids = self.context.context_modules.active.where(:id => prereq_ids).pluck(:id)
    self.prerequisites.select{|pre| pre[:type] == 'context_module' && active_ids.member?(pre[:id])}
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
      Shackles.activate(:master) do
        self.class.unique_constraint_retry do
          progression = context_module_progressions.where(user_id: user).first
          if !progression
            # check if we should even be creating a progression for this user
            return nil unless context.enrollments.except(:includes).where(user_id: user).exists?
            progression = context_module_progressions.create!(user: user)
          end
        end
      end
    end
    progression.context_module = self
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
    if publish_final_grade?
      callbacks << lambda { |user| context.publish_final_grades(user, user.id) }
    end
    callbacks
  end

  def differentiated_assignments_enabled?
    @differentiated_assignments_enabled ||= context.feature_enabled?(:differentiated_assignments)
  end

  def clear_cached_visibilities
    @content_tags_visible_to = nil
    @assignment_visibilities_by_user = nil
    @discussion_visibilities_by_user = nil
    @quiz_visibilities_by_user = nil
    @differentiated_assignments_enabled = nil
  end

  # call this method before filtering content tags for many users
  # this will avoid an N+1 query when finding individual visibilities
  def cache_visibilities_for_students(student_ids)
    raise "don't call this method without differentiated_assignments enabled" unless differentiated_assignments_enabled?
    @assignment_visibilities_by_user ||= AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(user_id: student_ids, course_id: [context.id])
    @discussion_visibilities_by_user ||= DiscussionTopic.visible_ids_by_user(user_id: student_ids, course_id: [context.id])
    @quiz_visibilities_by_user ||= Quizzes::QuizStudentVisibility.visible_quiz_ids_in_course_by_user(user_id: student_ids, course_id: [context.id])
  end

  # *_visibilities_for_users are preferably used with cache_visibilities_for_students
  # when called in batches
  def assignment_visibilities_for_users(user_ids)
    assignment_visibilities_by_user = @assignment_visibilities_by_user || AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(user_id: user_ids, course_id: [context.id])
    user_ids.flat_map{|id| assignment_visibilities_by_user[id]}
  end

  def discussion_visibilities_for_users(user_ids)
    discussion_visibilities_by_user = @discussion_visibilities_by_user || DiscussionTopic.visible_ids_by_user(user_id: user_ids, course_id: [context.id])
    user_ids.flat_map{|id| discussion_visibilities_by_user[id]}
  end

  def quiz_visibilities_for_users(user_ids)
    quiz_visibilities_by_user = @quiz_visibilities_by_user || Quizzes::QuizStudentVisibility.visible_quiz_ids_in_course_by_user(user_id: user_ids, course_id: [context.id])
    user_ids.flat_map{|id| quiz_visibilities_by_user[id]}
  end
end
