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

# == Schema Information
#
# Table name: wikis
#
#  id         :integer(4)      not null, primary key
#  title      :string(255)
#  created_at :datetime
#  updated_at :datetime
#
  
class Wiki < ActiveRecord::Base
  attr_accessible :title

  has_many :wiki_pages, :dependent => :destroy
  after_save :update_contexts

  def update_contexts
    self.context.try(:touch)
  end

  def to_atom
    Atom::Entry.new do |entry|
      entry.title     = self.title
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.links    << Atom::Link.new(:rel => 'alternate', 
                                    :href => "/wikis/#{self.id}")
    end
  end
  
  def update_default_wiki_page_roles(new_roles, old_roles)
    return if new_roles == old_roles
    self.wiki_pages.each do |p|
      if p.editing_roles == old_roles
        p.editing_roles = new_roles
        p.save
      end
    end
  end
  
  def wiki_page
    # TODO i18n
    t :front_page_name, "Front Page"
    self.wiki_pages.find_by_url("front-page") || self.wiki_pages.build(:title => "Front Page", :url => 'front-page')
  end

  def context
    @context ||= Course.find_by_wiki_id(self.id) || Group.find_by_wiki_id(self.id)
  end

  def context_type
    context.class.to_s
  end

  def context_id
    context.id
  end

  set_policy do
    given {|user| self.context.is_public }
    can :read

    given {|user, session| self.cached_context_grants_right?(user, session, :read) }#students.include?(user) }
    can :read

    given {|user, session| self.cached_context_grants_right?(user, session, :participate_as_student) && self.context.allow_student_wiki_edits}
    can :contribute and can :read and can :update and can :delete and can :create and can :create_page and can :update_page

    given {|user, session| self.cached_context_grants_right?(user, session, :manage_wiki) }#admins.include?(user) }
    can :manage and can :read and can :update and can :create and can :delete and can :create_page and can :update_page
  end

  def self.wiki_for_context(context)
    return context.wiki_without_create if context.wiki_id
    context.transaction do
      # otherwise we lose dirty changes
      context.save! if context.changed?
      context.lock!
      return context.wiki_without_create if context.wiki_id
      # TODO i18n
      t :default_course_wiki_name, "%{course_name} Wiki", :course_name => nil
      t :default_group_wiki_name, "%{group_name} Wiki", :group_name => nil

      self.extend TextHelper
      name = truncate_text(context.name, {:max_length => 200, :ellipsis => ''})

      context.wiki = wiki = Wiki.create!(:title => "#{name} Wiki")
      context.save!
      wiki
    end
  end
end
