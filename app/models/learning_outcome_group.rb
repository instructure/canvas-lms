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

class LearningOutcomeGroup < ActiveRecord::Base
  include Workflow
  attr_accessible :context, :title, :description, :learning_outcome_group
  belongs_to :learning_outcome_group
  has_many :learning_outcome_groups
  has_many :content_tags, :as => :associated_asset, :order => :position
  belongs_to :context, :polymorphic => true
  before_save :infer_defaults
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  sanitize_field :description, Instructure::SanitizeField::SANITIZE
  
  def infer_defaults
    self.context ||= self.learning_outcome_group && self.learning_outcome_group.context
    if self.context && !self.context.learning_outcome_groups.empty?
      self.learning_outcome_group ||= LearningOutcomeGroup.default_for(self.context) rescue nil
      self.root_learning_outcome_group ||= LearningOutcomeGroup.default_for(self.context) rescue nil
    end
    true
  end
  
  workflow do
    state :active
    state :deleted
  end
  
  def sorted_content(outcome_ids=[])
    tags = self.content_tags.active
    positions = {}
    tags.each{|t| positions[t.content_asset_string] = t.position }
    ids_to_find = tags.select{|t| t.content_type == 'LearningOutcome'}.map(&:content_id)
    ids_to_find = (ids_to_find & outcome_ids) unless outcome_ids.empty?
    objects = LearningOutcome.active.find_all_by_id(ids_to_find).compact
    objects += LearningOutcomeGroup.active.find_all_by_id(tags.select{|t| t.content_type == 'LearningOutcomeGroup'}.map(&:content_id)).compact
    if self.learning_outcome_group_id == nil
      all_tags = all_tags_for_context
      codes = all_tags.map(&:content_asset_string).uniq
      all_objects = LearningOutcome.active.find_all_by_id_and_context_id_and_context_type(outcome_ids, self.context_id, self.context_type).select{|o| !codes.include?(o.asset_string) } unless outcome_ids.empty?
      all_objects ||= LearningOutcome.active.find_all_by_context_id_and_context_type(self.context_id, self.context_type).select{|o| !codes.include?(o.asset_string) }
      objects += all_objects
    end
    sorted_objects = objects.uniq.sort_by{|o| positions[o.asset_string] || 999 }
  end
  
  def sorted_all_outcomes(ids=[])
    res = []
    self.sorted_content(ids).each do |obj|
      if obj.is_a?(LearningOutcome)
        res << obj
      else
        res += obj.sorted_all_outcomes(ids)
      end
    end
    res.uniq.compact
  end
  
  def reorder_content(orders)
    orders ||= {}
    all_tags = all_tags_for_context
    orders = orders.sort_by{|asset_string, position| position.to_i }.map{|asset_string, position| asset_string}
    orders += self.content_tags.active.map(&:content_asset_string)
    ordered = []
    updates = []
    orders.compact.uniq.each_with_index do |asset_string, idx|
      tag = all_tags.detect{|t| t.content_asset_string == asset_string }
      if !tag
        tag ||= ContentTag.new(:content_asset_string => asset_string)
        tag.context = self.context
        tag.associated_asset = self
        tag.tag_type = 'learning_outcome_association'
        tag.save!
      end
      tag.position  = idx + 1
      updates << "WHEN id=#{tag.id} THEN #{tag.position || 999}"
      ordered << tag
    end
    sql = "UPDATE content_tags SET associated_asset_id=#{self.id}, position=CASE #{updates.join(" ")} ELSE position END WHERE id IN (#{ordered.map(&:id).join(",")})"
    ActiveRecord::Base.connection.execute(sql) unless updates.empty?
    ordered
  end
  
  def all_tags_for_context
    self.context.learning_outcome_tags.active
 end
  
  def add_item(item, opts={})
    if item.is_a?(LearningOutcome)
      all_tags = all_tags_for_context
      tag = all_tags.detect{|t| t.content_asset_string == item.asset_string }
      tag ||= ContentTag.new(:content_asset_string => item.asset_string)
      tag.context = self.context
      tag.position ||= (self.content_tags.map(&:position).compact.max || 0) + 1
      tag.tag_type = 'learning_outcome_association'
      tag.associated_asset = self
      tag.save!
      tag
    elsif item.is_a?(LearningOutcomeGroup)
      all_tags = all_tags_for_context
      tag = all_tags.detect{|t| t.content_asset_string == item.asset_string }
      if !tag
        group = item
        if item.context != self.context
          group = self.learning_outcome_groups.build
          group.title = item.title
          group.learning_outcome_group_id = self.id
          group.description = item.description
          group.context = self.context
          group.save!
        end
        tag = ContentTag.new(:content_asset_string => group.asset_string)
      end
      tag.context = self.context
      tag.position ||= (self.content_tags.map(&:position).compact.max || 0) + 1
      tag.tag_type = 'learning_outcome_association'
      tag.associated_asset = self
      tag.save!
      group = tag.content
      outcomes = LearningOutcome.find_all_by_id(item.content_tags.select{|t| t.content_type == 'LearningOutcome'}.map(&:content_id))
      outcomes.each{|o| group.add_item(o) if !opts[:only] || opts[:only][o.id] == "1"  }
      tag
    end
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    ContentTag.delete_for(self)
    # also delete any tags for held outcomes
    # if we really do multi-nesting, you'll need it for sub-groups as well
    LearningOutcome.delete_if_unused(self.content_tags.select{|t| t.content_type == 'LearningOutcome'}.map(&:content_id))
    save!
  end
  
  def self.default_for(context)
    outcome = LearningOutcomeGroup.find_or_create_by_context_type_and_context_id_and_learning_outcome_group_id(context.class.to_s, context.id, nil)
    outcome.root_learning_outcome_group_id ||= outcome.id
    outcome.save if outcome.changed?
    outcome
  end
  
  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    item ||= find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
    item ||= context.learning_outcome_groups.new
    item.context = context
    item.migration_id = hash[:migration_id]
    item.title = hash[:title]
    item.description = hash[:description]
    
    item.save!
    
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?

    if hash[:outcomes]
      hash[:outcomes].each do |outcome|
        outcome[:learning_outcome_group] = item
        LearningOutcome.import_from_migration(outcome, context)
      end
    end
    
    log = LearningOutcomeGroup.default_for(context)
    log.add_item(item)

    item
  end
  
  named_scope :active, lambda{
    {:conditions => ['learning_outcome_groups.workflow_state != ?', 'deleted'] }
  }
end
