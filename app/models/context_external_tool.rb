class ContextExternalTool < ActiveRecord::Base
  include Workflow
  include SearchTermHelper

  has_many :content_tags, :as => :content
  has_many :context_external_tool_placements, :autosave => true

  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Account']
  attr_accessible :privacy_level, :domain, :url, :shared_secret, :consumer_key,
                  :name, :description, :custom_fields, :custom_fields_string,
                  :course_navigation, :account_navigation, :user_navigation,
                  :resource_selection, :editor_button, :homework_submission,
                  :course_home_sub_navigation, :course_settings_sub_navigation,
                  :config_type, :config_url, :config_xml, :tool_id,
                  :integration_type, :not_selectable

  validates_presence_of :context_id, :context_type, :workflow_state
  validates_presence_of :name, :consumer_key, :shared_secret
  validates_length_of :name, :maximum => maximum_string_length
  validates_presence_of :config_url, :if => lambda { |t| t.config_type == "by_url" }
  validates_presence_of :config_xml, :if => lambda { |t| t.config_type == "by_xml" }
  validates_length_of :domain, :maximum => 253, :allow_blank => true
  validate :url_or_domain_is_set
  serialize :settings
  attr_accessor :config_type, :config_url, :config_xml

  before_save :infer_defaults, :validate_vendor_help_link
  after_save :touch_context, :check_global_navigation_cache
  validate :check_for_xml_error

  workflow do
    state :anonymous
    state :name_only
    state :email_only
    state :public
    state :deleted
  end

  set_policy do
    given { |user, session| self.context.grants_right?(user, session, :update) }
    can :read and can :update and can :delete
  end

  EXTENSION_TYPES = [
    :user_navigation, :course_navigation, :account_navigation, :resource_selection,
    :editor_button, :homework_submission, :migration_selection, :course_home_sub_navigation,
    :course_settings_sub_navigation, :global_navigation,
    :assignment_menu, :discussion_topic_menu, :module_menu, :quiz_menu, :wiki_page_menu
  ]

  EXTENSION_TYPES.each do |type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{type}(setting=nil)
        extension_setting(:#{type}, setting)
      end

      def #{type}=(hash)
        set_extension_setting(:#{type}, hash)
      end
    RUBY
  end

  def extension_setting(type, property = nil)
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

    extension_keys = [:custom_fields, :default, :display_type, :enabled, :icon_url,
                      :selection_height, :selection_width, :text, :url, :message_type]
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
    self.context_external_tool_placements.to_a.any?{|p| p.placement_type == type.to_s}
  end

  def set_placement!(type, value=true)
    raise "invalid type" unless EXTENSION_TYPES.include?(type.to_sym)
    if value
      self.context_external_tool_placements.new(:placement_type => type.to_s) unless has_placement?(type)
    else
      if self.persisted?
        self.context_external_tool_placements.for_type(type).delete_all
      end
      self.context_external_tool_placements.delete_if{|p| p.placement_type == type.to_s}
    end
  end

  def url_or_domain_is_set
    setting_types = EXTENSION_TYPES
    # url or domain (or url on canvas lti extension) is required
    if url.blank? && domain.blank? && setting_types.all?{|k| !settings[k] || settings[k]['url'].blank? }
      errors.add(:url, t('url_or_domain_required', "Either the url or domain should be set."))
      errors.add(:domain, t('url_or_domain_required', "Either the url or domain should be set."))
    end
  end

  def settings
    read_attribute(:settings) || write_attribute(:settings, {})
  end

  def label_for(key, lang=nil)
    labels = settings[key] && settings[key][:labels]
    labels2 = settings[:labels]
    (labels && labels[lang]) ||
      (labels && lang && labels[lang.split('-').first]) ||
      (settings[key] && settings[key][:text]) ||
      (labels2 && labels2[lang]) ||
      (labels2 && lang && labels2[lang.split('-').first]) ||
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
    rescue URI::InvalidURIError, ArgumentError
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


    @config_errors = []
    error_field = config_type == 'by_xml' ? 'config_xml' : 'config_url'

    converter = CC::Importer::BLTIConverter.new
    tool_hash = if config_type == 'by_url'
                  uri = URI.parse(config_url)
                  raise URI::InvalidURIError unless uri.host && uri.port
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
  rescue URI::InvalidURIError
    @config_errors << [:config_url, "Invalid URL"]
  rescue ActiveRecord::RecordInvalid => e
    @config_errors += Array(e.record.errors)
  end

  def custom_fields_string=(str)
    hash = {}
    str.split(/[\r\n]+/).each do |line|
      key, val = line.split(/=/)
      hash[key] = val if key.present? && val.present?
    end
    settings[:custom_fields] = hash
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

  def text=(val)
    settings[:text] = val
  end

  def text
    settings[:text]
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

  def extension_default_value(type, property)
    case property
      when :url
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

  def infer_defaults
    self.url = nil if url.blank?
    self.domain = nil if domain.blank?

    settings[:selection_width] = settings[:selection_width].to_i if settings[:selection_width]
    settings[:selection_height] = settings[:selection_height].to_i if settings[:selection_height]

    EXTENSION_TYPES.each do |type|
      if settings[type]
        settings[type][:selection_width] = settings[type][:selection_width].to_i if settings[type][:selection_width]
        settings[type][:selection_height] = settings[type][:selection_height].to_i if settings[type][:selection_height]
      end
    end
    EXTENSION_TYPES.each do |type|
      if settings[type]
        if !(extension_setting(type, :url)) || (settings[type].has_key?(:enabled) && !settings[type][:enabled])
          settings.delete(type)
        end
      end
    end

    settings.delete(:editor_button) if !editor_button(:icon_url)

    EXTENSION_TYPES.each do |type|
      set_placement!(type, !!settings[type])
    end
    true
  end

  #This aggressively updates the domain on all URLs in this tool
  def change_domain!(new_domain)
    replace_host = lambda do |url, host|
      uri = URI.parse(url)
      uri.host = host
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
    return "" if url.empty?
    url = "http://" + url unless url.match(/:\/\//)
    res = URI.parse(url).normalize
    res.query = res.query.split(/&/).sort.join('&') if !res.query.blank?
    res.to_s
  end

  alias_method :destroy!, :destroy
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
        res = URI.parse(standard_url)
        @url_params = res.query.present? ? res.query.split(/&/) : []
      end
      res = URI.parse(url).normalize
      res.query = res.query.split(/&/).select{|p| @url_params.include?(p)}.sort.join('&') if res.query.present?
      res.query = nil if res.query.blank?
      res.normalize!
      return true if res.to_s == standard_url
    end
    host = URI.parse(url).host rescue nil
    !!(host && ('.' + host).match(/\.#{domain}\z/))
  end

  def matches_domain?(url)
    url = ContextExternalTool.standardize_url(url)
    host = URI.parse(url).host
    if domain
      domain == host
    elsif standard_url
      URI.parse(standard_url).host == host
    else
      false
    end
  end

  def self.contexts_to_search(context)
    case context
    when Course
      [context] + context.account_chain
    when Group
      [context] + (context.context ? contexts_to_search(context.context) : context.account_chain)
    when Account
      context.account_chain
    else
      []
    end
  end
  private_class_method :contexts_to_search

  LOR_TYPES = [:course_home_sub_navigation, :course_settings_sub_navigation, :global_navigation,
               :assignment_menu, :discussion_topic_menu, :module_menu, :quiz_menu, :wiki_page_menu]
  def self.all_tools_for(context, options={})
    if LOR_TYPES.include?(options[:type])
      return [] unless (options[:root_account] && options[:root_account].feature_enabled?(:lor_for_account)) ||
          (options[:current_user] && options[:current_user].feature_enabled?(:lor_for_user))
    end
    contexts = []
    if options[:user]
      contexts << options[:user]
    end
    contexts.concat contexts_to_search(context)
    return nil if contexts.empty?

    scope = ContextExternalTool.shard(context.shard).polymorphic_where(context: contexts).active
    scope = scope.having_setting(options[:type]) if options[:type]
    scope = scope.selectable if Canvas::Plugin.value_to_boolean(options[:selectable])
    scope.order(ContextExternalTool.best_unicode_collation_key('name'))
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
  def self.find_external_tool(url, context, preferred_tool_id=nil)
    contexts = contexts_to_search(context)
    preferred_tool = ContextExternalTool.active.find_by_id(preferred_tool_id) if preferred_tool_id
    if preferred_tool && contexts.member?(preferred_tool.context) && preferred_tool.matches_domain?(url)
      return preferred_tool
    end

    all_external_tools = ContextExternalTool.shard(context.shard).polymorphic_where(context: contexts).active.to_a
    sorted_external_tools = all_external_tools.sort_by { |t| [contexts.index { |c| c.id == t.context_id && c.class.name == t.context_type }, t.precedence, t.id == preferred_tool_id ? CanvasSort::First : CanvasSort::Last] }

    res = sorted_external_tools.detect{|tool| tool.url && tool.matches_url?(url) }
    return res if res

    # If exactly match doesn't work, try to match by ignoring extra query parameters
    res = sorted_external_tools.detect{|tool| tool.url && tool.matches_url?(url, false) }
    return res if res

    res = sorted_external_tools.detect{|tool| tool.domain && tool.matches_url?(url) }
    return res if res

    nil
  end

  def self.find_integration_for(context, type)
    contexts_to_search(context).each do |context|
      tools = context.context_external_tools.active.where(integration_type: type)
      return tools.first unless tools.empty?
    end

    nil
  end

  scope :having_setting, lambda { |setting| setting ? joins(:context_external_tool_placements).
      where("context_external_tool_placements.placement_type = ?", setting) : scoped }

  scope :placements, lambda { |*placements|
    if placements
      module_item_sql = if placements.include? 'module_item'
                          "(context_external_tools.not_selectable IS NOT TRUE AND
                           ((COALESCE(context_external_tools.url, '') <> '' ) OR
                           (COALESCE(context_external_tools.domain, '') <> ''))) OR "
                        else
                          ''
                        end
      where(module_item_sql + 'EXISTS (
              SELECT * FROM context_external_tool_placements
              WHERE context_external_tools.id = context_external_tool_placements.context_external_tool_id
              AND context_external_tool_placements.placement_type IN (?) )', placements || [])
    else
      scoped
    end
  }

  scope :selectable, lambda { where("context_external_tools.not_selectable IS NOT TRUE") }

  def self.find_for(id, context, type, raise_error=true)
    id = id[Api::ID_REGEX] if id.is_a?(String)
    unless id.present?
      if raise_error
        raise ActiveRecord::RecordNotFound
      else
        return nil
      end
    end

    tool = context.context_external_tools.having_setting(type).where(id: id).first
    if !tool && context.is_a?(Group)
      context = context.context
      tool = context.context_external_tools.having_setting(type).where(id: id).first
    end
    if !tool
      tool = ContextExternalTool.having_setting(type).find_by_context_type_and_context_id_and_id('Account', context.account_chain, id)
    end
    raise ActiveRecord::RecordNotFound if !tool && raise_error

    tool
  end
  scope :active, -> { where("context_external_tools.workflow_state<>'deleted'") }

  def self.find_all_for(context, type)
    tools = []
    if !context.is_a?(Account) && context.respond_to?(:context_external_tools)
      tools += context.context_external_tools.having_setting(type.to_s)
    end
    tools += ContextExternalTool.having_setting(type.to_s).find_all_by_context_type_and_context_id('Account', context.account_chain)
  end

  def self.serialization_excludes; [:shared_secret,:settings]; end

  # sets the custom fields from the main tool settings, and any on individual resource type settings
  def set_custom_fields(hash, resource_type)
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
  end

  def substituted_custom_fields(placement, substitutions)
    custom_fields = {}
    set_custom_fields(custom_fields, placement)

    custom_fields.each do |k,v|
      if substitutions.has_key?(v)
        if substitutions[v].respond_to?(:call)
          custom_fields[k] = substitutions[v].call
        else
          custom_fields[k] = substitutions[v]
        end
      end
    end
  end

  def resource_selection_settings
    settings[:resource_selection]
  end

  def opaque_identifier_for(asset)
    ContextExternalTool.opaque_identifier_for(asset, self.shard)
  end

  def self.opaque_identifier_for(asset, shard)
    shard.activate do
      lti_context_id = context_id_for(asset, shard)
      set_asset_context_id(asset, lti_context_id)
    end
  end

  private

  def self.set_asset_context_id(asset, context_id)
    lti_context_id = context_id
    if asset.respond_to?('lti_context_id')
      if asset.new_record?
        asset.lti_context_id = context_id
      else
        asset.reload unless asset.lti_context_id?
        unless asset.lti_context_id
          asset.lti_context_id = context_id
          asset.save!
        end
        lti_context_id = asset.lti_context_id
      end
    end
    lti_context_id
  end

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

  def self.global_navigation_visibility_for_user(root_account, user)
    Rails.cache.fetch(['external_tools/global_navigation/visibility', root_account.asset_string, user].cache_key) do
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
    tools = root_account.context_external_tools.active.having_setting(:global_navigation)
    if visibility == 'members'
      # reject the admin only tools
      tools.reject!{|tool| tool.global_navigation[:visibility] == 'admins'}
    end
    tools
  end

  def self.global_navigation_menu_cache_key(root_account, visibility)
    # only reload the menu if one of the global nav tools has changed
    key = "external_tools/global_navigation/#{root_account.asset_string}/#{visibility}"
    Rails.cache.fetch(key) do
      tools = global_navigation_tools(root_account, visibility)
      Digest::MD5.hexdigest(tools.map(&:cache_key).join('/'))
    end
  end
end
