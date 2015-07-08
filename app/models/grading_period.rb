#
# Copyright (C) 2015 Instructure, Inc.
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

class GradingPeriod < ActiveRecord::Base
  include Canvas::SoftDeletable

  attr_accessible :weight, :start_date, :end_date, :title

  belongs_to :grading_period_group, inverse_of: :grading_periods
  has_many :grading_period_grades, dependent: :destroy

  validates :title, :start_date, :end_date, :grading_period_group_id, presence: true
  validate :start_date_is_before_end_date
  validate :not_overlapping

  set_policy do
    given { |user| self.grading_period_group.grants_right?(user, :read) }
    can :read

    given { |user| self.grading_period_group.grants_right?(user, :manage) }
    can :manage
  end

  scope :current, -> do
    where("start_date <= :now AND end_date >= :now", now: Time.zone.now)
  end

  scope :grading_periods_by, ->(context_with_ids) do
    joins(:grading_period_group).where(grading_period_groups: context_with_ids)
  end

  # Takes a context and returns an Array (not an ActiveRecord::Relation)
  # which means this method is not .where() chainable
  def self.for(context)
    "GradingPeriod::#{context.class}GradingPeriodFinder"
      .constantize
      .new(context)
      .grading_periods
  end

  # Takes a context and a grading_period_id and returns a grading period
  # if it is in the for collection. Uses Enumberable#find to query
  # collection.
  def self.context_find(context, grading_period_id)
    self.for(context).find do |grading_period|
      grading_period.id == grading_period_id.to_i
    end
  end

  def assignments(assignment_scope)
    # TODO: avoid wasteful queries
    assignments = assignment_scope.where( "due_at BETWEEN ? AND ?", start_date, end_date)

    if last?
      assignments + assignment_scope.where(due_at: nil)
    else
      assignments
    end
  end

  def current?
    in_date_range?(Time.zone.now)
  end

  def in_date_range?(date)
    start_date <= date && end_date >= date
  end

  def is_closed?
    Time.now > end_date
  end

  def last?
    grading_period_group
      .grading_periods
      .active
      .sort_by(&:end_date)
      .last == self
  end

  def overlapping?
    overlaps.active.exists?
  end

  private
  scope :overlaps, ->(from, to) do
    # sourced: http://c2.com/cgi/wiki?TestIfDateRangesOverlap
    where('((start_date < ?) and (end_date > ?))', to, from)
  end

  def not_overlapping
    if overlapping?
      errors.add(:base, t('errors.overlap_message',
        "Grading period cannot overlap with existing grading periods in group"))
    end
  end

  def overlaps
    siblings.overlaps(start_date, end_date)
  end

  def siblings
    grading_periods = GradingPeriod.where(
      grading_period_group_id: grading_period_group_id
    )
    if new_record?
      grading_periods
    else
      grading_periods.where("id <> ?", id)
    end
  end

  def start_date_is_before_end_date
    if start_date && end_date && end_date < start_date
      errors.add(:end_date, t('errors.invalid_grading_period_end_date',
                              'Grading period end date precedes start date'))
    end
  end
end
