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
  has_many :context_module_progressions, :dependent => :destroy
  has_many :content_tags, :dependent => :destroy, :order => 'content_tags.position, content_tags.title'
  acts_as_list scope: { context: self, workflow_state: ['active', 'unpublished'] }
  
  serialize :prerequisites
  serialize :completion_requirements
  before_save :infer_position
  before_save :validate_prerequisites
  before_save :confirm_valid_requirements
  after_save :touch_context
  validates_presence_of :workflow_state, :context_id, :context_type

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
    self.workflow_state = context.feature_enabled?(:draft_state) ? 'unpublished' : 'active'
    self.save
  end
  
  def update_downstreams(original_position=nil)
    original_position ||= self.position || 0
    positions = ContextModule.module_positions(self.context).to_a.sort_by{|a| a[1] }
    downstream_ids = positions.select{|a| a[1] > (self.position || 0)}.map{|a| a[0] }
    downstreams = downstream_ids.empty? ? [] : self.context.context_modules.not_deleted.find_all_by_id(downstream_ids)
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
  
  scope :active, where(:workflow_state => 'active')
  scope :unpublished, where(:workflow_state => 'unpublished')
  scope :not_deleted, where("context_modules.workflow_state<>'deleted'")

  alias_method :published?, :active?

  def publish_items!
    self.content_tags.select{|t| t.unpublished?}.each do |tag|
      tag.publish
      tag.update_asset_workflow_state!
    end
  end

  def update_student_progressions(user=nil)
    # modules are ordered by position, so running through them in order will
    # automatically handle issues with dependencies loading in the correct
    # order
    modules = ContextModule.order(:position).where(
        :context_type => self.context_type, :context_id => self.context_id, :workflow_state => 'active')
    students = user ? [user] : self.context.students
    modules.each do |mod|
      mod.re_evaluate_for(students, true)
    end
  end
  
  set_policy do
    given {|user, session| self.cached_context_grants_right?(user, session, :manage_content) }
    can :read and can :create and can :update and can :delete
    
    given {|user, session| self.cached_context_grants_right?(user, session, :read) }
    can :read
  end
  
  def locked_for?(user, opts={})
    return false if self.grants_right?(user, nil, :update)
    available = self.available_for?(user, opts)
    return {:asset_string => self.asset_string, :context_module => self.attributes} unless available
    return {:asset_string => self.asset_string, :context_module => self.attributes, :unlock_at => self.unlock_at} if self.to_be_unlocked
    false
  end
  
  def available_for?(user, opts={})
    return true if self.active? && !self.to_be_unlocked && self.prerequisites.blank? && !self.require_sequential_progress
    if self.grants_right?(user, nil, :update)
      return true
    elsif !self.active?
      return false
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
      progression = self.evaluate_for(user, true, true)
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
      res = []
      tag_ids = self.content_tags.active.pluck(:id)
      val.each do |id, opts|
        if tag_ids.include?(id.to_i)
          res << {:id => id.to_i, :type => opts[:type], :min_score => opts[:min_score] && opts[:min_score].to_f, :max_score => opts[:max_score] && opts[:max_score].to_f}
        end
      end
      val = res
    else
      val = nil
    end
    write_attribute(:completion_requirements, val)
  end

  def content_tags_visible_to(user)
    if self.content_tags.loaded?
      if self.grants_right?(user, :update)
        self.content_tags.select{|tag| tag.workflow_state != 'deleted'}
      else
        self.content_tags.select{|tag| tag.workflow_state == 'active'}
      end
    else
      if self.grants_right?(user, :update)
        self.content_tags.not_deleted
      else
        self.content_tags.active
      end
    end
  end

  def add_item(params, added_item=nil, opts={})
    params[:type] = params[:type].underscore if params[:type]
    position = opts[:position] || (self.content_tags.not_deleted.maximum(:position) || 0) + 1
    if params[:type] == "wiki_page" || params[:type] == "page"
      item = opts[:wiki_page] || self.context.wiki.wiki_pages.find_by_id(params[:id])
    elsif params[:type] == "attachment" || params[:type] == "file"
      item = opts[:attachment] || self.context.attachments.active.find_by_id(params[:id])
    elsif params[:type] == "assignment"
      item = opts[:assignment] || self.context.assignments.active.find_by_id(params[:id])
    elsif params[:type] == "discussion_topic" || params[:type] == "discussion"
      item = opts[:discussion_topic] || self.context.discussion_topics.active.find_by_id(params[:id])
    elsif params[:type] == "quiz"
      item = opts[:quiz] || self.context.quizzes.active.find_by_id(params[:id])
    end
    workflow_state = ContentTag.asset_workflow_state(item) if item
    workflow_state ||= 'active'
    if params[:type] == 'external_url'
      title = params[:title]
      added_item ||= self.content_tags.build(:context => self.context)
      added_item.attributes = {
        :url => params[:url],
        :tag_type => 'context_module', 
        :title => title, 
        :indent => params[:indent], 
        :position => position
      }
      added_item.content_id = 0
      added_item.content_type = 'ExternalUrl'
      added_item.context_module_id = self.id
      added_item.indent = params[:indent] || 0
      added_item.workflow_state = (self.context.feature_enabled?(:draft_state) ? 'unpublished' : workflow_state)
      added_item.save
      added_item
    elsif params[:type] == 'context_external_tool' || params[:type] == 'external_tool'
      title = params[:title]
      added_item ||= self.content_tags.build(:context => self.context)
      tool = ContextExternalTool.find_external_tool(params[:url], self.context, params[:id].to_i)
      unless tool
        tool = ContextExternalTool.new
        tool.id = 0
      end
      added_item.attributes = {
        :content => tool,
        :url => params[:url], 
        :new_tab => params[:new_tab],
        :tag_type => 'context_module', 
        :title => title, 
        :indent => params[:indent], 
        :position => position
      }
      added_item.context_module_id = self.id
      added_item.indent = params[:indent] || 0
      added_item.workflow_state = (self.context.feature_enabled?(:draft_state) ? 'unpublished' : workflow_state)
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
      added_item.workflow_state = workflow_state
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
    return nil unless self.context.users.include?(user)
    return nil unless self.prerequisites_satisfied?(user)
    progression = self.find_or_create_progression(user)
    return unless progression
    progression.requirements_met ||= []
    requirement = self.completion_requirements.to_a.find{|p| p[:id] == tag.local_id}
    return if !requirement || progression.requirements_met.include?(requirement)
    met = false
    met = true if requirement[:type] == 'must_view' && (action == :read || action == :contributed)
    met = true if requirement[:type] == 'must_contribute' && action == :contributed
    met = true if requirement[:type] == 'must_submit' && action == :scored
    met = true if requirement[:type] == 'must_submit' && action == :submitted
    met = true if requirement[:type] == 'min_score' && action == :scored && points && points >= requirement[:min_score].to_f
    met = true if requirement[:type] == 'max_score' && action == :scored && points && points <= requirement[:max_score].to_f
    if met
      progression.requirements_met << requirement
    end
    progression.save!
    User.module_progression_job_queued(user.id)
    send_later_if_production :update_student_progressions, user
    progression
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
  

  def prerequisites_satisfied?(user)
    unlocked = (self.active_prerequisites || []).all? do |pre|
      if pre[:type] == 'context_module'
        prog = user.module_progression_for(pre[:id])
        if prog
          prog.completed?
        elsif pre[:id].present?
          if prereq = self.context.context_modules.active.find_by_id(pre[:id])
            prog = prereq.evaluate_for(user, true)
            prog.completed?
          else
            true
          end
        else
          true
        end
      else
        true
      end
    end
    unlocked
  end

  def active_prerequisites
    return [] unless self.prerequisites.any?
    prereq_ids = self.prerequisites.select{|pre|pre[:type] == 'context_module'}.map{|pre| pre[:id] }
    active_ids = self.context.context_modules.active.where(:id => prereq_ids).pluck(:id)
    self.prerequisites.select{|pre| pre[:type] == 'context_module' && active_ids.member?(pre[:id])}
  end
  
  def clear_cached_lookups
    @cached_tags = nil
  end

  def cached_tags
    @cached_tags ||= self.content_tags.active
  end
  
  def re_evaluate_for(users, skip_confirm_valid_requirements=false)
    users = Array(users)
    users.each{|u| u.clear_cached_lookups }
    progressions = self.find_or_create_progressions(users)
    progressions.each(&:mark_as_dirty)
    @already_confirmed_valid_requirements = true if skip_confirm_valid_requirements
    progressions.each do |progression|
      self.evaluate_for(progression, true, true)
    end
  end
  
  def confirm_valid_requirements(do_save=false)
    return if @already_confirmed_valid_requirements
    @already_confirmed_valid_requirements = true
    tags = self.content_tags.active
    new_reqs = []
    changed = false
    (self.completion_requirements || []).each do |req|
      added = false
      if !req[:id]
        
      elsif req[:type] == 'must_view'
        new_reqs << req if tags.any?{|t| t.id == req[:id].to_i }
        added = true
      elsif req[:type] == 'must_contribute'
        new_reqs << req if tags.any?{|t| t.id == req[:id].to_i }
        added = true
      elsif req[:type] == 'must_submit' || req[:type] == 'min_score' || req[:type] == 'max_score'
        tag = tags.detect{|t| t.id == req[:id].to_i }
        new_reqs << req if tag && tag.scoreable?
        added = true
      end
      changed = true if !added
    end
    self.completion_requirements = new_reqs
    self.save if do_save && changed
    new_reqs
  end
  
  def find_or_create_progressions(users)
    users = Array(users)
    users_hash = {}
    users.each{|u| users_hash[u.id] = u }
    progressions = self.context_module_progressions.find_all_by_user_id(users.map(&:id))
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
  
  def find_or_create_progression_with_multiple_lookups(user)
    user.module_progression_for(self.id) || self.find_or_create_progression(user)
  end
  
  def content_tags_hash
    return @tags_hash if @tags_hash
    @tags_hash = {}
    self.content_tags.each{|t| @tags_hash[t.id] = t }
    @tags_hash
  end

  def evaluate_for(user_or_progression, recursive_check=false, deep_check=false)
    if user_or_progression.is_a?(ContextModuleProgression)
      progression, user = [user_or_progression, user_or_progression.user]
    else
      progression, user = [self.find_or_create_progression_with_multiple_lookups(user_or_progression), user_or_progression] if user_or_progression
    end
    return nil unless progression && user

    progression.context_module = self if progression.context_module_id == self.id
    progression.user = user if progression.user_id == user.id
    progression.evaluate(recursive_check, deep_check)
    progression
  end

  def to_be_unlocked
    self.unlock_at && self.unlock_at > Time.now
  end

  def self.process_migration(data, migration)
    modules = data['modules'] ? data['modules'] : []
    modules.each do |mod|
      if migration.import_object?("context_modules", mod['migration_id']) || migration.import_object?("modules", mod['migration_id'])
        begin
          import_from_migration(mod, migration.context)
        rescue
          migration.add_import_warning(t('#migration.module_type', "Module"), mod[:title], $!)
        end
      end
    end
    migration.context.context_modules.first.try(:fix_position_conflicts)
    migration.context.touch
  end
  
  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:modules_to_import] && !hash[:modules_to_import][hash[:migration_id]]
    item ||= find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, hash[:id])
    item ||= find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, hash[:migration_id]) if hash[:migration_id]
    item ||= new(:context => context)
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item.name = hash[:title] || hash[:description]
    item.migration_id = hash[:migration_id]
    if hash[:workflow_state] == 'unpublished'
      item.workflow_state = 'unpublished'
    else
      item.workflow_state = 'active'
    end

    item.position = hash[:position] || hash[:order]
    item.context = context
    item.unlock_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:unlock_at]) if hash[:unlock_at]
    item.start_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:start_at]) if hash[:start_at]
    item.end_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:end_at]) if hash[:end_at]
    item.require_sequential_progress = hash[:require_sequential_progress] if hash[:require_sequential_progress]

    if hash[:prerequisites]
      preqs = []
      hash[:prerequisites].each do |prereq|
        if prereq[:module_migration_id]
          if ref_mod = find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, prereq[:module_migration_id])
            preqs << {:type=>"context_module", :name=>ref_mod.name, :id=>ref_mod.id}
          end
        end
      end
      item.prerequisites = preqs if preqs.length > 0
    end
    
    # Clear the old tags to be replaced by new ones
    item.content_tags.destroy_all
    item.save!
    
    item_map = {}
    @item_migration_position = item.content_tags.not_deleted.map(&:position).compact.max || 0
    (hash[:items] || []).each do |tag_hash|
      begin
        item.add_item_from_migration(tag_hash, 0, context, item_map)
      rescue
        context.content_migration.add_import_warning(t(:migration_module_item_type, "Module Item"), tag_hash[:title], $!) if context.content_migration
      end
    end
    
    if hash[:completion_requirements]
      c_reqs = []
      hash[:completion_requirements].each do |req|
        if item_ref = item_map[req[:item_migration_id]]
          req[:id] = item_ref.id
          req.delete :item_migration_id
          c_reqs << req
        end
      end
      if c_reqs.length > 0
        item.completion_requirements = c_reqs
        item.save
      end
    end

    item
  end
  
  def migration_position
    @migration_position_counter ||= 0
    @migration_position_counter = @migration_position_counter + 1
  end
  
  def add_item_from_migration(hash, level, context, item_map)
    hash = hash.with_indifferent_access
    hash[:migration_id] ||= hash[:item_migration_id]
    hash[:migration_id] ||= Digest::MD5.hexdigest(hash[:title]) if hash[:title]
    existing_item = content_tags.find_by_id(hash[:id]) if hash[:id].present?
    existing_item ||= content_tags.find_by_migration_id(hash[:migration_id]) if hash[:migration_id]
    existing_item ||= content_tags.new(:context => context)
    if hash[:workflow_state] == 'unpublished'
      existing_item.workflow_state = 'unpublished'
    else
      existing_item.workflow_state = 'active'
    end
    context.imported_migration_items << existing_item if context.imported_migration_items && existing_item.new_record?
    existing_item.migration_id = hash[:migration_id]
    hash[:indent] = [hash[:indent] || 0, level].max
    if hash[:linked_resource_type] =~ /wiki_type|wikipage/i
      wiki = self.context.wiki.wiki_pages.find_by_migration_id(hash[:linked_resource_id]) if hash[:linked_resource_id]
      if wiki
        item = self.add_item({
          :title => hash[:title] || hash[:linked_resource_title],
          :type => 'wiki_page',
          :id => wiki.id,
          :indent => hash[:indent].to_i
        }, existing_item, :wiki_page => wiki, :position => migration_position)
      end
    elsif hash[:linked_resource_type] =~ /page_type|file_type|attachment/i
      # this is a file of some kind
      file = self.context.attachments.active.find_by_migration_id(hash[:linked_resource_id]) if hash[:linked_resource_id]
      if file
        title = hash[:title] || hash[:linked_resource_title]
        item = self.add_item({
          :title => title,
          :type => 'attachment',
          :id => file.id,
          :indent => hash[:indent].to_i
        }, existing_item, :attachment => file, :position => migration_position)
      end
    elsif hash[:linked_resource_type] =~ /assignment|project/i
      # this is a file of some kind
      ass = self.context.assignments.find_by_migration_id(hash[:linked_resource_id]) if hash[:linked_resource_id]
      if ass
        item = self.add_item({
          :title => hash[:title] || hash[:linked_resource_title],
          :type => 'assignment',
          :id => ass.id,
          :indent => hash[:indent].to_i
        }, existing_item, :assignment => ass, :position => migration_position)
      end
    elsif (hash[:linked_resource_type] || hash[:type]) =~ /folder|heading|contextmodulesubheader/i
      # just a snippet of text
      item = self.add_item({
        :title => hash[:title] || hash[:linked_resource_title],
        :type => 'context_module_sub_header',
        :indent => hash[:indent].to_i
      }, existing_item, :position => migration_position)
    elsif hash[:linked_resource_type] =~ /url/i
      # external url
      if hash['url']
        item = self.add_item({
          :title => hash[:title] || hash[:linked_resource_title] || hash['description'],
          :type => 'external_url',
          :indent => hash[:indent].to_i,
          :url => hash['url']
        }, existing_item, :position => migration_position)
      end
    elsif hash[:linked_resource_type] =~ /contextexternaltool/i
      # external tool
      external_tool_id = nil
      if hash[:linked_resource_global_id]
        external_tool_id = hash[:linked_resource_global_id]
      elsif hash[:linked_resource_id] && et = self.context.context_external_tools.active.find_by_migration_id(hash[:linked_resource_id])
        external_tool_id = et.id
      end
      if hash['url']
        item = self.add_item({
          :title => hash[:title] || hash[:linked_resource_title] || hash['description'],
          :type => 'context_external_tool',
          :indent => hash[:indent].to_i,
          :url => hash['url'],
          :id => external_tool_id
        }, existing_item, :position => migration_position)
      end
    elsif hash[:linked_resource_type] =~ /assessment|quiz/i
      quiz = self.context.quizzes.find_by_migration_id(hash[:linked_resource_id]) if hash[:linked_resource_id]
      if quiz
        item = self.add_item({
          :title => hash[:title] || hash[:linked_resource_title],
          :type => 'quiz',
          :indent => hash[:indent].to_i,
          :id => quiz.id
        }, existing_item, :quiz => quiz, :position => migration_position)
      end
    elsif hash[:linked_resource_type] =~ /discussion|topic/i
      topic = self.context.discussion_topics.find_by_migration_id(hash[:linked_resource_id]) if hash[:linked_resource_id]
      if topic
        item = self.add_item({
          :title => hash[:title] || hash[:linked_resource_title],
          :type => 'discussion_topic',
          :indent => hash[:indent].to_i,
          :id => topic.id
        }, existing_item, :discussion_topic => topic, :position => migration_position)
      end
    elsif hash[:linked_resource_type] == 'UNSUPPORTED_TYPE'
      # We know what this is and that we don't support it
    else
      # We don't know what this is
    end
    if item
      item_map[hash[:migration_id]] = item if hash[:migration_id]
      item.migration_id = hash[:migration_id]
      item.new_tab = hash[:new_tab]
      item.position = (@item_migration_position ||= self.content_tags.not_deleted.map(&:position).compact.max || 0)
      item.workflow_state = 'active'
      @item_migration_position += 1
      item.save!
    end
    if hash[:sub_items]
      hash[:sub_items].each do |tag_hash|
        self.add_item_from_migration(tag_hash, level + 1, context, item_map)
      end
    end
    item
  end

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
end
