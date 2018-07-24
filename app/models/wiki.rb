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
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FORg
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'atom'

class Wiki < ActiveRecord::Base
  has_many :wiki_pages, :dependent => :destroy

  before_save :set_has_no_front_page_default
  after_update :set_downstream_change_for_master_courses

  after_save :update_contexts

  has_one :course
  has_one :group

  DEFAULT_FRONT_PAGE_URL = 'front-page'

  def set_has_no_front_page_default
    if self.has_no_front_page.nil?
      self.has_no_front_page = true
    end
  end
  private :set_has_no_front_page_default

  # some hacked up stuff similar to what's in MasterCourses::Restrictor
  def load_tag_for_master_course_import!(child_subscription_id)
    @child_tag_for_import = MasterCourses::ChildContentTag.all.polymorphic_where(:content => self).first ||
      MasterCourses::ChildContentTag.create(:content => self, :child_subscription_id => child_subscription_id)
  end

  def can_update_front_page_for_master_courses?
    !@child_tag_for_import.downstream_changes.include?("front_page_url")
  end

  def set_downstream_change_for_master_courses
    if self.saved_change_to_front_page_url? && !@child_tag_for_import
      child_tag = MasterCourses::ChildContentTag.all.polymorphic_where(:content => self).first
      if child_tag
        child_tag.downstream_changes = ["front_page_url"]
        child_tag.save! if child_tag.changed?
      end
    end
  end

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

  def front_page
    url = self.get_front_page_url
    return nil if url.nil?

    # TODO i18n
    t :front_page_name, "Front Page"
    # attempt to find the page and store it's url (if it is found)
    page = self.wiki_pages.not_deleted.where(url: url).first
    self.set_front_page_url!(url) if self.has_no_front_page && page

    # return an implicitly created page if a page could not be found
    unless page
      page = self.wiki_pages.temp_record(:title => url.titleize, :url => url, :context => self.context)
    end
    page
  end

  def has_front_page?
    !self.has_no_front_page
  end

  def get_front_page_url
    self.front_page_url || DEFAULT_FRONT_PAGE_URL if self.has_front_page?
  end

  def unset_front_page!
    if self.context.is_a?(Course) && self.context.default_view == 'wiki'
      self.context.default_view = nil
      self.context.save
    end

    self.front_page.touch if self.front_page&.persisted?

    self.front_page_url = nil
    self.has_no_front_page = true
    self.save
  end

  def set_front_page_url!(url)
    return false if url.blank?
    return true if self.has_front_page? && self.front_page_url == url

    self.has_no_front_page = false
    self.front_page_url = url
    self.save
  end

  def context
    shard.activate do
      @context ||= self.id && (self.course || self.group)
    end
  end

  def context_type
    context.class.to_s
  end

  def context_id
    context.id
  end

  set_policy do
    given {|user, session| self.context.grants_right?(user, session, :read)}
    can :read

    given {|user, session| self.context.grants_right?(user, session, :view_unpublished_items)}
    can :view_unpublished_items

    given {|user, session| self.context.grants_right?(user, session, :participate_as_student) && self.context.respond_to?(:allow_student_wiki_edits) && self.context.allow_student_wiki_edits}
    can :read and can :create_page and can :update_page and can :update_page_content

    given {|user, session| self.context.grants_right?(user, session, :manage_wiki)}
    can :manage and can :read and can :update and can :create_page and can :delete_page and can :delete_unpublished_page and can :update_page and can :update_page_content and can :view_unpublished_items

    given {|user, session| self.context.grants_right?(user, session, :manage_wiki) && !self.context.is_a?(Group)}
    # Pages created by a user without this permission will be automatically published
    can :publish_page
  end

  def self.wiki_for_context(context)
    context.transaction do
      # otherwise we lose dirty changes
      context.save! if context.changed?
      context.lock!
      return context.wiki if context.wiki_id
      # TODO i18n
      t :default_course_wiki_name, "%{course_name} Wiki", :course_name => nil
      t :default_group_wiki_name, "%{group_name} Wiki", :group_name => nil

      self.extend TextHelper
      name = CanvasTextHelper.truncate_text(context.name, {:max_length => 200, :ellipsis => ''})

      context.wiki = wiki = Wiki.create!(:title => "#{name} Wiki")
      context.save!
      wiki
    end
  end

  def build_wiki_page(user, opts={})
    if (opts.include?(:url) || opts.include?(:title)) && (!opts.include?(:url) || !opts.include?(:title))
      opts[:title] = opts[:url].to_s.titleize if opts.include?(:url)
      opts[:url] = opts[:title].to_s.to_url if opts.include?(:title)
    end

    self.shard.activate do
      page = WikiPage.new(opts)
      page.wiki = self
      page.context = self.context
      page.initialize_wiki_page(user)
      page
    end
  end

  def find_page(param)
    # to allow linking to a WikiPage by id (to avoid needing to hit the database to pull its url)
    if (match = param.match(/\Apage_id:(\d+)\z/))
      return self.wiki_pages.where(id: match[1].to_i).first
    end
    self.wiki_pages.not_deleted.where(url: param.to_s).first ||
      self.wiki_pages.not_deleted.where(url: param.to_url).first ||
      self.wiki_pages.not_deleted.where(id: param.to_i).first
  end

  def path
    # was a shim for draft state, can be removed
    'pages'
  end
end
