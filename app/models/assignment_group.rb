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

class AssignmentGroup < ActiveRecord::Base

  include Workflow

  attr_accessible :name, :rules, :assignment_weighting_scheme, :group_weight, :position, :default_assignment_name
  EXPORTABLE_ATTRIBUTES = [
    :id, :name, :rules, :default_assignment_name, :assignment_weighting_scheme, :group_weight, :context_id,
    :context_type, :workflow_state, :created_at, :updated_at, :cloned_item_id, :context_code
  ]

  EXPORTABLE_ASSOCIATIONS = [:context, :assignments]

  attr_readonly :context_id, :context_type
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course']
  acts_as_list scope: { context: self, workflow_state: 'available' }
  has_a_broadcast_policy

  has_many :assignments, :order => 'position, due_at, title', :dependent => :destroy
  has_many :active_assignments, :class_name => 'Assignment', :conditions => ['assignments.workflow_state != ?', 'deleted'], :order => 'assignments.position, assignments.due_at, assignments.title'
  has_many :published_assignments, :class_name => 'Assignment', :conditions => "assignments.workflow_state = 'published'", :order => 'assignments.position, assignments.due_at, assignments.title'

  validates_presence_of :context_id, :context_type, :workflow_state
  validates_length_of :rules, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :default_assignment_name, :maximum => maximum_string_length, :allow_nil => true
  validates_length_of :name, :maximum => maximum_string_length, :allow_nil => true

  before_save :set_context_code
  before_save :generate_default_values
  after_save :course_grading_change
  after_save :touch_context
  after_save :update_student_grades

  def generate_default_values
    if self.name.blank?
      self.name = t 'default_title', "Assignments"
    end
    if !self.group_weight
      self.group_weight = 0
    end
    self.default_assignment_name = self.name
    self.default_assignment_name = self.default_assignment_name.singularize if I18n.locale == :en
  end
  protected :generate_default_values

  def update_student_grades
    if self.rules_changed? || self.group_weight_changed?
      connection.after_transaction_commit { self.context.recompute_student_scores }
    end
  end

  def set_context_code
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}"
  end

  set_policy do
    given { |user, session| self.context.grants_any_right?(user, session, :read, :view_all_grades, :manage_grades) }
    can :read

    given { |user, session| self.context.grants_right?(user, session, :manage_assignments) }
    can :read and can :create and can :update and can :delete
  end

  workflow do
    state :available
    state :deleted
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.assignments.active.include_quiz_and_topic.each{|a| a.destroy }
    self.save
  end

  def restore(try_to_selectively_undelete_assignments = true)
    to_restore = self.assignments.include_quiz_and_topic
    if try_to_selectively_undelete_assignments
      # It's a pretty good guess that if an assignment was modified at the same
      # time that this group was last modified, that assignment was deleted
      # along with this group. This might help avoid undeleting assignments that
      # were deleted earlier.
      to_restore = to_restore.where('updated_at >= ?', self.updated_at.utc)
    end
    self.workflow_state = 'available'
    self.save
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
    self.assignments.map{|a| a.points_possible || 0}.sum
  end

  scope :include_active_assignments, -> { includes(:active_assignments) }
  scope :active, -> { where("assignment_groups.workflow_state<>'deleted'") }
  scope :before, lambda { |date| where("assignment_groups.created_at<?", date) }
  scope :for_context_codes, lambda { |codes| active.where(:context_code => codes).order(:position) }
  scope :for_course, lambda { |course| where(:context_id => course, :context_type => 'Course') }

  def course_grading_change
    self.context.grade_weight_changed! if group_weight_changed? && self.context && self.context.group_weighting_scheme == 'percent'
    true
  end

  set_broadcast_policy do |p|
    p.dispatch :grade_weight_changed
    p.to { context.participating_students }
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

    self.active_assignments.each do |asmnt|
      return true if asmnt.frozen_for_user?(user)
    end

    false
  end

  def has_frozen_assignment_group_id_assignment?(user)
    return false unless PluginSetting.settings_for_plugin(:assignment_freezer)
    return false unless self.active_assignments.length > 0

    self.active_assignments.each do |asmnt|
      return true if asmnt.att_frozen?(:assignment_group_id,user)
    end
    false
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
    Assignment.where(:id => ids_to_change).update_all(:assignment_group_id => new_group, :updated_at => Time.now.utc) unless ids_to_change.empty?
    Assignment.where(id: order).first.update_order(order) unless order.empty?
    new_group.touch
    self.reload
  end
end
