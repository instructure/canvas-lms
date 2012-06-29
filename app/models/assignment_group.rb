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
  attr_readonly :context_id, :context_type
  acts_as_list :scope => :context
  has_a_broadcast_policy
  
  has_many :assignments, :order => 'position, due_at, title', :dependent => :destroy
  has_many :active_assignments, :class_name => 'Assignment', :conditions => ['assignments.workflow_state != ?', 'deleted'], :order => 'assignments.position, assignments.due_at, assignments.title'

  belongs_to :context, :polymorphic => true
  belongs_to :cloned_item
  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_length_of :rules, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :default_assignment_name, :maximum => maximum_string_length, :allow_nil => true
  validates_length_of :name, :maximum => maximum_string_length, :allow_nil => true
  
  before_save :set_context_code
  before_save :generate_default_values
  before_save :group_weight_changed
  after_save :course_grading_change
  after_save :touch_context
  after_save :update_student_grades
  
  def generate_default_values
    self.name ||= t 'default_title', "Assignments"
    if !self.group_weight
      self.group_weight = 0
    end
    @grades_changed = self.rules_changed? || self.group_weight_changed?
    self.default_assignment_name = self.name
    self.default_assignment_name = self.default_assignment_name.singularize if I18n.locale == :en
  end
  protected :generate_default_values
  
  def update_student_grades
    if @grades_changed
      connection.after_transaction_commit { self.context.recompute_student_scores }
    end
  end
  
  def set_context_code
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}"
  end

  set_policy do
    given { |user, session| self.context.grants_rights?(user, session, :read)[:read] } #self.context.students.include? user }
    can :read
    
    given { |user, session| self.context.grants_right?(user, session, :manage_assignments) }
    can :update and can :delete and can :create and can :read

    given { |user, session| self.context.grants_right?(user, session, :manage_grades) }
    can :update and can :delete and can :create and can :read
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
      to_restore = to_restore.scoped(:conditions => ['updated_at >= ?', self.updated_at.utc])
    end
    self.workflow_state = 'available'
    self.save
    to_restore.each { |assignment| assignment.restore(:assignment_group) }
  end
  
  def rules_hash
    return @rules_hash if @rules_hash
    @rules_hash = {}.with_indifferent_access
    (rules || "").split("\n").each do |rule| 
      split = rule.split(":", 2)
      if split.length > 1
        if split[0] == 'never_drop'
          @rules_hash[split[0]] ||= []
          @rules_hash[split[0]] << split[1].to_i
        else
          @rules_hash[split[0]] = split[1].to_i
        end
      end
    end
    @rules_hash
  end
  
  def points_possible
    self.assignments.map{|a| a.points_possible || 0}.sum
  end
  
  named_scope :include_active_assignments, lambda{
    {:include => :active_assignments}
  }
  named_scope :active, :conditions => ['assignment_groups.workflow_state != ?', 'deleted']
  named_scope :before, lambda{|date|
    {:conditions => ['assignment_groups.created_at < ?', date]}
  }
  named_scope :for_context_codes, lambda {|codes|
    {:conditions => ['assignment_groups.context_code IN (?) and assignment_groups.workflow_state != ?', codes, 'deleted'], :order => :position }
  }
  
  def group_weight_changed
    @group_weight_changed = self.group_weight_changed?
    true
  end
  
  def course_grading_change
    self.context.grade_weight_changed! if @group_weight_changed && self.context && self.context.group_weighting_scheme == 'percent'
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
  
  attr_accessor :clone_updated
  def clone_for(context, dup=nil, options={})
    if !self.cloned_item && !self.new_record?
      self.cloned_item ||= ClonedItem.create(:original_item => self)
      self.save
    end
    existing = context.assignment_groups.active.find_by_id(self.id)
    existing ||= context.assignment_groups.active.find_by_cloned_item_id(self.cloned_item_id || 0)
    return existing if existing && !options[:overwrite]
    dup ||= AssignmentGroup.new
    dup = existing if existing && options[:overwrite]
    self.attributes.delete_if{|k,v| [:id, :position].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.context = context
    context.log_merge_result("Assignment Group \"#{self.name}\" created")
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
  end

  def students
    assignments.map(&:students).flatten
  end

  def self.process_migration(data, migration)
    groups = data['assignment_groups'] ? data['assignment_groups']: []
    groups.each do |group|
      if migration.import_object?("assignment_groups", group['migration_id'])
        begin
          import_from_migration(group, migration.context)
        rescue
          migration.add_warning("Couldn't import assignment group \"#{group[:title]}\"", $!)
        end
      end
    end
  end
  
  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:assignment_groups_to_import] && !hash[:assignment_groups_to_import][hash[:migration_id]]
    item ||= find_by_context_id_and_context_type_and_id(context.id, context.class.to_s, hash[:id])
    item ||= find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
    item ||= context.assignment_groups.new
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item.migration_id = hash[:migration_id]
    item.workflow_state = 'available' if item.deleted?
    item.name = hash[:title]
    item.position = hash[:position].to_i if hash[:position] && hash[:position].to_i > 0
    item.group_weight = hash[:group_weight] if hash[:group_weight]
    
    if hash[:rules] && hash[:rules].length > 0
      rules = ""
      hash[:rules].each do |rule|
        if rule[:drop_type] == "drop_lowest" || rule[:drop_type] == "drop_highest"
          rules += "#{rule[:drop_type]}:#{rule[:drop_count]}\n"
        elsif rule[:drop_type] == "never_drop"
          if context.respond_to?(:assignment_group_no_drop_assignments)
            context.assignment_group_no_drop_assignments[rule[:assignment_migration_id]] = item
          end
        end
      end
      item.rules = rules unless rules == ''
    end
    
    item.save!
    item
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

end
