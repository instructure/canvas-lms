class ContextExternalTool < ActiveRecord::Base
  include Workflow
  include SearchTermHelper

  has_many :content_tags, :as => :content
  belongs_to :context, :polymorphic => true
  attr_accessible :privacy_level, :domain, :url, :shared_secret, :consumer_key, 
                  :name, :description, :custom_fields, :custom_fields_string,
                  :course_navigation, :account_navigation, :user_navigation,
                  :resource_selection, :editor_button, :homework_submission,
                  :config_type, :config_url, :config_xml, :tool_id
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
  after_save :touch_context
  validate :check_for_xml_error

  workflow do
    state :anonymous
    state :name_only
    state :email_only
    state :public
    state :deleted
  end

  set_policy do
    given { |user, session| self.cached_context_grants_right?(user, session, :update) }
    can :read and can :update and can :delete
  end
  
  EXTENSION_TYPES = [:user_navigation, :course_navigation, :account_navigation, :resource_selection, :editor_button, :homework_submission, :migration_selection]
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
      Importers::ContextExternalToolImporter.import_from_migration(tool_hash, context, self)
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

  def course_navigation=(hash)
    tool_setting(:course_navigation, hash, :default) { |nav_settings|
      if hash[:visibility] == 'members' || hash[:visibility] == 'admins'
        nav_settings[:visibility] = hash[:visibility]
      end
    }
  end

  def course_navigation(setting = nil)
    extension_setting(:course_navigation, setting)
  end

  def account_navigation=(hash)
    tool_setting(:account_navigation, hash)
  end

  def account_navigation(setting = nil)
    extension_setting(:account_navigation, setting)
  end

  def user_navigation=(hash)
    tool_setting(:user_navigation, hash)
  end

  def user_navigation(setting = nil)
    extension_setting(:user_navigation, setting)
  end

  def resource_selection=(hash)
    tool_setting(:resource_selection, hash, :selection_width, :selection_height, :icon_url)
  end

  def resource_selection(setting = nil)
    extension_setting(:resource_selection, setting)
  end

  def editor_button=(hash)
    tool_setting(:editor_button, hash, :selection_width, :selection_height, :icon_url)
  end

  def editor_button(setting = nil)
    extension_setting(:editor_button, setting)
  end
  
  def homework_submission=(hash)
    tool_setting(:homework_submission, hash, :selection_width, :selection_height, :icon_url)
  end
  
  def homework_submission(setting = nil)
    extension_setting(:homework_submission, setting)
  end

  def migration_selection=(hash)
    tool_setting(:migration_selection, hash, :selection_width, :selection_height, :icon_url)
  end

  def migration_selection(setting = nil)
    extension_setting(:migration_selection, setting)
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
  
  def shared_secret=(val)
    write_attribute(:shared_secret, val) unless val.blank?
  end

  def extension_setting(type, property = nil)
    type = type.to_sym
    return settings[type] unless property && settings[type]
    settings[type][property] || settings[property] || extension_default_value(property)
  end

  def extension_default_value(property)
    case property
      when :url
        url
      when :selection_width
        800
      when :selection_height
        400
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
      message = "has_#{type}="
      self.send(message, !!settings[type]) if self.respond_to?(message)
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
  
  def self.all_tools_for(context, options={})
    contexts = []
    tools = []
    if options[:user]
      contexts << options[:user]
    end
    while context
      if context.is_a?(Group)
        contexts << context
        context = context.context || context.account
      elsif context.is_a?(Course)
        contexts << context
        context = context.account
      elsif context.is_a?(Account)
        contexts << context
        context = context.parent_account
      else
        context = nil
      end
    end
    return nil if contexts.empty?
    contexts.each do |context|
      tools += context.context_external_tools.active
    end
    Canvas::ICU.collate_by(tools, &:name)
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
    contexts = []
    while context
      if context.is_a?(Group)
        contexts << context
        context = context.context || context.account
      elsif context.is_a?(Course)
        contexts << context
        context = context.account
      elsif context.is_a?(Account)
        contexts << context
        context = context.parent_account
      else
        context = nil
      end
    end

    preferred_tool = ContextExternalTool.active.find_by_id(preferred_tool_id)
    if preferred_tool && contexts.member?(preferred_tool.context) && preferred_tool.matches_domain?(url)
      return preferred_tool
    end

    sorted_external_tools = contexts.collect{|context| context.context_external_tools.active.sort_by{|t| [t.precedence, t.id == preferred_tool_id ? CanvasSort::First : CanvasSort::Last] }}.flatten(1)

    res = sorted_external_tools.detect{|tool| tool.url && tool.matches_url?(url) }
    return res if res

    # If exactly match doesn't work, try to match by ignoring extra query parameters
    res = sorted_external_tools.detect{|tool| tool.url && tool.matches_url?(url, false) }
    return res if res

    res = sorted_external_tools.detect{|tool| tool.domain && tool.matches_url?(url) }
    return res if res

    nil
  end
  
  scope :having_setting, lambda { |setting| setting ? where("has_#{setting.to_s}" => true) : scoped }

  def self.find_for(id, context, type)
    id = id[Api::ID_REGEX] if id.is_a?(String)
    raise ActiveRecord::RecordNotFound unless id.present?
    tool = context.context_external_tools.having_setting(type).find_by_id(id)
    if !tool && context.is_a?(Group)
      context = context.context
      tool = context.context_external_tools.having_setting(type).find_by_id(id)
    end
    if !tool
      account_ids = context.account_chain_ids
      tool = ContextExternalTool.having_setting(type).find_by_context_type_and_context_id_and_id('Account', account_ids, id)
    end
    raise ActiveRecord::RecordNotFound if !tool
    tool
  end
  scope :active, where("context_external_tools.workflow_state<>'deleted'")
  
  def self.find_all_for(context, type)
    tools = []
    if !context.is_a?(Account) && context.respond_to?(:context_external_tools)
      tools += context.context_external_tools.having_setting(type.to_s)
    end
    account_ids = context.account_chain_ids
    tools += ContextExternalTool.having_setting(type.to_s).find_all_by_context_type_and_context_id('Account', account_ids)
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

  def self.process_migration(*args)
    Importers::ContextExternalToolImporter.process_migration(*args)
  end

  def self.import_from_migration(*args)
    Importers::ContextExternalToolImporter.import_from_migration(*args)
  end

  def resource_selection_settings
    settings[:resource_selection]
  end

  def opaque_identifier_for(asset)
    ContextExternalTool.opaque_identifier_for(asset, self.shard)
  end

  def self.opaque_identifier_for(asset, shard)
    shard.activate do
      str = asset.asset_string.to_s
      raise "Empty value" if str.blank?
      Canvas::Security.hmac_sha1(str, shard.settings[:encryption_key])
    end
  end

  private

  def tool_setting(setting, hash, *keys)
    if !hash || !hash.is_a?(Hash)
      settings.delete setting
      return
    else
      settings[setting] = {}.with_indifferent_access
    end

    hash = hash.with_indifferent_access

    settings[setting][:url] = hash[:url] if hash[:url]
    settings[setting][:text] = hash[:text] if hash[:text]
    settings[setting][:custom_fields] = hash[:custom_fields] if hash[:custom_fields]
    settings[setting][:enabled] = Canvas::Plugin.value_to_boolean(hash[:enabled]) if hash.has_key?(:enabled)
    keys.each { |key| settings[setting][key] = hash[key] if hash.has_key?(key) }

    # if the type needs to do some validations for specific keys
    yield settings[setting] if block_given?

    settings[setting]
  end
end
