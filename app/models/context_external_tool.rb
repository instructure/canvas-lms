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
require 'redcarpet'

class ContextExternalTool < ActiveRecord::Base
  include Workflow
  include SearchTermHelper

  has_many :content_tags, :as => :content
  has_many :context_external_tool_placements, :autosave => true

  belongs_to :context, polymorphic: [:course, :account]
  belongs_to :developer_key
  belongs_to :root_account, class_name: 'Account'

  include MasterCourses::Restrictor
  restrict_columns :content, [:name, :description]
  restrict_columns :settings, [:consumer_key, :shared_secret, :url, :domain, :settings]

  validates_presence_of :context_id, :context_type, :workflow_state
  validates_presence_of :name, :consumer_key, :shared_secret
  validates_length_of :name, :maximum => maximum_string_length
  validates_presence_of :config_url, :if => lambda { |t| t.config_type == "by_url" }
  validates_presence_of :config_xml, :if => lambda { |t| t.config_type == "by_xml" }
  validates_length_of :domain, :maximum => 253, :allow_blank => true
  validate :url_or_domain_is_set
  validate :validate_urls
  serialize :settings
  attr_accessor :config_type, :config_url, :config_xml

  before_save :infer_defaults, :validate_vendor_help_link
  after_save :touch_context, :check_global_navigation_cache, :clear_tool_domain_cache
  validate :check_for_xml_error

  scope :disabled, -> { where(workflow_state: DISABLED_STATE) }
  scope :quiz_lti, -> { where(tool_id: QUIZ_LTI) }

  CUSTOM_EXTENSION_KEYS = {
    :file_menu => [:accept_media_types].freeze,
    :editor_button => [:use_tray].freeze
  }.freeze

  DISABLED_STATE = 'disabled'.freeze
  QUIZ_LTI = 'Quizzes 2'.freeze
  ANALYTICS_2 = 'fd75124a-140e-470f-944c-114d2d93bb40'.freeze
  TOOL_FEATURE_MAPPING = { ANALYTICS_2 => :analytics_2 }.freeze

  workflow do
    state :anonymous
    state :name_only
    state :email_only
    state :public
    state :deleted
    state DISABLED_STATE.to_sym # The tool's developer key is "off" but not deleted
  end

  set_policy do
    given { |user, session| self.context.grants_right?(user, session, :lti_add_edit) }
    can :read and can :update and can :delete and can :update_manually
  end

  Lti::ResourcePlacement::PLACEMENTS.each do |type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{type}(setting=nil)
        extension_setting(:#{type}, setting)
      end

      def #{type}=(hash)
        set_extension_setting(:#{type}, hash)
      end
    RUBY
  end

  def self.tool_for_assignment(assignment)
    tag = assignment.external_tool_tag
    return unless tag
    launch_url = assignment.external_tool_tag.url
    self.find_external_tool(launch_url, assignment.context)
  end

  def deployment_id
    "#{self.id}:#{Lti::Asset.opaque_identifier_for(self.context)}"[0..254]
  end

  def content_migration_configured?
    settings.key?('content_migration') &&
      settings['content_migration'].is_a?(Hash) &&
      settings['content_migration'].key?('export_start_url') &&
      settings['content_migration'].key?('import_start_url')
  end

  def extension_setting(type, property = nil)
    val = calclulate_extension_setting(type, property)
    if val && property == :icon_url
      val = nil if (URI.parse(val) rescue nil).nil? # make sure it's a valid url
    end
    val
  end

  def calclulate_extension_setting(type, property = nil)
    return settings[property] unless type
    type = type.to_sym
    return settings[type] unless property && settings[type]
    settings[type][property] || settings[property] || extension_default_value(type, property)
  end

  def set_extension_setting(type, hash)
    if !hash || !hash.is_a?(Hash)
      settings.delete type
      return
    end

    hash = hash.with_indifferent_access
    hash[:enabled] = Canvas::Plugin.value_to_boolean(hash[:enabled]) if hash[:enabled]
    settings[type] = {}.with_indifferent_access

    extension_keys = [
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
      :selection_height,
      :selection_width,
      :text,
      :windowTarget,
      :url,
      :target_link_uri
    ]

    if custom_keys = CUSTOM_EXTENSION_KEYS[type]
      extension_keys += custom_keys
    end
    extension_keys += {
        :visibility => lambda{|v| %w{members admins}.include?(v)}
    }.to_a

    extension_keys.each do |key, validator|
      if hash.has_key?(key) && (!validator || validator.call(hash[key]))
        settings[type][key] = hash[key]
      end
    end

    settings[type]
  end

  def has_placement?(type)
    # Only LTI 1.0 tools (no developer key) support default placements
    # (LTI 2 tools also, but those are not handled by this class)
    if developer_key_id.blank? &&
        Lti::ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS.include?(type.to_s)
      !!(self.selectable && (self.domain || self.url))
    else
      self.context_external_tool_placements.to_a.any?{|p| p.placement_type == type.to_s}
    end
  end

  def sync_placements!(placements)
    old_placements = self.context_external_tool_placements.pluck(:placement_type)
    placements_to_delete = Lti::ResourcePlacement::PLACEMENTS.map(&:to_s) - placements
    if placements_to_delete.any?
      self.context_external_tool_placements.where(placement_type: placements_to_delete).delete_all if self.persisted?
      self.context_external_tool_placements.reload if self.context_external_tool_placements.loaded?
    end
    (placements - old_placements).each do |new_placement|
      self.context_external_tool_placements.new(:placement_type => new_placement)
    end
  end
  private :sync_placements!

  def url_or_domain_is_set
    placements = Lti::ResourcePlacement::PLACEMENTS
    # url or domain (or url on canvas lti extension) is required
    if url.blank? && domain.blank? && placements.all?{|k| !settings[k] || (settings[k]['url'].blank? && settings[k]['target_link_uri'].blank?) }
      errors.add(:url, t('url_or_domain_required', "Either the url or domain should be set."))
      errors.add(:domain, t('url_or_domain_required', "Either the url or domain should be set."))
    end
  end

  def validate_urls
    (
      [url] + Lti::ResourcePlacement::PLACEMENTS.map do |p|
        settings[p]&.with_indifferent_access&.fetch('url', nil) ||
        settings[p]&.with_indifferent_access&.fetch('target_link_uri', nil)

      end
    ).
      compact.
      map { |u| validate_url(u) }
  end
  private :validate_urls

  def validate_url(u)
    u = URI.parse(u)
  rescue
    errors.add(:url,
      t('url_or_domain_no_valid', "Incorrect url for %{url}", url: u)
    )
  end
  private :validate_url

  def settings
    read_or_initialize_attribute(:settings, {})
  end

  def label_for(key, lang=nil)
    lang = lang.to_s if lang
    labels = settings[key] && settings[key][:labels]
    (labels && labels[lang]) ||
      (labels && lang && labels[lang.split('-').first]) ||
      (settings[key] && settings[key][:text]) ||
      default_label(lang)
  end

  def default_label(lang = nil)
    lang = lang.to_s if lang
    default_labels = settings[:labels]
    (default_labels && default_labels[lang]) ||
        (default_labels && lang && default_labels[lang.split('-').first]) ||
        settings[:text] || name || "External Tool"
  end

  def check_for_xml_error
    (@config_errors || []).each { |attr,msg|
      errors.add attr, msg
    }
  end
  protected :check_for_xml_error

  def readable_state
    workflow_state.titleize
  end

  def privacy_level=(val)
    if ['anonymous', 'name_only', 'email_only', 'public'].include?(val)
      self.workflow_state = val
    end
  end

  def privacy_level
    self.workflow_state
  end

  def custom_fields_string
    (settings[:custom_fields] || {}).map{|key, val|
      "#{key}=#{val}"
    }.sort.join("\n")
  end

  def vendor_help_link
    settings[:vendor_help_link]
  end

  def vendor_help_link=(val)
    settings[:vendor_help_link] = val
  end

  def validate_vendor_help_link
    return if self.vendor_help_link.blank?
    begin
      value, uri = CanvasHttp.validate_url(self.vendor_help_link)
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
    return unless (config_type == 'by_url' && config_url) || (config_type == 'by_xml' && config_xml)
    tool_hash = nil
    @config_errors = []
    begin
       converter = CC::Importer::BLTIConverter.new
       if config_type == 'by_url'
         tool_hash = converter.retrieve_and_convert_blti_url(config_url)
       else
         tool_hash = converter.convert_blti_xml(config_xml)
       end
    rescue CC::Importer::BLTIConverter::CCImportError => e
       tool_hash = {:error => e.message}
    end

    error_field = config_type == 'by_xml' ? 'config_xml' : 'config_url'
    converter = CC::Importer::BLTIConverter.new
    tool_hash = if config_type == 'by_url'
                  uri = Addressable::URI.parse(config_url)
                  raise URI::Error unless uri.host
                  converter.retrieve_and_convert_blti_url(config_url)
                else
                  converter.convert_blti_xml(config_xml)
                end

    real_name = self.name
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
    settings.fetch(:use_1_3, settings['use_1_3'])
  end

  def use_1_3=(bool)
    settings[:use_1_3] = bool
  end

  def self.find_custom_fields_from_string(str)
    return {} if str.nil?
    str.split(/[\r\n]+/).each_with_object({}) do |line, hash|
      key, val = line.split(/=/)
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
    settings[:icon_url]
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
    extension_setting(extension_type, :display_type) || 'in_context'
  end

  def login_or_launch_url(extension_type: nil, content_tag_uri: nil)
    (use_1_3? && developer_key&.oidc_initiation_url) ||
    content_tag_uri ||
    (use_1_3? && extension_setting(extension_type, :target_link_uri)) ||
    extension_setting(extension_type, :url) ||
    url
  end

  def extension_default_value(type, property)
    case property
      when :url
        url
      when :target_link_uri
        url
      when :selection_width
        800
      when :selection_height
        400
      when :message_type
        if type == :resource_selection
          'resource_selection'
        else
          'basic-lti-launch-request'
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

    ContextExternalTool.normalize_sizes!(self.settings)

    Lti::ResourcePlacement::PLACEMENTS.each do |type|
      if settings[type]
        if !(extension_setting(type, :url)) || (settings[type].has_key?(:enabled) && !settings[type][:enabled])
          settings.delete(type)
        end
      end
    end

    settings.delete(:editor_button) unless editor_button(:icon_url) || editor_button(:canvas_icon_class)

    sync_placements!(Lti::ResourcePlacement::PLACEMENTS.select{|type| !!settings[type]}.map(&:to_s))
    true
  end

  #This aggressively updates the domain on all URLs in this tool
  def change_domain!(new_domain)
    replace_host = lambda do |url, host|
      uri = Addressable::URI.parse(url)
      uri.host = host if uri.host
      uri.to_s
    end

    self.domain = new_domain if self.domain

    self.url = replace_host.call(self.url, new_domain) if self.url

    settings.keys.each do |setting|
      next if [:custom_fields, :environments].include? setting.to_sym
      if settings[setting].is_a?(Hash)
        settings[setting].keys.each do |property|
          if settings[setting][property] =~ URI::regexp
            settings[setting][property] = replace_host.call(settings[setting][property], new_domain)
          end
        end
      elsif settings[setting] =~ URI::regexp
        settings[setting] = replace_host.call(settings[setting], new_domain)
      end
    end
  end

  def self.standardize_url(url)
    return "" if url.blank?
    url = url.gsub(/[[:space:]]/, '')
    url = "http://" + url unless url.match(/:\/\//)
    res = Addressable::URI.parse(url).normalize
    res.query = res.query.split(/&/).sort.join('&') if !res.query.blank?
    res.to_s
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    save!
  end

  def include_email?
    email_only? || public?
  end

  def include_name?
    name_only? || public?
  end

  def precedence
    if domain
      # Somebody tell me if we should be expecting more than
      # 25 dots in a url host...
      25 - domain.split(/\./).length
    elsif url
      25
    else
      26
    end
  end

  def standard_url
    if !defined?(@standard_url)
      @standard_url = !self.url.blank? && ContextExternalTool.standardize_url(self.url)
    end
    @standard_url
  end

  def matches_url?(url, match_queries_exactly=true)
    if match_queries_exactly
      url = ContextExternalTool.standardize_url(url)
      return true if url == standard_url
    elsif standard_url.present?
      if !defined?(@url_params)
        res = Addressable::URI.parse(standard_url)
        @url_params = res.query.present? ? res.query.split(/&/) : []
      end
      res = Addressable::URI.parse(url).normalize
      res.query = res.query.split(/&/).select{|p| @url_params.include?(p)}.sort.join('&') if res.query.present?
      res.query = nil if res.query.blank?
      res.normalize!
      return true if res.to_s == standard_url
    end
  end

  def matches_tool_domain?(url)
    return false if domain.blank?
    url = ContextExternalTool.standardize_url(url)
    host = Addressable::URI.parse(url).normalize.host rescue nil
    d = domain.gsub(/http[s]?\:\/\//, '')
    !!(host && ('.' + host).match(/\.#{d}\z/))
end

  def matches_domain?(url)
    url = ContextExternalTool.standardize_url(url)
    host = Addressable::URI.parse(url).host
    if domain
      domain.downcase == host.downcase
    elsif standard_url
      Addressable::URI.parse(standard_url).host == host
    else
      false
    end
  end

  def duplicated_in_context?
    duplicate_tool = self.class.find_external_tool(url, context, nil, self.id)

    # If tool with same launch URL is found in the context
    return true if url.present? && duplicate_tool.present?

    # If tool with same domain is found in the context
    self.class.all_tools_for(context).where.not(id: id).where(domain: domain).present? && domain.present?
  end

  def self.contexts_to_search(context)
    case context
    when Course
      [context] + context.account_chain
    when Group
      [context] + (context.context ? contexts_to_search(context.context) : context.account_chain)
    when Account
      context.account_chain
    when Assignment
      contexts_to_search(context.context)
    else
      []
    end
  end

  def self.all_tools_for(context, options={})
    placements =* options[:placements] || options[:type]
    contexts = []
    if options[:user]
      contexts << options[:user]
    end
    contexts.concat contexts_to_search(context)
    return nil if contexts.empty?

    context.shard.activate do
      scope = ContextExternalTool.shard(context.shard).polymorphic_where(context: contexts).active
      scope = scope.placements(*placements)
      scope = scope.selectable if Canvas::Plugin.value_to_boolean(options[:selectable])
      scope = scope.where(tool_id: options[:tool_ids]) if options[:tool_ids].present?
      if Canvas::Plugin.value_to_boolean(options[:only_visible])
        scope = scope.visible(options[:current_user], context, options[:session], options[:visibility_placements], scope)
      end
      scope.order(ContextExternalTool.best_unicode_collation_key('context_external_tools.name')).order(Arel.sql('context_external_tools.id'))
    end
  end

  def self.find_active_external_tool_by_consumer_key(consumer_key, context)
    self.active.where(:consumer_key => consumer_key).polymorphic_where(:context => contexts_to_search(context)).first
  end

  def self.find_external_tool_by_id(id, context)
    self.where(:id => id).polymorphic_where(:context => contexts_to_search(context)).first
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
  def self.find_external_tool(url, context, preferred_tool_id=nil, exclude_tool_id=nil)
    contexts = contexts_to_search(context)
    preferred_tool = ContextExternalTool.active.where(id: preferred_tool_id).first if preferred_tool_id
    if preferred_tool && contexts.member?(preferred_tool.context) && (url == nil || preferred_tool.matches_domain?(url))
      return preferred_tool
    end

    return nil unless url

    all_external_tools = ContextExternalTool.shard(context.shard).polymorphic_where(context: contexts).active.to_a
    sorted_external_tools = all_external_tools.sort_by { |t| [contexts.index { |c| c.id == t.context_id && c.class.name == t.context_type }, t.precedence, t.id == preferred_tool_id ? CanvasSort::First : CanvasSort::Last] }

    res = sorted_external_tools.detect{ |tool| tool.url && tool.matches_url?(url) && tool.id != exclude_tool_id }
    return res if res

    # If exactly match doesn't work, try to match by ignoring extra query parameters
    res = sorted_external_tools.detect{ |tool| tool.url && tool.matches_url?(url, false) && tool.id != exclude_tool_id }
    return res if res

    res = sorted_external_tools.detect{ |tool| tool.domain && tool.matches_tool_domain?(url) && tool.id != exclude_tool_id }
    return res if res

    nil
  end

  scope :having_setting, lambda { |setting| setting ? joins(:context_external_tool_placements).
      where("context_external_tool_placements.placement_type = ?", setting) : all }

  scope :placements, lambda { |*placements|
    if placements.present?
      # Default placements are only applicable to LTI 1.0. Ignore
      # LTI 1.3 tools with developer_key_id IS NULL
      default_placement_sql = if (placements.map(&:to_s) & Lti::ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS).present?
                          "(context_external_tools.developer_key_id IS NULL AND
                           context_external_tools.not_selectable IS NOT TRUE AND
                           ((COALESCE(context_external_tools.url, '') <> '' ) OR
                           (COALESCE(context_external_tools.domain, '') <> ''))) OR "
                        else
                          ''
                        end
      return none unless placements
      where(default_placement_sql + 'EXISTS (?)',
            ContextExternalToolPlacement.where(placement_type: placements).
        where("context_external_tools.id = context_external_tool_placements.context_external_tool_id"))
    else
      all
    end
  }

  scope :selectable, lambda { where("context_external_tools.not_selectable IS NOT TRUE") }

  scope :visible, lambda { |user, context, session, placements, current_scope=ContextExternalTool.all|
    if context.grants_right?(user, session, :read_as_admin)
      all
    elsif !placements
      none
    else
      allowed_visibility = ['public']
      allowed_visibility.push('members') if context.grants_any_right?(user, session, :participate_as_student, :read_as_admin)
      allowed_visibility.push('admins') if context.grants_right?(user, session, :read_as_admin)
      # To get at the visibility setting for each tool we need to use active record.  We will limit this to just the candidate tools using the current scope.
      valid_tools = current_scope.select{|cet|
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
      }.pluck(:id)
      where(id: valid_tools)
    end
  }

  def self.find_for(id, context, type, raise_error=true)
    id = id[Api::ID_REGEX] if id.is_a?(String)
    unless id.present?
      if raise_error
        raise ActiveRecord::RecordNotFound
      else
        return nil
      end
    end

    context = context.context if context.is_a?(Group)

    tool = context.context_external_tools.having_setting(type).active.where(id: id).first
    tool ||= ContextExternalTool.having_setting(type).active.where(context_type: 'Account', context_id: context.account_chain_ids, id: id).first
    raise ActiveRecord::RecordNotFound if !tool && raise_error

    tool
  end
  scope :active, -> do
    where.not(workflow_state: ['deleted', 'disabled'])
  end

  def self.find_all_for(context, type)
    tools = []
    if !context.is_a?(Account) && context.respond_to?(:context_external_tools)
      tools += context.context_external_tools.having_setting(type.to_s)
    end
    tools += ContextExternalTool.having_setting(type.to_s).where(context_type: 'Account', context_id: context.account_chain_ids)
  end

  def self.serialization_excludes; [:shared_secret,:settings]; end

  # sets the custom fields from the main tool settings, and any on individual resource type settings
  def set_custom_fields(resource_type)
    hash = {}
    fields = [settings[:custom_fields] || {}]
    fields << (settings[resource_type.to_sym][:custom_fields] || {}) if resource_type && settings[resource_type.to_sym]
    fields.each do |field_set|
      field_set.each do |key, val|
        key = key.to_s.gsub(/[^\w]/, '_').downcase
        if key.match(/^custom_/)
          hash[key] = val
        else
          hash["custom_#{key}"] = val
        end
      end
    end
    hash
  end

  def resource_selection_settings
    settings[:resource_selection]
  end

  def opaque_identifier_for(asset, context: nil)
    ContextExternalTool.opaque_identifier_for(asset, self.shard, context: context)
  end

  def self.opaque_identifier_for(asset, shard, context: nil)
    shard.activate do
      lti_context_id = context_id_for(asset, shard)
      Lti::Asset.set_asset_context_id(asset, lti_context_id, context: context)
    end
  end

  def visible_with_permission_check?(launch_type, user, context, session=nil)
    return false unless self.class.visible?(self.extension_setting(launch_type, 'visibility'), user, context, session)
    permission_given?(launch_type, user, context, session)
  end

  def permission_given?(launch_type, user, context, session=nil)
    if (required_permissions_str = self.extension_setting(launch_type, 'required_permissions'))
      # if configured with a comma-separated string of permissions, will only show the link
      # if all permissions are granted
      required_permissions_str.split(",").map(&:to_sym).all?{|p| context&.grants_right?(user, session, p)}
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

  private

  def self.context_id_for(asset, shard)
    str = asset.asset_string.to_s
    raise "Empty value" if str.blank?
    Canvas::Security.hmac_sha1(str, shard.settings[:encryption_key])
  end

  def check_global_navigation_cache
    if self.context.is_a?(Account) && self.context.root_account?
      %w{members admins}.each do |visibility|
        Rails.cache.delete("external_tools/global_navigation/#{self.context.asset_string}/#{visibility}")
      end
    end
  end

  def clear_tool_domain_cache
    if self.saved_change_to_domain? || self.saved_change_to_url?
      self.context.clear_tool_domain_cache
    end
  end

  def self.global_navigation_visibility_for_user(root_account, user)
    Rails.cache.fetch_with_batched_keys(['external_tools/global_navigation/visibility', root_account.asset_string].cache_key,
        batch_object: user, batched_keys: [:enrollments, :account_users]) do
      # let them see admin level tools if there are any courses they can manage
      if root_account.grants_right?(user, :manage_content) ||
        Course.manageable_by_user(user.id, true).not_deleted.where(:root_account_id => root_account).exists?
        'admins'
      else
        'members'
      end
    end
  end

  def self.global_navigation_tools(root_account, visibility)
    RequestCache.cache('global_navigation_tools', root_account, visibility) do
      tools = root_account.context_external_tools.active.having_setting(:global_navigation).to_a
      if visibility == 'members'
        # reject the admin only tools
        tools.reject!{|tool| tool.global_navigation[:visibility] == 'admins'}
      end
      tools
    end
  end

  def self.global_navigation_menu_cache_key(root_account, visibility)
    # only reload the menu if one of the global nav tools has changed
    key = "external_tools/global_navigation/#{root_account.asset_string}/#{visibility}"
    Rails.cache.fetch(key) do
      tools = global_navigation_tools(root_account, visibility)
      Digest::MD5.hexdigest(tools.map(&:cache_key).join('/'))
    end
  end

  def self.visible?(visibility, user, context, session = nil)
    visibility = visibility.to_s
    return true unless %w(public members admins).include?(visibility)
    return true if visibility == 'public'
    return true if visibility == 'members' &&
        context.grants_any_right?(user, session, :participate_as_student, :read_as_admin)
    return true if visibility == 'admins' && context.grants_right?(user, session, :read_as_admin)
    false
  end

  def self.editor_button_json(tools, context, user, session=nil)
    tools.select! {|tool| visible?(tool.editor_button['visibility'], user, context, session)}
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new({link_attributes: {target: '_blank'}}))
    tools.map do |tool|
      {
          :name => tool.label_for(:editor_button, I18n.locale),
          :id => tool.id,
          :url => tool.editor_button(:url),
          :icon_url => tool.editor_button(:icon_url),
          :canvas_icon_class => tool.editor_button(:canvas_icon_class),
          :width => tool.editor_button(:selection_width),
          :height => tool.editor_button(:selection_height),
          :use_tray => tool.editor_button(:use_tray) == "true",
          :description => if tool.description
                            Sanitize.clean(markdown.render(tool.description), CanvasSanitize::SANITIZE)
                          else
                            ""
                          end
      }
    end
  end
end
