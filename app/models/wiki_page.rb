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
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'atom'

# Force loaded so that it will be in ActiveRecord::Base.descendants for switchman to use
require_dependency 'assignment_student_visibility'

class WikiPage < ActiveRecord::Base
  attr_readonly :wiki_id
  attr_accessor :saved_by
  validates_length_of :body, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_presence_of :wiki_id
  include Canvas::SoftDeletable
  include HasContentTags
  include CopyAuthorizedLinks
  include ContextModuleItem
  include Submittable
  include Plannable
  include DuplicatingObjects
  include SearchTermHelper
  include LockedFor

  include MasterCourses::Restrictor
  restrict_columns :content, [:body, :title]
  restrict_columns :settings, [:editing_roles]
  restrict_assignment_columns
  restrict_columns :state, [:workflow_state]

  after_update :post_to_pandapub_when_revised

  belongs_to :wiki, :touch => true
  belongs_to :user

  belongs_to :context, polymorphic: [:course, :group]

  acts_as_url :title, :sync_url => true

  validate :validate_front_page_visibility

  before_save :default_submission_values,
    if: proc { self.context.try(:feature_enabled?, :conditional_release) }
  before_save :set_revised_at
  before_validation :ensure_wiki_and_context
  before_validation :ensure_unique_title

  after_save  :touch_context
  after_save  :update_assignment,
    if: proc { self.context.try(:feature_enabled?, :conditional_release) }

  scope :starting_with_title, lambda { |title|
    where('title ILIKE ?', "#{title}%")
  }

  scope :not_ignored_by, -> (user, purpose) do
    where("NOT EXISTS (?)", Ignore.where(asset_type: 'WikiPage', user_id: user, purpose: purpose).where("asset_id=wiki_pages.id"))
  end
  scope :todo_date_between, -> (starting, ending) { where(todo_date: starting...ending) }
  scope :for_courses_and_groups, -> (course_ids, group_ids) do
    wiki_ids = []
    wiki_ids += Course.where(:id => course_ids).pluck(:wiki_id) if course_ids.any?
    wiki_ids += Group.where(:id => group_ids).pluck(:wiki_id) if group_ids.any?
    where(:wiki_id => wiki_ids)
  end

  scope :visible_to_user, -> (user_id) do
    joins(sanitize_sql(["LEFT JOIN #{AssignmentStudentVisibility.quoted_table_name} as asv on wiki_pages.assignment_id = asv.assignment_id AND asv.user_id = ?", user_id])).
      where("wiki_pages.assignment_id IS NULL OR asv IS NOT NULL")
  end

  TITLE_LENGTH = 255
  SIMPLY_VERSIONED_EXCLUDE_FIELDS = [:workflow_state, :editing_roles, :notify_of_update].freeze

  def ensure_wiki_and_context
    self.wiki_id ||= (self.context.wiki_id || self.context.wiki.id)
  end

  def touch_context
    self.context.touch
  end

  def validate_front_page_visibility
    if !published? && self.is_front_page?
      self.errors.add(:published, t(:cannot_unpublish_front_page, "cannot unpublish front page"))
    end
  end

  def ensure_unique_title
    return if deleted?
    to_cased_title = ->(string) { string.gsub(/[^\w]+/, " ").gsub(/\b('?[a-z])/){$1.capitalize}.strip }
    self.title ||= to_cased_title.call(self.url || "page")
    # TODO i18n (see wiki.rb)

    if self.title == "Front Page" && self.new_record?
      baddies = self.context.wiki_pages.not_deleted.where(title: "Front Page").select{|p| p.url != "front-page" }
      baddies.each{|p| p.title = to_cased_title.call(p.url); p.save_without_broadcasting! }
    end
    if existing = self.context.wiki_pages.not_deleted.where(title: self.title).first
      return if existing == self
      real_title = self.title.gsub(/-(\d*)\z/, '') # remove any "-#" at the end
      n = $1 ? $1.to_i + 1 : 2
      begin
        mod = "-#{n}"
        new_title = real_title[0...(TITLE_LENGTH - mod.length)] + mod
        n = n.succ
      end while self.context.wiki_pages.not_deleted.where(title: new_title).exists?

      self.title = new_title
    end
  end

  def self.title_order_by_clause
    best_unicode_collation_key('wiki_pages.title')
  end

  def ensure_unique_url
    return if deleted?
    url_attribute = self.class.url_attribute
    base_url = self.send(url_attribute)
    base_url = self.send(self.class.attribute_to_urlify).to_s.to_url if base_url.blank? || !self.only_when_blank
    conditions = [wildcard("#{url_attribute}", base_url, :type => :right)]
    unless new_record?
      conditions.first << " and id != ?"
      conditions << id
    end

    urls = self.context.wiki_pages.where(*conditions).not_deleted.pluck(:url)
    # This is the part in stringex that messed us up, since it will never allow
    # a url of "front-page" once "front-page-1" or "front-page-2" is created
    # We modify it to allow "front-page" and start the indexing at "front-page-2"
    # instead of "front-page-1"
    if urls.size > 0 && urls.detect{|u| u == base_url}
      n = 2
      while urls.detect{|u| u == "#{base_url}-#{n}"}
        n = n.succ
      end
      write_attribute url_attribute, "#{base_url}-#{n}"
    else
      write_attribute url_attribute, base_url
    end
  end

  sanitize_field :body, CanvasSanitize::SANITIZE
  copy_authorized_links(:body) { [self.context, self.user] }

  validates_each :title do |record, attr, value|
    if value.blank?
      record.errors.add(attr, t('errors.blank_title', "Title can't be blank"))
    elsif value.size > maximum_string_length
      record.errors.add(attr, t('errors.title_too_long', "Title can't exceed %{max_characters} characters", :max_characters => maximum_string_length))
    elsif value.to_url.blank?
      record.errors.add(attr, t('errors.title_characters', "Title must contain at least one letter or number")) # it's a bit more liberal than this, but let's not complicate things
    end
  end

  has_a_broadcast_policy
  simply_versioned :exclude => SIMPLY_VERSIONED_EXCLUDE_FIELDS, :when => Proc.new { |wp|
    # always create a version when restoring a deleted page
    next true if wp.workflow_state_changed? && wp.workflow_state_was == 'deleted'
    # :user_id and :updated_at do not merit creating a version, but should be saved
    exclude_fields = [:user_id, :updated_at].concat(SIMPLY_VERSIONED_EXCLUDE_FIELDS).map(&:to_s)
    (wp.changes.keys.map(&:to_s) - exclude_fields).present?
  }
  after_save :remove_changed_flag


  workflow do
    state :active do
      event :unpublish, :transitions_to => :unpublished
    end
    state :unpublished do
      event :publish, :transitions_to => :active
    end
    state :post_delayed do
      event :delayed_post, :transitions_to => :active
    end
  end
  alias_method :published?, :active?

  def set_revised_at
    self.revised_at ||= Time.now
    self.revised_at = Time.now if self.body_changed? || self.title_changed?
    @page_changed = self.body_changed? || self.title_changed?
    true
  end

  attr_reader :wiki_page_changed
  def notify_of_update=(val)
    @wiki_page_changed = Canvas::Plugin.value_to_boolean(val)
  end

  def notify_of_update
    false
  end

  def remove_changed_flag
    @wiki_page_changed = false
  end

  def version_history
    self.versions.map(&:model)
  end

  scope :deleted_last, -> { order(Arel.sql("workflow_state='deleted'")) }

  scope :not_deleted, -> { where("wiki_pages.workflow_state<>'deleted'") }

  scope :published, -> { where("wiki_pages.workflow_state='active'", false) }
  scope :unpublished, -> { where("wiki_pages.workflow_state='unpublished'", true) }

  # needed for ensure_unique_url
  def not_deleted
    !deleted?
  end

  scope :order_by_id, -> { order(:id) }

  def low_level_locked_for?(user, opts={})
    return false unless self.could_be_locked
    Rails.cache.fetch([locked_cache_key(user), opts[:deep_check_if_needed]].cache_key, :expires_in => 1.minute) do
      locked = false
      if item = locked_by_module_item?(user, opts)
        locked = {object: self, :module => item.context_module}
        unlock_at = locked[:module].unlock_at
        locked[:unlock_at] = unlock_at if unlock_at && unlock_at > Time.now.utc
      end
      locked
    end
  end

  def is_front_page?
    return false if self.deleted?
    self.url == self.wiki.get_front_page_url # wiki.get_front_page_url checks has_front_page?
  end

  def set_as_front_page!
    if self.unpublished?
      self.errors.add(:front_page, t(:cannot_set_unpublished_front_page, 'could not set as front page because it is unpublished'))
      return false
    end

    self.wiki.set_front_page_url!(self.url)
    self.touch if self.persisted?
  end

  def context_module_tag_for(context)
    @tag ||= self.context_module_tags.where(context_id: context, context_type: context.class.base_class.name).first
  end

  def context_module_action(user, context, action)
    self.context_module_tags.where(context_id: context, context_type: context.class.base_class.name).each do |tag|
      tag.context_module_action(user, action)
    end
  end

  set_policy do
    given {|user, session| self.can_read_page?(user, session)}
    can :read

    given {|user| user && self.can_edit_page?(user)}
    can :update_content and can :read_revisions

    given {|user, session| user && self.can_edit_page?(user) && self.wiki.grants_right?(user, session, :create_page)}
    can :create

    given {|user, session| user && self.can_edit_page?(user) && self.wiki.grants_right?(user, session, :update_page)}
    can :update and can :read_revisions

    given {|user, session| user && self.can_edit_page?(user) && self.published? && self.wiki.grants_right?(user, session, :update_page_content)}
    can :update_content and can :read_revisions

    given {|user, session| user && self.can_edit_page?(user) && self.published? && self.wiki.grants_right?(user, session, :delete_page)}
    can :delete

    given {|user, session| user && self.can_edit_page?(user) && self.unpublished? && self.wiki.grants_right?(user, session, :delete_unpublished_page)}
    can :delete
  end

  def can_read_page?(user, session=nil)
    return true if self.unpublished? && self.wiki.grants_right?(user, session, :view_unpublished_items)
    self.published? && self.wiki.grants_right?(user, session, :read)
  end

  def can_edit_page?(user, session=nil)
    return false unless can_read_page?(user, session)

    # wiki managers are always allowed to edit
    return true if wiki.grants_right?(user, session, :manage)

    roles = effective_roles
    # teachers implies all course admins (teachers, TAs, etc)
    return true if roles.include?('teachers') && context.respond_to?(:admins) && context.admins.include?(user)

    # the page must be available for users of the following roles
    return false unless available_for?(user, session)
    return true if roles.include?('students') && context.respond_to?(:students) && context.includes_student?(user)
    return true if roles.include?('members') && context.respond_to?(:users) && context.users.include?(user)
    return true if roles.include?('public')
    false
  end

  def effective_roles
    context_roles = context.default_wiki_editing_roles rescue nil
    roles = (editing_roles || context_roles || default_roles).split(',')
    roles == %w(teachers) ? [] : roles # "Only teachers" option doesn't grant rights excluded by RoleOverrides
  end

  def available_for?(user, session=nil)
    return true if wiki.grants_right?(user, session, :manage)

    return false unless published? || (unpublished? && wiki.grants_right?(user, session, :view_unpublished_items))
    return false if locked_for?(user, :deep_check_if_needed => true)

    true
  end

  def default_roles
    if context.is_a?(Group)
      'members'
    elsif context.is_a?(Course)
      'teachers'
    else
      'members'
    end
  end

  set_broadcast_policy do |p|
    p.dispatch :updated_wiki_page
    p.to { participants }
    p.whenever do |wiki_page|
      BroadcastPolicies::WikiPagePolicy.new(wiki_page).
        should_dispatch_updated_wiki_page?
    end
  end

  def participants
    res = []
    if context && context.available?
      if !self.active?
        res += context.participating_admins
      else
        res += context.participants(by_date: true)
      end
    end
    res.flatten.uniq
  end

  def get_potentially_conflicting_titles(title_base)
    WikiPage.not_deleted.where(wiki_id: self.wiki_id).starting_with_title(title_base)
      .pluck("title").to_set
  end

  def to_atom(opts={})
    context = opts[:context]
    Atom::Entry.new do |entry|
      entry.title     = t(:atom_entry_title, "Wiki Page, %{course_or_group_name}: %{page_title}", :course_or_group_name => context.name, :page_title => self.title)
      entry.authors  << Atom::Person.new(:name => t(:atom_author, "Wiki Page"))
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/wiki_pages/#{self.feed_code}_#{self.updated_at.strftime("%Y-%m-%d")}"
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                    :href => "http://#{HostUrl.context_host(context)}/#{self.context.class.to_s.downcase.pluralize}/#{self.context.id}/pages/#{self.url}")
      entry.content   = Atom::Content::Html.new(self.body || t('defaults.no_content', "no content"))
    end
  end

  def user_name
    (user && user.name) || t('unknown_user_name', "Unknown")
  end

  def to_param
    url
  end

  def last_revision_at
    res = self.revised_at || self.updated_at
    res = Time.now if res.is_a?(String)
    res
  end

  def increment_view_count(user, context = nil)
    unless self.new_record?
      self.with_versioning(false) do |p|
        context ||= p.context
        WikiPage.where(id: p).update_all("view_count=COALESCE(view_count, 0) + 1")
        p.context_module_action(user, context, :read)
      end
    end
  end

  def can_unpublish?
    return @can_unpublish unless @can_unpublish.nil?
    @can_unpublish = !is_front_page?
  end
  attr_writer :can_unpublish

  def self.preload_can_unpublish(context, wiki_pages)
    return unless wiki_pages.any?
    front_page_url = context.wiki.get_front_page_url
    wiki_pages.each{|wp| wp.can_unpublish = !(wp.url == front_page_url)}
  end

  # opts contains a set of related entities that should be duplicated.
  # By default, all associated entities are duplicated.
  def duplicate(opts = {})
    # Don't clone a new record
    return self if self.new_record?
    default_opts = {
      :duplicate_assignment => true,
      :copy_title => nil
    }
    opts_with_default = default_opts.merge(opts)
    result = WikiPage.new({
      :title =>
        opts_with_default[:copy_title] ? opts_with_default[:copy_title] : get_copy_title(self, t("Copy"), self.title),
      :wiki_id => self.wiki_id,
      :context_id => self.context_id,
      :context_type => self.context_type,
      :body => self.body,
      :workflow_state => "unpublished",
      :user_id => self.user_id,
      :protected_editing => self.protected_editing,
      :editing_roles => self.editing_roles,
      :view_count => 0,
      :todo_date => self.todo_date
    })
    if self.assignment && opts_with_default[:duplicate_assignment]
        result.assignment = self.assignment.duplicate({
          :duplicate_wiki_page => false,
          :copy_title => result.title
        })
    end
    result
  end

  def initialize_wiki_page(user)
    if wiki.grants_right?(user, :publish_page)
      # Leave the page unpublished if the user is allowed to publish it later
      self.workflow_state = 'unpublished'
    else
      # If they aren't, publish it automatically
      self.workflow_state = 'active'
    end

    self.editing_roles = (context.default_wiki_editing_roles rescue nil) || default_roles

    if is_front_page?
      self.body = t "#application.wiki_front_page_default_content_course", "Welcome to your new course wiki!" if context.is_a?(Course)
      self.body = t "#application.wiki_front_page_default_content_group", "Welcome to your new group wiki!" if context.is_a?(Group)
      self.workflow_state = 'active'
    end
  end

  def post_to_pandapub_when_revised
    if saved_change_to_revised_at?
      CanvasPandaPub.post_update(
        "/private/wiki_page/#{self.global_id}/update", {
          revised_at: self.revised_at
        })
    end
  end
end
