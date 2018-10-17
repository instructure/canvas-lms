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

class LearningOutcome < ActiveRecord::Base
  include Workflow
  include OutcomeAttributes
  include MasterCourses::Restrictor
  restrict_columns :state, [:workflow_state]

  belongs_to :context, polymorphic: [:account, :course]
  has_many :learning_outcome_results
  has_many :alignments, -> { where("content_tags.tag_type='learning_outcome' AND content_tags.workflow_state<>'deleted'") }, class_name: 'ContentTag'

  serialize :data

  before_validation :infer_default_calculation_method, :adjust_calculation_int
  before_save :infer_defaults
  after_save :propagate_changes_to_rubrics

  CALCULATION_METHODS = {
    'decaying_average' => "Decaying Average",
    'n_mastery'        => "n Number of Times",
    'highest'          => "Highest Score",
    'latest'           => "Most Recent Score",
  }.freeze
  VALID_CALCULATION_INTS = {
    "decaying_average" => (1..99),
    "n_mastery" => (1..5),
    "highest" => [].freeze,
    "latest" => [].freeze,
  }.freeze

  validates :description, length: { maximum: maximum_text_length, allow_nil: true, allow_blank: true }
  validates :short_description, length: { maximum: maximum_string_length }
  validates :vendor_guid, length: { maximum: maximum_string_length, allow_nil: true }
  validates :display_name, length: { maximum: maximum_string_length, allow_nil: true, allow_blank: true }
  validates :calculation_method, inclusion: { in: CALCULATION_METHODS.keys,
    message: -> { t(
      "calculation_method must be one of the following: %{calc_methods}",
      :calc_methods => CALCULATION_METHODS.keys.to_s
    ) }
  }
  validates :short_description, :workflow_state, presence: true
  sanitize_field :description, CanvasSanitize::SANITIZE
  validate :validate_calculation_int

  set_policy do
    # managing a contextual outcome requires manage_outcomes on the outcome's context
    given {|user, session| self.context_id && self.context.grants_right?(user, session, :manage_outcomes) }
    can :create and can :read and can :update and can :delete

    # reading a contextual outcome is also allowed by read_outcomes on the outcome's context
    given {|user, session| self.context_id && self.context.grants_right?(user, session, :read_outcomes) }
    can :read

    # managing a global outcome requires manage_global_outcomes on the site_admin
    given {|user, session| self.context_id.nil? && Account.site_admin.grants_right?(user, session, :manage_global_outcomes) }
    can :create and can :read and can :update and can :delete

    # reading a global outcome is also allowed by just being logged in
    given {|user| self.context_id.nil? && user }
    can :read
  end

  def infer_defaults
    if self.data && self.data[:rubric_criterion]
      self.data[:rubric_criterion][:description] = self.short_description
    end
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil

    # if we are changing the calculation_method but not the calculation_int, set the int to the default value
    if calculation_method_changed? && !calculation_int_changed?
      self.calculation_int = default_calculation_int
    end
  end

  def validate_calculation_int
    unless self.class.valid_calculation_int?(calculation_int, calculation_method)
      valid_ints = self.class.valid_calculation_ints(self.calculation_method)
      if valid_ints.to_a.empty?
        errors.add(:calculation_int, t(
          "A calculation value is not used with this calculation method"
        ))
      else
        errors.add(:calculation_int, t(
          "'%{calculation_int}' is not a valid value for this calculation method. The value must be between '%{valid_calculation_ints_min}' and '%{valid_calculation_ints_max}'",
          :calculation_int => calculation_int,
          :valid_calculation_ints_min => valid_ints.min,
          :valid_calculation_ints_max => valid_ints.max
        ))
      end
    end
  end

  def self.valid_calculation_method?(method)
    CALCULATION_METHODS.keys.include?(method)
  end

  def self.valid_calculation_ints(method)
    VALID_CALCULATION_INTS[method]
  end

  def self.valid_calculation_int?(int, method)
    if valid_calculation_method?(method)
      valid_ints = valid_calculation_ints(method)
      (int.nil? && valid_ints.to_a.empty?) || valid_ints.include?(int)
    else
      true
    end
  end

  def infer_default_calculation_method
    # If we are a new record, or are not changing our calculation_method (such as on a pre-existing
    # record or an import), then assume the default of decaying average
    if new_record? || !calculation_method_changed?
      self.calculation_method ||= default_calculation_method
      self.calculation_int ||= default_calculation_int
    end
  end

  def adjust_calculation_int
    # If we are changing calculation_method, set default calculation_int
    if calculation_method_changed? && (!calculation_int_changed? || %w[highest latest].include?(calculation_method))
      self.calculation_int = default_calculation_int unless new_record?
    end
  end

  def default_calculation_method
    "decaying_average"
  end

  def default_calculation_int(method=self.calculation_method)
    case method
    when 'decaying_average' then 65
    when 'n_mastery' then 5
    else nil
    end
  end

  def align(asset, context, opts={})
    tag = find_or_create_tag(asset, context)
    tag.tag = determine_tag_type(opts[:mastery_type])
    tag.position = (self.alignments.map(&:position).compact.max || 1) + 1
    tag.mastery_score = opts[:mastery_score] if opts[:mastery_score]
    tag.save

    create_missing_outcome_link(context) if context.is_a? Course
    tag
  end

  def reorder_alignments(context, order)
    order_hash = {}
    order.each_with_index{|o, i| order_hash[o.to_i] = i; order_hash[o] = i }
    tags = self.alignments.where(context_id: context, context_type: context.class.to_s, tag_type: 'learning_outcome')
    tags = tags.sort_by{|t| order_hash[t.id] || order_hash[t.content_asset_string] || CanvasSort::Last }
    updates = []
    tags.each_with_index do |tag, idx|
      tag.position = idx + 1
      updates << "WHEN id=#{tag.id} THEN #{idx + 1}"
    end
    ContentTag.where(:id => tags).update_all("position=CASE #{updates.join(" ")} ELSE position END")
    self.touch
    tags
  end

  def remove_alignment(alignment_id, context)
    tag = self.alignments.where({
      context_id: context,
      context_type: context.class_name,
      id: alignment_id
    }).first
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
      LearningOutcome.where(id: missing_outcome_ids).each do |learning_outcome|
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

  def cached_context_short_name
    @cached_context_name ||= Rails.cache.fetch(['short_name_lookup', self.context_code].cache_key) do
      self.context.short_name rescue ""
    end
  end

  def self.default_rubric_criterion
    {
      description: t('No Description'),
      ratings: [
        {
          description: I18n.t('Exceeds Expectations'),
          points: 5
        },
        {
          description: I18n.t('Meets Expectations'),
          points: 3
        },
        {
          description: I18n.t('Does Not Meet Expectations'),
          points: 0
        }
      ],
      mastery_points: 3,
      points_possible: 5
    }
  end

  def rubric_criterion
    self.data ||= {}
    data[:rubric_criterion] ||= self.class.default_rubric_criterion
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
      criterion = self.class.default_rubric_criterion
    end

    self.data[:rubric_criterion] = criterion
  end

  alias_method :destroy_permanently!, :destroy
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

  def assessed?(course = nil)
    if course
      self.learning_outcome_results.where(context_id: course, context_type: "Course").exists?
    else
      if learning_outcome_results.loaded?
        learning_outcome_results.any?
      else
        learning_outcome_results.exists?
      end
    end
  end

  def tie_to(context)
    @tied_context = context
  end

  def mastery_points
    self.rubric_criterion[:mastery_points]
  end

  def points_possible
    self.rubric_criterion[:points_possible]
  end

  def mastery_percent
    return unless mastery_points && points_possible
    (mastery_points / points_possible).round(2)
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
    tags = ContentTag.active.where(content_id: ids, content_type: 'LearningOutcome').to_a
    to_delete = []
    ids.each do |id|
      to_delete << id unless tags.any?{|t| t.content_id == id }
    end
    LearningOutcome.where(:id => to_delete).update_all(:workflow_state => 'deleted', :updated_at => Time.now.utc)
  end

  def self.ensure_presence_in_context(outcome_ids, context)
    return unless outcome_ids && context
    missing_outcomes = LearningOutcome.where(id: outcome_ids)
                        .where.not(id: context.linked_learning_outcomes.select(:id))
                        .active
    missing_outcomes.each{ |o| context.root_outcome_group.add_outcome(o) }
  end

  scope(:for_context_codes, ->(codes) { where(:context_code => codes) })
  scope(:active, -> { where("learning_outcomes.workflow_state<>'deleted'") })
  scope(:has_result_for_user,
    lambda do |user|
      joins(:learning_outcome_results)
        .where("learning_outcomes.id=learning_outcome_results.learning_outcome_id " \
               "AND learning_outcome_results.user_id=?", user)
        .order(best_unicode_collation_key('short_description'))
    end
  )

  scope :global, -> { where(:context_id => nil) }

  def propagate_changes_to_rubrics
    # exclude new outcomes
    return if self.saved_change_to_id?
    return if !self.saved_change_to_data? &&
      !self.saved_change_to_short_description? &&
      !self.saved_change_to_description?

    self.send_later_if_production(:update_associated_rubrics)
  end

  def update_associated_rubrics
    updateable_rubrics.find_each do |rubric|
      rubric.update_learning_outcome_criteria(self)
    end
  end

  def updateable_rubrics
    conds = { learning_outcome_id: self.id, content_type: 'Rubric', workflow_state: 'active' }
    # Find all unassessed, active rubrics aligned to this outcome, referenced by no more than one assignment
    Rubric.where(id:
      Rubric.select('rubrics.id').
        where.not(workflow_state: 'deleted').
        joins(:learning_outcome_alignments).
        where(content_tags: conds).
        joins("LEFT JOIN #{RubricAssociation.quoted_table_name} ra2 ON rubrics.id = ra2.rubric_id AND ra2.purpose = 'grading'").
        group('rubrics.id').
        having('COUNT(rubrics.id) < 2')).
      joins("LEFT JOIN #{RubricAssociation.quoted_table_name} ra2 ON rubrics.id = ra2.rubric_id AND ra2.purpose = 'grading'" \
            " LEFT JOIN #{RubricAssessment.quoted_table_name} ra3 ON ra2.id = ra3.rubric_association_id").
      where('ra3.id IS NULL')
  end

  def updateable_rubrics?
    updateable_rubrics.exists?
  end

  private

  def create_missing_outcome_link(context)
    context_outcomes = context.learning_outcome_links.where(
      content_type: "LearningOutcome"
    ).pluck(:content_id)

    unless context_outcomes.include?(self.id)
      context.root_outcome_group.add_outcome(self)
    end
  end

  def find_or_create_tag(asset, context)
    self.alignments.find_or_create_by(
      content: asset,
      tag_type: 'learning_outcome',
      context: context
    )
  end

  def determine_tag_type(mastery_type)
    case mastery_type
    when 'points', 'points_mastery'
      new_mastery_type = 'points_mastery'
    else
      new_mastery_type = 'explicit_mastery'
    end
    new_mastery_type
  end
end
