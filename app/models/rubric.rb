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

class Rubric < ActiveRecord::Base
  include Workflow
  include HtmlTextHelper

  POINTS_POSSIBLE_PRECISION = 4

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
  before_create :set_root_account_id
  after_save :update_alignments
  after_save :touch_associations

  serialize :data
  simply_versioned

  scope :publicly_reusable, -> { where(:reusable => true).order(best_unicode_collation_key('title')) }
  scope :matching, lambda { |search| where(wildcard('rubrics.title', search)).order("rubrics.association_count DESC") }
  scope :before, lambda { |date| where("rubrics.created_at<?", date) }
  scope :active, -> { where.not(workflow_state: 'deleted') }

  set_policy do
    given {|user, session| self.context.grants_right?(user, session, :manage_rubrics)}
    can :read and can :create and can :delete_associations

    given {|user, session| self.context.grants_right?(user, session, :manage_assignments)}
    can :read and can :create and can :delete_associations

    given {|user, session| self.context.grants_right?(user, session, :manage)}
    can :read and can :create and can :delete_associations

    given {|user, session| self.context.grants_right?(user, session, :read_rubrics) }
    can :read

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

  def self.aligned_to_outcomes
    where(
      ContentTag.learning_outcome_alignments.
        active.
        where(content_type: 'Rubric').
        where('content_tags.content_id = rubrics.id').
        arel.exists
    )
  end

  def self.with_at_most_one_association
    joins(<<~JOINS).
      LEFT JOIN #{RubricAssociation.quoted_table_name} associations_for_count
      ON rubrics.id = associations_for_count.rubric_id
      AND associations_for_count.purpose = 'grading'
    JOINS
      group('rubrics.id').
      having('COUNT(rubrics.id) < 2')
  end

  def self.unassessed
    joins(<<~JOINS).
      LEFT JOIN #{RubricAssociation.quoted_table_name} associations_for_unassessed
      ON rubrics.id = associations_for_unassessed.rubric_id
      AND associations_for_unassessed.purpose = 'grading'
    JOINS
      joins(<<~JOINS).
        LEFT JOIN #{RubricAssessment.quoted_table_name} assessments_for_unassessed
        ON associations_for_unassessed.id = assessments_for_unassessed.rubric_association_id
      JOINS
      where(assessments_for_unassessed: {id: nil})
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
  def destroy_for(context, current_user: nil)
    ras = rubric_associations.where(:context_id => context, :context_type => context.class.to_s)
    if context.class.to_s == 'Course'
      # if rubric is removed at the course level, we want to destroy any
      # assignment associations found in the context of the course
      ras.each do |association|
        association.updating_user = current_user
        association.destroy
      end
    else
      ras.update_all(:bookmarked => false, :updated_at => Time.now.utc)
    end
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
    saved_change_to_data? || saved_change_to_workflow_state?
  end

  def data_outcome_ids
    (data || []).map{|c| c[:learning_outcome_id] }.compact.map(&:to_i).uniq
  end

  def criteria_object
    OpenObject.process(self.data)
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
    ra.updating_user = opts[:current_user]
    if ra.save
      association.mark_downstream_changes(["rubric"]) if association.is_a?(Assignment)
    end
    ra.updating_user = nil
    ra
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

  def update_mastery_scales
    return unless context.root_account.feature_enabled?(:account_level_mastery_scales)

    mastery_scale = context.resolved_outcome_proficiency
    return if mastery_scale.nil?

    self.data.each do |criterion|
      update_criterion_from_mastery_scales(criterion, mastery_scale)
    end
    if self.data_changed?
      self.points_possible = total_points_from_criteria(self.data)
      self.save!
    end
  end

  def update_criterion_from_mastery_scales(criterion, mastery_scale)
    return unless criterion[:learning_outcome_id].present?

    criterion[:points] = mastery_scale.points_possible
    criterion[:mastery_points] = mastery_scale.mastery_points
    criterion[:ratings] = mastery_scale.outcome_proficiency_ratings.map {|pr| criterion_rating(pr, criterion[:id])}
  end

  def update_learning_outcome_criteria(outcome)
    self.data.each do |criterion|
      update_learning_outcome_criterion(criterion, outcome) if criterion[:learning_outcome_id] == outcome.id
    end
    if self.data_changed?
      self.points_possible = total_points_from_criteria(self.data)
      self.save!
    end
  end

  def update_learning_outcome_criterion(criterion, outcome)
    criterion[:description] = outcome.short_description
    criterion[:long_description] = outcome.description
    unless context.root_account.feature_enabled?(:account_level_mastery_scales)
      criterion[:points] = outcome.points_possible
      criterion[:mastery_points] = outcome.mastery_points
      criterion[:ratings] = outcome.rubric_criterion.nil? ? [] : generate_criterion_ratings(outcome, criterion[:id])
    end
  end

  def generate_criterion_ratings(outcome, criterion_id)
    outcome.rubric_criterion[:ratings].map do |rating|
      criterion_rating(rating, criterion_id)
    end
  end

  def criterion_rating(rating_data, criterion_id)
    {
      description: (rating_data[:description].presence || t("No Description")).strip,
      long_description: (rating_data[:long_description] || "").strip,
      points: rating_data[:points].to_f || 0,
      criterion_id: criterion_id,
      id: unique_item_id(rating_data[:id])
    }
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
    criteria = []
    (params[:criteria] || {}).each do |idx, criterion_data|
      criterion = {}
      criterion[:description] = (criterion_data[:description].presence || t('no_description', "No Description")).strip
      # Outcomes descriptions are already html sanitized, so use that if an outcome criteria
      # is present. Otherwise we need to sanitize the input ourselves.
      unless criterion_data[:learning_outcome_id].present?
        criterion[:long_description] = format_message((criterion_data[:long_description] || "").strip).first
      end
      criterion[:points] = criterion_data[:points].to_f || 0
      criterion_data[:id].strip! if criterion_data[:id]
      criterion_data[:id] = nil if criterion_data[:id] && criterion_data[:id].empty?
      criterion[:id] = unique_item_id(criterion_data[:id])
      criterion[:criterion_use_range] = [true, 'true'].include?(criterion_data[:criterion_use_range])
      if criterion_data[:learning_outcome_id].present?
        outcome = LearningOutcome.where(id: criterion_data[:learning_outcome_id]).first
        criterion[:long_description] = outcome&.description || ''
        if outcome
          criterion[:learning_outcome_id] = outcome.id
          criterion[:mastery_points] = ((criterion_data[:mastery_points] || outcome.data[:rubric_criterion][:mastery_points]).to_f rescue nil)
          criterion[:ignore_for_scoring] = criterion_data[:ignore_for_scoring] == '1'
        end
      end

      ratings = (criterion_data[:ratings] || {}).values.map do |rating_data|
        rating_data[:id]&.strip!
        criterion_rating(rating_data, criterion[:id])
      end
      criterion[:ratings] = ratings.sort_by { |r| [-1 * (r[:points] || 0), r[:description] || CanvasSort::First] }
      criterion[:points] = criterion[:ratings].map{|r| r[:points]}.max || 0

      # Record both the criterion data and the original ID that was passed in
      # (we'll use the ID when we sort the criteria below)
      criteria.push([idx, criterion])
    end
    criteria = criteria.sort_by { |criterion| criterion.first&.to_i || CanvasSort::First }.
      map(&:second)
    points_possible = total_points_from_criteria(criteria)&.round(POINTS_POSSIBLE_PRECISION)
    CriteriaData.new(criteria, points_possible, title)
  end

  def total_points_from_criteria(criteria)
    criteria.reject { |c| c[:ignore_for_scoring] }.map { |c| c[:points] }.reduce(:+)
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

  def set_root_account_id
    self.root_account_id ||=
      if context_type == 'Account' && context.root_account?
        self.context.id
      else
        self.context&.root_account_id
      end
  end
end
