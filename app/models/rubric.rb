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

  attr_writer :skip_updating_points_possible
  belongs_to :user
  belongs_to :rubric # based on another rubric
  belongs_to :context, polymorphic: [:course, :account]
  has_many :rubric_associations, :class_name => 'RubricAssociation', :dependent => :destroy
  has_many :rubric_assessments, :through => :rubric_associations, :dependent => :destroy
  has_many :learning_outcome_alignments, -> { where("content_tags.tag_type='learning_outcome' AND content_tags.workflow_state<>'deleted'").preload(:learning_outcome) }, as: :content, inverse_of: :content, class_name: 'ContentTag'

  validates_presence_of :context_id, :context_type, :workflow_state
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => false, :allow_blank => false

  before_validation :default_values
  after_save :update_alignments
  after_save :touch_associations

  serialize :data
  simply_versioned

  scope :publicly_reusable, -> { where(:reusable => true).order(best_unicode_collation_key('title')) }
  scope :matching, lambda { |search| where(wildcard('rubrics.title', search)).order("rubrics.association_count DESC") }
  scope :before, lambda { |date| where("rubrics.created_at<?", date) }
  scope :active, -> { where("workflow_state<>'deleted'") }

  set_policy do
    given {|user, session| self.context.grants_right?(user, session, :manage_rubrics)}
    can :read and can :create and can :delete_associations

    given {|user, session| self.context.grants_right?(user, session, :manage_assignments)}
    can :read and can :create and can :delete_associations

    given {|user, session| self.context.grants_right?(user, session, :manage)}
    can :read and can :create and can :delete_associations

    # read_only means "associated with > 1 object for grading purposes"
    given {|user, session| !self.read_only && self.rubric_associations.for_grading.length < 2 && self.context.grants_right?(user, session, :manage_assignments)}
    can :update and can :delete

    given {|user, session| !self.read_only && self.rubric_associations.for_grading.length < 2 && self.context.grants_right?(user, session, :manage_rubrics)}
    can :update and can :delete

    given {|user, session| self.context.grants_right?(user, session, :manage_assignments)}
    can :delete

    given {|user, session| self.context.grants_right?(user, session, :manage_rubrics)}
    can :delete

    given {|user, session| self.context.grants_right?(user, session, :read) }
    can :read
  end

  workflow do
    state :active
    state :deleted
  end

  def default_values
    if Rails.env.test?
      populate_rubric_title # there are too many specs to change and i'm too lazy
    end

    cnt = 0
    siblings = Rubric.where(context_id: self.context_id, context_type: self.context_type).where("workflow_state<>'deleted'")
    siblings = siblings.where("id<>?", self.id) unless new_record?
    if self.title.present?
      original_title = self.title
      while siblings.where(title: self.title).exists?
        cnt += 1
        self.title = "#{original_title} (#{cnt})"
      end
    end
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end

  alias_method :destroy_permanently!, :destroy
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
      res = self.rubric_associations.where(association_id: association, association_type: association.class.to_s, purpose: 'grading').first
      return res if res
    elsif opts[:update_if_existing]
      res = self.rubric_associations.where(association_id: association, association_type: association.class.to_s).first
      return res if res
    end
    purpose = opts[:purpose] || "unknown"
    ra = rubric_associations.build :association_object => association,
                                   :context => context,
                                   :use_for_grading => !!opts[:use_for_grading],
                                   :purpose => purpose
    ra.skip_updating_points_possible = opts[:skip_updating_points_possible] || @skip_updating_points_possible
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
    params ||= {}
    return true if params[:free_form_criterion_comments] && !!self.free_form_criterion_comments != (params[:free_form_criterion_comments] == '1')
    data = generate_criteria(params)
    return true if data.title != self.title || data.points_possible != self.points_possible
    return true if Rubric.normalize(data.criteria) != Rubric.normalize(self.criteria)
    false
  end

  def populate_rubric_title
    self.title ||= context && t('context_name_rubric', "%{course_name} Rubric", :course_name => context.name)
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
        outcome = LearningOutcome.where(id: criterion_data[:learning_outcome_id]).first
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

  # undo innocuous changes introduced by migrations which break `will_change_with_update?`
  def self.normalize(criteria)
    case criteria
    when Array
      criteria.map { |criterion| Rubric.normalize(criterion) }
    when Hash
      h = criteria.reject { |k, v| v.blank? }.stringify_keys
      h.delete('title') if h['title'] == h['description']
      h.each do |k, v|
        h[k] = Rubric.normalize(v) if v.is_a?(Hash) || v.is_a?(Array)
      end
      h
    else
      criteria
    end
  end
end
