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
    self.shard.activate do
      str = send(column).to_s
      raise "Empty value" if str.blank?
      Canvas::Security.hmac_sha1(str, self.shard.settings[:encryption_key])
    end
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

  def self.find_by_asset_string(string, asset_types=nil)
    find_all_by_asset_string([string], asset_types)[0]
  end

  def self.find_all_by_asset_string(strings, asset_types=nil)
    # TODO: start checking asset_types, if provided
    strings.map{ |str| parse_asset_string(str) }.group_by(&:first).inject([]) do |result, (klass, id_pairs)|
      result.concat((klass.constantize.find_all_by_id(id_pairs.map(&:last)) rescue []))
    end
  end

  # takes an asset string list, like "course_5,user_7" and turns it into an
  # array of [class_name, id] like [ ["Course", 5], ["User", 7] ]
  def self.parse_asset_string_list(asset_string_list)
    asset_string_list.to_s.split(",").map { |str| parse_asset_string(str) }
  end

  def self.parse_asset_string(str)
    code = str.split(/_(\d+)\z/)
    [code.first.classify, code.last.to_i]
  end

  def self.initialize_by_asset_string(string, asset_types)
    code = string.split("_")
    id = code.pop
    res = code.join("_").classify.constantize rescue nil
    res.id = id if res
    res
  end

  def asset_string
    @asset_string ||= "#{self.class.base_ar_class.name.underscore}_#{id.to_s}"
  end

  # little helper to keep checks concise and avoid a db lookup
  def has_asset?(asset, field = :context)
    asset.id == send("#{field}_id") && asset.class.base_ar_class.name == send("#{field}_type")
  end

  def context_string(field = :context)
    send("#{field}_type").underscore + "_" + send("#{field}_id").to_s if send("#{field}_type")
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
      self.context_type.constantize.update_all({ :updated_at => Time.now.utc }, { :id => self.context_id })
    end
  rescue
    ErrorReport.log_exception(:touch_context, $!)
  end

  def touch_user
    if self.respond_to?(:user_id) && self.user_id
      User.update_all({ :updated_at => Time.now.utc }, { :id => self.user_id })
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
      unless options[:permissions][:include_permissions] == false
        permissions_hash = self.grants_rights?(options[:permissions][:user], options[:permissions][:session], *options[:permissions][:policies])
        obj_hash["permissions"] = permissions_hash
      end
    end

    self.revert_from_serialization_options if self.respond_to?(:revert_from_serialization_options)

    hash
  end

  def class_name
    self.class.to_s
  end

  def sanitize_sql(*args)
    self.class.send :sanitize_sql_for_conditions, *args
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
    if options[:delimiter]
      options[:type] = :full
      value = options[:delimiter] + value + options[:delimiter]
      delimiter = connection.quote(options[:delimiter])
      column_str = "#{delimiter} || %s || #{delimiter}"
      args = args.map{ |a| column_str % a.to_s }
    end

    value = value.to_s.downcase.gsub('\\', '\\\\\\\\').gsub('%', '\\%').gsub('_', '\\_')
    value = '%' + value unless options[:type] == :right
    value += '%' unless options[:type] == :left

    cols = args.map{ |col| like_condition(col) }
    sanitize_sql_array ["(" + cols.join(" OR ") + ")", *([value] * cols.size)]
  end

  def self.like_condition(value, pattern = '?', downcase = true)
    case connection.adapter_name
      when 'SQLite'
        # sqlite is always case-insensitive, and you must specify the escape char
        "#{value} LIKE #{pattern} ESCAPE '\\'"
      else
        # postgres is always case-sensitive (mysql depends on the collation)
        value = "LOWER(#{value})" if downcase
        "#{value} LIKE #{pattern}"
    end
  end

  def self.best_unicode_collation_key(col)
    if ActiveRecord::Base.configurations[RAILS_ENV]['adapter'] == 'postgresql'
      # For PostgreSQL, we can't trust a simple LOWER(column), with any collation, since
      # Postgres just defers to the C library which is different for each platform. The best
      # choice is the collkey function from pg_collkey which uses ICU to get a full unicode sort.
      # If that extension isn't around, casting to a bytea sucks for international characters,
      # but at least it's consistent, and orders commas before letters so you don't end up with
      # Johnson, Bob sorting before Johns, Jimmy
      @collkey ||= connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i
      @collkey == 0 ? "CAST(LOWER(#{col}) AS bytea)" : "collkey(#{col}, 'root', true, 2, true)"
    else
      # Not yet optimized for other dbs (MySQL's default collation is case insensitive;
      # SQLite can have custom collations inserted, but probably not worth the effort
      # since no one will actually use SQLite in a production install of Canvas)
      col
    end
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

  def self.merge_includes(first, second)
    result = (safe_to_array(first) + safe_to_array(second)).uniq
    result.each_with_index do |item, index|
      if item.is_a?(Hash) && item.has_key?(:exclude)
        exclude = item[:exclude]
        item.delete :exclude
        result.delete_at(index) if item.empty?
        result = (result - safe_to_array(exclude))
        break
      end
    end
    result
  end

  def self.rank_sql(ary, col)
    ary.each_with_index.inject('CASE '){ |string, (values, i)|
      string << "WHEN #{col} IN (" << Array(values).map{ |value| connection.quote(value) }.join(', ') << ") THEN #{i} "
    } << "ELSE #{ary.size} END"
  end

  def self.rank_hash(ary)
    ary.each_with_index.inject(Hash.new(ary.size + 1)){ |hash, (values, i)|
      Array(values).each{ |value| hash[value] = i + 1 }
      hash
    }
  end

  def self.distinct_on(columns, options)
    native = (connection.adapter_name == 'PostgreSQL')
    options[:select] = "DISTINCT ON (#{Array(columns).join(', ')}) " + (options[:select] || '*') if native
    raise "can't use limit with distinct on" if options[:limit] # while it's possible, it would be gross for non-native, so we don't allow it
    raise "distinct on columns must match the leftmost part of the order-by clause" unless options[:order] && options[:order] =~ /\A#{Array(columns).map{ |c| Regexp.escape(c) }.join(' (asc|desc)?,')}/i

    result = find(:all, options)

    if !native
      columns = columns.map{ |c| c.to_s.sub(/.*\./, '') }
      result = result.inject([]) { |ary, row|
        ary << row unless ary.last && columns.all?{ |c| ary.last[c] == row[c] }
        ary
      }
    end

    result
  end

  def self.distinct(column, options={})
    column = column.to_s
    options = {:include_nil => false}.merge(options)

    result = if ActiveRecord::Base.configurations[RAILS_ENV]['adapter'] == 'postgresql'
      sql = ''
      sql << "SELECT NULL AS #{column} WHERE EXISTS(SELECT * FROM #{table_name} WHERE #{column} IS NULL) UNION ALL (" if options[:include_nil]
      sql << <<-SQL
        WITH RECURSIVE t AS (
          SELECT MIN(#{column}) AS #{column} FROM #{table_name}
          UNION ALL
          SELECT (SELECT MIN(#{column}) FROM #{table_name} WHERE #{column} > t.#{column})
          FROM t
          WHERE t.#{column} IS NOT NULL
        )
        SELECT #{column} FROM t WHERE #{column} IS NOT NULL
      SQL
      sql << ")" if options[:include_nil]
      find_by_sql(sql)
    else
      conditions = "#{column} IS NOT NULL" unless options[:include_nil]
      find(:all, :select => "DISTINCT #{column}", :conditions => conditions, :order => column)
    end
    result.map(&column.to_sym)
  end

  named_scope :order, lambda { |order_by|
    {:order => order_by}
  }

  named_scope :where, lambda { |conditions|
    {:conditions => conditions}
  }

  # set up class-specific getters/setters for a polymorphic association, e.g.
  #   belongs_to :context, :polymorphic => true, :types => [:course, :account]
  def self.belongs_to(name, options={})
    if types = options.delete(:types)
      add_polymorph_methods(name, Array(types))
    end
    super
  end

  def self.add_polymorph_methods(generic, specifics)
    specifics.each do |specific|
      next if instance_methods.include?(specific.to_s)
      class_name = specific.to_s.classify
      correct_type = "#{generic}_type && self.class.send(:compute_type, #{generic}_type) <= #{class_name}"

      class_eval <<-CODE
      def #{specific}
        #{generic} if #{correct_type}
      end

      def #{specific}=(val)
        if val.nil?
          # we don't want to unset it if it's currently some other type, i.e.
          # foo.bar = Bar.new
          # foo.baz = nil
          # foo.bar.should_not be_nil
          self.#{generic} = nil if #{correct_type}
        elsif val.is_a?(#{class_name})
          self.#{generic} = val
        else
          raise ArgumentError, "argument is not a #{class_name}"
        end
      end
      CODE
    end
  end

  module UniqueConstraintViolation
    def self.===(error)
      ActiveRecord::StatementInvalid === error &&
      error.message.match(/PGError: ERROR: +duplicate key value violates unique constraint|Mysql::Error: Duplicate entry .* for key|SQLite3::ConstraintException: columns .* not unique/)
    end
  end

  def self.unique_constraint_retry(retries = 1)
    # runs the block in a (possibly nested) transaction. if a unique constraint
    # violation occurs, it will run it "retries" more times. the nested
    # transaction (savepoint) ensures we don't mess up things for the outer
    # transaction. useful for possible race conditions where we don't want to
    # take a lock (e.g. when we create a submission).
    retries.times do
      begin
        return transaction(:requires_new => true) { uncached { yield } }
      rescue UniqueConstraintViolation
      end
    end
    transaction(:requires_new => true) { uncached { yield } }
  end

  # returns batch_size ids at a time, working through the primary key from
  # smallest to largest.
  #
  # note this does a raw connection.select_values, so it doesn't work with scopes
  def self.find_ids_in_batches(options = {})
    batch_size = options[:batch_size] || 1000
    ids = connection.select_values("select #{primary_key} from #{table_name} order by #{primary_key} limit #{batch_size.to_i}")
    ids = ids.map(&:to_i) unless options[:no_integer_cast]
    while ids.present?
      yield ids
      break if ids.size < batch_size
      last_value = ids.last
      ids = connection.select_values(sanitize_sql_array(["select #{primary_key} from #{table_name} where #{primary_key} > ? order by #{primary_key} limit #{batch_size.to_i}", last_value]))
      ids = ids.map(&:to_i) unless options[:no_integer_cast]
    end
  end

  # returns 2 ids at a time (the min and the max of a range), working through
  # the primary key from smallest to largest.
  #
  # note this does a raw connection.select_values, so it doesn't work with scopes
  def self.find_ids_in_ranges(options = {})
    batch_size = options[:batch_size] || 1000
    ids = connection.select_rows("select min(id), max(id) from (select #{primary_key} as id from #{table_name} order by #{primary_key} limit #{batch_size.to_i}) as subquery").first
    ids = ids.map { |id| id.try(:to_i) }
    while ids.first.present?
      yield *ids
      last_value = ids.last
      ids = connection.select_rows(sanitize_sql_array(["select min(id), max(id) from (select #{primary_key} as id from #{table_name} where #{primary_key} > ? order by #{primary_key} limit #{batch_size.to_i}) as subquery", last_value])).first
      ids = ids.map { |id| id.try(:to_i) }
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
  def bulk_insert(table_name, records)
    return if records.empty?
    transaction do
      keys = records.first.keys
      quoted_keys = keys.map{ |k| quote_column_name(k) }.join(', ')
      records.each do |record|
        execute <<-SQL
          INSERT INTO #{quote_table_name(table_name)}
            (#{quoted_keys})
          VALUES
            (#{keys.map{ |k| quote(record[k]) }.join(', ')})
        SQL
      end
    end
  end
end

if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
    def bulk_insert(table_name, records)
      return if records.empty?
      transaction do
        keys = records.first.keys
        quoted_keys = keys.map{ |k| quote_column_name(k) }.join(', ')
        execute "INSERT INTO #{quote_table_name(table_name)} (#{quoted_keys}) VALUES" <<
          records.map{ |record| "(#{keys.map{ |k| quote(record[k]) }.join(', ')})" }.join(',')
      end
    end
  end
end
if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
    def bulk_insert(table_name, records)
      return if records.empty?
      transaction do
        keys = records.first.keys
        quoted_keys = keys.map{ |k| quote_column_name(k) }.join(', ')
        execute "COPY #{quote_table_name(table_name)} (#{quoted_keys}) FROM STDIN"
        raw_connection.put_copy_data records.inject(''){ |result, record|
          result << keys.map{ |k| quote_text(record[k]) }.join("\t") << "\n"
        }
        raw_connection.put_copy_end
      end
    end

    def quote_text(value)
      if value.nil?
        "\\N"
      else
        hash = {"\n" => "\\n", "\r" => "\\r", "\t" => "\\t", "\\" => "\\\\"}
        value.to_s.gsub(/[\n\r\t\\]/){ |c| hash[c] }
      end
    end

    def supports_delayed_constraint_validation?
      postgresql_version >= 90100
    end

    def add_foreign_key_with_delayed_validation(from_table, to_table, options = {})
      raise ArgumentError, "Cannot specify custom options with :delay_validation" if options[:options] && options[:delay_validation]

      options.delete(:delay_validation) unless supports_delayed_constraint_validation?
      options[:options] = 'NOT VALID' if options[:delay_validation]

      column  = options[:column] || "#{to_table.to_s.singularize}_id"
      foreign_key_name = foreign_key_name(from_table, column, options)

      add_foreign_key_without_delayed_validation(from_table, to_table, options)

      execute("ALTER TABLE #{quote_table_name(from_table)} VALIDATE CONSTRAINT #{quote_column_name(foreign_key_name)}") if options[:delay_validation]
    end
    alias_method_chain :add_foreign_key, :delayed_validation

    # have to replace the entire method to support concurrent
    def add_index(table_name, column_name, options = {})
      column_names = Array(column_name)
      index_name   = index_name(table_name, :column => column_names)

      if Hash === options # legacy support, since this param was a string
        index_type = options[:unique] ? "UNIQUE" : ""
        index_name = options[:name].to_s if options[:name]
      else
        index_type = options
      end

      if index_name.length > index_name_length
        @logger.warn("Index name '#{index_name}' on table '#{table_name}' is too long; the limit is #{index_name_length} characters. Skipping.")
        return
      end
      if index_exists?(table_name, index_name, false)
        @logger.warn("Index name '#{index_name}' on table '#{table_name}' already exists. Skipping.")
        return
      end
      quoted_column_names = quoted_columns_for_index(column_names, options).join(", ")

      execute "CREATE #{index_type} INDEX #{"CONCURRENTLY " if options[:concurrently]}#{quote_column_name(index_name)} ON #{quote_table_name(table_name)} (#{quoted_column_names})"
    end
  end
end

class ActiveRecord::Serialization::Serializer
  def serializable_record
    hash = HashWithIndifferentAccess.new.tap do |serializable_record|
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
    hash = { @record.class.base_ar_class.model_name.element => hash }.with_indifferent_access if options[:include_root]
    hash
  end

end

class ActiveRecord::Errors
  def as_json(*a)
    {:errors => @errors}.as_json(*a)
  end
end

# We are currently using the ActiveRecord::Errors modification above to return
# the errors to our javascript in a specific expected format. however, this
# format was returning the @base attribute of each ActiveRecord::Error, which
# is a data leakage issue since that's the full json representation of the AR object.
#
# This modification removes the @base attribute from the json, which
# fortunately wasn't being used by our javascript.
# further development will eventually remove these two modifications
# completely, and switch our javascript to use the default json formatting of
# ActiveRecord::Errors
# See #6733
class ActiveRecord::Error
  def as_json(*a)
    super.slice('attribute', 'type', 'message')
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


class ActiveRecord::ConnectionAdapters::AbstractAdapter
  # for functions that differ from one adapter to the next, use the following
  # method (overriding as needed in non-standard adapters), e.g.
  #
  #   connection.func(:group_concat, :name, '|') ->
  #     group_concat(name, '|')           (default)
  #     group_concat(name SEPARATOR '|')  (mysql)
  #     string_agg(name::text, '|')       (postgres)

  def func(name, *args)
    "#{name}(#{args.map{ |arg| func_arg_esc(arg) }.join(', ')})"
  end

  def func_arg_esc(arg)
    arg.is_a?(Symbol) ? arg : quote(arg)
  end

  def group_by(*columns)
    # the first item should be the primary key(s) that the other
    # columns are functionally dependent on
    Array(columns.first).join(", ")
  end

  def after_transaction_commit(&block)
    if open_transactions == 0
      block.call
    else
      @after_transaction_commit ||= []
      @after_transaction_commit << block
    end
  end

  def after_transaction_commit_callbacks
    @after_transaction_commit || []
  end

  # the alias_method_chain needs to happen in the subclass, since they all
  # override commit_db_transaction
  def commit_db_transaction_with_callbacks
    commit_db_transaction_without_callbacks
    return unless @after_transaction_commit
    # the callback could trigger a new transaction on this connection,
    # and leaving the callbacks in @after_transaction_commit could put us in an
    # infinite loop.
    # so we store off the callbacks to a local var here.
    callbacks = @after_transaction_commit
    @after_transaction_commit = []
    callbacks.each { |cb| cb.call() }
  ensure
    @after_transaction_commit = [] if @after_transaction_commit
  end

  def rollback_db_transaction_with_callbacks
    rollback_db_transaction_without_callbacks
    @after_transaction_commit = [] if @after_transaction_commit
  end
end

if defined?(ActiveRecord::ConnectionAdapters::SQLiteAdapter)
  ActiveRecord::ConnectionAdapters::SQLiteAdapter.class_eval do
    alias_method_chain :commit_db_transaction, :callbacks
    alias_method_chain :rollback_db_transaction, :callbacks
  end
end

if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
    def func(name, *args)
      case name
        when :group_concat
          "group_concat(#{func_arg_esc(args.first)} SEPARATOR #{quote(args[1] || ',')})"
        else
          super
      end
    end

    alias_method_chain :commit_db_transaction, :callbacks
    alias_method_chain :rollback_db_transaction, :callbacks
  end
end
if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
    def func(name, *args)
      case name
        when :group_concat
          "string_agg((#{func_arg_esc(args.first)})::text, #{quote(args[1] || ',')})"
        else
          super
      end
    end

    def group_by(*columns)
      # although postgres 9.1 lets you omit columns that are functionally
      # dependent on the primary keys, that's only true if the FROM items are
      # all tables (i.e. not subselects). to keep things simple, we always
      # specify all columns for postgres
      columns.flatten.join(', ')
    end

    alias_method_chain :commit_db_transaction, :callbacks
    alias_method_chain :rollback_db_transaction, :callbacks
  end
end

class ActiveRecord::Migration
  class << self
    def transactional?
      @transactional != false
    end
    def transactional=(value)
      @transactional = !!value
    end

    def tag(*tags)
      raise "invalid tags #{tags.inspect}" unless tags - [:predeploy, :postdeploy] == []
      (@tags ||= []).concat(tags).uniq!
    end

    def tags
      @tags ||= []
    end
  end

  def transactional?
    connection.supports_ddl_transactions? && self.class.transactional?
  end

  def tags
    self.class.tags
  end
end

class ActiveRecord::MigrationProxy
  delegate :connection, :transactional?, :tags, :to => :migration

  def load_migration
    load(filename)
    @migration = name.constantize
    raise "#{self.name} (#{self.version}) is not tagged as predeploy or postdeploy!" if @migration.tags.empty? && self.version > 20120217214153
    @migration
  end
end

class ActiveRecord::Migrator
  def self.migrations_paths
    @@migration_paths ||= [migrations_path]
  end

  def migrations
    @@migrations ||= begin
      files = self.class.migrations_paths.map { |p| Dir["#{p}/[0-9]*_*.rb"] }.flatten

      migrations = files.inject([]) do |klasses, file|
        version, name = file.scan(/([0-9]+)_([_a-z0-9]*).rb/).first

        raise ActiveRecord::IllegalMigrationNameError.new(file) unless version
        version = version.to_i

        if klasses.detect { |m| m.version == version }
          raise ActiveRecord::DuplicateMigrationVersionError.new(version)
        end

        if klasses.detect { |m| m.name == name.camelize }
          raise ActiveRecord::DuplicateMigrationNameError.new(name.camelize)
        end

        klasses << (ActiveRecord::MigrationProxy.new).tap do |migration|
          migration.name     = name.camelize
          migration.version  = version
          migration.filename = file
        end
      end

      migrations = migrations.sort_by(&:version)
      down? ? migrations.reverse : migrations
    end
  end

  def migrate(tag = nil)
    current = migrations.detect { |m| m.version == current_version }
    target = migrations.detect { |m| m.version == @target_version }

    if target.nil? && !@target_version.nil? && @target_version > 0
      raise UnknownMigrationVersionError.new(@target_version)
    end

    start = up? ? 0 : (migrations.index(current) || 0)
    finish = migrations.index(target) || migrations.size - 1
    runnable = migrations[start..finish]

    # skip the last migration if we're headed down, but not ALL the way down
    runnable.pop if down? && !target.nil?

    runnable.each do |migration|
      ActiveRecord::Base.logger.info "Migrating to #{migration.name} (#{migration.version})"

      # On our way up, we skip migrating the ones we've already migrated
      next if up? && migrated.include?(migration.version.to_i)

      # On our way down, we skip reverting the ones we've never migrated
      if down? && !migrated.include?(migration.version.to_i)
        migration.announce 'never migrated, skipping'; migration.write
        next
      end

      next if !tag.nil? && !migration.tags.include?(tag)

      begin
        ddl_transaction(migration) do
          migration.migrate(@direction)
          record_version_state_after_migrating(migration.version) unless tag == :predeploy && migration.tags.include?(:postdeploy)
        end
      rescue => e
        canceled_msg = migration.transactional? ? "this and " : ""
        raise StandardError, "An error has occurred, #{canceled_msg}all later migrations canceled:\n\n#{e}", e.backtrace
      end
    end
  end

  def ddl_transaction(migration)
    if migration.transactional?
      migration.connection.transaction { yield }
    else
      yield
    end
  end
end

ActiveRecord::Migrator.migrations_paths.concat Dir[Rails.root.join('vendor', 'plugins', '*', 'db', 'migrate')]
ActiveRecord::ConnectionAdapters::SchemaStatements.class_eval do
  def add_index_with_length_raise(table_name, column_name, options = {})
    unless options[:name].to_s =~ /^temp_/
      column_names = Array(column_name)
      index_name = index_name(table_name, :column => column_names)
      index_name = options[:name].to_s if options[:name]
      if index_name.length > index_name_length
        raise(ArgumentError, "Index name '#{index_name}' on table '#{table_name}' is too long; the limit is #{index_name_length} characters.")
      end
      if index_exists?(table_name, index_name, false)
        raise(ArgumentError, "Index name '#{index_name}' on table '#{table_name}' already exists.")
      end
    end
    add_index_without_length_raise(table_name, column_name, options)
  end
  alias_method_chain :add_index, :length_raise
end
