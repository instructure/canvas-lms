class ActiveRecord::Base
  extend ActiveSupport::Memoizable # used for a lot of the reporting queries  

  class ProtectedAttributeAssigned < Exception; end
  def log_protected_attribute_removal_with_raise(*attributes)
    if Canvas.protected_attribute_error == :raise
      raise ProtectedAttributeAssigned, "Can't mass-assign these protected attributes for class #{self.class.name}: #{attributes.join(', ')}"
    else
      log_protected_attribute_removal_without_raise(*attributes)
    end
  end
  alias_method_chain :log_protected_attribute_removal, :raise

  def feed_code
    id = self.uuid rescue self.id
    "#{self.class.base_ar_class.name.underscore}_#{id.to_s}"
  end
  
  def self.maximum_text_length
    @maximum_text_length ||= 64.kilobytes-1
  end
  
  def self.maximum_long_text_length
    @maximum_text_length ||= 500.kilobytes-1
  end
  
  def self.find_by_asset_string(string, asset_types)
    code = string.split("_")
    id = code.pop
    code.join("_").classify.constantize.find(id) rescue nil
  end

  # takes an asset string list, like "course_5,user_7" and turns it into an
  # array of [class_name, id] like [ ["Course", 5], ["User", 7] ]
  def self.parse_asset_string_list(asset_string_list)
    asset_string_list.to_s.split(",").map do |str|
      code = str.split("_", 2)
      [code.first.classify, code.last.to_i]
    end
  end

  def self.initialize_by_asset_string(string, asset_types)
    code = string.split("_")
    id = code.pop
    res = code.join("_").classify.constantize rescue nil
    res.id = id if res
    res
  end
  
  def self.find_cached(key, &block)
    attrs = Rails.cache.read(key)
    if !attrs || attrs.empty? || attrs.is_a?(String) || attrs[:assigned_cache_key] != key
      obj = block.call rescue nil
      attrs = obj && obj.is_a?(self) ? obj.attributes : nil
      attrs[:assigned_cache_key] = key if attrs
      Rails.cache.write(key, attrs) if attrs
    end
    return nil if !attrs || attrs.empty?
    obj = self.new
    attrs = attrs.dup if attrs.frozen?
    attrs.delete(:assigned_cache_key)
    obj.instance_variable_set("@attributes", attrs)
    obj.instance_variable_set("@new_record", false)
    obj
  end
  
  def self.find_all_cached(key, &block)
    attrs_list = Rails.cache.read(key)
    if !attrs_list || attrs_list.empty? || !attrs_list.is_a?(Array) || attrs_list.any?{|attr| attr[:assigned_cache_key] != key }
      list = block.call.to_a rescue nil
      attrs_list = list.map{|obj| obj && obj.is_a?(self) ? obj.attributes : nil }.compact
      attrs_list.each{|attrs| attrs[:assigned_cache_key] = key }
      Rails.cache.write(key, attrs_list)
    end
    return [] if !attrs_list || attrs_list.empty?
    attrs_list.map do |attrs|
      obj = self.new
      attrs = attrs.dup if attrs.frozen?
      attrs.delete(:assigned_cache_key)
      obj.instance_variable_set("@attributes", attrs)
      obj.instance_variable_set("@new_record", false)
      obj
    end
  end
  
  def asset_string
    @asset_string ||= "#{self.class.base_ar_class.name.underscore}_#{id.to_s}"
  end
  
  def export_columns(format = nil)
    self.class.content_columns.map(&:name)
  end
  
  def to_row(format = nil)
    export_columns(format).map { |c| self.send(c) }
  end
  
  def is_a_context?
    false
  end
  
  def self.clear_cached_contexts
    @@cached_contexts = {}
    @@cached_permissions = {}
  end
  
  def cached_context_grants_right?(user, session, permission, context_key=nil)
    @@cached_contexts = nil if ENV['RAILS_ENV'] == "test"
    @@cached_contexts ||= {}
    context_key ||= "#{self.context_type}_#{self.context_id}"
    @@cached_contexts[context_key] ||= self.context rescue nil
    @@cached_contexts[context_key] ||= self.course rescue nil
    @@cached_permissions ||= {}
    key = [context_key, (user ? user.id : nil)].join
    @@cached_permissions[key] = nil if ENV['RAILS_ENV'] == "test"
    @@cached_permissions[key] = nil if session && session[:session_affects_permissions]
    @@cached_permissions[key] ||= @@cached_contexts[context_key].grants_rights?(user, session, nil)
    @@cached_permissions[key][permission]
  end
  
  def cached_course_grants_right?(user, session, permission)
    cached_context_grants_right?(user, session, permission, "Course_#{self.course_id}")
  end
  
  def cached_context_short_name
    if self.respond_to?(:context)
      code = self.respond_to?(:context_code) ? self.context_code : self.context.asset_string
      @cached_context_name ||= Rails.cache.fetch(['short_name_lookup', code].cache_key) do
        self.context.short_name rescue ""
      end
    else
      raise "Can only call cached_context_short_name on items with a context"
    end
  end
  
  def self.skip_touch_context(skip=true)
    @@skip_touch_context = skip
  end
  
  def save_without_touching_context
    @skip_touch_context = true
    self.save
    @skip_touch_context = false
  end
  
  def touch_context
    return if (@@skip_touch_context ||= false || @skip_touch_context ||= false)
    if self.respond_to?(:context_type) && self.respond_to?(:context_id) && self.context_type && self.context_id
      conn = ActiveRecord::Base.connection
      conn.execute("UPDATE #{self.context_type.underscore.pluralize} SET updated_at=#{conn.quote(Time.now.utc.to_s(:db))} WHERE id=#{self.context_id}") rescue nil
    end
  end
  
  def touch_user
    if self.respond_to?(:user_id) && self.user_id
      conn = ActiveRecord::Base.connection
      conn.execute("UPDATE users SET updated_at=#{conn.quote(Time.now.utc.to_s(:db))} WHERE id=#{self.user_id}") rescue nil
      User.invalidate_cache(self.user_id)
    end
    true
  rescue
    false
  end
  
  def context_url_prefix
    "#{self.context_type.downcase.pluralize}/#{self.context_id}"
  end
  
  def send_later_if_production(*args)
    if ENV['RAILS_ENV'] == 'production'
      send_later(*args)
    else
      send(*args)
    end
  end

  def self.send_later_if_production(*args)
    if ENV['RAILS_ENV'] == 'production'
      send_later(*args)
    else
      send(*args)
    end
  end

  # Example: 
  # obj.to_json(:permissions => {:user => u, :policies => [:read, :write, :update]})
  def as_json(options = nil)
    options ||= {}

    self.set_serialization_options rescue nil
    options[:except] = [options[:except]] 
    options[:methods] = [options[:methods]]

    options[:except] = (options[:except] + ([self.class.serialization_excludes] rescue []) + [@serialization_excludes]).flatten.compact
    options[:methods] = (options[:methods] + ([self.class.serialization_methods] rescue []) + [@serialization_methods]).flatten.compact

    options.delete :except if options[:except].empty?
    options.delete :methods if options[:methods].empty?

    # We include a root in all the association json objects (if it's a
    # collection), which is different than the rails behavior of just including
    # the root in the base json object. Hence the hackies.
    #
    # We are in the process of migrating away from including the root in all our
    # json serializations at all. Once that's done, we can remove this and the
    # monkey patch to Serialzer, below.
    unless options.key?(:include_root)
      options[:include_root] = ActiveRecord::Base.include_root_in_json
    end

    hash = Serializer.new(self, options).serializable_record

    if options[:permissions]
      permissions_hash = self.grants_rights?(options[:permissions][:user], options[:permissions][:session], *options[:permissions][:policies])
      if options[:include_root]
        hash[self.class.base_ar_class.model_name.element]["permissions"] = permissions_hash
      else
        hash["permissions"] = permissions_hash
      end
    end

    self.revert_from_serialization_options rescue nil

    hash
  end

  def class_name
    self.class.to_s
  end

  def self.execute_with_sanitize(array)
    self.connection.execute(__send__(:sanitize_sql_array, array))
  end

  def self.base_ar_class
    class_of_active_record_descendant(self)
  end
end

class ActiveRecord::Serialization::Serializer
  def serializable_record
    hash = {}.tap do |serializable_record|
      serializable_names.each { |name| serializable_record[name] = @record.send(name) }
      add_includes do |association, records, opts|
        if records.is_a?(Enumerable)
          serializable_record[association] = records.compact.collect { |r| self.class.new(r, opts).serializable_record }
        else
          # don't include_root on non-plural associations
          opts = opts.merge(:include_root => false)
          serializable_record[association] = self.class.new(records, opts).serializable_record
        end
      end
    end
    hash = { @record.class.base_ar_class.model_name.element => hash } if options[:include_root]
    hash
  end

end

class ActiveRecord::Errors
  def to_json
    {:errors => @errors}.to_json
  end
end

# We need to have 64-bit ids and foreign keys.
if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  ActiveRecord::ConnectionAdapters::MysqlAdapter::NATIVE_DATABASE_TYPES[:primary_key] = "bigint DEFAULT NULL auto_increment PRIMARY KEY".freeze
  ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
    def add_column_with_foreign_key_check(table, name, type, options = {})
      Canvas.active_record_foreign_key_check(name, type, options)
      add_column_without_foreign_key_check(table, name, type, options)
    end
    alias_method_chain :add_column, :foreign_key_check
  end
end

if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = "bigserial primary key".freeze
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
    def add_column_with_foreign_key_check(table, name, type, options = {})
      Canvas.active_record_foreign_key_check(name, type, options)
      add_column_without_foreign_key_check(table, name, type, options)
    end
    alias_method_chain :add_column, :foreign_key_check
  end
end

ActiveRecord::ConnectionAdapters::SchemaStatements.class_eval do
  def add_column_with_foreign_key_check(table, name, type, options = {})
    Canvas.active_record_foreign_key_check(name, type, options)
    add_column_without_foreign_key_check(table, name, type, options)
  end
  alias_method_chain :add_column, :foreign_key_check
end

ActiveRecord::ConnectionAdapters::TableDefinition.class_eval do
  def column_with_foreign_key_check(name, type, options = {})
    Canvas.active_record_foreign_key_check(name, type, options)
    column_without_foreign_key_check(name, type, options)
  end
  alias_method_chain :column, :foreign_key_check
end

# patch adapted from https://rails.lighthouseapp.com/projects/8994/tickets/6535-find_or_create_by-on-an-association-always-creates-new-records
ActiveRecord::Associations::AssociationCollection.class_eval do
  def method_missing_with_splat_fix(method, *args, &block)
    if method.to_s =~ /^find_or_create_by_(.*)$/
      rest = $1
      find_args = pull_finder_args_from(::ActiveRecord::DynamicFinderMatch.match(method).attribute_names, *args)
      return send("find_by_#{rest}", *find_args) ||
             method_missing("create_by_#{rest}", *args, &block)
    else
      method_missing_without_splat_fix(method, *args, &block)
    end
  end
  alias_method_chain :method_missing, :splat_fix
end