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
  attr_accessible :context, :description, :short_description, :rubric_criterion
  belongs_to :context, :polymorphic => true
  has_many :learning_outcome_results
  has_many :content_tags, :order => :position
  has_many :learning_outcome_group_associations, :as => :content, :class_name => 'ContentTag'
  serialize :data
  before_save :infer_defaults
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  sanitize_field :description, Instructure::SanitizeField::SANITIZE

  set_policy do
    given {|user, session| self.cached_context_grants_right?(user, session, :manage_outcomes) }
    can :create and can :read and can :update and can :delete
  end
  
  def infer_defaults
    if self.data && self.data[:rubric_criterion]
      self.data[:rubric_criterion][:description] = self.short_description
    end
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  def align(asset, context, opts={})
    tag = self.content_tags.find_by_content_id_and_content_type_and_tag_type_and_context_id_and_context_type(asset.id, asset.class.to_s, 'learning_outcome', context.id, context.class.to_s)
    tag ||= self.content_tags.create(:content => asset, :tag_type => 'learning_outcome', :context => context)
    mastery_type = opts[:mastery_type]
    if mastery_type == 'points'
      mastery_type = 'points_mastery'
    else
      mastery_type = 'explicit_mastery'
    end
    tag.tag = mastery_type
    tag.position = (self.content_tags.map(&:position).compact.max || 1) + 1
    tag.save
    tag
  end
  
  def reorder_alignments(context, order)
    order_hash = {}
    order.each_with_index{|o, i| order_hash[o.to_i] = i; order_hash[o] = i }
    tags = self.content_tags.find_all_by_context_id_and_context_type_and_tag_type(context.id, context.class.to_s, 'learning_outcome')
    tags = tags.sort_by{|t| order_hash[t.id] || order_hash[t.content_asset_string] || 999 }
    updates = []
    tags.each_with_index do |tag, idx|
      tag.position = idx + 1
      updates << "WHEN id=#{tag.id} THEN #{idx + 1}"
    end
    ContentTag.connection.execute("UPDATE content_tags SET position=CASE #{updates.join(" ")} ELSE position END WHERE id IN (#{tags.map(&:id).join(",")})")
    self.touch
    tags
  end
  
  def remove_alignment(asset, context, opts={})
    tag = self.content_tags.find_by_content_id_and_content_type_and_tag_type_and_context_id_and_context_type(asset.id, asset.class.to_s, 'learning_outcome', context.id, context.class.to_s)
    tag.destroy if tag
    tag
  end
  
  workflow do
    state :active
    state :retired
    state :deleted
  end
  
  named_scope :active, lambda{
    {:conditions => ['workflow_state != ?', 'deleted'] }
  }
  
  def cached_context_short_name
    @cached_context_name ||= Rails.cache.fetch(['short_name_lookup', self.context_code].cache_key) do
      self.context.short_name rescue ""
    end
  end
  
  def rubric_criterion=(hash)
    criterion = {}
    if hash[:enable] != '1'
      self.data ||= {}
      self.data[:rubric_criterion] = nil
      return
    end
    criterion[:description] = hash[:description] || t(:no_description, "No Description")
    criterion[:ratings] = []
    (hash[:ratings] || []).each do |key, rating|
      criterion[:ratings] << {
        :description => rating[:description] || t(:no_comment, "No Comment"),
        :points => rating[:points].to_f || 0
      }
    end
    criterion[:ratings] = criterion[:ratings].sort_by{|r| r[:points] }.reverse
    criterion[:mastery_points] = (hash[:mastery_points] || criterion[:ratings][0][:points]).to_f
    criterion[:points_possible] = criterion[:ratings][0][:points] rescue 0
    self.data ||= {}
    self.data[:rubric_criterion] = criterion
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    ContentTag.delete_for(self)
    ContentTag.find_all_by_learning_outcome_id(self.id).each{|t| t.destroy }
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
        codes = @tied_context.all_courses.scoped({:select => 'id'}).map(&:asset_string)
      end
    end
    self.learning_outcome_results.for_context_codes(codes).count
  end
  
  def clone_for(context, parent)
    lo = context.learning_outcomes.new
    lo.context = context
    lo.short_description = self.short_description
    lo.description = self.description
    lo.data = self.data
    lo.save
    parent.add_item(lo)
    
    lo
  end
  
  def self.available_in_context(context, ids=[])
    account_contexts = context.associated_accounts rescue []
    codes = account_contexts.map(&:asset_string)
    order = {}
    codes.each_with_index{|c, idx| order[c] = idx }
    outcomes = []
    ([context] + account_contexts).uniq.each do |context|
      outcomes += LearningOutcomeGroup.default_for(context).try(:sorted_all_outcomes, ids) || []
    end
    outcomes.uniq
  end
  
  def self.non_rubric_outcomes?
    false
  end
  
  def self.delete_if_unused(ids)
    tags = ContentTag.active.find_all_by_content_id_and_content_type(ids, 'LearningOutcome')
    to_delete = []
    ids.each do |id|
      to_delete << id unless tags.any?{|t| t.content_id == id }
    end
    LearningOutcome.update_all({:workflow_state => 'deleted', :updated_at => Time.now.utc}, {:id => to_delete})
  end
  
  def self.enabled?
    true
  end

  def self.process_migration(data, migration)
    outcomes = data['learning_outcomes'] ? data['learning_outcomes'] : []
    outcomes.each do |outcome|
      begin
        if outcome[:type] == 'learning_outcome_group'
          LearningOutcomeGroup.import_from_migration(outcome, migration.context)
        else
          import_from_migration(outcome, migration.context)
        end
      rescue
        migration.add_warning("Couldn't import learning outcome \"#{outcome[:title]}\"", $!)
      end
    end
  end

  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    item ||= find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
    item ||= context.learning_outcomes.new
    item.context = context
    item.migration_id = hash[:migration_id]
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
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    
    log = hash[:learning_outcome_group] || LearningOutcomeGroup.default_for(context)
    log.add_item(item)

    item
  end
  
  named_scope :for_context_codes, lambda{|codes| 
    {:conditions => {:context_code => Array(codes)} }
  }
  named_scope :active, lambda{
    {:conditions => ['learning_outcomes.workflow_state != ?', 'deleted'] }
  }
  named_scope :has_result_for, lambda{|user|
    {:joins => [:learning_outcome_results],
     :conditions => ['learning_outcomes.id = learning_outcome_results.learning_outcome_id AND learning_outcome_results.user_id = ?', user.id],
     :order => 'short_description'
    }
  }
end
