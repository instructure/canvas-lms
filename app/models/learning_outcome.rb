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

class LearningOutcome < ActiveRecord::Base
  include Workflow
  attr_accessible :context, :description, :short_description, :title, :rubric_criterion, :vendor_guid
  belongs_to :context, :polymorphic => true
  has_many :learning_outcome_results
  has_many :alignments, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND content_tags.workflow_state != ?', 'learning_outcome', 'deleted']
  serialize :data
  before_save :infer_defaults
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :short_description, :maximum => maximum_string_length
  validates_presence_of :short_description, :workflow_state
  sanitize_field :description, Instructure::SanitizeField::SANITIZE

  set_policy do
    # managing a contextual outcome requires manage_outcomes on the outcome's context
    given {|user, session| self.context_id && self.cached_context_grants_right?(user, session, :manage_outcomes) }
    can :create and can :read and can :update and can :delete

    # reading a contextual outcome is also allowed by read_outcomes on the outcome's context
    given {|user, session| self.context_id && self.cached_context_grants_right?(user, session, :read_outcomes) }
    can :read

    # managing a global outcome requires manage_global_outcomes on the site_admin
    given {|user, session| self.context_id.nil? && Account.site_admin.grants_right?(user, session, :manage_global_outcomes) }
    can :create and can :read and can :update and can :delete

    # reading a global outcome is also allowed by just being logged in
    given {|user, session| self.context_id.nil? && user }
    can :read
  end
  
  def infer_defaults
    if self.data && self.data[:rubric_criterion]
      self.data[:rubric_criterion][:description] = self.short_description
    end
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  def align(asset, context, opts={})
    tag = self.alignments.find_by_content_id_and_content_type_and_tag_type_and_context_id_and_context_type(asset.id, asset.class.to_s, 'learning_outcome', context.id, context.class.to_s)
    tag ||= self.alignments.create(:content => asset, :tag_type => 'learning_outcome', :context => context)
    mastery_type = opts[:mastery_type]
    if mastery_type == 'points'
      mastery_type = 'points_mastery'
    else
      mastery_type = 'explicit_mastery'
    end
    tag.tag = mastery_type
    tag.position = (self.alignments.map(&:position).compact.max || 1) + 1
    tag.mastery_score = opts[:mastery_score] if opts[:mastery_score]
    tag.save
    tag
  end
  
  def reorder_alignments(context, order)
    order_hash = {}
    order.each_with_index{|o, i| order_hash[o.to_i] = i; order_hash[o] = i }
    tags = self.alignments.find_all_by_context_id_and_context_type_and_tag_type(context.id, context.class.to_s, 'learning_outcome')
    tags = tags.sort_by{|t| order_hash[t.id] || order_hash[t.content_asset_string] || SortLast }
    updates = []
    tags.each_with_index do |tag, idx|
      tag.position = idx + 1
      updates << "WHEN id=#{tag.id} THEN #{idx + 1}"
    end
    ContentTag.where(:id => tags).update_all("position=CASE #{updates.join(" ")} ELSE position END")
    self.touch
    tags
  end
  
  def remove_alignment(asset, context, opts={})
    tag = self.alignments.find_by_content_id_and_content_type_and_tag_type_and_context_id_and_context_type(asset.id, asset.class.to_s, 'learning_outcome', context.id, context.class.to_s)
    tag.destroy if tag
    tag
  end

  def self.update_alignments(asset, context, new_outcome_ids)
    old_outcome_ids = asset.learning_outcome_alignments.
      where("learning_outcome_id IS NOT NULL").
      pluck(:learning_outcome_id).
      uniq

    defunct_outcome_ids = old_outcome_ids - new_outcome_ids
    unless defunct_outcome_ids.empty?
      asset.learning_outcome_alignments.
        where(:learning_outcome_id => defunct_outcome_ids).
        update_all(:workflow_state => 'deleted')
    end

    missing_outcome_ids = new_outcome_ids - old_outcome_ids
    unless missing_outcome_ids.empty?
      LearningOutcome.find_all_by_id(missing_outcome_ids).each do |learning_outcome|
        learning_outcome.align(asset, context)
      end
    end
  end

  def title
    self.short_description
  end

  def title=(new_title)
    self.short_description = new_title
  end
  
  workflow do
    state :active
    state :retired
    state :deleted
  end
  
  scope :active, where("workflow_state<>'deleted'")

  def cached_context_short_name
    @cached_context_name ||= Rails.cache.fetch(['short_name_lookup', self.context_code].cache_key) do
      self.context.short_name rescue ""
    end
  end
  
  def rubric_criterion=(hash)
    self.data ||= {}

    if hash
      criterion = {}
      criterion[:description] = hash[:description] || t(:no_description, "No Description")
      criterion[:ratings] = []
      ratings = hash[:enable] ? hash[:ratings].values : (hash[:ratings] || [])
      ratings.each do |rating|
        criterion[:ratings] << {
          :description => rating[:description] || t(:no_comment, "No Comment"),
          :points => rating[:points].to_f || 0
        }
      end
      criterion[:ratings] = criterion[:ratings].sort_by{|r| r[:points] }.reverse
      criterion[:mastery_points] = (hash[:mastery_points] || criterion[:ratings][0][:points]).to_f
      criterion[:points_possible] = criterion[:ratings][0][:points] rescue 0
    else
      criterion = nil
    end

    self.data[:rubric_criterion] = criterion
  end

  alias_method :destroy!, :destroy
  def destroy
    # delete any remaining links to the outcome. in case of UI, this was
    # triggered by ContentTag#destroy and the checks have already run, we don't
    # need to do it again. in case of console, we don't care to force the
    # checks. so just an update_all of workflow_state will do.
    ContentTag.learning_outcome_links.active.where(:content_id => self).update_all(:workflow_state => 'deleted')

    # in case this got called in a console, delete the alignments also. the UI
    # won't (shouldn't) allow deleting the outcome if there are still
    # alignments, so this will be a no-op in that case. either way, these are
    # not outcome links, so ContentTag#destroy is just changing the
    # workflow_state; use update_all for efficiency.
    ContentTag.learning_outcome_alignments.active.where(:learning_outcome_id => self).update_all(:workflow_state => 'deleted')

    self.workflow_state = 'deleted'
    save!
  end
  
  def tie_to(context)
    @tied_context = context
  end
  
  def artifacts_count_for_tied_context
    codes = [@tied_context.asset_string]
    if @tied_context.is_a?(Account)
      if @tied_context == context
        codes = "all"
      else
        codes = @tied_context.all_courses.select(:id).map(&:asset_string)
      end
    end
    self.learning_outcome_results.for_context_codes(codes).count
  end

  def self.delete_if_unused(ids)
    tags = ContentTag.active.find_all_by_content_id_and_content_type(ids, 'LearningOutcome')
    to_delete = []
    ids.each do |id|
      to_delete << id unless tags.any?{|t| t.content_id == id }
    end
    LearningOutcome.where(:id => to_delete).update_all(:workflow_state => 'deleted', :updated_at => Time.now.utc)
  end
  
  def self.process_migration(data, migration)
    outcomes = data['learning_outcomes'] ? data['learning_outcomes'] : []
    migration.outcome_to_id_map = {}
    outcomes.each do |outcome|
      begin
        if outcome[:type] == 'learning_outcome_group'
          LearningOutcomeGroup.import_from_migration(outcome, migration)
        else
          LearningOutcome.import_from_migration(outcome, migration)
        end
      rescue
        migration.add_import_warning(t('#migration.learning_outcome_type', "Learning Outcome"), outcome[:title], $!)
      end
    end
  end

  def self.import_from_migration(hash, migration, item=nil)
    context = migration.context
    hash = hash.with_indifferent_access
    outcome = nil
    if !item && hash[:external_identifier]
      if hash[:is_global_outcome]
        outcome = LearningOutcome.active.find_by_id_and_context_id(hash[:external_identifier], nil)
      else
        outcome = context.available_outcome(hash[:external_identifier])
      end
      
      if outcome
        # Help prevent linking to the wrong outcome if copying into a different install of canvas
        outcome = nil if outcome.short_description != hash[:title]
      end
      
      if !outcome
        migration.add_warning(t(:no_context_found, %{The external Learning Outcome couldn't be found for "%{title}", creating a copy.}, :title => hash[:title]))
      end
    end
    
    if !outcome
      if hash[:is_global_standard]
        if Account.site_admin.grants_right?(migration.user, :manage_global_outcomes)
          # import from vendor with global outcomes
          context = nil
          hash[:learning_outcome_group] ||= LearningOutcomeGroup.global_root_outcome_group
          item ||= LearningOutcome.global.find_by_migration_id(hash[:migration_id]) if hash[:migration_id]
          item ||= LearningOutcome.global.find_by_vendor_guid(hash[:vendor_guid]) if hash[:vendor_guid]
          item ||= LearningOutcome.new
        else
          migration.add_warning(t(:no_global_permission, %{You're not allowed to manage global outcomes, can't add "%{title}"}, :title => hash[:title]))
          return
        end
      else
        item ||= find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
        item ||= context.created_learning_outcomes.new
        item.context = context
      end
      item.migration_id = hash[:migration_id]
      item.vendor_guid = hash[:vendor_guid]
      item.low_grade = hash[:low_grade]
      item.high_grade = hash[:high_grade]
      item.workflow_state = 'active' if item.deleted?
      item.short_description = hash[:title]
      item.description = hash[:description]
      
      if hash[:ratings]
        item.data = {:rubric_criterion=>{}}
        item.data[:rubric_criterion][:ratings] = hash[:ratings] ? hash[:ratings].map(&:symbolize_keys) : []
        item.data[:rubric_criterion][:mastery_points] = hash[:mastery_points]
        item.data[:rubric_criterion][:points_possible] = hash[:points_possible]
        item.data[:rubric_criterion][:description] = item.short_description || item.description
      end
      
      item.save!
      context.imported_migration_items << item if context && context.imported_migration_items && item.new_record?
    else
      item = outcome
    end
    
    log = hash[:learning_outcome_group] || context.root_outcome_group
    log.add_outcome(item)
    
    migration.outcome_to_id_map[hash[:migration_id]] = item.id

    item
  end

  scope :for_context_codes, lambda { |codes| where(:context_code => codes) }
  scope :active, where("learning_outcomes.workflow_state<>'deleted'")
  scope :has_result_for, lambda { |user|
    joins(:learning_outcome_results).
        where("learning_outcomes.id=learning_outcome_results.learning_outcome_id AND learning_outcome_results.user_id=?", user).
        order(best_unicode_collation_key('short_description'))
  }

  scope :global, where(:context_id => nil)
end
