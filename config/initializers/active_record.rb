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
  
  def opaque_identifier(column)
    str = send(column).to_s
    raise "Empty value" if str.blank?
    Canvas::Security.hmac_sha1(str)
  end
  
  def self.maximum_text_length
    @maximum_text_length ||= 64.kilobytes-1
  end
  
  def self.maximum_long_text_length
    @maximum_long_text_length ||= 500.kilobytes-1
  end

  def self.maximum_string_length
    255
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
  
  def self.find_cached(key, opts = nil, &block)
    attrs = Rails.cache.read(key)
    if !attrs || attrs.empty? || attrs.is_a?(String) || attrs[:assigned_cache_key] != key
      obj = block.call rescue nil
      attrs = obj && obj.is_a?(self) ? obj.attributes : nil
      attrs[:assigned_cache_key] = key if attrs
      Rails.cache.write(key, attrs, opts) if attrs
    end
    return nil if !attrs || attrs.empty?
    obj = self.new
    attrs = attrs.dup if attrs.frozen?
    attrs.delete(:assigned_cache_key)
    obj.instance_variable_set("@attributes", attrs)
    obj.instance_variable_set("@new_record", false)
    obj
  end
  
  def self.find_all_cached(key, opts = nil, &block)
    attrs_list = Rails.cache.read(key)
    if !attrs_list || attrs_list.empty? || !attrs_list.is_a?(Array) || attrs_list.any?{|attr| attr[:assigned_cache_key] != key }
      list = block.call.to_a rescue nil
      attrs_list = list.map{|obj| obj && obj.is_a?(self) ? obj.attributes : nil }.compact
      attrs_list.each{|attrs| attrs[:assigned_cache_key] = key }
      Rails.cache.write(key, attrs_list, opts)
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
  
  def cached_context_grants_right?(user, session, *permissions)
    @@cached_contexts = nil if ENV['RAILS_ENV'] == "test"
    @@cached_contexts ||= {}
    context_key = "#{self.context_type}_#{self.context_id}" if self.respond_to?(:context_type)
    context_key ||= "Course_#{self.course_id}"
    @@cached_contexts[context_key] ||= self.context if self.respond_to?(:context)
    @@cached_contexts[context_key] ||= self.course
    @@cached_permissions ||= {}
    key = [context_key, (user ? user.id : nil)].join
    @@cached_permissions[key] = nil if ENV['RAILS_ENV'] == "test"
    @@cached_permissions[key] = nil if session && session[:session_affects_permissions]
    @@cached_permissions[key] ||= @@cached_contexts[context_key].grants_rights?(user, session, nil).keys
    (@@cached_permissions[key] & Array(permissions).flatten).any?
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
      self.context_type.constantize.update_all({ :updated_at => Time.now }, { :id => self.context_id })
    end
  rescue
    ErrorReport.log_exception(:touch_context, $!)
  end

  def touch_user
    if self.respond_to?(:user_id) && self.user_id
      User.update_all({ :updated_at => Time.now }, { :id => self.user_id })
      User.invalidate_cache(self.user_id)
    end
    true
  rescue
    ErrorReport.log_exception(:touch_user, $!)
    false
  end

  def context_url_prefix
    "#{self.context_type.downcase.pluralize}/#{self.context_id}"
  end

  # Example: 
  # obj.to_json(:permissions => {:user => u, :policies => [:read, :write, :update]})
  def as_json(options = nil)
    options = options.try(:dup) || {}

    self.set_serialization_options if self.respond_to?(:set_serialization_options)

    except = options.delete(:except) || []
    except = Array(except)
    except.concat(self.class.serialization_excludes) if self.class.respond_to?(:serialization_excludes)
    except.concat(@serialization_excludes) if @serialization_excludes
    except.uniq!
    methods = options.delete(:methods) || []
    methods = Array(methods)
    methods.concat(self.class.serialization_methods) if self.class.respond_to?(:serialization_methods)
    methods.concat(@serialization_methods) if @serialization_methods
    methods.uniq!

    options[:except] = except unless except.empty?
    options[:methods] = methods unless methods.empty?

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
      obj_hash = options[:include_root] ? hash[self.class.base_ar_class.model_name.element] : hash
      if self.respond_to?(:filter_attributes_for_user)
        self.filter_attributes_for_user(obj_hash, options[:permissions][:user], options[:permissions][:session])
      end
      permissions_hash = self.grants_rights?(options[:permissions][:user], options[:permissions][:session], *options[:permissions][:policies])
      obj_hash["permissions"] = permissions_hash
    end

    self.revert_from_serialization_options if self.respond_to?(:revert_from_serialization_options)

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

  def wildcard(*args)
    self.class.wildcard(*args)
  end

  def self.wildcard(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options[:type] ||= :full

    value = args.pop
    value = value.to_s.downcase.gsub('\\', '\\\\\\\\').gsub('%', '\\%').gsub('_', '\\_')
    value = '%' + value unless options[:type] == :right
    value += '%' unless options[:type] == :left

    cols = case connection.adapter_name
      when 'SQLite'
        # sqlite is always case-insensitive, and you must specify the escape char
        args.map{|col| "#{col} LIKE ? ESCAPE '\\'"}
      else
        # postgres is always case-sensitive (mysql depends on the collation)
        args.map{|col| "LOWER(#{col}) LIKE ?"}
    end
    sanitize_sql_array ["(" + cols.join(" OR ") + ")", *([value] * cols.size)]
  end

  class DynamicFinderTypeError < Exception; end
  class << self
    def construct_attributes_from_arguments_with_type_cast(attribute_names, arguments)
      log_dynamic_finder_nil_arguments(attribute_names) if current_scoped_methods.nil? && arguments.flatten.compact.empty?
      attributes = construct_attributes_from_arguments_without_type_cast(attribute_names, arguments)
      attributes.each_pair do |attribute, value|
        next unless column = columns.detect{ |col| col.name == attribute.to_s }
        next if [value].flatten.compact.empty?
        cast_value = [value].flatten.map{ |v| v.respond_to?(:quoted_id) ? v : column.type_cast(v) }
        cast_value = cast_value.first unless value.is_a?(Array)
        next if [value].flatten.map(&:to_s) == [cast_value].flatten.map(&:to_s)
        log_dynamic_finder_type_cast(value, column)
        attributes[attribute] = cast_value
      end
    end
    alias_method_chain :construct_attributes_from_arguments, :type_cast

    def log_dynamic_finder_nil_arguments(attribute_names)
      error = "No non-nil arguments passed to #{self.base_class}.find_by_#{attribute_names.join('_and_')}"
      raise DynamicFinderTypeError, error if Canvas.dynamic_finder_nil_arguments_error == :raise
      logger.debug "WARNING: " + error
    end

    def log_dynamic_finder_type_cast(value, column)
      error = "Cannot cleanly cast #{value.inspect} to #{column.type} (#{self.base_class}\##{column.name})"
      raise DynamicFinderTypeError, error if Canvas.dynamic_finder_type_cast_error == :raise
      logger.debug "WARNING: " + error
    end
  end
end

class ActiveRecord::Serialization::Serializer
  def serializable_record
    hash = {}.tap do |serializable_record|
      user_content_fields = options[:user_content] || []
      serializable_names.each do |name|
        val = @record.send(name)
        if val.present? && user_content_fields.include?(name.to_s)
          val = UserContent.escape(val)
        end
        serializable_record[name] = val
      end

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

# See https://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/66-true-false-conditions-broken-for-sqlite#ticket-66-9
# The default 't' and 'f' are no good, since sqlite treats them both as 0 in boolean logic.
# This patch makes it so you can do stuff like:
#   :conditions => "active"
# instead of having to do:
#   :conditions => ["active = ?", true]
if defined?(ActiveRecord::ConnectionAdapters::SQLiteAdapter)
  ActiveRecord::ConnectionAdapters::SQLiteAdapter.class_eval do
    def quoted_true
      '1'
    end
    def quoted_false
      '0'
    end
  end
end

if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
    def configure_connection_with_pg_compat
      configure_connection_without_pg_compat
      execute "SET SESSION SQL_MODE='PIPES_AS_CONCAT'"
    end
    alias_method_chain :configure_connection, :pg_compat
  end
end

# postgres doesn't support limit on text columns, but it does on varchars. assuming we don't exceed
# the varchar limit, change the type. otherwise drop the limit. not a big deal since we already
# have max length validations in the models.
if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
    def type_to_sql_with_text_to_varchar(type, limit = nil, *args)
      if type == :text && limit
        if limit <= 10485760
          type = :string
        else
          limit = nil
        end
      end
      type_to_sql_without_text_to_varchar(type, limit, *args)
    end
    alias_method_chain :type_to_sql, :text_to_varchar
  end
end

# patch adapted from https://rails.lighthouseapp.com/projects/8994/tickets/4887-has_many-through-belongs_to-association-bug
# this isn't getting fixed in rails 2.3.x, and we need it. otherwise the following sorts of things
# will generate sql errors:
#  Course.new.default_wiki_wiki_pages.scoped(:limit => 10)
#  Group.new.active_default_wiki_wiki_pages.size
ActiveRecord::Associations::HasManyThroughAssociation.class_eval do
  def construct_scope_with_has_many_fix
    if target_reflection_has_associated_record?
      construct_scope_without_has_many_fix
    else
      {:find => {:conditions => "1 != 1"}}
    end
  end
  alias_method_chain :construct_scope, :has_many_fix
end
