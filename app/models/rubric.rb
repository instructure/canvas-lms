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

  validates_presence_of :context_id, :context_type, :workflow_state
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true

  before_save :default_values
  after_save :update_alignments
  after_save :touch_associations

  serialize :data
  simply_versioned
  
  scope :publicly_reusable, lambda { where(:reusable => true).order(best_unicode_collation_key('title')) }
  scope :matching, lambda { |search| where(wildcard('rubrics.title', search)).order("rubrics.association_count DESC") }
  scope :before, lambda { |date| where("rubrics.created_at<?", date) }
  scope :active, where("workflow_state<>'deleted'")

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
    siblings = Rubric.where(context_id: self.context_id, context_type: self.context_type).where("workflow_state<>'deleted'")
    siblings = siblings.where("id<>?", self.id) unless new_record?
    while siblings.where(title: self.title).exists?
      cnt += 1
      self.title = "#{original_title} (#{cnt})"
    end
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  alias_method :destroy!, :destroy
  def destroy
    rubric_associations.update_all(:bookmarked => false, :updated_at => Time.now.utc)
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
    rubric_associations.where(:context_id => context, :context_type => context.class.to_s).
        update_all(:bookmarked => false, :updated_at => Time.now.utc)
    unless rubric_associations.bookmarked.exists?
      self.destroy
    end
  end

  def update_alignments
    if alignments_need_update?
      outcome_ids = []
      unless deleted?
        outcome_ids = data_outcome_ids
      end
      LearningOutcome.update_alignments(self, context, outcome_ids)
    end
    true
  end

  def touch_associations
    if alignments_need_update?
      # associations might need to update their alignments also
      rubric_associations.bookmarked.each { |ra|
        ra.skip_updating_points_possible = @skip_updating_points_possible
        ra.save
      }
    end
  end

  def alignments_need_update?
    data_changed? || workflow_state_changed?
  end

  def data_outcome_ids
    (data || []).map{|c| c[:learning_outcome_id] }.compact.map(&:to_i).uniq
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
    ra = rubric_associations.build :association_object => association,
                                   :context => context,
                                   :use_for_grading => !!opts[:use_for_grading],
                                   :purpose => purpose
    ra.skip_updating_points_possible = @skip_updating_points_possible
    ra.tap &:save
  end

  def update_with_association(current_user, rubric_params, context, association_params)
    self.free_form_criterion_comments = rubric_params[:free_form_criterion_comments] == '1' if rubric_params[:free_form_criterion_comments]
    self.user ||= current_user
    rubric_params[:hide_score_total] ||= association_params[:hide_score_total]
    @skip_updating_points_possible = association_params[:skip_updating_points_possible]
    self.update_criteria(rubric_params)
    RubricAssociation.generate(current_user, self, context, association_params) if association_params[:association_object] || association_params[:url]
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
  
  CriteriaData = Struct.new(:criteria, :points_possible, :title)
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
      criterion[:ratings] = ratings.select{|r| r}.sort_by{|r| [-1 * (r[:points] || 0), r[:description] || CanvasSort::First]}
      criterion[:points] = criterion[:ratings].map{|r| r[:points]}.max || 0
      points_possible += criterion[:points] unless criterion[:ignore_for_scoring]
      criteria[idx.to_i] = criterion
    end
    criteria = criteria.compact
    CriteriaData.new(criteria, points_possible, title)
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
          migration.add_import_warning(t('#migration.rubric_type', "Rubric"), rubric[:title], $!)
        end
      end
    end
  end
  
  def self.import_from_migration(hash, migration, item=nil)
    context = migration.context
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:rubrics_to_import] && !hash[:rubrics_to_import][hash[:migration_id]]

    rubric = nil
    if !item && hash[:external_identifier]
      rubric = context.available_rubric(hash[:external_identifier])

      if !rubric
        migration.add_warning(t(:no_context_found, %{The external Rubric couldn't be found for "%{title}", creating a copy.}, :title => hash[:title]))
      end
    end

    if rubric
      item = rubric
    else
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
    end

    unless context.rubric_associations.find_by_rubric_id(item.id)
      item.associate_with(context, context)
    end
    
    item
  end
end
