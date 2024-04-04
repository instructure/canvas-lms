# frozen_string_literal: true

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

class Wiki < ActiveRecord::Base
  has_many :wiki_pages, dependent: :destroy
  has_one :course
  has_one :group
  belongs_to :root_account, class_name: "Account"

  before_save :set_has_no_front_page_default
  after_update :set_downstream_change_for_master_courses
  after_save :update_contexts

  DEFAULT_FRONT_PAGE_URL = "front-page"

  def set_has_no_front_page_default
    if has_no_front_page.nil?
      self.has_no_front_page = true
    end
  end
  private :set_has_no_front_page_default

  # some hacked up stuff similar to what's in MasterCourses::Restrictor
  def load_tag_for_master_course_import!(child_subscription_id)
    @child_tag_for_import = MasterCourses::ChildContentTag.where(content: self).first ||
                            MasterCourses::ChildContentTag.create(content: self, child_subscription_id:)
  end

  def can_update_front_page_for_master_courses?
    !@child_tag_for_import.downstream_changes.include?("front_page_url")
  end

  def set_downstream_change_for_master_courses
    if saved_change_to_front_page_url? && !@child_tag_for_import
      child_tag = MasterCourses::ChildContentTag.where(content: self).first
      if child_tag
        child_tag.downstream_changes = ["front_page_url"]
        child_tag.save! if child_tag.changed?
      end
    end
  end

  def update_contexts
    context.try(:touch)
  end

  def to_atom
    {
      title:,
      updated: updated_at,
      published: created_at,
      link: "/wikis/#{id}"
    }
  end

  def update_default_wiki_page_roles(new_roles, old_roles)
    return if new_roles == old_roles

    wiki_pages.each do |p|
      if p.editing_roles == old_roles
        p.editing_roles = new_roles
        p.save
      end
    end
  end

  def front_page
    url = get_front_page_url
    return nil if url.nil?

    # TODO: i18n
    t :front_page_name, "Front Page"
    # attempt to find the page and store it's url (if it is found)
    page = find_page(url)
    set_front_page_url!(url) if has_no_front_page && page

    # return an implicitly created page if a page could not be found
    page ||= wiki_pages.temp_record(title: url.titleize, url:, context:)
    page
  end

  def has_front_page?
    !has_no_front_page
  end

  def get_front_page_url
    front_page_url || DEFAULT_FRONT_PAGE_URL if has_front_page?
  end

  def unset_front_page!
    if context.is_a?(Course) && context.default_view == "wiki"
      context.default_view = nil
      context.save
    end

    front_page.touch if front_page&.persisted?

    self.front_page_url = nil
    self.has_no_front_page = true
    save
  end

  def set_front_page_url!(url)
    return false if url.blank?
    return true if has_front_page? && front_page_url == url

    self.has_no_front_page = false
    self.front_page_url = url
    save
  end

  def context
    @context ||= id && (course || group)
  end

  def context_loaded?
    @context || association(:course).loaded? || association(:group).loaded?
  end

  def context_type
    context.class.to_s
  end

  delegate :id, to: :context, prefix: true

  set_policy do
    given { |user, session| context.grants_right?(user, session, :read) }
    can :read

    given { |user, session| context.grants_right?(user, session, :view_unpublished_items) }
    can :view_unpublished_items

    given { |user, session| context.grants_right?(user, session, :participate_as_student) && context.respond_to?(:allow_student_wiki_edits) && context.allow_student_wiki_edits }
    can :read and can :create_page and can :update_page

    given do |user, session|
      context.grants_right?(user, session, :manage_wiki_create)
    end
    can :read and can :create_page and can :view_unpublished_items

    given do |user, session|
      context.grants_right?(user, session, :manage_wiki_delete)
    end
    can :read and can :delete_page and can :view_unpublished_items

    given do |user, session|
      context.grants_right?(user, session, :manage_wiki_update)
    end
    can :read and can :update and can :update_page and can :view_unpublished_items

    # Pages created by a user without this permission will be automatically published
    given do |user, session|
      context.grants_right?(user, session, :manage_wiki_update) && !context.is_a?(Group)
    end
    can :publish_page
  end

  def self.wiki_for_context(context)
    GuardRail.activate(:primary) do
      context.transaction do
        # otherwise we lose dirty changes
        context.save! if context.changed?
        context.lock!
        next context.wiki if context.wiki_id

        # TODO: i18n
        t :default_course_wiki_name, "%{course_name} Wiki", course_name: nil
        t :default_group_wiki_name, "%{group_name} Wiki", group_name: nil

        extend TextHelper
        name = CanvasTextHelper.truncate_text(context.name, { max_length: 200, ellipsis: "" })

        context.wiki = wiki = Wiki.create!(title: "#{name} Wiki", root_account_id: context.root_account_id)
        context.save!
        wiki
      end
    end
  end

  def build_wiki_page(user, opts = {})
    if (opts.include?(:url) || opts.include?(:title)) && (!opts.include?(:url) || !opts.include?(:title))
      opts[:title] = opts[:url].to_s.titleize if opts.include?(:url)
      opts[:url] = WikiPage.url_for(opts[:title]) if opts.include?(:title)
    end

    shard.activate do
      page = WikiPage.new(opts)
      page.wiki = self
      page.context = context
      page.initialize_wiki_page(user)
      page
    end
  end

  def find_page(param, include_deleted: false)
    # to allow linking to a WikiPage by id (to avoid needing to hit the database to pull its url)
    if (match = param.match(/\Apage_id:(\d+)\z/))
      return wiki_pages.where(id: match[1].to_i).first
    end

    scope = if include_deleted
              wiki_pages.order(Arel.sql("CASE WHEN workflow_state <> 'deleted' THEN 0 ELSE 1 END"))
            else
              wiki_pages.not_deleted
            end
    lookup = if Account.site_admin.feature_enabled?(:permanent_page_links)
               # Just want to look at the WikiPageLookups associated with the pages in this wiki
               wiki_lookups = WikiPageLookup.by_wiki_id(id)
               wiki_lookups.where(slug: [param.to_s, param.to_url]).first
             end
    if lookup
      scope.where(id: lookup.wiki_page_id).first
    else
      scope.where(url: [param.to_s, param.to_url]).first || scope.where(id: param.to_i).first
    end
  end

  def path
    # was a shim for draft state, can be removed
    "pages"
  end
end
