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
  attr_accessible :context, :description, :short_description, :title, :display_name
  attr_accessible :rubric_criterion, :vendor_guid, :calculation_method, :calculation_int

  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Account', 'Course']
  has_many :learning_outcome_results
  has_many :alignments, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND content_tags.workflow_state != ?', 'learning_outcome', 'deleted']

  EXPORTABLE_ATTRIBUTES = [:id, :context_id, :context_type, :short_description, :context_code, :description, :data, :workflow_state, :created_at, :updated_at, :vendor_guid, :low_grade, :high_grade]
  EXPORTABLE_ASSOCIATIONS = [:context, :learning_outcome_results, :alignments]
  serialize :data

  before_validation :adjust_calculation_int
  before_save :infer_defaults
  before_create :infer_calculation_method_defaults

  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :short_description, :maximum => maximum_string_length
  validates_presence_of :short_description, :workflow_state
  sanitize_field :description, CanvasSanitize::SANITIZE
  validate :validate_calculation_options

  CALCULATION_METHODS = %w[decaying_average n_mastery highest latest]
  VALID_CALCULATION_INTS = {
    "decaying_average" => (1..99),
    "n_mastery" => (2..5),
    "highest" => [],
    "latest" => [],
  }

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

  def infer_calculation_method_defaults
      self.calculation_method ||= default_calculation_method
      self.calculation_int ||= default_calculation_int
  end

  def validate_calculation_options
    if assessed?
      validate_calculation_changes_after_asessing
    else
      validate_calculation_method
      validate_calculation_int
    end
  end

  def validate_calculation_changes_after_asessing
    # if we've been used to assess a student, refuse to accept any changes to our calculation options
    if calculation_method_changed?
      errors.add(:calculation_method, t(
        "This outcome has been used to assess a student. Calculation method is fixed at %{old_value}",
        :old_value => calculation_method_was
      ))
    end

    if calculation_int_changed?
      errors.add(:calculation_int, t(
        "This outcome has been used to assess a student. Calculation int is fixed at %{old_value}",
        :old_value => calculation_int_was
      ))
    end
  end

  def validate_calculation_method_nil
    # don't let the calculation_method be set to nil, unless we are a new record (in which case the default
    # will be inferred), or we previously were nil
    if calculation_method.nil?
      # In the case we were previously nil, it is ok to leave it nil because we want to preserve the old behavior
      # of using 'highest' as the calculation method (the new default is "decaying_average"
      # Having a nil calculation_method is how we identify learning outcomes that existed before we added
      # the learning outcome calculation_method and calculation_int
      unless new_record?
        unless calculation_method_was.nil?
          errors.add(:calculation_method, t(
            "Calculation method cannot be set to nil. A sensible default is %{default_calculation_method}",
            :default_calculation_method => default_calculation_method
          ))
        end
      end
    end
  end

  def validate_calculation_method
    # Don't add the error message for a nil calculation method because one is already added
    # in our explicit check for nil
    if calculation_method.nil?
      validate_calculation_method_nil
    else
      unless valid_calculation_method?(calculation_method)
        errors.add(:calculation_method, t(
          "'%{calculation_method}' is not a valid calculation_method. Valid options are %{valid_options}",
          :calculation_method => calculation_method, :valid_options => CALCULATION_METHODS.to_s
        ))
      end
    end
  end

  def validate_calculation_int
    unless valid_calculation_int?(calculation_int, calculation_method)
      errors.add(:calculation_int, t(
        "'%{calculation_int}' is not a valid calculation_int for calculation_method of '%{calculation_method}'. Valid range is '%{valid_calculation_ints}'",
        :calculation_int => calculation_int, :calculation_method => calculation_method,
        :valid_calculation_ints => valid_calculation_ints
      ))
    end
  end

  def valid_calculation_method?(method=self.calculation_method)
    CALCULATION_METHODS.include?(method)
  end

  def valid_calculation_ints(method=self.calculation_method)
    VALID_CALCULATION_INTS[method]
  end

  def valid_calculation_int?(int, method=self.calculation_method)
    if valid_calculation_method?(method)
      valid_ints = valid_calculation_ints(method)
      (int.nil? && valid_ints.to_a.empty?) || valid_ints.include?(int)
    else
      true
    end
  end

  def adjust_calculation_int
    # If we are setting calculation_method to latest or highest,
    # set calculation_int nil unless it is a new record (meaning it was set explicitly)
    if %w[highest latest].include?(calculation_method) && calculation_method_changed?
      self.calculation_int = nil unless new_record?
    end
  end

  def default_calculation_method
    "decaying_average"
  end

  def default_calculation_int(method=self.calculation_method)
    case method
    when 'decaying_average' then 75
    when 'n_mastery' then 5
    else nil
    end
  end

  def align(asset, context, opts={})
    tag = self.alignments.where(content_id: asset, content_type: asset.class.to_s, tag_type: 'learning_outcome', context_id: context, context_type: context.class.to_s).first
    tag ||= self.alignments.create(:content => asset, :tag_type => 'learning_outcome', :context => context)
    mastery_type = opts[:mastery_type]
    if mastery_type == 'points' || mastery_type == 'points_mastery'
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

  def remove_alignment(asset, context, opts={})
    tag = self.alignments.where(content_id: asset, content_type: asset.class.to_s, tag_type: 'learning_outcome', context_id: context, context_type: context.class.to_s).first
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

  def assessed?
    learning_outcome_results.exists?
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
    tags = ContentTag.active.where(content_id: ids, content_type: 'LearningOutcome').to_a
    to_delete = []
    ids.each do |id|
      to_delete << id unless tags.any?{|t| t.content_id == id }
    end
    LearningOutcome.where(:id => to_delete).update_all(:workflow_state => 'deleted', :updated_at => Time.now.utc)
  end

  scope :for_context_codes, lambda { |codes| where(:context_code => codes) }
  scope :active, -> { where("learning_outcomes.workflow_state<>'deleted'") }
  scope :has_result_for, lambda { |user|
    joins(:learning_outcome_results).
        where("learning_outcomes.id=learning_outcome_results.learning_outcome_id AND learning_outcome_results.user_id=?", user).
        order(best_unicode_collation_key('short_description'))
  }

  scope :global, -> { where(:context_id => nil) }
end
