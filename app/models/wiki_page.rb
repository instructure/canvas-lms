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
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class WikiPage < ActiveRecord::Base
  attr_readonly :wiki_id
  attr_accessor :saved_by

  validates :body, length: { maximum: maximum_long_text_length, allow_blank: true }
  validates :wiki_id, presence: true
  include Canvas::SoftDeletable
  include ScheduledPublication
  include HasContentTags
  include CopyAuthorizedLinks
  include ContextModuleItem
  include Submittable
  include Plannable
  include DuplicatingObjects
  include SearchTermHelper
  include LockedFor
  include HtmlTextHelper
  include DatesOverridable

  include MasterCourses::Restrictor
  restrict_columns :content, [:body, :title]
  restrict_columns :settings, [:editing_roles, :url]
  restrict_assignment_columns
  restrict_columns :state, [:workflow_state]
  restrict_columns :availability_dates, [:publish_at]

  include SmartSearchable
  use_smart_search title_column: :title,
                   body_column: :body,
                   index_scope: ->(course) { course.wiki_pages.not_deleted },
                   search_scope: ->(course, user) { WikiPages::ScopedToUser.new(course, user, course.wiki_pages.not_deleted).scope }

  after_update :post_to_pandapub_when_revised

  belongs_to :wiki, touch: true
  belongs_to :user

  belongs_to :context, polymorphic: [:course, :group]
  belongs_to :root_account, class_name: "Account"

  belongs_to :current_lookup, class_name: "WikiPageLookup"
  has_many :wiki_page_lookups, inverse_of: :wiki_page
  has_many :wiki_page_student_visibilities
  has_one :master_content_tag, class_name: "MasterCourses::MasterContentTag", inverse_of: :wiki_page
  has_one :block_editor, as: :context, dependent: :destroy
  accepts_nested_attributes_for :block_editor, allow_destroy: true
  acts_as_url :title, sync_url: true

  validate :validate_front_page_visibility

  before_save :default_submission_values,
              if: proc { context.try(:conditional_release?) }
  before_save :set_revised_at

  before_validation :ensure_wiki_and_context
  before_validation :ensure_unique_title
  before_create :set_root_account_id

  after_save  :touch_context
  after_save  :update_assignment,
              if: proc { context.try(:conditional_release?) }
  after_save :create_lookup, if: :should_create_lookup?
  after_save :delete_lookups, if: -> { !Account.site_admin.feature_enabled?(:permanent_page_links) && saved_change_to_workflow_state? && deleted? }

  scope :starting_with_title, lambda { |title|
    where("title ILIKE ?", "#{title}%")
  }

  scope :not_ignored_by, lambda { |user, purpose|
    where.not(Ignore.where(asset_type: "WikiPage", user_id: user, purpose:).where("asset_id=wiki_pages.id").arel.exists)
  }
  scope :todo_date_between, ->(starting, ending) { where(todo_date: starting...ending) }
  scope :for_courses_and_groups, lambda { |course_ids, group_ids|
    wiki_ids = []
    wiki_ids += Course.where(id: course_ids).pluck(:wiki_id) if course_ids.any?
    wiki_ids += Group.where(id: group_ids).pluck(:wiki_id) if group_ids.any?
    where(wiki_id: wiki_ids)
  }

  scope :visible_to_user, lambda { |user_id|
    where("wiki_pages.assignment_id IS NULL OR EXISTS (SELECT 1 FROM #{AssignmentStudentVisibility.quoted_table_name} asv WHERE wiki_pages.assignment_id = asv.assignment_id AND asv.user_id = ?)", user_id)
  }

  TITLE_LENGTH = 255
  SIMPLY_VERSIONED_EXCLUDE_FIELDS = %i[workflow_state editing_roles notify_of_update].freeze

  def ensure_wiki_and_context
    self.wiki_id ||= context.wiki_id || context.wiki.id
  end

  def context
    if !association(:context).loaded? &&
       association(:wiki).loaded? &&
       wiki.context_loaded? &&
       context_type == wiki.context_type &&
       context_id == wiki.context_id
      self.context = wiki.context
    end
    super
  end

  def touch_context
    context.touch
  end

  def validate_front_page_visibility
    if !published? && is_front_page?
      errors.add(:published, t(:cannot_unpublish_front_page, "cannot unpublish front page"))
    end
  end

  def url
    return read_attribute(:url) unless Account.site_admin.feature_enabled?(:permanent_page_links)

    current_lookup&.slug || read_attribute(:url)
  end

  def should_create_lookup?
    # covers page creation and title changes, and undeletes
    saved_change_to_title? || (saved_change_to_workflow_state? && workflow_state_before_last_save == "deleted")
  end

  def create_lookup
    new_record = id_changed?
    WikiPageLookup.unique_constraint_retry do
      lookup = wiki_page_lookups.find_by(slug: read_attribute(:url)) unless new_record
      lookup ||= wiki_page_lookups.build(slug: read_attribute(:url))
      lookup.save
      # this is kind of circular so we want to avoid triggering callbacks again
      update_column(:current_lookup_id, lookup.id)
    end
  end

  def delete_lookups
    update_column(:current_lookup_id, nil)
    wiki_page_lookups.delete_all(:delete_all)
  end

  def ensure_unique_title
    return if deleted? || Account.site_admin.feature_enabled?(:permanent_page_links)

    to_cased_title = ->(string) { string.gsub(/[^\w]+/, " ").gsub(/\b('?[a-z])/) { $1.capitalize }.strip }
    self.title ||= to_cased_title.call(read_attribute(:url) || "page")
    # TODO: i18n (see wiki.rb)

    if self.title == "Front Page" && new_record?
      baddies = context.wiki_pages.not_deleted.where(title: "Front Page").reject { |p| p.url == "front-page" }
      baddies.each do |p|
        p.title = to_cased_title.call(p.url)
        p.save_without_broadcasting!
      end
    end

    if context.wiki_pages.not_deleted.where(title: self.title).where.not(id:).first
      if /-\d+\z/.match?(self.title)
        # A page with this title already exists and the title ends in -<some number>.
        # This has potential to conflict with our handling of duplicate title names.
        # We tried to fix in earnest but there are too many edge cases. Thus, we just disallow this.
        errors.add(:title, t("A page with this title already exists. Please choose a different title."))
      end
      n = 2
      new_title = nil
      loop do
        mod = "-#{n}"
        new_title = self.title[0...(TITLE_LENGTH - mod.length)] + mod
        n = n.succ
        break unless context.wiki_pages.not_deleted.where(title: new_title).where.not(id:).exists?
      end

      self.title = new_title
    end
  end

  def self.title_order_by_clause
    best_unicode_collation_key("wiki_pages.title")
  end

  def ensure_unique_url
    return if deleted?

    url_attribute = self.class.url_attribute
    base_url = send(url_attribute)

    if base_url.blank? || !only_when_blank
      base_url = self.class.url_for(
        send(self.class.attribute_to_urlify).to_s
      )
    end

    url_conditions = [wildcard(url_attribute.to_s, base_url, type: :right)]
    unless new_record?
      url_conditions.first << " and id != ?"
      url_conditions << id
    end
    urls = context.wiki_pages.where(*url_conditions).not_deleted.pluck(:url)

    lookup_conditions = [wildcard("slug", base_url, type: :right)]
    urls += context.wiki_page_lookups.where(*lookup_conditions).where.not(wiki_page_id: id).pluck(:slug)

    # This is the part in stringex that messed us up, since it will never allow
    # a url of "front-page" once "front-page-1" or "front-page-2" is created
    # We modify it to allow "front-page" and start the indexing at "front-page-2"
    # instead of "front-page-1"
    if !urls.empty? && urls.detect { |u| u == base_url }
      n = 2
      while urls.detect { |u| u == "#{base_url}-#{n}" }
        n = n.succ
      end
      write_attribute url_attribute, "#{base_url}-#{n}"
    else
      write_attribute url_attribute, base_url
    end
  end

  sanitize_field :body, CanvasSanitize::SANITIZE
  copy_authorized_links(:body) { [context, user] }

  validates_each :title do |record, attr, value|
    if value.blank?
      record.errors.add(attr, t("errors.blank_title", "Title can't be blank"))
    elsif value.size > maximum_string_length
      record.errors.add(attr, t("errors.title_too_long", "Title can't exceed %{max_characters} characters", max_characters: maximum_string_length))
    elsif value.to_url.blank?
      record.errors.add(attr, t("errors.title_characters", "Title must contain at least one letter or number")) # it's a bit more liberal than this, but let's not complicate things
    end
  end

  has_a_broadcast_policy
  simply_versioned exclude: SIMPLY_VERSIONED_EXCLUDE_FIELDS, when: proc { |wp|
    # always create a version when restoring a deleted page
    next true if wp.workflow_state_changed? && wp.workflow_state_was == "deleted"

    # :user_id and :updated_at do not merit creating a version, but should be saved
    exclude_fields = [:user_id, :updated_at].concat(SIMPLY_VERSIONED_EXCLUDE_FIELDS).map(&:to_s)
    (wp.changes.keys.map(&:to_s) - exclude_fields).present?
  }

  after_save :remove_changed_flag

  workflow do
    state :active do
      event :unpublish, transitions_to: :unpublished
    end
    state :unpublished do
      event :publish, transitions_to: :active
    end
    state :post_delayed do
      event :delayed_post, transitions_to: :active
    end
  end
  alias_method :published?, :active?

  def set_revised_at
    self.revised_at ||= Time.now
    self.revised_at = Time.now if body_changed? || title_changed?
    @page_changed = body_changed? || title_changed?
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
    versions.map(&:model)
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

  def low_level_locked_for?(user, opts = {})
    return false unless could_be_locked

    RequestCache.cache(locked_request_cache_key(user), opts[:deep_check_if_needed]) do
      locked = false
      if (item = locked_by_module_item?(user, opts))
        locked = { object: self, module: item.context_module }
        unlock_at = locked[:module].unlock_at
        locked[:unlock_at] = unlock_at if unlock_at && unlock_at > Time.now.utc
      end
      locked
    end
  end

  def is_front_page?
    return false if deleted?

    url == wiki.get_front_page_url # wiki.get_front_page_url checks has_front_page?
  end

  def set_as_front_page!
    if unpublished?
      errors.add(:front_page, t(:cannot_set_unpublished_front_page, "could not set as front page because it is unpublished"))
      return false
    end

    wiki.set_front_page_url!(url)
    touch if persisted?
  end

  def context_module_tag_for(context)
    @context_module_tag_for ||= context_module_tags.where(context:).first
  end

  def context_module_action(user, context, action)
    context_module_tags.where(context:).each do |tag|
      tag.context_module_action(user, action)
    end
  end

  set_policy do
    given { |user, session| can_read_page?(user, session) }
    can :read

    given { |user| user && can_edit_page?(user) }
    can :update_content and can :read_revisions

    given { |user, session| user && wiki.grants_right?(user, session, :create_page) }
    can :create

    given { |user, session| user && can_edit_page?(user) && wiki.grants_right?(user, session, :update_page) }
    can :update and can :read_revisions

    given { |user, session| user && can_read_page?(user) && wiki.grants_right?(user, session, :delete_page) }
    can :delete
  end

  def can_read_page?(user, session = nil)
    return true if unpublished? && wiki.grants_right?(user, session, :view_unpublished_items)

    published? && wiki.grants_right?(user, session, :read)
  end

  def can_edit_page?(user, session = nil)
    return false unless can_read_page?(user, session)

    # wiki managers are always allowed to edit.
    return true if wiki.grants_right?(user, session, :update)

    roles = effective_roles
    return false if context.try(:completed?)
    # teachers implies all course admins (teachers, TAs, etc)
    return true if roles.include?("teachers") && context.respond_to?(:admins) && context.admins.include?(user)

    # the page must be available for users of the following roles
    return false unless available_for?(user, session)
    return true if roles.include?("students") && context.respond_to?(:students) && context.includes_student?(user)

    if roles.include?("members") || roles.include?("public")
      if context.is_a?(Course)
        return true if context.active_users.include?(user)
      elsif context.respond_to?(:users) && context.users.include?(user)
        return true
      end
    end

    false
  end

  def effective_roles
    context_roles = context.default_wiki_editing_roles rescue nil
    roles = (editing_roles || context_roles || default_roles).split(",")
    (roles == %w[teachers]) ? [] : roles # "Only teachers" option doesn't grant rights excluded by RoleOverrides
  end

  def available_for?(user, session = nil)
    return true if wiki.grants_right?(user, session, :update)

    return false unless published? || (unpublished? && wiki.grants_right?(user, session, :view_unpublished_items))
    return false if locked_for?(user, deep_check_if_needed: true)

    true
  end

  def default_roles
    if context.is_a?(Course)
      "teachers"
    else
      "members"
    end
  end

  def course_broadcast_data
    context&.broadcast_data
  end

  set_broadcast_policy do |p|
    p.dispatch :updated_wiki_page
    p.to { participants }
    p.whenever do |wiki_page|
      BroadcastPolicies::WikiPagePolicy.new(wiki_page)
                                       .should_dispatch_updated_wiki_page?
    end
    p.data { course_broadcast_data }
  end

  def participants
    res = []
    if context&.available?
      res += if active?
               context.participants(by_date: true)
             else
               context.participating_admins
             end
    end
    res.flatten.uniq
  end

  def get_potentially_conflicting_titles(title_base)
    WikiPage.not_deleted.where(wiki_id: self.wiki_id).starting_with_title(title_base)
            .pluck("title").to_set
  end

  def to_atom(opts = {})
    context = opts[:context]

    {
      title: t(:atom_entry_title, "Wiki Page, %{course_or_group_name}: %{page_title}", course_or_group_name: context.name, page_title: self.title),
      author: t(:atom_author, "Wiki Page"),
      updated: updated_at,
      published: created_at,
      id: "tag:#{HostUrl.default_host},#{created_at.strftime("%Y-%m-%d")}:/wiki_pages/#{feed_code}_#{updated_at.strftime("%Y-%m-%d")}",
      link: "http://#{HostUrl.context_host(context)}/#{self.context.class.to_s.downcase.pluralize}/#{self.context.id}/pages/#{url}",
      content: body || t("defaults.no_content", "no content")
    }
  end

  def user_name
    user&.name || t("unknown_user_name", "Unknown")
  end

  def to_param
    url
  end

  def last_revision_at
    res = self.revised_at || updated_at
    res = Time.now if res.is_a?(String)
    res
  end

  def can_unpublish?
    return @can_unpublish unless @can_unpublish.nil?

    @can_unpublish = !is_front_page?
  end
  attr_writer :can_unpublish

  def self.preload_can_unpublish(context, wiki_pages)
    return unless wiki_pages.any?

    front_page_url = context.wiki.get_front_page_url
    wiki_pages.each { |wp| wp.can_unpublish = wp.url != front_page_url }
  end

  def self.reinterpret_version_yaml(yaml_string)
    # TODO: This should be temporary.  For a long time
    # course exports/imports would corrupt the yaml in the first version
    # of an imported wiki page by trying to replace placeholders right
    # in the yaml.  This doctors the yaml back, and can be removed
    # when the "content_imports" exception type for psych syntax errors
    # isn't happening anymore.
    pattern_1 = %r{(<a[^<>]*?id=.*?"media_comment.*?/>)}im
    pattern_2 = %r{(<a[^<>]*?id=.*?"media_comment.*?</a>)}
    replacements = []
    [pattern_1, pattern_2].each do |regex_pattern|
      yaml_string.scan(regex_pattern).each do |matched_groups|
        matched_groups.each do |group|
          # this should be an UNESCAPED version of a media comment.
          # let's try to escape it.
          replacements << [group, group.inspect[1..-2]]
        end
      end
    end
    new_string = yaml_string.dup
    replacements.each do |operation|
      new_string = new_string.sub(operation[0], operation[1])
    end
    # if this works without throwing another error, we've
    # cleaned up the yaml successfully
    YAML.load(new_string)
    new_string
  end

  def self.url_for(title)
    use_unicode_scripts = %w[Katakana]

    return title if title.blank?

    # Convert to ascii chars unless the string matches
    # a script we want to store in unicode
    return title.to_s.to_url unless title.match?(
      /#{use_unicode_scripts.map { |s| "\\p{#{s}}" }.join("|")}/
    )

    # Return title with unicode chars, replacing chars like ? and &
    title.to_s.convert_misc_characters.collapse
  end

  # opts contains a set of related entities that should be duplicated.
  # By default, all associated entities are duplicated.
  def duplicate(opts = {})
    # Don't clone a new record
    return self if new_record?

    default_opts = {
      duplicate_assignment: true,
      copy_title: nil
    }
    opts_with_default = default_opts.merge(opts)
    result = WikiPage.new({
                            title: opts_with_default[:copy_title] || get_copy_title(self, t("Copy"), self.title),
                            wiki_id: self.wiki_id,
                            context_id:,
                            context_type:,
                            body:,
                            workflow_state: "unpublished",
                            user_id:,
                            protected_editing:,
                            editing_roles:,
                            todo_date:
                          })
    if assignment && opts_with_default[:duplicate_assignment]
      result.assignment = assignment.duplicate({
                                                 duplicate_wiki_page: false,
                                                 copy_title: result.title
                                               })
    end
    result
  end

  def can_duplicate?
    true
  end

  def initialize_wiki_page(user)
    self.workflow_state = if wiki.grants_right?(user, :publish_page)
                            # Leave the page unpublished if the user is allowed to publish it later
                            "unpublished"
                          else
                            # If they aren't, publish it automatically
                            "active"
                          end

    self.editing_roles = (context.default_wiki_editing_roles rescue nil) || default_roles

    if is_front_page?
      self.body = t "#application.wiki_front_page_default_content_course", "Welcome to your new course wiki!" if context.is_a?(Course)
      self.body = t "#application.wiki_front_page_default_content_group", "Welcome to your new group wiki!" if context.is_a?(Group)
      self.workflow_state = "active"
    end
  end

  def post_to_pandapub_when_revised
    if saved_change_to_revised_at?
      CanvasPandaPub.post_update(
        "/private/wiki_page/#{global_id}/update", {
          revised_at: self.revised_at
        }
      )
    end
  end

  def set_root_account_id
    self.root_account_id = context&.root_account_id unless root_account_id
  end
end
