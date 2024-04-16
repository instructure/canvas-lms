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

class GradingStandard < ActiveRecord::Base
  include Canvas::SoftDeletable

  belongs_to :context, polymorphic: [:account, :course], required: true
  belongs_to :user
  has_many :assignments
  has_many :courses
  has_many :assessed_course_assignments,
           lambda {
             where(grading_standard_id: nil, grading_type: ["letter_grade", "gpa_scale"])
               .joins(:submissions)
               .where("submissions.workflow_state='graded'")
           },
           through: :courses,
           source: :assignments

  has_many :accounts, inverse_of: :grading_standard, dependent: :nullify

  validates :workflow_state, presence: true
  validates :data, presence: true
  validate :valid_grading_scheme_data
  validate :full_range_scheme
  validate :scaling_factor_points_based
  before_destroy :prevent_deletion_of_used_schemes

  # version 1 data is an array of [ letter, max_integer_value ]
  # we created a version 2 because this is ambiguous once we added support for
  # fractional values -- 89 used to actually mean < 90, so 89.9999... , but
  # 89.5 actually means 89.5. by switching the version 2 format to [ letter,
  # min_integer_value ], we remove the ambiguity.
  #
  # version 1:
  #
  # [ 'A',  100 ],
  # [ 'A-',  93 ]
  #
  # It's implied that a 93.9 is actually an A-, not an A, but once we add fractional cutoffs to the mix, that implication breaks down.
  #
  # version 2:
  #
  # [ 'A',   94   ],
  # [ 'A-',  89.5 ]
  #
  # No more ambiguity, because anything >= 94 is an A, and anything < 94 and >=
  # 89.5 is an A-.
  serialize :data

  before_save :trim_whitespace, if: :will_save_change_to_data?
  before_save :update_usage_count
  attr_accessor :default_standard

  before_create :set_root_account_id

  workflow do
    state :active do
      event :archive!, transitions_to: :archived
    end
    state :deleted
    state :archived do
      event :unarchive!, transitions_to: :active
    end
  end

  scope :active, -> { where("grading_standards.workflow_state = 'active'") }
  scope :archived, -> { where("grading_standards.workflow_state = 'archived'") }
  scope :sorted, -> { order(Arel.sql("usage_count >= 3 DESC")).order(nulls(:last, best_unicode_collation_key("title"))) }
  scope :for_context, lambda { |context|
    context_codes = [context.asset_string]
    context_codes = context_codes.concat(Account.all_accounts_for(context).map(&:asset_string)).uniq
    where(context_code: context_codes)
  }

  VERSION = 2

  set_policy do
    given { |user| context.grants_right?(user, :manage_grades) }
    can :manage
  end

  def self.for(context, include_archived: false)
    unless Account.site_admin.feature_enabled?(:archived_grading_schemes)
      return GradingStandard.active.for_context(context)
    end

    case context
    when Account
      for_account(context)
    when Course
      for_course(context, include_archived:)
    else
      for_assignment(context, include_archived:)
    end
  end

  def self.for_assignment(assignment, include_archived: false)
    standards = include_archived ? GradingStandard.for_context(assignment.context) : GradingStandard.active.for_context(assignment.context)
    standards = GradingStandard.where(id: standards)
    course_scheme = assignment.context.grading_standard
    standards = standards.union(GradingStandard.where(id: course_scheme)) if course_scheme&.archived?
    if assignment.grading_standard&.archived?
      standards = standards.union(GradingStandard.where(id: assignment.grading_standard))
    end
    standards
  end

  def self.for_course(course, include_archived: false)
    standards = include_archived ? GradingStandard.for_context(course) : GradingStandard.active.for_context(course)
    standards = GradingStandard.where(id: standards)
    standards = standards.union(GradingStandard.where(id: course.grading_standard)) if course.grading_standard&.archived?
    standards
  end

  def self.for_account(account)
    GradingStandard.active.union(GradingStandard.archived).for_context(account)
  end

  def version
    read_attribute(:version).presence || 1
  end

  def ordered_scheme
    # Convert to BigDecimal so we don't get weird float behavior: 0.545 * 100 (gives 54.50000000000001 with floats)
    @ordered_scheme ||= grading_scheme.to_a
                                      .map { |grade_letter, percent| [grade_letter, BigDecimal(percent.to_s)] }
                                      .sort_by { |_, percent| -percent }
  end

  def place_in_scheme(key_name)
    # look for keys with only digits and a single '.'
    key_name_str = key_name.to_s
    if key_name_str&.match?(/\A(\d*[.])?\d+\Z/)
      # compare numbers
      # second condition to filter letters so zeros work properly ("A".to_d == 0)
      ordered_scheme.index { |g, _| g.to_d == key_name.to_d && g.to_s.match(/\A(\d*[.])?\d+\Z/) }
    else
      idx = index_of_key(key_name_str)
      if idx.nil? && minus_grade?(key_name_str)
        idx = index_of_key(key_name_str.sub(/−$/, "-"))
      end

      idx
    end
  end

  # e.g. convert B to 86
  def grade_to_score(grade)
    idx = place_in_scheme(grade)
    if idx == 0
      100.0
    # if there's room to step down at least one whole number, do that. this
    # matches the previous behavior, before we added support for fractional
    # grade cutoffs.
    # otherwise, we step down just 1/10th of a point, which is the
    # granularity we support right now
    elsif idx && (ordered_scheme[idx].last - ordered_scheme[idx - 1].last).abs >= BigDecimal("0.01")
      if points_based
        (((ordered_scheme[idx - 1].last * scaling_factor) - BigDecimal("0.1")) / scaling_factor) * BigDecimal("100.0")
      else
        (ordered_scheme[idx - 1].last * BigDecimal("100.0")) - BigDecimal("1.0")
      end
    elsif idx
      if points_based
        (((ordered_scheme[idx - 1].last * scaling_factor) - BigDecimal("0.1")) / scaling_factor) * BigDecimal("100.0")
      else
        (ordered_scheme[idx - 1].last * BigDecimal("100.0")) - BigDecimal("0.1")
      end
    else
      nil
    end
  end

  # e.g. convert 89.7 to B+
  def score_to_grade(score)
    score = 0 if score < 0
    # assign the highest grade whose min cutoff is less than the score
    # if score is less than all scheme cutoffs, assign the lowest grade
    score = BigDecimal(score.to_s) # Cast this to a BigDecimal too or comparisons get wonky
    ordered_scheme.max_by { |_, lower_bound| (score >= lower_bound * BigDecimal("100.0")) ? lower_bound : -lower_bound }[0]
  end

  def data=(new_val)
    self.version = VERSION
    # round values to the nearest 0.01 (0.0001 since e.g. 78 is stored as .78)
    # and dup the data while we're at it. (new_val.dup only dups one level, the
    # elements of new_val.dup are the same objects as the elements of new_val)
    if new_val.respond_to?(:map)
      new_val = new_val.map { |grade_name, lower_bound| [grade_name, lower_bound.round(4)] }
    end
    write_attribute(:data, new_val)
    @ordered_scheme = nil
  end

  def data
    unless version == VERSION
      data = read_attribute(:data)
      data = GradingStandard.upgrade_data(data, version) unless data.nil?
      self.data = data
    end
    read_attribute(:data)
  end

  def self.upgrade_data(data, version)
    case version.to_i
    when VERSION
      data
    when 1
      0.upto(data.length - 2) do |i|
        data[i][1] = data[i + 1][1] + 0.01
      end
      data[-1][1] = 0
      data
    else
      raise "Unknown GradingStandard data version: #{version}"
    end
  end

  def trim_whitespace
    data.each do |scheme|
      scheme.first.strip!
    end
  end
  private :trim_whitespace

  def update_usage_count
    self.usage_count = assignments.active.count
    self.context_code = "#{context_type.underscore}_#{context_id}" rescue nil
  end

  def prevent_deletion_of_used_schemes
    return unless Account.site_admin.feature_enabled?(:archived_grading_schemes) && assessed_assignment?

    errors.add(:workflow_state, "You cannot delete a used scheme")
    throw :error
  end
  private :prevent_deletion_of_used_schemes

  def assessed_assignment?
    GuardRail.activate(:secondary) do
      unless Account.site_admin.feature_enabled?(:archived_grading_schemes)
        return assignments.active.joins(:submissions).where("submissions.workflow_state='graded'").exists?
      end

      return true if assessed_course_assignments.exists? || assessed_assignments.exists?

      false
    end
  end

  def used_locations
    assessed_assignments.union(assessed_course_assignments)
  end

  def assessed_assignments
    assignments
      .except(:order).joins(:submissions)
      .where("submissions.workflow_state='graded'")
  end

  delegate :name, to: :context, prefix: true

  def update_data(params)
    self.data = params.to_a.sort_by { |_, lower_bound| lower_bound }.reverse
  end

  def display_name
    res = ""
    res += user.name + ", " rescue ""
    res += context.name rescue ""
    res = t("unknown_grading_details", "Unknown Details") if res.empty?
    res
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"

    run_callbacks(:destroy) { save }
  end

  def grading_scheme
    res = {}
    data.sort_by { |_, lower_bound| lower_bound }.reverse_each do |grade_name, lower_bound|
      res[grade_name] = lower_bound.to_f
    end
    res
  end

  def standard_data=(params = {})
    params ||= {}
    res = {}
    params.each_value do |row|
      res[row[:name]] = (row[:value].to_f / 100.0) if row[:name] && row[:value]
    end
    self.data = res.to_a.sort_by { |_, lower_bound| lower_bound }.reverse
  end

  def valid_grading_scheme_data
    errors.add(:data, "grading scheme values cannot be negative") if data.present? && data.any? { |v| v[1] < 0 }
    errors.add(:data, "grading scheme cannot contain duplicate values") if data.present? && data.pluck(1) != data.pluck(1).uniq
    errors.add(:data, "a grading scheme name is too long") if data.present? && data.any? { |v| v[0].length > self.class.maximum_string_length }
  end

  def scaling_factor_points_based
    errors.add(:scaling_factor, "must be 1 if scheme points_based is false") if !points_based && scaling_factor != 1
  end

  def full_range_scheme
    if data.present? && data.none? { |datum| datum[1].abs < Float::EPSILON }
      errors.add(:data, "grading schemes must have 0% for the lowest grade")
    end
  end
  private :full_range_scheme

  def self.default_grading_standard
    default_grading_scheme.to_a.sort_by { |_, lower_bound| lower_bound }.reverse
  end

  def self.default_instance
    gs = GradingStandard.new
    gs.data = default_grading_scheme
    gs.title = "Default Grading Scheme"
    gs.default_standard = true
    gs
  end

  def default_standard?
    !!default_standard
  end

  def self.default_grading_scheme
    {
      "A" => 0.94,
      "A-" => 0.90,
      "B+" => 0.87,
      "B" => 0.84,
      "B-" => 0.80,
      "C+" => 0.77,
      "C" => 0.74,
      "C-" => 0.70,
      "D+" => 0.67,
      "D" => 0.64,
      "D-" => 0.61,
      "F" => 0.0,
    }
  end

  def set_root_account_id
    self.root_account_id ||= context.is_a?(Account) ? context.resolved_root_account_id : context.root_account_id
  end

  private

  def minus_grade?(grade)
    !!grade && /.+−$/.match?(grade)
  end

  def index_of_key(key)
    ordered_scheme.index { |scheme_key, _| scheme_key.to_s.casecmp?(key) }
  end
end
