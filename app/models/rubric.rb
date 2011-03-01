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

class Rubric < ActiveRecord::Base
  include Workflow
  attr_accessible :user, :rubric, :context, :points_possible, :title, :description, :reusable, :public, :free_form_criterion_comments, :hide_score_total
  belongs_to :user
  belongs_to :rubric # based on another rubric
  belongs_to :context, :polymorphic => true
  has_many :rubric_associations, :class_name => 'RubricAssociation', :dependent => :destroy
  has_many :rubric_assessments, :through => :rubric_associations, :dependent => :destroy
  has_many :learning_outcome_tags, :as => :content, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND workflow_state != ?', 'learning_outcome', 'deleted'], :include => :learning_outcome
  adheres_to_policy
  before_save :default_values
  after_save :update_outcome_tags
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  
  serialize :data
  simply_versioned
  
  named_scope :publicly_reusable, lambda {
    {:conditions => {:reusable => true}, :order => :title}
  }
  named_scope :matching, lambda {|search|
    {:order => 'rubrics.association_count DESC', :conditions => wildcard('rubrics.title', search)}
  }
  named_scope :before, lambda{|date|
    {:conditions => ['rubrics.created_at < ?', date]}
  }
  named_scope :active, lambda{
    {:conditions => ['workflow_state != ?', 'deleted'] }
  }
  
  set_policy do
    given {|user, session| self.cached_context_grants_right?(user, session, :manage_grades)}
    set {can :read and can :create and can :delete_associations }
    
    given {|user, session| self.cached_context_grants_right?(user, session, :manage_assignments)}
    set {can :read and can :create and can :delete_associations }
    
    given {|user, session| self.cached_context_grants_right?(user, session, :manage)}
    set {can :read and can :create and can :delete_associations }
    
    given {|user, session| !self.read_only && self.rubric_associations.for_grading.length < 2 && self.cached_context_grants_right?(user, session, :manage_assignments)}
    set {can :update and can :delete }
    
    given {|user, session| !self.read_only && self.rubric_associations.for_grading.length < 2 && self.cached_context_grants_right?(user, session, :manage_grades)}
    set {can :update and can :delete }

    given {|user, session| self.cached_context_grants_right?(user, session, :manage_assignments)}
    set {can :delete }
    
    given {|user, session| self.cached_context_grants_right?(user, session, :manage_grades)}
    set {can :delete }

    given {|user, session| self.cached_context_grants_right?(user, session, :read) }
    set {can :read }
  end
  
  workflow do
    state :active
    state :deleted
  end
  
  def default_values
    original_title = self.title
    cnt = 0
    while Rubric.find(:first, :conditions => ['context_id = ? AND context_type = ? AND id != ? AND title = ?', self.context_id, self.context_type, self.id, self.title])
      cnt += 1
      self.title = "#{original_title} (#{cnt})"
    end
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  alias_method :destroy!, :destroy
  def destroy
    RubricAssociation.update_all({:bookmarked => false, :updated_at => Time.now}, {:rubric_id => self.id})
    self.workflow_state = 'deleted'
    self.save
  end
  
  def restore
    self.workflow_state = 'active'
    self.save
  end
  
  def destroy_for(context)
    RubricAssociation.update_all({:bookmarked => false, :updated_at => Time.now}, {:rubric_id => self.id, :context_id => context.id, :context_type => context.class.to_s})
    if !self.read_only && self.rubric_associations.for_grading.length < 2
      self.destroy
    end
  end
  
  def update_outcome_tags
    return unless @outcomes_changed
    ids = (self.data || []).map{|c| c[:learning_outcome_id] }.compact.map(&:to_i).uniq
    tags = self.learning_outcome_tags
    tag_outcome_ids = tags.map(&:learning_outcome_id).compact.uniq
    outcomes = LearningOutcome.find(ids)
    missing_ids = ids.select{|id| !tag_outcome_ids.include?(id) }
    tags_to_delete = tags.select{|t| !ids.include?(t.learning_outcome_id) }
    missing_ids.each do |id|
      self.learning_outcome_tags.create!(:learning_outcome_id => id, :context => self.context, :tag_type => 'learning_outcome')
    end
    tags_to_delete.each{|t| t.destroy }
    true
  end
  
  def criteria_object
    OpenObject.process(self.data)
  end
  
  def display_name
    res = ""
    res += self.user.name + ", " rescue ""
    res += self.context.name rescue ""
    res = "Unknown Details" if res.empty?
    res
  end

  def criteria
    self.data
  end
  
  def associate_with(association, context, opts={})
    if opts[:purpose] == "grading"
      res = self.rubric_associations.find_by_association_id_and_association_type_and_purpose(association.id, association.class.to_s, 'grading')
      return res if res
    elsif opts[:update_if_existing]
      res = self.rubric_associations.find_by_association_id_and_association_type(association.id, association.class.to_s)
      return res if res
    end
    purpose = opts[:purpose] || "unknown"
    self.rubric_associations.create(:association => association, :context => context, :use_for_grading => !!opts[:use_for_grading], :purpose => purpose)
  end
  
  def clone_for_association(current_user, association, rubric_params, association_params, invitees="")
    rubric = Rubric.new
    self.attributes.delete_if{|k, v| false}.each do |key, value|
      rubric.send("#{key}=", value) if rubric.respond_to?(key)
    end
    rubric.migration_id = "cloned_from_#{self.id}"
    rubric.rubric_id = self.id
    rubric.free_form_criterion_comments = rubric_params[:free_form_criterion_comments] == '1' if rubric_params[:free_form_criterion_comments]
    rubric.user = current_user
    rubric_params[:hide_score_total] ||= association_params[:hide_score_total]
    rubric.update_criteria(rubric_params)
    RubricAssociation.generate_with_invitees(current_user, rubric, context, association_params, invitees) if association_params[:association] || association_params[:url]
  end
  
  def update_with_association(current_user, rubric_params, context, association_params, invitees="")
    self.free_form_criterion_comments = rubric_params[:free_form_criterion_comments] == '1' if rubric_params[:free_form_criterion_comments]
    self.user ||= current_user
    rubric_params[:hide_score_total] ||= association_params[:hide_score_total]
    self.update_criteria(rubric_params)
    RubricAssociation.generate_with_invitees(current_user, self, context, association_params, invitees) if association_params[:association] || association_params[:url]
  end
  
  def unique_item_id(id=nil)
    @used_ids ||= {}
    while !id || @used_ids[id]
      id = "#{self.rubric_id || self.id}_#{rand(10000)}"
    end
    @used_ids[id] = true
    id
  end
  
  def update_criteria(params)
    self.save if self.new_record?
    data = generate_criteria(params)
    self.update_assessments_for_new_criteria(data.criteria)
    self.hide_score_total = params[:hide_score_total] if self.hide_score_total == nil || (self.association_count || 0) < 2
    self.data = data.criteria
    self.title = data.title
    self.points_possible = data.points_possible
    self.save
    self
  end
  
  def will_change_with_update?(params)
    return true if params[:free_form_criterion_comments] && self.free_form_criterion_comments != (params[:free_form_criterion_comments] == '1')
    data = generate_criteria(params)
    return true if data.title != self.title || data.points_possible != self.points_possible
    return true if data.criteria != self.criteria
    false
  end
  
  def generate_criteria(params)
    @used_ids = {}
    title = params[:title] || "#{context.name} Rubric"
    points_possible = 0
    criteria = []
    (params[:criteria] || {}).each do |idx, criterion_data|
      criterion = {}
      criterion[:description] = (criterion_data[:description] || "No Description").strip
      criterion[:long_description] = (criterion_data[:long_description] || "").strip
      criterion[:points] = criterion_data[:points].to_i || 0
      criterion_data[:id].strip! if criterion_data[:id]
      criterion_data[:id] = nil if criterion_data[:id] && criterion_data[:id].empty?
      criterion[:id] = unique_item_id(criterion_data[:id])
      ratings = []
      points = 0
      if criterion_data[:learning_outcome_id]
        outcome = LearningOutcome.find_by_id(criterion_data[:learning_outcome_id])
        if outcome
          @outcomes_changed = true
          criterion[:learning_outcome_id] = outcome.id
          criterion[:mastery_points] = ((criterion_data[:mastery_points] || outcome.data[:rubric_criterion][:mastery_points]).to_f rescue nil)
          criterion[:ignore_for_scoring] = criterion_data[:ignore_for_scoring] == '1'
        end
      end
      (criterion_data[:ratings] || []).each do |jdx, rating_data|
        rating = {}
        rating[:description] = (rating_data[:description] || "No Description").strip
        rating[:long_description] = (rating_data[:long_description] || "").strip
        rating[:points] = rating_data[:points].to_i || 0
        rating[:criterion_id] = criterion[:id]
        rating_data[:id].strip! if rating_data[:id]
        rating[:id] = unique_item_id(rating_data[:id])
        ratings[jdx.to_i] = rating
      end
      criterion[:ratings] = ratings.select{|r| r}.sort_by{|r| [-1 * (r[:points] || 0), (r[:description] || "")]}
      criterion[:points] = criterion[:ratings].map{|r| r[:points]}.max || 0
      points_possible += criterion[:points] unless criterion[:ignore_for_scoring]
      criteria[idx.to_i] = criterion
    end
    criteria = criteria.select{|c| c}
    OpenObject.new(:criteria => criteria, :points_possible => points_possible, :title => title)
  end
  
  def update_assessments_for_new_criteria(new_criteria)
    criteria = self.data
  end

  def self.process_migration(data, migration)
    rubrics = data['rubrics'] ? data['rubrics']: []
    to_import = migration.to_import 'rubrics'
    rubrics.each do |rubric|
      if rubric['migration_id'] && (!to_import || to_import[rubric['migration_id']])
        import_from_migration(rubric, migration.context)
      end
    end
  end
  
  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:rubrics_to_import] && !hash[:rubrics_to_import][hash[:migration_id]]
    item ||= find_by_context_id_and_context_type_and_id(context.id, context.class.to_s, hash[:id])
    item ||= find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
    item ||= self.new(:context => context)
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item.migration_id = hash[:migration_id]
    item.title = hash[:title]
    item.description = hash[:description]
    item.data = hash[:data]
    item.points_possible = hash[:points_possible].to_f
    item.save!
    context.imported_migration_items << item
    item
  end
  
  def self.generate(opts={})
    context = opts[:context]
    raise "Context required for rubrics" unless context
    rubric = context.rubrics.build(:user => opts[:user])
    user = opts[:user]
    params = opts[:data]
    rubric.update_criteria(params)
    rubric
  end
  
end
