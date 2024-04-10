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
require "redcarpet"

class ContextExternalTool < ActiveRecord::Base
  include Workflow
  include SearchTermHelper
  include PermissionsHelper

  has_many :content_tags, as: :content
  has_many :context_external_tool_placements, autosave: true
  has_many :lti_resource_links, class_name: "Lti::ResourceLink"

  belongs_to :context, polymorphic: [:course, :account]
  belongs_to :developer_key
  belongs_to :root_account, class_name: "Account"

  include MasterCourses::Restrictor
  restrict_columns :content, [:name, :description]
  restrict_columns :settings, %i[consumer_key shared_secret url domain settings]

  validates :context_id, :context_type, :workflow_state, presence: true
  validates :name, :consumer_key, :shared_secret, presence: true
  validates :name, length: { maximum: maximum_string_length }
  validates :consumer_key, length: { maximum: 2048 }
  validates :config_url, presence: { if: ->(t) { t.config_type == "by_url" } }
  validates :config_xml, presence: { if: ->(t) { t.config_type == "by_xml" } }
  validates :domain, length: { maximum: 253, allow_blank: true }
  validates :lti_version, inclusion: { in: %w[1.1 1.3], message: -> { t("%{value} is not a valid LTI version") } }
  validate :url_or_domain_is_set
  validate :validate_urls
  attr_reader :config_type, :config_url, :config_xml

  # handles both serialized Hashes and HashWithIndifferentAccesses
  # and always returns a HashWithIndifferentAccess
  #
  # would LOVE to rip this out and not store everything in `settings`
  class SettingsSerializer
    def self.load(value)
      return nil unless value

      obj = YAML.safe_load(value)
      if obj.respond_to? :with_indifferent_access
        return obj.with_indifferent_access
      end

      obj
    end

    def self.dump(value)
      YAML.dump(value)
    end
  end
  serialize :settings, coder: SettingsSerializer

  # add_identity_hash needs to calculate off of other data in the object, so it
  # should always be the last field change callback to run
  before_save :infer_defaults, :validate_vendor_help_link, :add_identity_hash
  after_save :touch_context, :check_global_navigation_cache, :clear_tool_domain_cache
  validate :check_for_xml_error

  scope :disabled, -> { where(workflow_state: DISABLED_STATE) }
  scope :quiz_lti, -> { where(tool_id: QUIZ_LTI) }

  STANDARD_EXTENSION_KEYS = [
    :canvas_icon_class,
    :custom_fields,
    :default,
    :display_type,
    :enabled,
    :icon_svg_path_64,
    :icon_url,
    :message_type,
    :prefer_sis_email,
    :required_permissions,
    :launch_height,
    :launch_width,
    :selection_height,
    :selection_width,
    :text,
    :labels,
    :windowTarget,
    :url,
    :target_link_uri,
    :root_account_only,
    [:visibility, ->(v) { %w[members admins public].include?(v) || v.nil? }].freeze,
  ].freeze

  CUSTOM_EXTENSION_KEYS = {
    file_menu: [:accept_media_types].freeze,
    editor_button: [:use_tray].freeze
  }.freeze

  DISABLED_STATE = "disabled"
  QUIZ_LTI = "Quizzes 2"
  ANALYTICS_2 = "fd75124a-140e-470f-944c-114d2d93bb40"
  ADMIN_ANALYTICS = "admin-analytics"
  TOOL_FEATURE_MAPPING = { ANALYTICS_2 => :analytics_2, ADMIN_ANALYTICS => :admin_analytics }.freeze
  PREFERRED_LTI_VERSION = "1_3"

  workflow do
    state :anonymous
    state :name_only
    state :email_only
    state :public
    state :deleted
    state DISABLED_STATE.to_sym # The tool's developer key is "off" but not deleted
  end

  set_policy do
    #################### Begin legacy permission block #########################
    given do |user, session|
      !context.root_account.feature_enabled?(:granular_permissions_manage_lti) &&
        context.grants_right?(user, session, :lti_add_edit)
    end
    can :read and can :update and can :delete and can :update_manually
    ##################### End legacy permission block ##########################

    given do |user, session|
      context.root_account.feature_enabled?(:granular_permissions_manage_lti) &&
        context.grants_right?(user, session, :manage_lti_edit)
    end
    can :read and can :update and can :update_manually

    given do |user, session|
      context.root_account.feature_enabled?(:granular_permissions_manage_lti) &&
        context.grants_right?(user, session, :manage_lti_delete)
    end
    can :read and can :delete
  end

  class << self
    # because global navigation tool visibility can depend on a user having particular permissions now
    # this needs to expand from being a simple "admins/members" check to something more full-fledged
    # this will return a hash with the original visibility setting alone with a computed list of
    # all other permissions (as needed) granted by the current context so all users with the same
    # set of computed permissions will share the same global nav cache
    def global_navigation_granted_permissions(root_account:, user:, context:, session: nil)
      return { original_visibility: "members" } unless user

      permissions_hash = {}
      # still use the original visibility setting
      permissions_hash[:original_visibility] = Rails.cache.fetch_with_batched_keys(
        ["external_tools/global_navigation/visibility", root_account.asset_string].cache_key,
        batch_object: user,
        batched_keys: [:enrollments, :account_users]
      ) do
        # let them see admin level tools if there are any courses they can manage
        if root_account.grants_any_right?(user, :manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS) ||
           GuardRail.activate(:secondary) { Course.manageable_by_user(user.id, false).not_deleted.where(root_account_id: root_account).exists? }
          "admins"
        else
          "members"
        end
      end
      required_permissions = global_navigation_permissions_to_check(root_account)
      required_permissions.each do |permission|
        # run permission checks against the context if any of the tools are configured to require them
        permissions_hash[permission] = context.grants_right?(user, session, permission)
      end
      permissions_hash
    end

    def filtered_global_navigation_tools(root_account, granted_permissions)
      tools = all_global_navigation_tools(root_account)

      if granted_permissions[:original_visibility] != "admins"
        # reject the admin only tools
        tools.reject! { |tool| tool.global_navigation[:visibility] == "admins" }
      end
      # check against permissions if needed
      tools.select! do |tool|
        required_permissions_str = tool.extension_setting(:global_navigation, "required_permissions")
        if required_permissions_str
          required_permissions_str.split(",").map(&:to_sym).all? { |p| granted_permissions[p] }
        else
          true
        end
      end
      tools
    end

    # returns a key composed of the updated_at times for all the tools visible to someone with the granted_permissions
    # i.e. if it hasn't changed since the last time we rendered the erb template for the menu then we can re-use the same html
    def global_navigation_menu_render_cache_key(root_account, granted_permissions)
      # only re-render the menu if one of the global nav tools has changed
      perm_key = key_for_granted_permissions(granted_permissions)
      compiled_key = ["external_tools/global_navigation/compiled_tools_updated_at", root_account.global_asset_string, perm_key].cache_key

      # shameless plug for the cache register system:
      # batching with the :global_navigation key means that we can easily mark every one of these for recalculation
      # in the :check_global_navigation_cache callback instead of having to explicitly delete multiple keys
      # (which was fine when we only had two visibility settings but not when an infinite combination of permissions is in play)
      Rails.cache.fetch_with_batched_keys(compiled_key, batch_object: root_account, batched_keys: :global_navigation) do
        tools = filtered_global_navigation_tools(root_account, granted_permissions)
        Digest::SHA256.hexdigest(tools.sort.map(&:cache_key).join("/"))
      end
    end

    def visible?(visibility, user, context, session = nil)
      visibility = visibility.to_s
      return true unless %w[public members admins].include?(visibility)
      return true if visibility == "public"
      return true if visibility == "members" &&
                     context.grants_any_right?(user, session, :participate_as_student, :read_as_admin)
      return true if visibility == "admins" && context.grants_right?(user, session, :read_as_admin)

      false
    end

    def editor_button_json(tools, context, user, session, default_tool_icon_base_url)
      tools.select! { |tool| visible?(tool.editor_button["visibility"], user, context, session) }
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new({ link_attributes: { target: "_blank" } }))
      always_on_ids = Setting.get("rce_always_on_developer_key_ids", "").split(",").map(&:to_i)
      tools.map do |tool|
        canvas_icon_class = tool.editor_button(:canvas_icon_class)
        icon_url = tool.editor_button(:icon_url)
        if canvas_icon_class.blank? && icon_url.blank?
          # Default tool icons are served by canvas; some users of this method
          # may need a full URL rather than path.
          icon_url = default_tool_icon_base_url + tool.default_icon_path
        end

        {
          name: tool.label_for(:editor_button, I18n.locale),
          id: tool.id,
          favorite: tool.is_rce_favorite_in_context?(context),
          url: tool.editor_button(:url),
          icon_url:,
          canvas_icon_class:,
          width: tool.editor_button(:selection_width),
          height: tool.editor_button(:selection_height),
          use_tray: tool.editor_button(:use_tray) == "true",
          always_on: always_on_ids.include?(tool.global_developer_key_id),
          description: if tool.description
                         Sanitize.clean(markdown.render(tool.description), CanvasSanitize::SANITIZE)
                       else
                         ""
                       end
        }
      end
    end

    private

    def context_id_for(asset, shard)
      str = asset.asset_string.to_s
      raise "Empty value" if str.blank?

      Canvas::Security.hmac_sha1(str, shard.settings[:encryption_key])
    end

    def global_navigation_permissions_to_check(root_account)
      # look at the list of tools that are configured for the account and see if any are asking for permissions checks
      Rails.cache.fetch_with_batched_keys("external_tools/global_navigation/permissions_to_check", batch_object: root_account, batched_keys: :global_navigation) do
        tools = all_global_navigation_tools(root_account)
        tools.filter_map { |tool| tool.extension_setting(:global_navigation, "required_permissions")&.split(",")&.map(&:to_sym) }.flatten.uniq
      end
    end

    def all_global_navigation_tools(root_account)
      RequestCache.cache("global_navigation_tools", root_account) do # prevent re-querying
        Lti::ContextToolFinder.new(root_account, type: :global_navigation).all_tools_scope_union.to_unsorted_array
      end
    end

    def key_for_granted_permissions(granted_permissions)
      Digest::SHA256.hexdigest(granted_permissions.sort.flatten.join(",")) # for consistency's sake
    end
  end

  Lti::ResourcePlacement::PLACEMENTS.each do |type|
    class_eval <<~RUBY, __FILE__, __LINE__ + 1
      def #{type}(setting=nil)
        # expose inactive placements to API
        extension_setting(:#{type}, setting) || extension_setting(:inactive_placements, :#{type})
      end

      def #{type}=(hash)
        set_extension_setting(:#{type}, hash)
      end
    RUBY
  end

  def deployment_id
    "#{id}:#{Lti::Asset.opaque_identifier_for(context)}"[0..254]
  end

  def content_migration_configured?
    settings.key?("content_migration") &&
      settings["content_migration"].is_a?(Hash) &&
      settings["content_migration"].key?("export_start_url") &&
      settings["content_migration"].key?("import_start_url")
  end

  def extension_setting(type, property = nil)
    val = calculate_extension_setting(type, property)
    if property == :icon_url
      # make sure it's a valid url
      return nil if val && (URI.parse(val) rescue nil).nil?

      # account for beta and test overrides
      return url_with_environment_overrides(val)
    end

    val
  end

  def calculate_extension_setting(type, property = nil)
    return settings[property] unless type

    type = type.to_sym
    return setting_with_default_enabled(type) unless property && settings[type]

    settings[type][property] || settings[property] || extension_default_value(type, property)
  end

  def setting_with_default_enabled(type)
    return nil unless settings[type]
    return settings[type] unless Lti::ResourcePlacement::PLACEMENTS.include?(type)

    { enabled: true }.with_indifferent_access.merge(settings[type])
  end

  # Returns array of either <symbol type> or array [<symbol type>, <validator block>]
  def self.extension_keys_for_placement(type)
    extension_keys = STANDARD_EXTENSION_KEYS

    if (custom_keys = CUSTOM_EXTENSION_KEYS[type])
      extension_keys += custom_keys
    end

    extension_keys
  end

  def set_extension_setting(type, hash)
    if !hash || !hash.is_a?(Hash)
      settings.delete type
      remove_from_inactive_placements(type)
      return
    end

    hash = hash.with_indifferent_access
    hash[:enabled] = Canvas::Plugin.value_to_boolean(hash[:enabled]) if hash[:enabled]

    # merge with existing settings so that no caller can complain
    settings[type] = (settings[type] || {}).with_indifferent_access unless placement_inactive?(type)

    ContextExternalTool.extension_keys_for_placement(type).each do |key, validator|
      if hash.key?(key) && (!validator || validator.call(hash[key]))
        if placement_inactive?(type)
          settings[:inactive_placements][type][key] = hash[key]
        else
          settings[type][key] = hash[key]
        end
      end
    end

    # on deactivation, make sure placement data is kept
    if settings[type]&.key?(:enabled) && !settings[type][:enabled]
      # resource_selection is a default placement, which can only be overridden
      # by not_selectable, see scope :placements on line 826
      self.not_selectable = true if type == :resource_selection

      settings[:inactive_placements] ||= {}.with_indifferent_access
      settings[:inactive_placements][type] ||= {}.with_indifferent_access
      settings[:inactive_placements][type].merge!(settings[type])
      settings.delete(type)
      return
    end

    # on reactivation, use the old placement data
    old_placement_data = settings.dig(:inactive_placements, type)
    if old_placement_data&.include?(:enabled) && old_placement_data[:enabled]
      # resource_selection is a default placement, which can only be overridden
      # by not_selectable, see scope :placements on line 826
      self.not_selectable = false if type == :resource_selection

      settings[type] = old_placement_data
      remove_from_inactive_placements(type)
    end

    settings[type]&.compact!
  end

  def remove_from_inactive_placements(type)
    settings[:inactive_placements]&.delete(type)
    settings.delete(:inactive_placements) if settings[:inactive_placements] && settings[:inactive_placements].empty?
  end

  def placement_inactive?(type)
    settings.dig(:inactive_placements, type).present?
  end

  def has_placement?(type)
    # Only LTI 1.1 tools support default placements
    # (LTI 2 tools also, but those are not handled by this class)
    if lti_version == "1.1" &&
       Lti::ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS.include?(type.to_s) &&
       !!(selectable && (domain || url))
      true
    else
      context_external_tool_placements.to_a.any? { |p| p.placement_type == type.to_s }
    end
  end

  def can_be_rce_favorite?
    !editor_button.nil?
  end

  def is_rce_favorite_in_context?(context)
    context = context.context if context.is_a?(Group)
    context = context.account if context.is_a?(Course)
    rce_favorite_tool_ids = context.rce_favorite_tool_ids[:value]
    if rce_favorite_tool_ids
      rce_favorite_tool_ids.include?(global_id)
    else
      # TODO: remove after the datafixup and this column is dropped
      is_rce_favorite
    end
  end

  def sync_placements!(placements)
    context_external_tool_placements.reload if context_external_tool_placements.loaded?
    old_placements = context_external_tool_placements.pluck(:placement_type)
    placements_to_delete = Lti::ResourcePlacement::PLACEMENTS.map(&:to_s) - placements
    if placements_to_delete.any?
      context_external_tool_placements.where(placement_type: placements_to_delete).delete_all if persisted?
      context_external_tool_placements.reload if context_external_tool_placements.loaded?
    end
    (placements - old_placements).each do |new_placement|
      context_external_tool_placements.new(placement_type: new_placement)
    end
  end
  private :sync_placements!

  def url_or_domain_is_set
    placements = Lti::ResourcePlacement::PLACEMENTS
    # url or domain (or url on canvas lti extension) is required
    if url.blank? && domain.blank? && placements.all? { |k| !settings[k] || (settings[k]["url"].blank? && settings[k]["target_link_uri"].blank?) }
      errors.add(:url, t("url_or_domain_required", "Either the url or domain should be set."))
      errors.add(:domain, t("url_or_domain_required", "Either the url or domain should be set."))
    end
  end

  def validate_urls
    (
      [url] + Lti::ResourcePlacement::PLACEMENTS.map do |p|
        settings[p]&.with_indifferent_access&.fetch("url", nil) ||
        settings[p]&.with_indifferent_access&.fetch("target_link_uri", nil)
      end
    )
      .compact
      .map { |u| validate_url(u) }
  end
  private :validate_urls

  def validate_url(u)
    u = URI.parse(u)
  rescue
    errors.add(:url,
               t("url_or_domain_no_valid", "Incorrect url for %{url}", url: u))
  end
  private :validate_url

  def settings
    read_or_initialize_attribute(:settings, {}.with_indifferent_access)
  end

  def label_for(key, lang = nil)
    lang = lang.to_s if lang
    labels = settings[key] && settings[key][:labels]
    (labels && labels[lang]) ||
      (labels && lang && labels[lang.split("-").first]) ||
      (settings[key] && settings[key][:text]) ||
      default_label(lang)
  end

  def default_label(lang = nil)
    lang = lang.to_s if lang
    default_labels = settings[:labels]
    (default_labels && default_labels[lang]) ||
      (default_labels && lang && default_labels[lang.split("-").first]) ||
      settings[:text] || name || "External Tool"
  end

  def check_for_xml_error
    (@config_errors || []).each do |attr, msg|
      errors.add attr, msg
    end
  end
  protected :check_for_xml_error

  def readable_state
    workflow_state.titleize
  end

  # --- Privacy Level ---
  # See doc/lti_manual/16_privacy_level.md for a full explanation
  def privacy_level=(val)
    if %w[anonymous name_only email_only public].include?(val)
      self.workflow_state = val
    end
  end

  def privacy_level
    workflow_state
  end

  def include_email?
    email_only? || public?
  end

  def include_name?
    name_only? || public?
  end
  # --- End Privacy Level ---

  def custom_fields_string
    (settings[:custom_fields] || {}).map do |key, val|
      "#{key}=#{val}"
    end.sort.join("\n")
  end

  def vendor_help_link
    settings[:vendor_help_link]
  end

  def vendor_help_link=(val)
    settings[:vendor_help_link] = val
  end

  def validate_vendor_help_link
    return if vendor_help_link.blank?

    begin
      _value, uri = CanvasHttp.validate_url(vendor_help_link)
      self.vendor_help_link = uri.to_s
    rescue URI::Error, ArgumentError
      self.vendor_help_link = nil
    end
  end

  def config_type=(val)
    @config_type = val
    process_extended_configuration
  end

  def config_xml=(val)
    @config_xml = val
    process_extended_configuration
  end

  def config_url=(val)
    @config_url = val
    process_extended_configuration
  end

  def process_extended_configuration
    return unless (config_type == "by_url" && config_url) || (config_type == "by_xml" && config_xml)

    @config_errors = []
    error_field = (config_type == "by_xml") ? "config_xml" : "config_url"
    converter = CC::Importer::BLTIConverter.new
    tool_hash = if config_type == "by_url"
                  uri = Addressable::URI.parse(config_url)
                  raise URI::Error unless uri.host

                  converter.retrieve_and_convert_blti_url(config_url)
                else
                  converter.convert_blti_xml(config_xml)
                end

    real_name = name
    if tool_hash[:error]
      @config_errors << [error_field, tool_hash[:error]]
    else
      Importers::ContextExternalToolImporter.import_from_migration(tool_hash, context, nil, self)
    end
    self.name = real_name unless real_name.blank?
  rescue CC::Importer::BLTIConverter::CCImportError => e
    @config_errors << [error_field, e.message]
  rescue URI::Error, CanvasHttp::Error
    @config_errors << [:config_url, "Invalid URL"]
  rescue ActiveRecord::RecordInvalid => e
    @config_errors += Array(e.record.errors)
  end

  def use_1_3?
    lti_version == "1.3"
  end

  def use_1_3=(bool)
    self.lti_version = bool ? "1.3" : "1.1"
  end

  def uses_preferred_lti_version?
    !!send(:"use_#{PREFERRED_LTI_VERSION}?")
  end

  def active?
    ["deleted", "disabled"].exclude? workflow_state
  end

  def self.find_custom_fields_from_string(str)
    return {} if str.nil?

    str.split(/[\r\n]+/).each_with_object({}) do |line, hash|
      key, val = line.split("=")
      hash[key] = val if key.present? && val.present?
    end
  end

  def custom_fields_string=(str)
    settings[:custom_fields] = ContextExternalTool.find_custom_fields_from_string(str)
  end

  def custom_fields=(hash)
    settings[:custom_fields] = hash if hash.is_a?(Hash)
  end

  def custom_fields
    settings[:custom_fields]
  end

  def icon_url=(i_url)
    settings[:icon_url] = i_url
  end

  def icon_url
    url_with_environment_overrides(settings[:icon_url])
  end

  def canvas_icon_class=(i_url)
    settings[:canvas_icon_class] = i_url
  end

  def canvas_icon_class
    settings[:canvas_icon_class]
  end

  def text=(val)
    settings[:text] = val
  end

  def text
    settings[:text]
  end

  def oauth_compliant=(val)
    settings[:oauth_compliant] = Canvas::Plugin.value_to_boolean(val)
  end

  def oauth_compliant
    settings[:oauth_compliant]
  end

  def not_selectable
    !!read_attribute(:not_selectable)
  end

  def not_selectable=(bool)
    write_attribute(:not_selectable, Canvas::Plugin.value_to_boolean(bool))
  end

  def selectable
    !not_selectable
  end

  def shared_secret=(val)
    write_attribute(:shared_secret, val) unless val.blank?
  end

  def display_type(extension_type)
    extension_setting(extension_type, :display_type) || "in_context"
  end

  def lti_1_3_login_url
    return nil unless use_1_3? && developer_key

    settings.dig("oidc_initiation_urls", shard.database_server.config[:region]) ||
      developer_key.oidc_initiation_url
  end

  def login_or_launch_url(extension_type: nil, preferred_launch_url: nil)
    lti_1_3_login_url || launch_url(extension_type:, preferred_launch_url:)
  end

  def launch_url(extension_type: nil, preferred_launch_url: nil)
    launch_url = preferred_launch_url ||
                 (use_1_3? && extension_setting(extension_type, :target_link_uri)) ||
                 extension_setting(extension_type, :url) ||
                 url

    url_with_environment_overrides(launch_url, include_launch_url: true)
  end

  # Modifies url based on `environments` overrides.
  # Only valid for 1.1 tools, and only in beta or test Instructure-hosted Canvas.
  # Only valid for tools that define overrides in the `environments` configuration
  # (see doc/api/file.tools_xml.md#test_env_settings for details).
  # Replaces the old behavior of rewriting tool urls/domain in the database during
  # a beta refresh.
  # launch_url overrides are only considered when include_launch_url: true is
  # provided, and are preferred over domain overrides. Query strings from the
  # base_url and launch_url override will be merged together.
  # @param base_url [String]
  def url_with_environment_overrides(base_url, include_launch_url: false)
    return base_url unless use_environment_overrides?

    override_url = environment_overrides_for(:launch_url)
    if override_url && include_launch_url
      base_query = Addressable::URI.parse(base_url)&.query_values
      return override_url if base_query.nil?

      override_uri = Addressable::URI.parse(override_url)
      override_uri.query_values = base_query.merge(override_uri&.query_values || {})
      return override_uri.to_s
    end

    override_domain = environment_overrides_for(:domain)
    if override_domain
      base_uri = Addressable::URI.parse(base_url)
      return base_url if base_uri.nil?
      return base_url unless base_uri.host

      begin
        base_uri.host = override_domain.chomp("/") # ignore trailing slash
      rescue Addressable::URI::InvalidURIError
        # account for domains with "http(s)://"
        override_uri = Addressable::URI.parse(override_domain)
        base_uri.host = override_uri.host
      end

      return base_uri.to_s
    end

    base_url
  end

  # Modifies domain based on `environments` overrides.
  # Only valid for 1.1 tools, and only in beta or test Instructure-hosted Canvas.
  # Only valid for tools that define overrides in the `environments` configuration
  # (see doc/api/file.tools_xml.md#test_env_settings for details).
  # Replaces the old behavior of rewriting tool domain in the database during
  # a beta refresh.
  def domain_with_environment_overrides
    return domain unless use_environment_overrides?

    override_domain = environment_overrides_for(:domain)
    return override_domain if override_domain

    domain
  end

  # Retrieve `environments` overrides for either :domain or :launch_url.
  # Prefers environment-specific overrides (eg `beta_domain`) over general
  # overrides (eg `domain`).
  def environment_overrides_for(key)
    return nil unless [:domain, :launch_url].include?(key.to_sym)

    env = ApplicationController.test_cluster_name
    settings.dig(:environments, "#{env}_#{key}").presence ||
      settings.dig(:environments, key).presence
  end

  def use_environment_overrides?
    return false if use_1_3?
    return false unless ApplicationController.test_cluster?
    return false if settings[:environments].blank?

    true
  end

  def extension_default_value(type, property)
    case property
    when :enabled
      true
    when :url, :target_link_uri
      url
    when :selection_width
      800
    when :selection_height
      400
    when :message_type
      if type == :resource_selection
        "resource_selection"
      else
        "basic-lti-launch-request"
      end
    else
      nil
    end
  end

  def self.normalize_sizes!(settings)
    settings[:selection_width] = settings[:selection_width].to_i if settings[:selection_width]
    settings[:selection_height] = settings[:selection_height].to_i if settings[:selection_height]

    Lti::ResourcePlacement::PLACEMENTS.each do |type|
      if settings[type]
        settings[type][:selection_width] = settings[type][:selection_width].to_i if settings[type][:selection_width]
        settings[type][:selection_height] = settings[type][:selection_height].to_i if settings[type][:selection_height]
      end
    end
  end

  def infer_defaults
    self.url = nil if url.blank?
    self.domain = nil if domain.blank?
    self.root_account ||= context.root_account
    self.is_rce_favorite &&= can_be_rce_favorite?
    ContextExternalTool.normalize_sizes!(settings)

    Lti::ResourcePlacement::PLACEMENTS.each do |type|
      next unless settings[type]
      next if settings[type].key? :enabled

      settings.delete(type) unless extension_setting(type, :url)
    end

    unless root_account.feature_enabled?(:allow_lti_tools_editor_button_placement_without_icon)
      settings.delete(:editor_button) unless editor_button(:icon_url) || editor_button(:canvas_icon_class)
    end

    sync_placements!(Lti::ResourcePlacement::PLACEMENTS.select { |type| settings[type] }.map(&:to_s))
    true
  end

  # This aggressively updates the domain on all URLs in this tool
  def change_domain!(new_domain)
    replace_host = lambda do |url, host|
      uri = Addressable::URI.parse(url)
      uri.host = host if uri.host
      uri.to_s
    end

    self.domain = new_domain if domain

    self.url = replace_host.call(self.url, new_domain) if self.url

    settings.each_key do |setting|
      next if [:custom_fields, :environments].include? setting.to_sym

      case settings[setting]
      when Hash
        settings[setting].each do |property, value|
          if value.try(:match?, URI::DEFAULT_PARSER.make_regexp)
            settings[setting][property] = replace_host.call(value, new_domain)
          end
        end
      when URI::DEFAULT_PARSER.make_regexp
        settings[setting] = replace_host.call(settings[setting], new_domain)
      end
    end
  end

  def self.standardize_url(url)
    return nil if url.blank?

    url = url.gsub(/[[:space:]]/, "")
    url = "http://" + url unless url.include?("://")
    begin
      res = Addressable::URI.parse(url)&.normalize
      res.query = res.query.split("&").sort.join("&") if res&.query.present?
      res
    rescue Addressable::URI::InvalidURIError
      nil
    end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    save!
  end

  def precedence
    if domain
      # Somebody tell me if we should be expecting more than
      # 25 dots in a url host...
      25 - domain.split(".").length
    elsif url
      25
    else
      26
    end
  end

  def standard_url(use_environment_overrides = false)
    standard_url = ContextExternalTool.standardize_url(url)

    if use_environment_overrides
      ContextExternalTool.standardize_url(url_with_environment_overrides(standard_url.to_s, include_launch_url: true))
    else
      standard_url
    end
  end

  # Does the tool match the host of the given url?
  # Checks for batches on both domain and url
  #
  # This method checks both the domain and url
  # host when attempting to match host.
  def matches_host?(url, use_environment_overrides: false)
    standard_url = standard_url(use_environment_overrides)
    matches_tool_domain?(url) ||
      (standard_url.present? &&
        standard_url.host == ContextExternalTool.standardize_url(url)&.host)
  end

  def matches_url?(url, match_queries_exactly = true, use_environment_overrides: false)
    tool_url = standard_url(use_environment_overrides)
    if match_queries_exactly
      url = ContextExternalTool.standardize_url(url)
      url == tool_url
    elsif tool_url.present?
      @url_params ||= tool_url.query&.split("&") || []
      res = ContextExternalTool.standardize_url(url)
      return false if res.blank?

      if res.query.present?
        res.query = res.query.split("&").select { |p| @url_params.include?(p) }.sort.join("&")
      end

      res.normalize!
      res == tool_url
    end
  end

  # Returns true if the host of given url is the same or a subdomain of the tool domain.
  # Also requires the port numbers to match if present.
  # If the tool doesn't have a domain, returns false.
  def matches_tool_domain?(url, use_environment_overrides: false)
    domain = use_environment_overrides ? domain_with_environment_overrides : self.domain
    return false if domain.blank?

    url = ContextExternalTool.standardize_url(url)
    host = url&.host
    port = url&.port
    d = domain.downcase.gsub(%r{https?://}, "")
    !!(host && ("." + host + (port ? ":#{port}" : "")).match(/\.#{Regexp.escape(d)}\z/))
  end

  def duplicated_in_context?
    duplicate_tool = self.class.find_external_tool(url, context, nil, id)

    # If tool with same launch URL is found in the context
    return true if url.present? && duplicate_tool.present?

    # If tool with same domain is found in the context
    if domain.present?
      same_domain_diff_id = ContextExternalTool.where.not(id:).where(domain:)
      Lti::ContextToolFinder.all_tools_scope_union(context, base_scope: same_domain_diff_id).exists?
    else
      false
    end
  end

  def check_for_duplication(verify_uniqueness)
    if duplicated_in_context? && verify_uniqueness
      errors.add(:tool_currently_installed, "The tool is already installed in this context.")
    end
  end

  IDENTITY_FIELDS = %i[name
                       context_id
                       context_type
                       domain
                       url
                       consumer_key
                       shared_secret
                       description
                       workflow_state
                       settings].freeze

  def calculate_identity_hash
    props = [*slice(IDENTITY_FIELDS.excluding(:settings)).values, Utils::HashUtils.sort_nested_data(settings)]
    Digest::SHA2.new(256).hexdigest(props.to_json)
  end

  def add_identity_hash
    if identity_fields_changed?
      ident_hash = calculate_identity_hash
      self.identity_hash = ContextExternalTool.where(identity_hash: ident_hash).exists? ? "duplicate" : ident_hash
    end
  end

  def identity_fields_changed?
    IDENTITY_FIELDS.excluding(:settings).any? { |field| send(:"#{field}_changed?") } ||
      (Utils::HashUtils.sort_nested_data(settings_was) != Utils::HashUtils.sort_nested_data(settings))
  end

  def self.from_assignment(assignment)
    tag = assignment.external_tool_tag
    return unless tag

    from_content_tag(tag, assignment.context)
  end

  def self.from_content_tag(tag, context)
    return nil if tag.blank? || context.blank?

    # We can simply return the content if we
    # know it uses the preferred LTI version.
    # No need to go through the tool lookup logic.
    content = tag.content
    return content if content&.active? && content&.uses_preferred_lti_version?

    # Lookup the tool by the usual "find_external_tool"
    # method. Fall back on the tag's content if
    # no matches found.
    find_external_tool(
      tag.url,
      context,
      content&.id
    )
  end

  def self.contexts_to_search(context, include_federated_parent: false)
    case context
    when Course
      [:self, :account_chain]
    when Group
      if context.context
        [:self, :recursive]
      else
        [:self, :account_chain]
      end
    when Account
      [:account_chain]
    when Assignment
      [:recursive]
    else
      []
    end.flat_map do |component|
      case component
      when :self
        context
      when :recursive
        contexts_to_search(context.context, include_federated_parent:)
      when :account_chain
        inc_fp = include_federated_parent &&
                 Account.site_admin.feature_enabled?(:lti_tools_from_federated_parents) &&
                 !context.root_account.primary_settings_root_account?
        context.account_chain(include_federated_parent: inc_fp)
      end
    end
  end

  def self.find_active_external_tool_by_consumer_key(consumer_key, context)
    active.where(consumer_key:, context: contexts_to_search(context)).first
  end

  def self.find_active_external_tool_by_client_id(client_id, context)
    active.where(developer_key_id: client_id, context: contexts_to_search(context)).first
  end

  def self.find_external_tool_by_id(id, context)
    where(id:, context: contexts_to_search(context)).first
  end

  # Order of precedence: Basic LTI defines precedence as first
  # checking for a match on domain.  Subdomains count as a match
  # on less-specific domains, but the most-specific domain will
  # match first.  So awesome.bob.example.com matches an
  # external_tool with example.com as the domain, but only if
  # there isn't another external_tool where awesome.bob.example.com
  # or bob.example.com is set as the domain.
  #
  # If there is no domain match then check for an exact url match
  # as configured by an admin.  If there is still no match
  # then check for a match on the current context (configured by
  # the teacher).
  #
  # Tools with exclude_tool_id as their ID will never be returned.
  def self.find_external_tool(
    url,
    context,
    preferred_tool_id = nil, exclude_tool_id = nil, preferred_client_id = nil,
    only_1_3: false,
    prefer_1_1: false
  )
    GuardRail.activate(:secondary) do
      preferred_tool = ContextExternalTool.where(id: preferred_tool_id).first if preferred_tool_id # don't raise an exception if it's not found
      original_client_id = preferred_tool&.developer_key_id
      can_use_preferred_tool = preferred_tool&.active? && contexts_to_search(context).member?(preferred_tool.context)

      # always use the preferred_tool_id if url isn't provided
      return preferred_tool if url.blank? && can_use_preferred_tool
      return nil unless url

      sorted_external_tools = find_and_order_tools(
        context:,
        preferred_tool_id:,
        exclude_tool_id:,
        preferred_client_id:,
        original_client_id:,
        only_1_3:,
        prefer_1_1:
      )

      # Check for a tool that exactly matches the given URL
      match = find_matching_tool(url, sorted_external_tools)

      # always use the preferred tool id *unless* the preferred tool is a 1.1 tool
      # and the matched tool is a 1.3 tool, since 1.3 is the preferred version of a tool
      if can_use_preferred_tool && preferred_tool.matches_host?(url)
        if match&.use_1_3? && !preferred_tool.use_1_3?
          return match
        end

        return preferred_tool
      end

      match
    end
  end

  # Sorts all tools in the context chain by a variety of criteria in SQL
  # as opposed to in memory, in order to make it easier to find a tool that matches
  # the given URL.
  #
  # Criteria:
  # * closer contexts preferred (Course over Account over Root Account etc)
  # * more specific subdomains preferred (sub.domain.instructure.com over instructure.com)
  # * LTI 1.3 tools preferred over 1.1 tools
  # * if preferred_tool_id is provided, moves that tool to the front
  # * if preferred_client_id is provided, only retrieves tools that came from that developer key
  # * if exclude_tool_id is provided, does not retrieve that tool
  #
  # Theoretically once this method is done, the very first tool to match the URL will be
  # the right tool, making it possible to eventually perform the rest of the URL matching
  # in SQL as well.
  def self.find_and_order_tools(
    context:,
    preferred_tool_id: nil, exclude_tool_id: nil, preferred_client_id: nil,
    original_client_id: nil,
    only_1_3: false,
    prefer_1_1: false
  )
    context.shard.activate do
      preferred_tool_id = Shard.integral_id_for(preferred_tool_id)
      contexts = contexts_to_search(context)
      context_order = contexts.map.with_index { |c, i| "(#{c.id},'#{c.class.polymorphic_name}',#{i})" }.join(",")

      preferred_version = prefer_1_1 ? "1.1" : "1.3" # Hack required for one Turnitin case :( see git blame

      order_clauses = [
        # prefer 1.3 tools (unless told otherwise)
        sort_by_sql_string("lti_version = '#{preferred_version}'"),
        # prefer tools that are not duplicates
        sort_by_sql_string("identity_hash != 'duplicate'"),
        # prefer tools from closer contexts
        "context_order.ordering",
        # prefer tools with more subdomains
        precedence_sql_string
      ]
      # move preferred tool to the front when requested, and only if the id
      # is in an actual id format
      if preferred_tool_id
        order_clauses << sort_by_sql_string("#{quoted_table_name}.id = #{preferred_tool_id}")
      end

      # prefer tools from the original developer key when requested,
      # and over other order clauses like context
      prefer_original_client_id = context.root_account.feature_enabled?(:lti_find_external_tool_prefer_original_client_id)
      if prefer_original_client_id && (original_client_id = Shard.integral_id_for(original_client_id))
        order_clauses.prepend(sort_by_sql_string("developer_key_id = #{original_client_id}"))
      end

      query = ContextExternalTool.where(context: contexts).active
      query = query.where(lti_version: "1.3") if only_1_3
      query = query.where(developer_key_id: preferred_client_id) if preferred_client_id
      query = query.where.not(id: exclude_tool_id) if exclude_tool_id

      query.joins(sanitize_sql("INNER JOIN (values #{context_order}) as context_order (context_id, class, ordering)
        ON #{quoted_table_name}.context_id = context_order.context_id AND #{quoted_table_name}.context_type = context_order.class"))
           .order(Arel.sql(sanitize_sql_for_order(order_clauses.join(","))))
    end
  end

  # replicates the ContextExternalTool.precedence method, in SQL for an order clause.
  # prefer tools that have more specific subdomains
  def self.precedence_sql_string
    <<~SQL.squish
      CASE WHEN domain IS NOT NULL
        THEN 25 - ARRAY_LENGTH(STRING_TO_ARRAY(domain, '.'), 1)
        ELSE CASE WHEN url IS NOT NULL
          THEN 25
          ELSE 26
        END
      END
    SQL
  end

  # Used in an SQL order clause to push tools that match the condition to the front of the relation.
  def self.sort_by_sql_string(condition)
    "CASE WHEN #{condition} THEN 1 ELSE 2 END"
  end

  # Given a collection of tools, finds the first tool that matches the given conditions.
  #
  # First only loads non-duplicate tools into memory for matching, then will load
  # all tools if necessary.
  def self.find_tool_match(tool_collection, matcher, matcher_condition)
    possible_match = tool_collection.not_duplicate.find do |tool|
      matcher_condition.call(tool) && matcher.call(tool)
    end

    # an LTI 1.1 non-duplicate match means we still need to search
    # all tools since a 1.3 match with 'duplicate' identity_hash
    # still takes precedence
    return possible_match if possible_match&.use_1_3?

    tool_collection.find do |tool|
      matcher_condition.call(tool) && matcher.call(tool)
    end
  end

  def self.find_matching_tool(url, sorted_external_tools)
    # Check for a tool that exactly matches the given URL
    match = find_tool_match(
      sorted_external_tools,
      ->(t) { t.matches_url?(url) },
      ->(t) { t.url.present? }
    )

    # If exactly match doesn't work, try to match by ignoring extra query parameters
    match ||= find_tool_match(
      sorted_external_tools,
      ->(t) { t.matches_url?(url, false) },
      ->(t) { t.url.present? }
    )

    # If still no matches, use domain matching to try to find a tool
    match ||= find_tool_match(
      sorted_external_tools,
      ->(t) { t.matches_tool_domain?(url) },
      ->(t) { t.domain.present? }
    )

    # repeat matches with environment-specific url and domain overrides
    if ApplicationController.test_cluster?
      match ||= find_tool_match(
        sorted_external_tools,
        ->(t) { t.matches_url?(url, use_environment_overrides: true) },
        ->(t) { t.url.present? }
      )

      match ||= find_tool_match(
        sorted_external_tools,
        ->(t) { t.matches_url?(url, false, use_environment_overrides: true) },
        ->(t) { t.url.present? }
      )

      match ||= find_tool_match(
        sorted_external_tools,
        ->(t) { t.matches_tool_domain?(url, use_environment_overrides: true) },
        ->(t) { t.domain.present? }
      )
    end
    match
  end

  scope :having_setting, lambda { |setting|
                           if setting
                             joins(:context_external_tool_placements)
                               .where(context_external_tool_placements: { placement_type: setting })
                           else
                             all
                           end
                         }

  scope :placements, lambda { |*placements|
    if placements.present?
      scope = ContextExternalTool.where(
        ContextExternalToolPlacement
          .where(placement_type: placements)
          .where("context_external_tools.id = context_external_tool_placements.context_external_tool_id").arel.exists
      )
      # Default placements are only applicable to LTI 1.1
      if placements.map(&:to_s).intersect?(Lti::ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS)
        scope = ContextExternalTool
                .where(lti_version: "1.1", not_selectable: [nil, false])
                .merge(
                  ContextExternalTool.where("COALESCE(context_external_tools.url, '') <> ''")
                                     .or(ContextExternalTool.where("COALESCE(context_external_tools.domain, '') <> ''"))
                ).or(scope)
      end

      merge(scope)
    else
      all
    end
  }

  scope :selectable, -> { where("context_external_tools.not_selectable IS NOT TRUE") }

  scope :visible, lambda { |user, context, session, placements, current_scope = ContextExternalTool.default_scoped.all|
    if context.grants_right?(user, session, :read_as_admin)
      all
    elsif !placements
      none
    else
      allowed_visibility = ["public"]
      allowed_visibility.push("members") if context.grants_any_right?(user, session, :participate_as_student, :read_as_admin)
      allowed_visibility.push("admins") if context.grants_right?(user, session, :read_as_admin)
      # To get at the visibility setting for each tool we need to use active record.  We will limit this to just the candidate tools using the current scope.
      valid_tools = current_scope.select do |cet|
        include_tool = false
        placements.each do |placement|
          tool_settings = cet.settings.with_indifferent_access
          # The tool must have no visibility settings, or else a visibility threshold met by the current user.
          if tool_settings[placement] && (!tool_settings[placement][:visibility] || allowed_visibility.include?(tool_settings[placement][:visibility]))
            include_tool = true
          end
          break if include_tool
        end
        include_tool
      end.pluck(:id)
      where(id: valid_tools)
    end
  }

  def self.find_for(id, context, type, raise_error = true)
    id = id[Api::ID_REGEX] if id.is_a?(String)
    unless id.present?
      if raise_error
        raise ActiveRecord::RecordNotFound
      else
        return nil
      end
    end

    context = context.context if context.is_a?(Group)

    tool = context.context_external_tools.having_setting(type).active.where(id:).first
    tool ||= ContextExternalTool.having_setting(type).active.where(context_type: "Account", context_id: context.account_chain_ids, id:).first
    raise ActiveRecord::RecordNotFound if !tool && raise_error

    tool
  end

  scope :active, lambda {
    where.not(workflow_state: ["deleted", "disabled"])
  }

  scope :not_duplicate, lambda {
    where.not(identity_hash: "duplicate")
  }

  def self.find_all_for(context, type)
    tools = []
    if !context.is_a?(Account) && context.respond_to?(:context_external_tools)
      tools += context.context_external_tools.having_setting(type.to_s)
    end
    tools + ContextExternalTool.having_setting(type.to_s).where(context_type: "Account", context_id: context.account_chain_ids)
  end

  def self.serialization_excludes
    [:shared_secret, :settings]
  end

  # sets the custom fields from the main tool settings, and any on individual resource type settings
  def set_custom_fields(resource_type)
    hash = {}
    fields = [settings[:custom_fields] || {}]
    fields << (settings[resource_type.to_sym][:custom_fields] || {}) if resource_type && settings[resource_type.to_sym]
    fields.each do |field_set|
      field_set.each do |key, val|
        key = key.to_s.gsub(/[^\w]/, "_").downcase
        if key.match?(/^custom_/)
          hash[key] = val
        else
          hash["custom_#{key}"] = val
        end
      end
    end
    hash
  end

  def opaque_identifier_for(asset, context: nil)
    ContextExternalTool.opaque_identifier_for(asset, shard, context:)
  end

  def self.opaque_identifier_for(asset, shard, context: nil)
    return if asset.blank?

    shard.activate do
      lti_context_id = context_id_for(asset, shard)
      Lti::Asset.set_asset_context_id(asset, lti_context_id, context:)
    end
  end

  def visible_with_permission_check?(launch_type, user, context, session = nil)
    return false unless self.class.visible?(extension_setting(launch_type, "visibility"), user, context, session)

    permission_given?(launch_type, user, context, session)
  end

  def permission_given?(launch_type, user, context, session = nil)
    if (required_permissions_str = extension_setting(launch_type, "required_permissions"))
      # if configured with a comma-separated string of permissions, will only show the link
      # if all permissions are granted
      required_permissions_str.split(",").map(&:to_sym).all? do |p|
        permission_given = context&.grants_right?(user, session, p)

        # Global navigation tools are always installed in the root account.
        # This means if the current user is using a course-based role, the
        # standard `grants_right?` call to the context (always the root account)
        # will always fail.
        #
        # If this is the scenario, check to see if the user has any active enrollments
        # in the account with the required permission. If they do, grant access.
        if !permission_given &&
           context.present? &&
           launch_type.to_s == Lti::ResourcePlacement::GLOBAL_NAVIGATION.to_s
          permission_given = manageable_enrollments_by_permission(
            p,
            user.enrollments_for_account_and_sub_accounts(context.root_account)
          ).present?
        end

        permission_given
      end
    else
      true
    end
  end

  def quiz_lti?
    tool_id == QUIZ_LTI
  end

  def feature_flag_enabled?(context = nil)
    feature = TOOL_FEATURE_MAPPING[tool_id]
    !feature || (context || self.context).feature_enabled?(feature)
  end

  # Add new types to this as we finish their migration methods
  # and they'll be automagically migrated.
  VALID_MIGRATION_TYPES = [Assignment, ContentTag, ExternalToolCollaboration].freeze

  # for helping tool providers upgrade from 1.1 to 1.3.
  # this method will upgrade all related content to 1.3,
  # only if this is a 1.3 tool and has a matching 1.1 tool.
  # since finding all content related to this tool is an
  # expensive operation (unavoidable N+1 for indirectly
  # related assignments, which are more rare), this is done
  # in a delayed job.
  # @see Lti::Migratable
  def migrate_content_to_1_3_if_needed!
    return unless use_1_3?

    # is there a 1.1 tool that matches this one?
    matching_1_1_tool = self.class.find_external_tool(url || domain, context, nil, id, prefer_1_1: true)
    return if matching_1_1_tool.nil? || matching_1_1_tool.use_1_3?

    delay_if_production(priority: Delayed::LOW_PRIORITY).migrate_content_to_1_3(matching_1_1_tool.id)
  end

  # Migrates all content associated with an LTI 1.1 tool to LTI 1.3.
  # Loads content in batches and kicks off smaller jobs that perform
  # the actual work of migrating the content.
  # @param [Integer] tool_id The id of the LTI 1.1 tool whose content we're migrating
  # @see Lti::Migratable
  def migrate_content_to_1_3(tool_id)
    tool_id ||= id
    GuardRail.activate(:secondary) do
      VALID_MIGRATION_TYPES.each do |type|
        next unless type.include?(Lti::Migratable)

        type.scope_to_context(
          type.directly_associated_items(tool_id), context
        ).find_ids_in_batches do |ids|
          delay_if_production(
            priority: Delayed::LOW_PRIORITY,
            n_strand: ["ContextExternalTool#migrate_content_to_1_3", tool_id]
          ).prepare_direct_batch_for_migration(ids, type)
        end
        type.scope_to_context(
          type.indirectly_associated_items(tool_id), context
        ).find_ids_in_batches do |ids|
          delay_if_production(
            priority: Delayed::LOW_PRIORITY,
            n_strand: ["ContextExternalTool#migrate_content_to_1_3", tool_id]
          ).prepare_indirect_batch_for_migration(tool_id, ids, type)
        end
      end
    end
  end

  # For the given content_type, migrates the direct batch
  # from 1.1 to 1.3 according to the types migration method.
  # @see Lti::Migratable
  def prepare_direct_batch_for_migration(ids, content_type)
    content_type.fetch_direct_batch(ids) do |item|
      prepare_content_for_migration(item)
    end
  end

  # For the given content_type, migrates the direct batch
  # from 1.1 to 1.3 according to the types migration method.
  # @see Lti::Migratable
  def prepare_indirect_batch_for_migration(tool_id, ids, content_type)
    content_type.fetch_indirect_batch(tool_id, id, ids) do |item|
      prepare_content_for_migration(item)
    end
  end

  def prepare_content_for_migration(content)
    GuardRail.activate(:primary) do
      content.migrate_to_1_3_if_needed!(self)
    end
  rescue ActiveRecord::RecordInvalid, PG::UniqueViolation => e
    Sentry.with_scope do |scope|
      scope.set_tags(content_id: content.global_id)
      scope.set_tags(content_type: content.class.name)
      scope.set_tags(tool_id: global_id)
      scope.set_tags(exception_class: e.class.name)
      scope.set_context(
        "exception",
        {
          name: e.class.name,
          message: e.message
        }
      )
      Sentry.capture_message("ContextExternalTool#prepare_content_for_migration", level: :warning)
    end
  end

  # Intended to return true only for Instructure-owned tools that have been
  # properly configured as "internal" tools. Used for some custom variable substitutions.
  # Will only return true if the launch_url's domain ends with a domain from the allowlist,
  # or exactly matches a domain from the allowlist.
  def internal_service?(launch_url)
    return false unless developer_key&.internal_service?
    return false unless launch_url

    domain = URI.parse(launch_url).host rescue nil
    return false unless domain

    internal_tool_domain_allowlist.any? { |d| domain.end_with?(".#{d}") || domain == d }
  end

  # Used in ContextToolFinder
  def sort_key
    [Canvas::ICU.collation_key(name), global_id]
  end

  def self.associated_1_1_tool(tool, context, launch_url)
    return nil unless launch_url && tool.use_1_3?

    # Finding tools is expensive and this relationship doesn't change very often, so
    # it's worth it to maintain this possibly "incorrect" relationship for 5 minutes.
    id = Rails.cache.fetch([tool.global_asset_string, context.global_asset_string, launch_url.slice(0..1024)].cache_key, expires_in: 5.minutes) do
      # Rails themselves recommends against caching ActiveRecord models directly
      # https://guides.rubyonrails.org/caching_with_rails.html#avoid-caching-instances-of-active-record-objects
      GuardRail.activate(:secondary) do
        sorted_external_tools = context.shard.activate do
          contexts = contexts_to_search(context)
          context_order = contexts.map.with_index { |c, i| "(#{c.id},'#{c.class.polymorphic_name}',#{i})" }.join(",")

          order_clauses = [
            # prefer tools that are not duplicates
            sort_by_sql_string("identity_hash != 'duplicate'"),
            # prefer tools from closer contexts
            "context_order.ordering",
            # prefer tools with more subdomains
            precedence_sql_string
          ]
          query = ContextExternalTool.where(context: contexts, lti_version: "1.1")
          query.joins(sanitize_sql("INNER JOIN (values #{context_order}) as context_order (context_id, class, ordering)
          ON #{quoted_table_name}.context_id = context_order.context_id AND #{quoted_table_name}.context_type = context_order.class"))
               .order(Arel.sql(sanitize_sql_for_order(order_clauses.join(","))))
        end

        find_matching_tool(launch_url, sorted_external_tools)&.id
      end
    end

    ContextExternalTool.find_by(id:)
  end

  def associated_1_1_tool(context, launch_url = nil)
    ContextExternalTool.associated_1_1_tool(self, context, launch_url || url || domain)
  end

  # Icon for tools which don't provide one, based on the DeveloperKey or tool
  # id, and the tool name
  def default_icon_path
    Rails.application.routes.url_helpers.lti_tool_default_icon_path(
      id: global_developer_key_id || global_id,
      name:
    )
  end

  def placement_allowed?(placement)
    return true if placement != :submission_type_selection

    allowed_domains = Setting.get("submission_type_selection_allowed_launch_domains", "").split(",").map(&:strip).reject(&:empty?)
    allowed_dev_keys = Setting.get("submission_type_selection_allowed_dev_keys", "").split(",").map(&:strip).reject(&:empty?)
    allowed_domains.include?(domain) || allowed_dev_keys.include?(Shard.global_id_for(developer_key&.id).to_s)
  end

  private

  # Locally and in OSS installations, this can be configured in config/dynamic_settings.yml.
  # Returns an array of strings, each listing a partial or full domain suffix that is considered "internal".
  # Domains should not have a preceding ".".
  # For example, ["instructure.com", "inscloudgate.net", "inseng.net"] in Instructure-deployed production Canvas.
  def internal_tool_domain_allowlist
    config = DynamicSettings.find("lti", default_ttl: 2.hours)["internal_tool_domain_allowlist"] || "[]"
    @internal_tool_domain_allowlist ||= YAML.safe_load(config)
  end

  def check_global_navigation_cache
    if context.is_a?(Account) && context.root_account?
      context.clear_cache_key(:global_navigation) # it's hard to know exactly _what_ changed so clear all initial global nav caches at once
    end
  end

  def clear_tool_domain_cache
    if saved_change_to_domain? || saved_change_to_url? || saved_change_to_workflow_state?
      context.clear_tool_domain_cache
    end
  end
end
