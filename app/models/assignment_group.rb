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

class AssignmentGroup < ActiveRecord::Base
  include Workflow
  # Unlike our other soft-deletable models, assignment groups use 'available' instead of 'active'
  # to indicate a not-deleted state. This means we have to add the 'available' state here before
  # Canvas::SoftDeletable adds the 'active' and 'deleted' states, so that 'available' becomes the
  # initial state for this model.
  workflow { state :available }
  include Canvas::SoftDeletable

  attr_readonly :context_id, :context_type
  belongs_to :context, polymorphic: [:course]
  acts_as_list scope: { context: self, workflow_state: 'available' }
  has_a_broadcast_policy
  serialize :integration_data, Hash

  has_many :scores, -> { active }
  has_many :assignments, -> { order('position, due_at, title') }

  has_many :active_assignments, -> {
    where("assignments.workflow_state<>'deleted'").order('assignments.position, assignments.due_at, assignments.title')
  }, class_name: 'Assignment', dependent: :destroy

  has_many :published_assignments, -> {
    where(workflow_state: 'published').order('assignments.position, assignments.due_at, assignments.title')
  }, class_name: 'Assignment'

  validates :context_id, :context_type, :workflow_state, presence: true
  validates :rules, length: { maximum: maximum_text_length }, allow_nil: true, allow_blank: true
  validates :default_assignment_name, length: { maximum: maximum_string_length }, allow_nil: true
  validates :name, length: { maximum: maximum_string_length }, allow_nil: true

  before_save :set_context_code
  before_save :generate_default_values
  after_save :course_grading_change
  after_save :touch_context
  after_save :update_student_grades

  before_destroy :destroy_scores

  def generate_default_values
    if self.name.blank?
      self.name = t 'default_title', "Assignments"
    end
    if !self.group_weight || self.group_weight.nan?
      self.group_weight = 0
    end
    self.default_assignment_name = self.name
    self.default_assignment_name = self.default_assignment_name.singularize if I18n.locale == :en
  end
  protected :generate_default_values

  def update_student_grades
    if self.saved_change_to_rules? || self.saved_change_to_group_weight?
      self.class.connection.after_transaction_commit { self.context.recompute_student_scores }
    end
  end

  def set_context_code
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}"
  end

  set_policy do
    given { |user, session| self.context.grants_any_right?(user, session, :read, :view_all_grades, :manage_grades) }
    can :read

    given { |user, session| self.context.grants_right?(user, session, :manage_assignments) }
    can :read and can :create and can :update

    given do |user, session|
      self.context.grants_right?(user, session, :manage_assignments) &&
        (self.context.account_membership_allows(user) ||
         !any_assignment_in_closed_grading_period?)
    end
    can :delete
  end

  def restore(try_to_selectively_undelete_assignments = true)
    to_restore = self.assignments.include_submittables
    if try_to_selectively_undelete_assignments
      # It's a pretty good guess that if an assignment was modified at the same
      # time that this group was last modified, that assignment was deleted
      # along with this group. This might help avoid undeleting assignments that
      # were deleted earlier.
      to_restore = to_restore.where('updated_at >= ?', self.updated_at.utc)
    end
    undestroy(active_state: 'available')
    restore_scores
    to_restore.each { |assignment| assignment.restore(:assignment_group) }
  end

  def rules_hash (options={})
    return @rules_hash if @rules_hash
    @rules_hash = {}.with_indifferent_access
    (rules || "").split("\n").each do |rule|
      split = rule.split(":", 2)
      if split.length > 1
        if split[0] == 'never_drop'
          @rules_hash[split[0]] ||= []
          @rules_hash[split[0]] << (options[:stringify_json_ids] ? split[1].to_s : split[1].to_i)
        else
          @rules_hash[split[0]] = split[1].to_i
        end
      end
    end
    @rules_hash
  end

  # Converts a hash representation of rules to the string representation of rules in the database
  # {
  #   "drop_lowest" => '1',
  #   "drop_highest" => '1',
  #   "never_drop" => ['33','17','24']
  # }
  #
  # drop_lowest:2\ndrop_highest:1\nnever_drop:12\nnever_drop:14\n
  def rules_hash=(incoming_hash)
    rule_string = ""
    rule_string += "drop_lowest:#{incoming_hash['drop_lowest']}\n" if incoming_hash['drop_lowest']
    rule_string += "drop_highest:#{incoming_hash['drop_highest']}\n" if incoming_hash['drop_highest']
    if incoming_hash['never_drop']
      incoming_hash['never_drop'].each do |r|
        rule_string += "never_drop:#{r}\n"
      end
    end
    self.rules = rule_string
  end

  def points_possible
    self.assignments.reduce(0) { |sum, assignment| sum + (assignment.points_possible || 0) }
  end

  scope :include_active_assignments, -> { preload(:active_assignments) }
  scope :active, -> { where("assignment_groups.workflow_state<>'deleted'") }
  scope :before, lambda { |date| where("assignment_groups.created_at<?", date) }
  scope :for_context_codes, lambda { |codes| active.where(:context_code => codes).order(:position) }
  scope :for_course, lambda { |course| where(:context_id => course, :context_type => 'Course') }

  def course_grading_change
    self.context.grade_weight_changed! if saved_change_to_group_weight? && self.context && self.context.group_weighting_scheme == 'percent'
    true
  end

  set_broadcast_policy do |p|
    p.dispatch :grade_weight_changed
    p.to { context.participating_students_by_date }
    p.whenever { |record|
      false &&
      record.changed_in_state(:available, :fields => :group_weight)
    }
  end

  def students
    assignments.map(&:students).flatten
  end

  def self.add_never_drop_assignment(group, assignment)
    rule = "never_drop:#{assignment.id}\n"
    if group.rules
      group.rules += rule
    else
      group.rules = rule
    end
    group.save
  end

  def has_frozen_assignments?(user)
    return false unless PluginSetting.settings_for_plugin(:assignment_freezer)
    return false unless self.active_assignments.length > 0

    self.active_assignments.any? do |assignment|
      assignment.frozen_for_user?(user)
    end
  end

  def has_frozen_assignment_group_id_assignment?(user)
    return false unless PluginSetting.settings_for_plugin(:assignment_freezer)
    return false unless self.active_assignments.length > 0

    self.active_assignments.any? do |assignment|
      assignment.att_frozen?(:assignment_group_id, user)
    end
  end

  def any_assignment_in_closed_grading_period?
    effective_due_dates.any_in_closed_grading_period?
  end

  def visible_assignments(user, includes=[])
    self.class.visible_assignments(user, self.context, [self], includes)
  end

  def self.visible_assignments(user, context, assignment_groups, includes = [])
    if context.grants_any_right?(user, :manage_grades, :read_as_admin, :manage_assignments)
      scope = context.active_assignments.where(:assignment_group_id => assignment_groups)
    elsif user.nil?
      scope = context.active_assignments.published.where(:assignment_group_id => assignment_groups)
    else
      scope = user.assignments_visible_in_course(context).
              where(:assignment_group_id => assignment_groups).published
    end
    includes.any? ? scope.preload(includes) : scope
  end

  def move_assignments_to(move_to_id)
    new_group = context.assignment_groups.active.find(move_to_id)
    order = new_group.assignments.active.pluck(:id)
    ids_to_change = self.assignments.active.pluck(:id)
    order += ids_to_change
    Assignment.where(:id => ids_to_change).update_all(:assignment_group_id => new_group.id, :updated_at => Time.now.utc) unless ids_to_change.empty?
    Assignment.where(id: order).first.update_order(order) unless order.empty?
    new_group.touch
    self.reload
  end

  private

  def destroy_scores
    # TODO: soft-delete score metadata as part of GRADE-746
    set_scores_workflow_state_in_batches(:deleted)
  end

  def restore_scores
    # TODO: restore score metadata as part of GRADE-746
    set_scores_workflow_state_in_batches(:active, exclude_workflow_states: [:completed, :deleted])
  end

  def set_scores_workflow_state_in_batches(new_workflow_state, exclude_workflow_states: [:completed])
    student_enrollments = Enrollment.where(
      course_id: context_id,
      type: [:StudentEnrollment, :StudentViewEnrollment]
    ).where.not(workflow_state: exclude_workflow_states)

    score_ids = Score.where(
      assignment_group_id: self,
      enrollment_id: student_enrollments,
      workflow_state: new_workflow_state == :active ? :deleted : :active
    ).pluck(:id)

    score_ids.each_slice(1000) do |score_ids_batch|
      Score.where(id: score_ids_batch).update_all(workflow_state: new_workflow_state, updated_at: Time.zone.now)
    end
  end

  def effective_due_dates
    @effective_due_dates ||= EffectiveDueDates.for_course(context, published_assignments)
  end
end
