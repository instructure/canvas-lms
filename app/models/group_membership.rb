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

class GroupMembership < ActiveRecord::Base
  
  include Workflow
  
  belongs_to :group
  belongs_to :user

  attr_accessible :group, :user, :workflow_state, :moderator
  
  before_save :ensure_mutually_exclusive_membership
  before_save :assign_uuid
  before_save :auto_join
  before_save :capture_old_group_id

  before_validation :verify_section_homogeneity_if_necessary

  after_save :touch_groups
  after_save :check_auto_follow_group
  before_destroy :touch_groups
  after_destroy :check_auto_follow_group
  
  has_a_broadcast_policy
  
  named_scope :include_user, :include => :user
  
  named_scope :active, :conditions => ['group_memberships.workflow_state != ?', 'deleted']
  named_scope :moderators, :conditions => { :moderator => true }
  
  set_broadcast_policy do |p|
    p.dispatch :new_context_group_membership
    p.to { self.user }
    p.whenever {|record| record.just_created && record.accepted? && record.group && record.group.context }
    
    p.dispatch :new_context_group_membership_invitation
    p.to { self.user }
    p.whenever {|record| record.just_created && record.invited? && record.group && record.group.context }
    
    p.dispatch :group_membership_accepted
    p.to { self.user }
    p.whenever {|record| record.changed_state(:accepted, :requested) }
    
    p.dispatch :group_membership_rejected
    p.to { self.user }
    p.whenever {|record| record.changed_state(:rejected, :requested) }
  
    p.dispatch :new_student_organized_group
    p.to { self.group.context.admins }
    p.whenever {|record|
      record.group.context && 
      record.group.context.is_a?(Course) && 
      record.just_created &&
      record.group.group_memberships.count == 1 &&
      record.group.student_organized?
    }
  end
  
  def assign_uuid
    self.uuid ||= AutoHandle.generate_securish_uuid
  end
  protected :assign_uuid

  # auto accept 'requested' or 'invited' memberships until we implement
  # accepting requests/invitations
  def auto_join
    return true if self.group.try(:group_category).try(:communities?)
    self.workflow_state = 'accepted' if self.group && (self.requested? || self.invited?)
    true
  end
  protected :auto_join

  def ensure_mutually_exclusive_membership
    return unless self.group
    peer_groups = self.group.peer_groups.map(&:id)
    GroupMembership.find(:all, :conditions => { :group_id => peer_groups, :user_id => self.user_id }).each {|gm| gm.destroy }
  end
  protected :ensure_mutually_exclusive_membership
  
  def verify_section_homogeneity_if_necessary
    return true unless self.group.group_category && self.group.group_category.restricted_self_signup?
    return true if self.group.has_common_section_with_user?(self.user)
    self.errors.add(:user_id, t('errors.not_in_group_section', "%{student} does not share a section with the other members of %{group}.", :student => self.user.name, :group => self.group.name))
    return false
  end
  protected :verify_section_homogeneity_if_necessary
  
  attr_accessor :old_group_id
  def capture_old_group_id
    self.old_group_id = self.group_id_was if self.group_id_changed?
    true
  end
  protected :capture_old_group_id

  def check_auto_follow_group
    if (self.id_changed? || self.workflow_state_changed?) && self.active?
      UserFollow.create_follow(self.user, self.group)
    elsif self.destroyed? || (self.workflow_state_changed? && self.deleted?)
      user_follow = self.user.user_follows.find(:first, :conditions => { :followed_item_id => self.group_id, :followed_item_type => 'Group' })
      user_follow.try(:destroy)
    end
  end
  
  def touch_groups
    groups_to_touch = [ self.group_id ]
    groups_to_touch << self.old_group_id if self.old_group_id
    Group.update_all({ :updated_at => Time.now.utc }, { :id => groups_to_touch })
  end
  protected :touch_groups
  
  workflow do
    state :accepted
    state :invited do
      event :reject, :transitions_to => :rejected
      event :accept, :transitions_to => :accepted
    end
    state :requested
    state :rejected
    state :deleted
  end
  alias_method :active?, :accepted?
  
  def self.serialization_excludes; [:uuid]; end

  # true iff 'active' and the pair of user and group's course match one of the
  # provided enrollments
  def active_given_enrollments?(enrollments)
    accepted? && (!self.group.context.is_a?(Course) ||
     enrollments.any?{ |e| e.user == self.user && e.course == self.group.context })
  end

  set_policy do
    # for non-communities, people can be put into groups
    given { |user, session| user.present? && (user == self.user || self.group.grants_right?(user, session, :manage)) && self.group.can_join?(user) && !self.group.group_category.try(:communities?) }
    can :create

    # for communities, users must initiate in order to be added to a group
    given { |user, session| user.present? && user == self.user && self.group.can_join?(user) && self.group.group_category.try(:communities?) }
    can :create

    given { |user, session| user.present? && self.group.grants_right?(user, session, :manage) }
    can :update

    given { |user, session| user.present? && (user == self.user || self.group.grants_right?(user, session, :manage)) && self.group.can_leave?(user) }
    can :delete
  end
end
