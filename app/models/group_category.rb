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

class GroupCategory < ActiveRecord::Base
  attr_accessible :name, :role, :context
  belongs_to :context, :polymorphic => true
  has_many :groups, :dependent => :destroy
  has_many :assignments, :dependent => :nullify

  named_scope :active, lambda {
    { :conditions => ['group_categories.deleted_at is null'] }
  }

  named_scope :other_than, lambda{ |cat|
    { :conditions => ['group_categories.id != ?', cat.id || 0] }
  }

  class << self
    def protected_name_for_context?(name, context)
      protected_names_for_context(context).include?(name)
    end

    def student_organized_for(context)
      role_category_for_context('student_organized', context)
    end

    def imported_for(context)
      role_category_for_context('imported', context)
    end

    def communities_for(context)
      role_category_for_context('communities', context)
    end

    protected
    def name_for_role(role)
      case role
      when 'student_organized' then t('group_categories.student_organized', "Student Groups")
      when 'imported'          then t('group_categories.imported', "Imported Groups")
      when 'communities'       then t('group_categories.communities', "Communities")
      end
    end

    def protected_roles_for_context(context)
      case context
      when Course  then ['student_organized', 'imported']
      when Account then ['communities', 'imported']
      else              []
      end
    end

    def protected_role_for_context?(role, context)
      protected_roles_for_context(context).include?(role)
    end

    def protected_names_for_context(context)
      protected_roles_for_context(context).map{ |role| name_for_role(role) }
    end

    def role_category_for_context(role, context)
      return unless context and protected_role_for_context?(role, context)
      context.group_categories.find_by_role(role) ||
      context.group_categories.create(:name => name_for_role(role), :role => role)
    end
  end

  def communities?
    self.role == 'communities'
  end

  def student_organized?
    self.role == 'student_organized'
  end

  def protected?
    self.role.present?
  end

  # Group categories generally restrict students to only be in one group per
  # category, but we sort of cheat and implement student organized groups and
  # communities as one big group category, and then relax that membership
  # restriction.
  def allows_multiple_memberships?
    self.student_organized? || self.communities?
  end

  # Communities can be joined by anyone,
  # otherwise defer to the permission on the context
  def available_for?(user)
    self.communities? || (self.context && self.context.grants_right?(user, :participate_in_groups))
  end

  # this is preferred over setting self_signup directly. know that if you set
  # self_signup directly to anything other than nil (or ''), 'restricted', or
  # 'enabled', it will behave as if you used 'enabled'.
  def configure_self_signup(enabled, restricted)
    if !enabled
      self.self_signup = nil
    elsif restricted
      self.self_signup = 'restricted'
    else
      self.self_signup = 'enabled'
    end
  end

  def self_signup?
    self.self_signup.present?
  end

  def unrestricted_self_signup?
    self.self_signup.present? && self.self_signup != 'restricted'
  end

  def restricted_self_signup?
    self.self_signup.present? && self.self_signup == 'restricted'
  end

  def has_heterogenous_group?
    # if it's not a course, we want the answer to be false. but that same
    # condition would may any group in the category say has_common_section?
    # false, and force us true. so we special case it, and get the short
    # circuit as a bonus.
    return false unless self.context && self.context.is_a?(Course)
    self.groups.any?{ |group| !group.has_common_section? }
  end

  def group_for(user)
    groups.active.to_a.find{ |g| g.users.include?(user) }
  end

  alias_method :destroy!, :destroy
  def destroy
    # TODO: this is kinda redundant with the :dependent => :destroy on the
    # groups association, but that doesn't get called since we override
    # destroy. also, the group destroy happens to be "soft" as well, and I
    # double checked groups.destroy_all does the right thing. :)
    groups.destroy_all
    self.deleted_at = Time.now
    self.save
  end
end
