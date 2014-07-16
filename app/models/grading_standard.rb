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

class GradingStandard < ActiveRecord::Base
  include Workflow
  attr_accessible :title, :standard_data
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Account', 'Course']
  belongs_to :user
  has_many :assignments

  EXPORTABLE_ATTRIBUTES = [:id, :title, :data, :context_id, :context_type, :created_at, :updated_at, :user_id, :usage_count, :context_code, :workflow_state, :version]
  EXPORTABLE_ASSOCIATIONS = [:context, :user, :assignments]

  validates_presence_of :context_id, :context_type, :workflow_state, :data
  validate :valid_grading_scheme_data

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

  before_save :update_usage_count

  workflow do
    state :active
    state :deleted
  end

  scope :active, where("grading_standards.workflow_state<>'deleted'")
  scope :sorted, lambda { order("usage_count >= 3 DESC").order(nulls(:last, best_unicode_collation_key('title'))) }

  VERSION = 2

  def version
    read_attribute(:version).presence || 1
  end

  def ordered_scheme
    @ordered_scheme ||= grading_scheme.to_a.sort_by { |_, percent| -percent }
  end

  def place_in_scheme(key_name)
    # look for keys with only digits and a single '.'
    if key_name.to_s =~ (/\A(\d*[.])?\d+\Z/)
    # compare numbers
      # second condition to filter letters so zeros work properly ("A".to_f == 0)
      ordered_scheme.index { |g, _| g.to_f == key_name.to_f && g.to_s.match(/\A(\d*[.])?\d+\Z/)}
    else
    # compare words
      ordered_scheme.index { |g, _| g.to_s.downcase == key_name.to_s.downcase}
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
    elsif idx && (ordered_scheme[idx].last - ordered_scheme[idx - 1].last).abs >= 0.01
      ordered_scheme[idx - 1].last * 100.0 - 1.0
    elsif idx
      ordered_scheme[idx - 1].last * 100.0 - 0.1
    else
      nil
    end
  end

  # e.g. convert 89.7 to B+
  def score_to_grade(score)
    score = 0 if score < 0
    # assign the highest grade whose min cutoff is less than the score
    # if score is less than all scheme cutoffs, assign the lowest grade
    ordered_scheme.max_by {|grade_name, lower_bound| score >= lower_bound * 100 ? lower_bound : -lower_bound }[0]
  end

  def data=(new_val)
    self.version = VERSION
    # round values to the nearest 0.01 (0.0001 since e.g. 78 is stored as .78)
    # and dup the data while we're at it. (new_val.dup only dups one level, the
    # elements of new_val.dup are the same objects as the elements of new_val)
    new_val = new_val.map{ |grade_name, lower_bound| [ grade_name, (lower_bound * 10000).to_i / 10000.0 ] }
    write_attribute(:data, new_val)
    @ordered_scheme = nil
  end

  def data
    unless self.version == VERSION
      data = read_attribute(:data)
      data = GradingStandard.upgrade_data(data, self.version)
      self.data = data
    end
    read_attribute(:data)
  end

  def self.upgrade_data(data, version)
    case version.to_i
    when VERSION
      data
    when 1
      0.upto(data.length-2) do |i|
        data[i][1] = data[i+1][1] + 0.01
      end
      data[-1][1] = 0
      data
    else
      raise "Unknown GradingStandard data version: #{version}"
    end
  end

  def update_usage_count
    self.usage_count = self.assignments.active.count
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end

  set_policy do
    given {|user| true }
    can :read and can :create

    given {|user| self.assignments.active.length < 2}
    can :update and can :delete
  end

  def update_data(params)
    self.data = params.to_a.sort_by{|_, lower_bound| lower_bound}.reverse
  end

  def display_name
    res = ""
    res += self.user.name + ", " rescue ""
    res += self.context.name rescue ""
    res = t("unknown_grading_details", "Unknown Details") if res.empty?
    res
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save
  end

  def grading_scheme
    res = {}
    self.data.sort_by{|_, lower_bound| lower_bound}.reverse.each do |grade_name, lower_bound|
      res[grade_name] = lower_bound.to_f
    end
    res
  end

  def self.standards_for(context)
    context_codes = [context.asset_string]
    context_codes.concat Account.all_accounts_for(context).map(&:asset_string)
    GradingStandard.active.where(:context_code => context_codes.uniq)
  end

  def standard_data=(params={})
    params ||= {}
    res = {}
    params.each do |key, row|
      res[row[:name]] = (row[:value].to_f / 100.0) if row[:name] && row[:value]
    end
    self.data = res.to_a.sort_by{|_, lower_bound| lower_bound}.reverse
  end

  def valid_grading_scheme_data
    self.errors.add(:data, 'grading scheme values cannot be negative') if self.data.any?{ |v| v[1] < 0 }
    self.errors.add(:data, 'grading scheme cannot contain duplicate values') if self.data.map{|v| v[1]} != self.data.map{|v| v[1]}.uniq
  end

  def self.default_grading_standard
    default_grading_scheme.to_a.sort_by{|_, lower_bound| lower_bound}.reverse
  end

  def self.default_instance
    gs = GradingStandard.new()
    gs.data = default_grading_scheme
    gs.title = "Default Grading Standard"
    gs
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
end
