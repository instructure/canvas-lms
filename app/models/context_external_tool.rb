class ContextExternalTool < ActiveRecord::Base
  include Workflow
  has_many :content_tags, :as => :content
  has_many :assignments
  belongs_to :context, :polymorphic => true
  belongs_to :cloned_item
  attr_accessible :privacy_level, :domain, :url, :shared_secret, :consumer_key, :name, :description, :custom_fields, :custom_fields_string
  validates_presence_of :name
  validates_presence_of :consumer_key
  validates_presence_of :shared_secret
  serialize :settings
  
  before_save :infer_defaults

  workflow do
    state :anonymous
    state :name_only
    state :public
    state :deleted
  end
  
  set_policy do 
    given { |user, session| self.cached_context_grants_right?(user, session, :update) }
    can :read and can :update and can :delete
  end
  
  def settings
    read_attribute(:settings) || write_attribute(:settings, {})
  end
  
  def label_for(key, lang=nil)
    labels = settings[key] && settings[key][:labels]
    (labels && labels[lang]) || (settings[key] && settings[key][:text]) || name || "External Tool"
  end
  
  def readable_state
    workflow_state.titleize
  end
  
  def privacy_level=(val)
    if ['anonymous', 'name_only', 'public'].include?(val)
      self.workflow_state = val
    end
  end
  
  def custom_fields_string
    (settings[:custom_fields] || {}).map{|key, val|
      "#{key}=#{val}"
    }.join("\n")
  end
  
  def custom_fields_string=(str)
    hash = {}
    str.split(/\n/).each do |line|
      key, val = line.split(/=/)
      hash[key] = val if key.present? && val.present?
    end
    settings[:custom_fields] = hash
  end
  
  def custom_fields=(hash)
    settings[:custom_fields] = hash if hash.is_a?(Hash)
  end
  
  def shared_secret=(val)
    write_attribute(:shared_secret, val) unless val.blank?
  end
  
  def infer_defaults
    self.url = nil if url.blank?
    self.domain = nil if domain.blank?
    self.has_user_navigation = !!settings[:user_navigation]
    self.has_course_navigation = !!settings[:course_navigation]
    self.has_account_navigation = !!settings[:account_navigation]
    self.has_resource_selection = !!settings[:resource_selection]
    self.has_editor_button = !!settings[:editor_button]
    true
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
    public?
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
  
  def matches_url?(url)
    if !defined?(@standard_url)
      @standard_url = !self.url.blank? && ContextExternalTool.standardize_url(self.url)
    end
    return true if url == @standard_url
    host = URI.parse(url).host rescue nil
    !!(host && ('.' + host).match(/\.#{domain}\z/))
  end
  
  def self.all_tools_for(context)
    contexts = []
    tools = []
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
    tools.sort_by(&:name)
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
  def self.find_external_tool(url, context)
    url = ContextExternalTool.standardize_url(url)
    account_contexts = []
    other_contexts = []
    while context
      if context.is_a?(Group)
        other_contexts << context
        context = context.context || context.account
      elsif context.is_a?(Course)
        other_contexts << context
        context = context.account
      elsif context.is_a?(Account)
        account_contexts << context
        context = context.parent_account
      else
        context = nil
      end
    end
    return nil if account_contexts.empty? && other_contexts.empty?
    account_contexts.each do |context|
      res = context.context_external_tools.active.sort_by(&:precedence).detect{|tool| tool.domain && tool.matches_url?(url) }
      return res if res
    end
    account_contexts.each do |context|
      res = context.context_external_tools.active.sort_by(&:precedence).detect{|tool| tool.matches_url?(url) }
      return res if res
    end
    other_contexts.reverse.each do |context|
      res = context.context_external_tools.active.sort_by(&:precedence).detect{|tool| tool.matches_url?(url) }
      return res if res
    end
    nil
  end
  
  named_scope :having_setting, lambda{|setting|
    {:conditions => {"has_#{setting.to_s}" => true} }
  }
  
  def self.find_for(id, context, type)
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
  named_scope :active, :conditions => ['context_external_tools.workflow_state != ?', 'deleted']
  
  def self.find_all_for(context, type)
    tools = []
    if !context.is_a?(Account) && context.respond_to?(:context_external_tools)
      tools += context.context_external_tools.having_setting(type.to_s)
    end
    account_ids = context.account_chain_ids
    tools += ContextExternalTool.having_setting(type.to_s).find_all_by_context_type_and_context_id('Account', account_ids)
  end
  
  def self.serialization_excludes; [:shared_secret,:settings]; end
  
  def self.serialization_methods; [:custom_fields_string]; end
  
  def self.process_migration(data, migration)
    tools = data['external_tools'] ? data['external_tools']: []
    to_import = migration.to_import 'external_tools'
    tools.each do |tool|
      if tool['migration_id'] && (!to_import || to_import[tool['migration_id']])
        item = import_from_migration(tool, migration.context)
        migration.add_warning(t('external_tool_attention_needed', 'The security parameters for the external tool "%{tool_name}" need to be set in Course Settings.', :tool_name => item.name))
      end
    end
  end
  
  def set_custom_fields(hash, resource_type)
    fields = resource_type ? settings[resource_type.to_sym][:custom_fields] : settings[:custom_fields]
    (fields || {}).each do |key, val|
      key = key.gsub(/[^\w]/, '_').downcase
      if key.match(/^custom_/)
        hash[key] = val
      else
        hash["custom_#{key}"] = val
      end
    end
  end
  
  def clone_for(context, dup=nil, options={})
    if !self.cloned_item && !self.new_record?
      self.cloned_item = ClonedItem.create(:original_item => self)
      self.save!
    end
    existing = ContextExternalTool.active.find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, self.id)
    existing ||= ContextExternalTool.active.find_by_context_type_and_context_id_and_cloned_item_id(context.class.to_s, context.id, self.cloned_item_id)
    return existing if existing && !options[:overwrite]
    new_tool = existing
    new_tool ||= ContextExternalTool.new
    new_tool.context = context
    new_tool.settings = self.settings.clone
    [:name, :shared_secret, :url, :domain, :consumer_key, :workflow_state, :description].each do |att|
      new_tool.write_attribute(att, self.read_attribute(att))
    end
    new_tool.cloned_item_id = self.cloned_item_id
    
    new_tool
  end
  
  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:external_tools_to_import] && !hash[:external_tools_to_import][hash[:migration_id]]
    item ||= find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
    item ||= context.context_external_tools.new
    item.migration_id = hash[:migration_id]
    item.name = hash[:title]
    item.description = hash[:description]
    item.url = hash[:url] unless hash[:url].blank?
    item.domain = hash[:domain] unless hash[:domain].blank?
    item.privacy_level = hash[:privacy_level] || 'name_only'
    item.consumer_key = 'fake'
    item.shared_secret = 'fake'
    if hash[:custom_fields].is_a? Hash
      item.settings[:custom_fields] ||= {}
      item.settings[:custom_fields].merge! hash[:custom_fields] 
    end
    if hash[:extensions].is_a? Array
      item.settings[:vendor_extensions] ||= []
      hash[:extensions].each do |ext|
        next unless ext[:custom_fields].is_a? Hash
        if existing = item.settings[:vendor_extensions].find { |ve| ve[:platform] == ext[:platform] }
          existing[:custom_fields] ||= {}
          existing[:custom_fields].merge! ext[:custom_fields]
        else
          item.settings[:vendor_extensions] << {:platform => ext[:platform], :custom_fields => ext[:custom_fields]}
        end
      end
    end
    
    item.save!
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item
  end
  
end
