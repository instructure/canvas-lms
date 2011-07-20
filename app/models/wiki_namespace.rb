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

class WikiNamespace < ActiveRecord::Base
  attr_accessible :namespace
  attr_readonly :wiki_id, :context_id, :context_type
  validates_presence_of :wiki_id, :context_id, :context_type
  belongs_to :wiki
  belongs_to :context, :polymorphic => true
  

  def to_atom
    Atom::Entry.new do |entry|
      entry.title     = self.name
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.links    << Atom::Link.new(:rel => 'alternate', 
                                    :href => "/wiki_namespaces/#{self.id}")
    end
  end
  
  def namespace_name
    read_attribute(:namespace)
  end
  
  def context_code
    "#{self.context_type.to_s.underscore}_#{self.context_id}" rescue nil
  end

  def default?
    self.namespace_name == "default"
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
  
  def self.default_for_context(context)
    name = "default"
    wiki_namespace = nil
    WikiNamespace.transaction do
      wiki_namespace = context.wiki_namespaces.find_by_namespace(name)
      wiki_namespace ||= context.wiki_namespaces.build(:namespace => name)
      if !wiki_namespace.wiki
        # TODO i18n
        t :default_course_wiki_name, "%{course_name} Wiki", :course_name => nil
        t :default_group_wiki_name, "%{group_name} Wiki", :group_name => nil
        wiki_namespace.wiki = Wiki.create(:title => "#{context.name} Wiki")
        wiki_namespace.save!
      end
    end
    page = wiki_namespace.wiki.wiki_page if wiki_namespace
    wiki_namespace
  end
  
  def context_prefix
    context_url_prefix
  end
  
end
