# frozen_string_literal: true

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
  include ManyRootAccounts
  include Workflow
  include MasterCourses::Restrictor
  restrict_columns :state, [:workflow_state]

  belongs_to :context, polymorphic: [:account, :course]
  has_many :learning_outcome_results
  has_many :alignments, -> { where("content_tags.tag_type='learning_outcome' AND content_tags.workflow_state<>'deleted'") }, class_name: "ContentTag"

  belongs_to :copied_from,
             class_name: "LearningOutcome",
             optional: true,
             inverse_of: :cloned_outcomes,
             foreign_key: "copied_from_outcome_id"
  has_many :cloned_outcomes,
           class_name: "LearningOutcome",
           inverse_of: :copied_from,
           foreign_key: "copied_from_outcome_id"
  serialize :data

  before_validation :adjust_calculation_method, :infer_default_calculation_method, :adjust_calculation_int
  before_save :infer_defaults
  before_save :infer_root_account_ids
  after_save :propagate_changes_to_rubrics

  validates :description, length: { maximum: maximum_text_length, allow_blank: true }
  validates :short_description, length: { maximum: maximum_string_length }
  validates :vendor_guid, length: { maximum: maximum_string_length, allow_nil: true }
  validates :display_name, length: { maximum: maximum_string_length, allow_blank: true }
  validates :calculation_method, inclusion: {
    in: OutcomeCalculationMethod::CALCULATION_METHODS,
    message: lambda do
      t(
        "calculation_method must be one of the following: %{calc_methods}",
        calc_methods: OutcomeCalculationMethod::CALCULATION_METHODS.to_s
      )
    end
  }
  validates :short_description, :workflow_state, presence: true
  sanitize_field :description, CanvasSanitize::SANITIZE
  validate :validate_calculation_int

  set_policy do
    # managing a contextual outcome requires manage_outcomes on the outcome's context
    given { |user, session| context_id && context.grants_right?(user, session, :manage_outcomes) }
    can :create and can :read and can :update and can :delete

    # reading a contextual outcome is also allowed by read_outcomes on the outcome's context
    given { |user, session| context_id && context.grants_right?(user, session, :read_outcomes) }
    can :read

    # managing a global outcome requires manage_global_outcomes on the site_admin
    given { |user, session| context_id.nil? && Account.site_admin.grants_right?(user, session, :manage_global_outcomes) }
    can :create and can :read and can :update and can :delete

    # reading a global outcome is also allowed by just being logged in
    given { |user| context_id.nil? && user }
    can :read
  end

  def infer_defaults
    if data && data[:rubric_criterion]
      data[:rubric_criterion][:description] = short_description
    end
    self.context_code = "#{context_type.underscore}_#{context_id}" rescue nil

    # if we are changing the calculation_method but not the calculation_int, set the int to the default value
    if calculation_method_changed? && !calculation_int_changed?
      self.calculation_int = default_calculation_int
    end
  end

  def infer_root_account_ids
    return if root_account_ids.present?

    context_root_account_id = context.try(:resolved_root_account_id)

    # find linked contexts
    links = if new_record?
              []
            else
              ContentTag.learning_outcome_links
                        .preload(:context)
                        .where(content_id: self, context_type: ["Account", "Course"])
                        .select(:context_type, :context_id)
                        .distinct
            end
    link_root_account_ids = links.map { |link| link.context.resolved_root_account_id }

    self.root_account_ids = ([context_root_account_id] + link_root_account_ids).uniq.compact
  end

  def add_root_account_id_for_context!(context)
    return if root_account_ids.nil? # not initialized yet

    root_account_id = context.try(:resolved_root_account_id)
    return if root_account_id.nil?

    unless root_account_ids.include? root_account_id
      root_account_ids << root_account_id
      save!
    end
  end

  def validate_calculation_int
    unless self.class.valid_calculation_int?(calculation_int, calculation_method)
      valid_ints = self.class.valid_calculation_ints(calculation_method)
      if valid_ints.to_a.empty?
        errors.add(:calculation_int, t(
                                       "A calculation value is not used with this calculation method"
                                     ))
      else
        errors.add(:calculation_int, t(
                                       "'%{calculation_int}' is not a valid value for this calculation method. The value must be between '%{valid_calculation_ints_min}' and '%{valid_calculation_ints_max}'",
                                       calculation_int:,
                                       valid_calculation_ints_min: valid_ints.min,
                                       valid_calculation_ints_max: valid_ints.max
                                     ))
      end
    end
  end

  def self.valid_calculation_method?(method)
    OutcomeCalculationMethod::CALCULATION_METHODS.include?(method)
  end

  def self.valid_calculation_ints(method)
    OutcomeCalculationMethod::VALID_CALCULATION_INTS[method]
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
    if calculation_method_changed? && (!calculation_int_changed? || %w[highest latest].include?(calculation_method)) && !new_record?
      self.calculation_int = default_calculation_int
    end
  end

  def new_decaying_average_calculation_ff_enabled?
    return context.root_account.feature_enabled?(:outcomes_new_decaying_average_calculation) if context

    LoadAccount.default_domain_root_account.feature_enabled?(:outcomes_new_decaying_average_calculation)
  end

  # We have redefined the calculation methods as follows:
  # weighted_average - This is the preferred way to describe legacy decaying_average.
  # decaying_average - This is the deprecated way to describe legacy decaying_average.
  # standard_decaying_average - This is the preferred way to describe the new decaying_average.
  # if this FF is ENABLED then on user facing side(Only UI)
  # end-user will use "weighted_average" for old "decaying_average"
  # and "decaying_average" for "standard_decaying_average"
  # eg:
  # |User Facing Name | DB Value                                                                           |
  # |------------------------------------------------------------------------------------------------------|
  # |decaying_average | standard_decaying_average [after data migration will be named as decaying_average] |
  # |weighted_average | decaying_average [after data migration this old decaying_average                   |
  # |                 | will be named as weighted_average]                                                 |
  # |------------------------------------------------------------------------------------------------------|
  def adjust_calculation_method(method = self.calculation_method)
    if new_decaying_average_calculation_ff_enabled?
      self.calculation_method = "decaying_average" if method == "weighted_average"
    elsif method == "standard_decaying_average"
      # If FF is disabled “decaying_average” and “standard_decaying_average”
      # will all be treated the same and calculate using the legacy approach.
      # Any time a learning outcome is updated / saved it will have the calculation_method
      # updated back to being “decaying_average”.
      self.calculation_method = "decaying_average"
    end
  end

  def default_calculation_method
    if new_decaying_average_calculation_ff_enabled?
      "standard_decaying_average"
    else
      "decaying_average"
    end
  end

  def default_calculation_int(method = self.calculation_method)
    case method
    when "decaying_average", "standard_decaying_average", "weighted_average" then 65
    when "n_mastery" then 5
    else nil
    end
  end

  def align(asset, context, opts = {})
    tag = find_or_create_tag(asset, context)
    tag.tag = determine_tag_type(opts[:mastery_type])
    tag.mastery_score = opts[:mastery_score] if opts[:mastery_score]
    tag.save

    if context.is_a? Course
      create_missing_outcome_link(context)
      if MasterCourses::MasterTemplate.is_master_course?(context)
        # mark for re-sync
        context.learning_outcome_links.where(content: self).touch_all
        touch
      end
    end
    tag
  end

  def remove_alignment(alignment_id, context)
    tag = alignments.where({
                             context_id: context,
                             context_type: context.class_name,
                             id: alignment_id
                           }).first
    tag&.destroy
    tag
  end

  def self.update_alignments(asset, context, new_outcome_ids)
    old_outcome_ids = asset.learning_outcome_alignments
                           .where.not(learning_outcome_id: nil)
                           .pluck(:learning_outcome_id)
                           .uniq

    defunct_outcome_ids = old_outcome_ids - new_outcome_ids
    unless defunct_outcome_ids.empty?
      asset.learning_outcome_alignments
           .where(learning_outcome_id: defunct_outcome_ids)
           .update_all(workflow_state: "deleted")
    end

    missing_outcome_ids = new_outcome_ids - old_outcome_ids
    unless missing_outcome_ids.empty?
      LearningOutcome.where(id: missing_outcome_ids).each do |learning_outcome|
        learning_outcome.align(asset, context)
      end
    end
  end

  def title
    short_description
  end

  def title=(new_title)
    self.short_description = new_title
  end

  workflow do
    state :active
    state :archived
    state :retired
    state :deleted
  end

  def cached_context_short_name
    @cached_context_name ||= Rails.cache.fetch(["short_name_lookup", context_code].cache_key) do
      context.short_name rescue ""
    end
  end

  def self.default_rubric_criterion
    {
      description: t("No Description"),
      ratings: [
        {
          description: I18n.t("Exceeds Expectations"),
          points: 5
        },
        {
          description: I18n.t("Meets Expectations"),
          points: 3
        },
        {
          description: I18n.t("Does Not Meet Expectations"),
          points: 0
        }
      ],
      mastery_points: 3,
      points_possible: 5
    }
  end

  # Set default mastery level and color scheme for outcome ratings
  # will not override current values stored in ratings
  def find_or_set_rating_defaults(ratings, mastery_points)
    mastery_index = find_mastery_index(ratings, mastery_points)
    set_mastery_level(ratings, mastery_index)
    if meets_color_criteria(ratings, mastery_index)
      find_or_set_default_mastery_colors(ratings, mastery_index)
    end
    ratings
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
          description: rating[:description] || t(:no_comment, "No Comment"),
          points: rating[:points].to_f || 0.00
        }
      end
      criterion[:ratings] = criterion[:ratings].sort_by { |r| r[:points] }.reverse
      criterion[:mastery_points] = (hash[:mastery_points] || criterion[:ratings][0][:points]).to_f
      criterion[:points_possible] = criterion[:ratings][0][:points] rescue 0
    else
      criterion = self.class.default_rubric_criterion
    end

    self.data[:rubric_criterion] = criterion
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    # delete total_outcomes cache for each active learning_outcome_links contexts
    clear_total_outcomes_cache

    # delete any remaining links to the outcome. in case of UI, this was
    # triggered by ContentTag#destroy and the checks have already run, we don't
    # need to do it again. in case of console, we don't care to force the
    # checks. so just an update_all of workflow_state will do.
    ContentTag.learning_outcome_links.active.where(content_id: self).update_all(workflow_state: "deleted")

    # in case this got called in a console, delete the alignments also. the UI
    # won't (shouldn't) allow deleting the outcome if there are still
    # alignments, so this will be a no-op in that case. either way, these are
    # not outcome links, so ContentTag#destroy is just changing the
    # workflow_state; use update_all for efficiency.
    ContentTag.learning_outcome_alignments.active.where(learning_outcome_id: self).update_all(workflow_state: "deleted")

    self.workflow_state = "deleted"
    save!
  end

  def archive!
    # Only active outcomes can be archived
    if workflow_state == "active"
      self.workflow_state = "archived"
      self.archived_at = Time.now.utc
      save!
    elsif workflow_state == "deleted"
      raise ActiveRecord::RecordNotSaved, "Cannot archive a deleted LearningOutcome"
    end
  end

  def unarchive!
    # Only archived outcomes can be unarchived
    if workflow_state == "archived"
      self.workflow_state = "active"
      self.archived_at = nil
      save!
    elsif workflow_state == "deleted"
      raise ActiveRecord::RecordNotSaved, "Cannot unarchive a deleted LearningOutcome"
    end
  end

  def assessed?(course = nil)
    if course
      learning_outcome_results.active.where(context_id: course, context_type: "Course").exists?
    elsif learning_outcome_results.active.loaded?
      learning_outcome_results.active.any?
    else
      learning_outcome_results.active.exists?
    end
  end

  def tie_to(context)
    @tied_context = context
  end

  def mastery_points
    rubric_criterion[:mastery_points]
  end

  def points_possible
    rubric_criterion[:points_possible]
  end

  def mastery_percent
    return unless mastery_points && points_possible

    (mastery_points / points_possible).round(2)
  end

  def artifacts_count_for_tied_context
    codes = [@tied_context.asset_string]
    if @tied_context.is_a?(Account)
      codes = if @tied_context == context
                "all"
              else
                @tied_context.all_courses.select(:id).map(&:asset_string)
              end
    end
    learning_outcome_results.active.for_context_codes(codes).count
  end

  def self.delete_if_unused(ids)
    tags = ContentTag.active.where(content_id: ids, content_type: "LearningOutcome").to_a
    to_delete = []
    ids.each do |id|
      to_delete << id unless tags.any? { |t| t.content_id == id }
    end
    LearningOutcome.where(id: to_delete).update_all(workflow_state: "deleted", updated_at: Time.now.utc)
  end

  def self.ensure_presence_in_context(outcome_ids, context)
    return unless outcome_ids && context

    missing_outcomes = LearningOutcome.where(id: outcome_ids)
                                      .where.not(id: context.linked_learning_outcomes.select(:id))
                                      .active
    missing_outcomes.each { |o| context.root_outcome_group.add_outcome(o) }
  end

  scope(:for_context_codes, ->(codes) { where(context_code: codes) })
  scope(:active, -> { where("learning_outcomes.workflow_state NOT IN ('deleted', 'archived')") })
  scope(:active_first, -> { order(Arel.sql("CASE WHEN workflow_state = 'active' THEN 0 ELSE 1 END")) })
  scope(:has_result_for_user,
        lambda do |user|
          joins(:learning_outcome_results)
            .where(<<~SQL.squish, user)
              learning_outcomes.id=learning_outcome_results.learning_outcome_id
              AND learning_outcome_results.workflow_state <> 'deleted'
              AND learning_outcome_results.user_id=?
            SQL
            .order(best_unicode_collation_key("short_description"))
        end)

  scope :global, -> { where(context_id: nil) }

  def propagate_changes_to_rubrics
    # exclude new outcomes
    return if saved_change_to_id?
    return if !saved_change_to_data? &&
              !saved_change_to_short_description? &&
              !saved_change_to_description?

    delay_if_production.update_associated_rubrics
  end

  def update_associated_rubrics
    updateable_rubrics.in_batches(of: 100).each do |relation|
      Rubric.transaction do
        relation.lock("FOR UPDATE OF rubrics").each do |rubric|
          rubric.update_learning_outcome_criteria(self)
        end
      end
    end
  end

  def updateable_rubrics
    conds = { learning_outcome_id: id, content_type: "Rubric", workflow_state: "active" }
    # Find all unassessed, active rubrics aligned to this outcome, referenced by no more than one assignment
    Rubric.where(
      id: Rubric
        .active
        .joins(:learning_outcome_alignments)
        .where(content_tags: conds)
        .with_at_most_one_association
        .select("rubrics.id")
    ).unassessed
  end

  def updateable_rubrics?
    updateable_rubrics.exists?
  end

  private

  def create_missing_outcome_link(context)
    context_outcomes = context.learning_outcome_links.where(
      content_type: "LearningOutcome"
    ).pluck(:content_id)

    unless context_outcomes.include?(id)
      context.root_outcome_group.add_outcome(self)
    end
  end

  def find_or_create_tag(asset, context)
    alignments.find_or_create_by(
      content: asset,
      tag_type: "learning_outcome",
      context:
    ) do |_a|
      InstStatsd::Statsd.increment("learning_outcome.align", tags: { type: asset.class.name })
    end
  end

  def determine_tag_type(mastery_type)
    case mastery_type
    when "points", "points_mastery"
      "points_mastery"
    else
      "explicit_mastery"
    end
  end

  def clear_total_outcomes_cache
    return unless improved_outcomes_management?

    ContentTag.learning_outcome_links
              .active
              .distinct
              .where(content_id: id)
              .select(<<~SQL.squish)
                root_account_id,
                (CASE WHEN context_type='LearningOutcomeGroup' THEN NULL ELSE context_type END) context_type,
                (CASE WHEN context_type='LearningOutcomeGroup' THEN NULL ELSE context_id END) context_id
              SQL
              .map do |ct|
      Outcomes::LearningOutcomeGroupChildren.new(ct.context).clear_total_outcomes_cache
    end
  end

  def improved_outcomes_management?
    return context.root_account.feature_enabled?(:improved_outcomes_management) if context

    LoadAccount.default_domain_root_account.feature_enabled?(:improved_outcomes_management)
  end

  # finds rating set as mastery and returns index of rating in ratings
  def find_mastery_index(ratings, mastery_points)
    length = ratings.length
    mastery_index = case length
                    when 1, 2, 3, 4
                      0
                    else
                      1
                    end

    # If mastery_points exactly matches a rating, then set mastery_index to that rating
    ratings.each_with_index do |rating, i|
      if rating[:points] == mastery_points
        mastery_index = i
        break
      end
    end

    mastery_index
  end

  # checks to see if ratings and mastery level meet certain criteria to be assigned default colors
  def meets_color_criteria(ratings, mastery_index)
    length = ratings.length
    case length
    # 1, 2, or 3 ratings will always get colors
    when 1, 2, 3
      true
    # If mastery_index is set to 2 then use numbers
    when 4
      (mastery_index != 2)
    # If mastery_index is set to 0, 2, 3, 4, or 5 then use numbers
    when 5, 6
      mastery_index == 1
      # Anything larger than 6 ratings will use numbers
    else
      false
    end
  end

  # set color defaults for ratings in an outcome
  # rubocop:disable Lint/DuplicateBranch
  def find_or_set_default_mastery_colors(ratings, mastery_index)
    length = ratings.length
    # apply appropriate defaults for each length if
    case length
    when 1
      ratings[0][:color] ||= "0B874B"

    when 2
      ratings[0][:color] ||= "0B874B"
      ratings[1][:color] ||= "555555"

    when 3
      ratings[0][:color] ||= (mastery_index == 1) ? "0374B5" : "0B874B"
      ratings[1][:color] ||= (mastery_index == 1) ? "0B874B" : "FAB901"
      ratings[2][:color] ||= "555555"

    when 4
      ratings[0][:color] ||= (mastery_index == 1) ? "0374B5" : "0B874B"
      ratings[1][:color] ||= (mastery_index == 1) ? "0B874B" : "FAB901"
      ratings[2][:color] ||= (mastery_index == 1) ? "FAB901" : "E0061F"
      ratings[3][:color] ||= "555555"

    when 5
      ratings[0][:color] ||= "0374B5"
      ratings[1][:color] ||= "0B874B"
      ratings[2][:color] ||= "FAB901"
      ratings[3][:color] ||= "E0061F"
      ratings[4][:color] ||= "555555"

    when 6
      ratings[0][:color] ||= "0374B5"
      ratings[1][:color] ||= "0B874B"
      ratings[2][:color] ||= "FAB901"
      ratings[3][:color] ||= "D97900"
      ratings[4][:color] ||= "E0061F"
      ratings[5][:color] ||= "555555"
    end
  end
  # rubocop:enable Lint/DuplicateBranch

  def set_mastery_level(ratings, mastery_index)
    ratings.each_with_index do |rating, i|
      rating[:mastery] = (i == mastery_index)
    end
  end
end
