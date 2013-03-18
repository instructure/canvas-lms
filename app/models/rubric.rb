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
  has_many :learning_outcome_alignments, :as => :content, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND content_tags.workflow_state != ?', 'learning_outcome', 'deleted'], :include => :learning_outcome
  before_save :default_values
  after_save :update_alignments
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :title, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true

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
    given {|user, session| self.cached_context_grants_right?(user, session, :manage_rubrics)}
    can :read and can :create and can :delete_associations
    
    given {|user, session| self.cached_context_grants_right?(user, session, :manage_assignments)}
    can :read and can :create and can :delete_associations
    
    given {|user, session| self.cached_context_grants_right?(user, session, :manage)}
    can :read and can :create and can :delete_associations
    
    # read_only means "associated with > 1 object for grading purposes"
    given {|user, session| !self.read_only && self.rubric_associations.for_grading.length < 2 && self.cached_context_grants_right?(user, session, :manage_assignments)}
    can :update and can :delete
    
    given {|user, session| !self.read_only && self.rubric_associations.for_grading.length < 2 && self.cached_context_grants_right?(user, session, :manage_rubrics)}
    can :update and can :delete

    given {|user, session| self.cached_context_grants_right?(user, session, :manage_assignments)}
    can :delete
    
    given {|user, session| self.cached_context_grants_right?(user, session, :manage_rubrics)}
    can :delete

    given {|user, session| self.cached_context_grants_right?(user, session, :read) }
    can :read
  end
  
  workflow do
    state :active
    state :deleted
  end
  
  def default_values
    original_title = self.title
    cnt = 0

    loop do
      dup_title = if new_record?
                    Rubric.first :conditions => ["title = ? AND context_id = ? AND context_type = ? AND workflow_state != 'deleted'", self.title, self.context_id, self.context_type]
                  else
                    Rubric.first :conditions => ["title = ? AND context_id = ? AND context_type = ? AND id != ? AND workflow_state != 'deleted'", self.title, self.context_id, self.context_type, self.id]
                  end
      break unless dup_title

      cnt += 1
      self.title = "#{original_title} (#{cnt})"
    end
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  alias_method :destroy!, :destroy
  def destroy
    RubricAssociation.where(:rubric_id => self).update_all(:bookmarked => false, :updated_at => Time.now.utc)
    self.workflow_state = 'deleted'
    self.save
  end
  
  def restore
    self.workflow_state = 'active'
    self.save
  end
  
  # If any rubric_associations for a given context are marked as
  # bookmarked, then the rubric will show up in the context's list
  # of rubrics.  The two main values for the 'purpose' field on
  # a rubric_association are 'grading' and 'bookmark'.  Confusing,
  # I know.
  def destroy_for(context)
    RubricAssociation.where(:rubric_id => self, :context_id => context, :context_type => context.class.to_s).
        update_all(:bookmarked => false, :updated_at => Time.now.utc)
    unless RubricAssociation.where(:rubric_id => self, :bookmarked => true).exists?
      self.destroy
    end
  end

  attr_accessor :alignments_changed
  def update_alignments
    return unless @alignments_changed
    outcome_ids = (self.data || []).map{|c| c[:learning_outcome_id] }.compact.map(&:to_i).uniq
    LearningOutcome.update_alignments(self, context, outcome_ids)
    true
  end
  
  def criteria_object
    OpenObject.process(self.data)
  end
  
  def display_name
    res = ""
    res += self.user.name + ", " rescue ""
    res += self.context.name rescue ""
    res = t('unknown_details', "Unknown Details") if res.empty?
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
    self.without_versioning(&:save) if self.new_record?
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
    return true if params[:free_form_criterion_comments] && !!self.free_form_criterion_comments != (params[:free_form_criterion_comments] == '1')
    data = generate_criteria(params)
    return true if data.title != self.title || data.points_possible != self.points_possible
    return true if data.criteria != self.criteria
    false
  end
  
  def generate_criteria(params)
    @used_ids = {}
    title = params[:title] || t('context_name_rubric', "%{course_name} Rubric", :course_name => context.name)
    points_possible = 0
    criteria = []
    (params[:criteria] || {}).each do |idx, criterion_data|
      criterion = {}
      criterion[:description] = (criterion_data[:description] || t('no_description', "No Description")).strip
      criterion[:long_description] = (criterion_data[:long_description] || "").strip
      criterion[:points] = criterion_data[:points].to_f || 0
      criterion_data[:id].strip! if criterion_data[:id]
      criterion_data[:id] = nil if criterion_data[:id] && criterion_data[:id].empty?
      criterion[:id] = unique_item_id(criterion_data[:id])
      ratings = []
      points = 0
      if criterion_data[:learning_outcome_id].present?
        outcome = LearningOutcome.find_by_id(criterion_data[:learning_outcome_id])
        if outcome
          @alignments_changed = true
          criterion[:learning_outcome_id] = outcome.id
          criterion[:mastery_points] = ((criterion_data[:mastery_points] || outcome.data[:rubric_criterion][:mastery_points]).to_f rescue nil)
          criterion[:ignore_for_scoring] = criterion_data[:ignore_for_scoring] == '1'
        end
      end
      (criterion_data[:ratings] || {}).each do |jdx, rating_data|
        rating = {}
        rating[:description] = (rating_data[:description] || t('no_description', "No Description")).strip
        rating[:long_description] = (rating_data[:long_description] || "").strip
        rating[:points] = rating_data[:points].to_f || 0
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
    migration.outcome_to_id_map ||= {}
    rubrics.each do |rubric|
      if migration.import_object?("rubrics", rubric['migration_id'])
        begin
          import_from_migration(rubric, migration)
        rescue
          migration.add_warning(t('errors.could_not_import', "Couldn't import rubric %{rubric}", :rubric => rubric[:title]), $!)
        end
      end
    end
  end
  
  def self.import_from_migration(hash, migration, item=nil)
    context = migration.context
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:rubrics_to_import] && !hash[:rubrics_to_import][hash[:migration_id]]
    item ||= find_by_context_id_and_context_type_and_id(context.id, context.class.to_s, hash[:id])
    item ||= find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
    item ||= self.new(:context => context)
    item.migration_id = hash[:migration_id]
    item.workflow_state = 'active' if item.deleted?
    item.title = hash[:title]
    item.description = hash[:description]
    item.points_possible = hash[:points_possible].to_f
    item.read_only = hash[:read_only] unless hash[:read_only].nil?
    item.reusable = hash[:reusable] unless hash[:reusable].nil?
    item.public = hash[:public] unless hash[:public].nil?
    item.hide_score_total = hash[:hide_score_total] unless hash[:hide_score_total].nil?
    item.free_form_criterion_comments = hash[:free_form_criterion_comments] unless hash[:free_form_criterion_comments].nil?
    
    item.data = hash[:data]
    item.data.each do |crit|
      if crit[:learning_outcome_migration_id]
        item.alignments_changed = true
        if migration.respond_to?(:outcome_to_id_map) && id = migration.outcome_to_id_map[crit[:learning_outcome_migration_id]]
          crit[:learning_outcome_id] = id
        elsif lo = context.created_learning_outcomes.find_by_migration_id(crit[:learning_outcome_migration_id])
          crit[:learning_outcome_id] = lo.id
        end
        crit.delete :learning_outcome_migration_id
      end
    end
    
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item.save!
    
    unless context.rubric_associations.find_by_rubric_id(item.id)
      item.associate_with(context, context)
    end
    
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
