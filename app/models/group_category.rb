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

    protected
    def name_for_role(role)
      case role
      when 'student_organized' then t('group_categories.student_organized', "Student Groups")
      when 'imported'          then t('group_categories.imported', "Imported Groups")
      end
    end

    def protected_roles_for_context(context)
      case context
      when Course  then ['student_organized', 'imported']
      when Account then ['imported']
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

  def student_organized?
    self.role == 'student_organized'
  end

  def protected?
    self.role.present?
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
