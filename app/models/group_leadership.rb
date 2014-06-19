#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
class GroupLeadership
  attr_reader :group

  def initialize(target_group)
    @group = target_group
  end

  def member_changed_event(membership)
    revoke_leadership_if_necessary(membership)
    propogate_event_for_prior_groups(membership)
    if auto_leader_enabled? && leadership_spot_empty?
      auto_assign!(category.auto_leader)
    end
  end

  def auto_assign!(strategy)
    return if valid_leader_in_place?
    group.update_attribute(:leader, select_leader(strategy))
  end

  private
  def select_leader(strategy)
    return users.first if strategy == "first"
    return users.sample if strategy == "random"
    raise(ArgumentError, "Unkown auto leader strategy: '#{strategy}'")
  end

  def valid_leader_in_place?
    group.leader.present? && member_ids.include?(group.leader_id)
  end

  def propogate_event_for_prior_groups(membership)
    old_id = membership.old_group_id
    if old_id && old_id != group.id
      propogation_target = self.class.new(Group.find(membership.old_group_id))
      propogation_target.member_changed_event(membership)
    end
  end

  def leadership_spot_empty?
    group.reload.leader_id.nil?
  end

  def auto_leader_enabled?
    category && category.auto_leader.present?
  end

  def revoke_leadership_if_necessary(membership)
    if no_longer_member?(membership)
      user_id = membership.user_id
      group.update_attribute(:leader_id, nil) if group.leader_id == user_id
    end
  end

  def no_longer_member?(membership)
    !membership_ids.include?(membership.id)
  end

  def category
    group.group_category
  end

  def users
    group.users
  end

  def member_ids
    group.group_memberships.pluck(:user_id)
  end

  def membership_ids
    group.reload.group_memberships.pluck(:id)
  end

end
