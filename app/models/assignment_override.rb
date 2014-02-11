#
# Copyright (C) 2012 Instructure, Inc.
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

class AssignmentOverride < ActiveRecord::Base
  include Workflow
  include TextHelper

  simply_versioned :keep => 10

  attr_accessible
  EXPORTABLE_ATTRIBUTES = [
    :id, :created_at, :updated_at, :assignment_id, :assignment_version, :set_type, :set_id, :title, :workflow_state, :due_at_overridden, :due_at, :all_day,
    :all_day_date, :unlock_at_overridden, :unlock_at, :lock_at_overridden, :lock_at, :quiz_id, :quiz_version
  ]

  EXPORTABLE_ASSOCIATIONS = [:assignment, :quiz, :assignment_override_students]

  attr_accessor :dont_touch_assignment

  belongs_to :assignment
  belongs_to :quiz, class_name: 'Quizzes::Quiz'
  belongs_to :set, :polymorphic => true
  has_many :assignment_override_students, :dependent => :destroy

  validates_presence_of :assignment_version, :if => :assignment
  validates_presence_of :title, :workflow_state
  validates_inclusion_of :set_type, :in => %w(CourseSection Group ADHOC)
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true

  concrete_set = lambda{ |override| ['CourseSection', 'Group'].include?(override.set_type) }

  validates_presence_of :set, :set_id, :if => concrete_set
  validates_uniqueness_of :set_id, :scope => [:assignment_id, :set_type, :workflow_state],
    :if => lambda{ |override| override.assignment? && override.active? && concrete_set.call(override) }
  validates_uniqueness_of :set_id, :scope => [:quiz_id, :set_type, :workflow_state],
    :if => lambda{ |override| override.quiz? && override.active? && concrete_set.call(override) }
  validate :if => concrete_set do |record|
    if record.set && record.assignment && record.active?
      case record.set
      when CourseSection
        record.errors.add :set, "not from assignment's course" unless record.set.course_id == record.assignment.context_id
      when Group
        record.errors.add :set, "not from assignment's group category" unless record.set.group_category_id == record.assignment.group_category_id
      end
    end
  end

  validate :set_id, :unless => concrete_set do |record|
    if record.set_type == 'ADHOC' && !record.set_id.nil?
      record.errors.add :set_id, "must be nil with set_type ADHOC"
    end
  end

  validate do |record|
    if [record.assignment, record.quiz].all?(&:nil?)
      record.errors.add :base, "assignment or quiz required"
    end
  end

  after_save :update_cached_due_dates
  after_save :touch_assignment, :if => :assignment

  def update_cached_due_dates
    return unless assignment?
    if due_at_overridden_changed? ||
      (due_at_overridden && due_at_changed?) ||
      (due_at_overridden && workflow_state_changed?)
      DueDateCacher.recompute(assignment)
    end
  end

  def touch_assignment
    return true if assignment.nil? || dont_touch_assignment
    assignment.touch
  end
  private :touch_assignment

  def assignment?; !!assignment_id; end
  def quiz?; !!quiz_id; end

  workflow do
    state :active
    state :deleted
  end

  alias_method :destroy!, :destroy
  def destroy
    transaction do
      self.assignment_override_students.destroy_all
      self.workflow_state = 'deleted'
      self.save!
    end
  end

  scope :active, where(:workflow_state => 'active')

  before_validation :default_values
  def default_values
    self.set_type ||= 'ADHOC'
    if assignment
      self.assignment_version = assignment.version_number
      self.quiz = assignment.quiz
      self.quiz_version = quiz.version_number if quiz
    elsif quiz
      self.quiz_version = quiz.version_number
      self.assignment = quiz.assignment
      self.assignment_version = assignment.version_number if assignment
    end

    self.title = set.name if set_type != 'ADHOC' && set
  end
  protected :default_values

  # override set read accessor and set_id read/write accessors so that reading
  # set/set_id or setting set_id while set_type=ADHOC doesn't try and find the
  # ADHOC model
  def set_id
    read_attribute(:set_id)
  end

  def set_with_adhoc
    if self.set_type == 'ADHOC'
      assignment_override_students.includes(:user).map(&:user)
    else
      set_without_adhoc
    end
  end
  alias_method_chain :set, :adhoc

  def set_id=(id)
    if self.set_type == 'ADHOC'
      write_attribute(:set_id, id)
    else
      super
    end
  end

  def self.override(field)
    define_method "override_#{field}" do |value|
      send("#{field}_overridden=", true)
      send("#{field}=", value)
    end

    define_method "clear_#{field}_override" do
      send("#{field}_overridden=", false)
      send("#{field}=", nil)
    end

    validates_inclusion_of "#{field}_overridden", :in => [false, true]
    before_validation do |override|
      if override.send("#{field}_overridden").nil?
        override.send("#{field}_overridden=", false)
      end
      true
    end

    scope "overriding_#{field}", where("#{field}_overridden" => true)
  end

  override :due_at
  override :unlock_at
  override :lock_at

  def due_at=(new_due_at)
    new_due_at = CanvasTime.fancy_midnight(new_due_at)
    new_all_day, new_all_day_date = Assignment.all_day_interpretation(
      :due_at => new_due_at,
      :due_at_was => read_attribute(:due_at),
      :all_day_was => read_attribute(:all_day),
      :all_day_date_was => read_attribute(:all_day_date))

    write_attribute(:due_at, new_due_at)
    write_attribute(:all_day, new_all_day)
    write_attribute(:all_day_date, new_all_day_date)
  end

  def lock_at=(new_lock_at)
    write_attribute(:lock_at, CanvasTime.fancy_midnight(new_lock_at))
  end

  def as_hash
    { :title => title,
      :due_at => due_at,
      :id => id,
      :all_day => all_day,
      :set_type => set_type,
      :set_id => set_id,
      :all_day_date => all_day_date,
      :lock_at => lock_at,
      :unlock_at => unlock_at,
      :override => self }
  end

  def applies_to_students
    # FIXME: exclude students for whom this override does not apply
    # because a higher-priority override exists
    case set_type
    when 'ADHOC'
      set
    when 'CourseSection'
      set.participating_students
    when 'Group'
      set.participants
    end
  end

  def applies_to_admins
    case set_type
    when 'CourseSection'
      set.participating_admins
    else
      assignment.context.participating_admins
    end
  end

  def notify_change?
    self.assignment &&
    self.assignment.context.available? &&
    self.assignment.published? &&
    self.assignment.created_at < 3.hours.ago &&
    (!self.prior_version ||
      self.workflow_state != self.prior_version.workflow_state ||
      self.due_at_overridden != self.prior_version.due_at_overridden ||
      self.due_at_overridden && !Assignment.due_dates_equal?(self.due_at, self.prior_version.due_at))
  end

  has_a_broadcast_policy
  set_broadcast_policy do |p|
    p.dispatch :assignment_due_date_changed
    p.to { applies_to_students }
    p.whenever { |record| record.notify_change? }
    p.filter_asset_by_recipient { |record, user|
      # note that our asset for this message is an Assignment, not an AssignmentOverride
      record.assignment.overridden_for(user)
    }

    p.dispatch :assignment_due_date_override_changed
    p.to { applies_to_admins }
    p.whenever { |record| record.notify_change? }
  end
end
