class ActiveRecord::Base
  # XXX: Rails3 There are lots of issues with these patches in Rails3 still

  extend ActiveSupport::Memoizable # used for a lot of the reporting queries

  if Rails.version < "3.0"
    # this functionality is built into rails 3
    class ProtectedAttributeAssigned < Exception; end
    def log_protected_attribute_removal_with_raise(*attributes)
      if Canvas.protected_attribute_error == :raise
        raise ProtectedAttributeAssigned, "Can't mass-assign these protected attributes for class #{self.class.name}: #{attributes.join(', ')}"
      else
        log_protected_attribute_removal_without_raise(*attributes)
      end
    end
    alias_method_chain :log_protected_attribute_removal, :raise
  end

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

  def self.all_models
    return @all_models if @all_models.present?
    @all_models = (ActiveRecord::Base.send(:subclasses) +
                   ActiveRecord::Base.models_from_files +
                   [Version]).compact.uniq.reject { |model|
      model.superclass != ActiveRecord::Base || (model.respond_to?(:tableless?) && model.tableless?)
    }
  end

  def self.models_from_files
    @from_files ||= Dir[
      "#{Rails.root}/app/models/*",
      "#{Rails.root}/vendor/plugins/*/app/models/*"
    ].collect { |file|
      model = File.basename(file, ".*").camelize.constantize
      next unless model < ActiveRecord::Base
      model
    }
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
      next result if asset_types && !asset_types.include?(klass)
      result.concat((klass.constantize.find_all_by_id(id_pairs.map(&:last)) rescue []))
    end
  end

  # takes an asset string list, like "course_5,user_7" and turns it into an
  # array of [class_name, id] like [ ["Course", 5], ["User", 7] ]
  def self.parse_asset_string_list(asset_string_list)
    asset_string_list.to_s.split(",").map { |str| parse_asset_string(str) }
  end

  def self.parse_asset_string(str)
    code = asset_string_components(str)
    [code.first.classify, code.last.try(:to_i)]
  end

  def self.asset_string_components(str)
    components = str.split('_', -1)
    id = components.pop
    [components.join('_'), id.presence]
  end

  def self.initialize_by_asset_string(string, asset_types)
    type, id = asset_string_components(string)
    res = type.classify.constantize rescue nil
    res.id = id if res
    res
  end

  def asset_string
    @asset_string ||= {}
    @asset_string[Shard.current] ||= "#{self.class.base_ar_class.name.underscore}_#{id}"
  end

  def global_asset_string
    @global_asset_string ||= "#{self.class.base_ar_class.name.underscore}_#{global_id}"
  end

  # little helper to keep checks concise and avoid a db lookup
  def has_asset?(asset, field = :context)
    asset.id == send("#{field}_id") && asset.class.base_ar_class.name == send("#{field}_type")
  end

  def context_string(field = :context)
    send("#{field}_type").underscore + "_" + send("#{field}_id").to_s if send("#{field}_type")
  end

  def self.define_asset_string_backcompat_method(string_version_name, association_version_name = string_version_name, method = nil)
    # just chain to the two methods
    unless method
      # this is weird, but gets the instance methods defined so they can be chained
      begin
        self.new.send("#{association_version_name}_id")
      rescue
        # the db doesn't exist yet; no need to bother with backcompat methods anyway
        return
      end
      define_asset_string_backcompat_method(string_version_name, association_version_name, 'id')
      define_asset_string_backcompat_method(string_version_name, association_version_name, 'type')
      return
    end

    self.class_eval <<-CODE
      def #{association_version_name}_#{method}_with_backcompat
        res = #{association_version_name}_#{method}_without_backcompat
        if !res && #{string_version_name}.present?
          type, id = ActiveRecord::Base.parse_asset_string(#{string_version_name})
          write_attribute(:#{association_version_name}_type, type)
          write_attribute(:#{association_version_name}_id, id)
          res = #{association_version_name}_#{method}_without_backcompat
        end
        res
      end
    CODE
    self.alias_method_chain "#{association_version_name}_#{method}".to_sym, :backcompat
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
    @@cached_contexts = nil if Rails.env.test?
    @@cached_contexts ||= {}
    context_key = "#{self.context_type}_#{self.context_id}" if self.respond_to?(:context_type)
    context_key ||= "Course_#{self.course_id}"
    @@cached_contexts[context_key] ||= self.context if self.respond_to?(:context)
    @@cached_contexts[context_key] ||= self.course
    @@cached_permissions ||= {}
    key = [context_key, (user ? user.id : nil)].cache_key
    @@cached_permissions[key] = nil if Rails.env.test?
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
      shard = self.user.shard
      User.update_all({ :updated_at => Time.now.utc }, { :id => self.user_id })
      User.connection.after_transaction_commit do
        shard.activate do
          User.update_all({ :updated_at => Time.now.utc }, { :id => self.user_id })
        end if shard != Shard.current
        User.invalidate_cache(self.user_id)
      end
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

    value = wildcard_pattern(value, options)
    cols = args.map{ |col| like_condition(col, '?', !options[:case_sensitive]) }
    sanitize_sql_array ["(" + cols.join(" OR ") + ")", *([value] * cols.size)]
  end

  def self.wildcard_pattern(value, options = {})
    value = value.to_s
    value = value.downcase unless options[:case_sensitive]
    value = value.gsub('\\', '\\\\\\\\').gsub('%', '\\%').gsub('_', '\\_')
    value = '%' + value unless options[:type] == :right
    value += '%' unless options[:type] == :left
    value
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

  def self.init_icu
    return if defined?(@icu)
    begin
      Bundler.require 'icu'
      if !ICU::Lib.respond_to?(:ucol_getRules)
        suffix = ICU::Lib.figure_suffix(ICU::Lib.version.to_s)
        ICU::Lib.attach_function(:ucol_getRules, "ucol_getRules#{suffix}", [:pointer, :pointer], :pointer)
        ICU::Collation::Collator.class_eval do
          def rules
            length = FFI::MemoryPointer.new(:int)
            ptr = ICU::Lib.ucol_getRules(@c, length)
            ptr.read_array_of_uint16(length.read_int).pack("U*")
          end
        end
      end
      @icu = true
      @collation_local_map = {}
    rescue LoadError
      @icu = false
    end
  end

  def self.best_unicode_collation_key(col)
    if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'postgresql'
      # For PostgreSQL, we can't trust a simple LOWER(column), with any collation, since
      # Postgres just defers to the C library which is different for each platform. The best
      # choice is the collkey function from pg_collkey which uses ICU to get a full unicode sort.
      # If that extension isn't around, casting to a bytea sucks for international characters,
      # but at least it's consistent, and orders commas before letters so you don't end up with
      # Johnson, Bob sorting before Johns, Jimmy
      @collkey ||= connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i
      if @collkey == 0
        "CAST(LOWER(replace(#{col}, '\\', '\\\\')) AS bytea)"
      else
        locale = 'root'
        init_icu
        if @icu
          # only use the actual locale if it differs from root; using a different locale means we
          # can't use our index, which usually doesn't matter, but sometimes is very important
          locale = @collation_local_map[I18n.locale] ||= ICU::Collation::Collator.new(I18n.locale.to_s).rules.empty? ? 'root' : I18n.locale
        end

        "collkey(#{col}, '#{locale}', true, 2, true)"
      end
    else
      # Not yet optimized for other dbs (MySQL's default collation is case insensitive;
      # SQLite can have custom collations inserted, but probably not worth the effort
      # since no one will actually use SQLite in a production install of Canvas)
      col
    end
  end

  def self.count_by_date(options = {})
    column = options[:column] || "created_at"
    max_date = (options[:max_date] || Time.zone.now).midnight
    num_days = options[:num_days] || 20
    min_date = (options[:min_date] || max_date.advance(:days => -(num_days-1))).midnight

    # if the db can't do (named) timezones, we do the best we can (dates on the
    # other side of dst will be wrong though)
    offset = max_date.utc_offset

    expression = case connection.adapter_name
    when 'MySQL', 'Mysql2'
      # TODO: detect mysql named timezone support and use it
      offset = "%s%02d:%02d" % [offset < 0 ? "-" : "+", offset.abs / 3600, offset.abs % 3600]
      "DATE(CONVERT_TZ(#{column}, '+00:00', '#{offset}'))"
    when /sqlite/
      "DATE(STRFTIME('%s', #{column}) + #{offset}, 'unixepoch')"
    when 'PostgreSQL'
      "(#{column} AT TIME ZONE '#{Time.zone.tzinfo.name}')::DATE"
    end

    result = count(
      :conditions => [
        "#{column} >= ? AND #{column} < ?",
        min_date,
        max_date.advance(:days => 1)
      ],
      :group => expression,
      :order => expression
    )
    # mysql gives us date keys, sqlite/postgres don't 
    return result if result.keys.first.is_a?(Date)
    Hash[result.map { |date, count|
      [Time.zone.parse(date).to_date, count]
    }]
  end

  class DynamicFinderTypeError < Exception; end
  class << self
    def construct_attributes_from_arguments_with_type_cast(attribute_names, arguments)
      log_dynamic_finder_nil_arguments(attribute_names) if current_scoped_methods.nil? && arguments.flatten.compact.empty?
      construct_attributes_from_arguments_without_type_cast(attribute_names, arguments)
    end
    alias_method_chain :construct_attributes_from_arguments, :type_cast

    def log_dynamic_finder_nil_arguments(attribute_names)
      error = "No non-nil arguments passed to #{self.base_class}.find_by_#{attribute_names.join('_and_')}"
      raise DynamicFinderTypeError, error if Canvas.dynamic_finder_nil_arguments_error == :raise
      logger.debug "WARNING: " + error
    end
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
    raise "distinct on columns must match the leftmost part of the order-by clause" unless options[:order] && options[:order] =~ /\A#{Array(columns).map{ |c| Regexp.escape(c) }.join(' *(?:asc|desc)?, *')}/i

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

    result = if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'postgresql'
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

  def self.find_in_batches_with_usefulness(options = {}, &block)
    # already in a transaction (or transactions don't matter); cursor is fine
    if connection.adapter_name == 'PostgreSQL' && (Shackles.environment == :slave || connection.open_transactions > 0)
      shard = scope(:find, :shard)
      if shard
        shard.activate(shard_category) { find_in_batches_with_cursor(options, &block) }
      else
        find_in_batches_with_cursor(options, &block)
      end
    elsif scope(:find, :order) || scope(:find, :group)
      options[:transactional] = false
      shard = scope(:find, :shard)
      if shard
        shard.activate(:shard_category) { find_in_batches_with_temp_table(options, &block) }
      else
        find_in_batches_with_temp_table(options, &block)
      end
    else
      find_in_batches_without_usefulness(options) do |batch|
        with_exclusive_scope { yield batch }
      end
    end
  end
  class << self
    alias_method_chain :find_in_batches, :usefulness
  end

  def self.find_in_batches_with_cursor(options = {}, &block)
    batch_size = options[:batch_size] || 1000
    transaction do
      begin
        cursor = "#{table_name}_in_batches_cursor"
        connection.execute("DECLARE #{cursor} CURSOR FOR #{scoped.to_sql}")
        includes = scope(:find, :include)
        with_exclusive_scope do
          batch = connection.uncached { find_by_sql("FETCH FORWARD #{batch_size} FROM #{cursor}") }
          while !batch.empty?
            preload_associations(batch, includes) if includes
            yield batch
            break if batch.size < batch_size
            batch = connection.uncached { find_by_sql("FETCH FORWARD #{batch_size} FROM #{cursor}") }
          end
        end
        # not ensure; if the transaction rolls back to due another exception, it will
        # automatically close
        connection.execute("CLOSE #{cursor}")
      end
    end
  end

  def self.generate_temp_table(options = {})
    Canvas::TempTable.new(connection, construct_finder_sql({}), options)
  end

  def self.find_in_batches_with_temp_table(options = {}, &block)
    temptable = generate_temp_table(options)
    with_exclusive_scope do
      temptable.execute do |table|
        table.find_in_batches(self, options, &block)
      end
    end
  end

  def self.find_each_with_temp_table(options = {}, &block)
    find_in_batches_with_temp_table(options.merge(ar_objects: false)) do |batch|
      batch.each(&block)
    end
    self
  end

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
      next if method_defined?(specific.to_sym)
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
      error.message.match(/PG(?:::)?Error: ERROR: +duplicate key value violates unique constraint|Mysql2?::Error: Duplicate entry .* for key|SQLite3::ConstraintException: columns .* not unique/)
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
  def self.find_ids_in_ranges(options = {})
    batch_size = options[:batch_size].try(:to_i) || 1000

    ids = connection.select_rows("select min(id), max(id) from (#{self.send(:construct_finder_sql, :select => "#{quoted_table_name}.#{primary_key} as id", :order => primary_key, :limit => batch_size)}) as subquery").first
    while ids.first.present?
      yield(*ids)
      last_value = ids.last
      ids = connection.select_rows("select min(id), max(id) from (#{self.send(:construct_finder_sql, :select => "#{quoted_table_name}.#{primary_key} as id", :conditions => ["#{quoted_table_name}.#{primary_key}>?", last_value], :order => primary_key, :limit => batch_size)}) as subquery").first
    end
  end

  class << self
    def deconstruct_joins
      joins_sql = ''
      add_joins!(joins_sql, nil)
      tables = []
      join_conditions = []
      joins_sql.strip.split('INNER JOIN')[1..-1].each do |join|
        # this could probably be improved
        raise "PostgreSQL update_all/delete_all only supports INNER JOIN" unless join.strip =~ /([a-zA-Z'"_]+)\s+ON\s+(.*)/
        tables << $1
        join_conditions << $2
      end
      [tables, join_conditions]
    end

    def update_all_with_joins(updates, conditions = nil, options = {})
      scope = scope(:find)
      if scope && scope[:joins]
        case connection.adapter_name
        when 'PostgreSQL'
          sql  = "UPDATE #{quoted_table_name} SET #{sanitize_sql_for_assignment(updates)} "

          tables, join_conditions = deconstruct_joins

          unless tables.empty?
            sql.concat('FROM ')
            sql.concat(tables.join(', '))
            sql.concat(' ')
          end

          conditions = merge_conditions(conditions, *join_conditions)
        when 'MySQL', 'Mysql2'
          sql  = "UPDATE #{quoted_table_name}"
          add_joins!(sql, nil, scope)
          sql << " SET "
          # can't just use sanitize_sql_for_assignment cause MySQL supports
          # updating multiple tables in a single statement, so we have to
          # qualify the column names
          sql << case updates
             when Array
               sanitize_sql_array(updates)
             when Hash;
               updates.map do |attr, value|
                 "#{quoted_table_name}.#{connection.quote_column_name(attr)} = #{quote_bound_value(value)}"
               end.join(', ')
             else
               updates
             end << " "
        else
          raise "Joins in update not supported!"
        end
        select_sql = ""
        add_conditions!(select_sql, conditions, scope)

        if options.has_key?(:limit) || (scope && scope[:limit])
          # Only take order from scope if limit is also provided by scope, this
          # is useful for updating a has_many association with a limit.
          add_order!(select_sql, options[:order], scope)

          add_limit!(select_sql, options, scope)
          sql.concat(connection.limited_update_conditions(select_sql, quoted_table_name, connection.quote_column_name(primary_key)))
        else
          add_order!(select_sql, options[:order], nil)
          sql.concat(select_sql)
        end

        return connection.update(sql, "#{name} Update")
      end
      update_all_without_joins(updates, conditions, options)
    end
    alias_method_chain :update_all, :joins

    def delete_all_with_joins(conditions = nil)
      scope = scope(:find)
      if scope && scope[:joins]
        case connection.adapter_name
        when 'PostgreSQL'
          sql = "DELETE FROM #{quoted_table_name} "

          tables, join_conditions = deconstruct_joins

          sql.concat('USING ')
          sql.concat(tables.join(', '))
          sql.concat(' ')

          conditions = merge_conditions(conditions, *join_conditions)
        when 'MySQL', 'Mysql2'
          sql = "DELETE #{quoted_table_name} FROM #{quoted_table_name}"
          add_joins!(sql, nil, scope)
        else
          raise "Joins in delete not supported!"
        end
        add_conditions!(sql, conditions, scope)
        return connection.delete(sql, "#{name} Delete all")
      end
      delete_all_without_joins(conditions)
    end
    alias_method_chain :delete_all, :joins
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
    # the first item should be the primary key(s) that the other columns are
    # functionally dependent on. alternatively, it can be a class, and all
    # columns will be inferred from it. this is useful for cases where you want
    # to select all columns from one table, and an aggregate from another.
    Array(infer_group_by_columns(columns).first).join(", ")
  end

  def infer_group_by_columns(columns)
    columns.map { |col|
      col.respond_to?(:columns) ?
          col.columns.map { |c|
            "#{col.quoted_table_name}.#{quote_column_name(c.name)}"
          } :
          col
    }
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

module MySQLAdapterExtensions
  def self.included(klass)
    klass::NATIVE_DATABASE_TYPES[:primary_key] = "bigint DEFAULT NULL auto_increment PRIMARY KEY".freeze
    klass.alias_method_chain :add_column, :foreign_key_check
    klass.alias_method_chain :configure_connection, :pg_compat
    klass.alias_method_chain :commit_db_transaction, :callbacks
    klass.alias_method_chain :rollback_db_transaction, :callbacks
  end

  def bulk_insert(table_name, records)
    return if records.empty?
    transaction do
      keys = records.first.keys
      quoted_keys = keys.map{ |k| quote_column_name(k) }.join(', ')
      execute "INSERT INTO #{quote_table_name(table_name)} (#{quoted_keys}) VALUES" <<
                  records.map{ |record| "(#{keys.map{ |k| quote(record[k]) }.join(', ')})" }.join(',')
    end
  end

  def add_column_with_foreign_key_check(table, name, type, options = {})
    Canvas.active_record_foreign_key_check(name, type, options)
    add_column_without_foreign_key_check(table, name, type, options)
  end

  def configure_connection_with_pg_compat
    configure_connection_without_pg_compat
    execute "SET SESSION SQL_MODE='PIPES_AS_CONCAT'"
  end

  def func(name, *args)
    case name
      when :group_concat
        "group_concat(#{func_arg_esc(args.first)} SEPARATOR #{quote(args[1] || ',')})"
      else
        super
    end
  end
end

if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  ActiveRecord::ConnectionAdapters::MysqlAdapter.send(:include, MySQLAdapterExtensions)
end
if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
  ActiveRecord::ConnectionAdapters::Mysql2Adapter.send(:include, MySQLAdapterExtensions)
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
      # pointless if we're in a transaction
      options.delete(:delay_validation) if open_transactions > 0
      column  = options[:column] || "#{to_table.to_s.singularize}_id"
      foreign_key_name = foreign_key_name(from_table, column, options)

      if options[:delay_validation]
        options[:options] = 'NOT VALID'
        # NOT VALID doesn't fully work through 9.3 at least, so prime the cache to make
        # it as fast as possible. Note that a NOT EXISTS would be faster, but this is
        # the query postgres does for the VALIDATE CONSTRAINT, so we want exactly this
        # query to be warm
        execute("SELECT fk.#{column} FROM #{from_table} fk LEFT OUTER JOIN #{to_table} pk ON fk.#{column}=pk.id WHERE pk.id IS NULL AND fk.#{column} IS NOT NULL LIMIT 1")
      end

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
        concurrently = "CONCURRENTLY " if options[:concurrently] && self.open_transactions == 0
        conditions = options[:conditions]
        if conditions
          conditions = " WHERE #{ActiveRecord::Base.send(:sanitize_sql, conditions, table_name.to_s.dup)}"
        end
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

      execute "CREATE #{index_type} INDEX #{concurrently}#{quote_column_name(index_name)} ON #{quote_table_name(table_name)} (#{quoted_column_names})#{conditions}"
    end

    def set_standard_conforming_strings_with_version_check
      set_standard_conforming_strings_without_version_check unless postgresql_version >= 90100
    end
    alias_method_chain :set_standard_conforming_strings, :version_check
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

if defined?(ActiveRecord::ConnectionAdapters::SQLiteAdapter)
  ActiveRecord::ConnectionAdapters::SQLiteAdapter.class_eval do
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
      infer_group_by_columns(columns).flatten.join(', ')
    end

    alias_method_chain :commit_db_transaction, :callbacks
    alias_method_chain :rollback_db_transaction, :callbacks
  end
end

class ActiveRecord::Migration
  VALID_TAGS = [:predeploy, :postdeploy, :cassandra]
  # at least one of these tags is required
  DEPLOY_TAGS = [:predeploy, :postdeploy]

  class << self
    def transactional?
      @transactional != false
    end
    def transactional=(value)
      @transactional = !!value
    end

    def tag(*tags)
      raise "invalid tags #{tags.inspect}" unless tags - VALID_TAGS == []
      (@tags ||= []).concat(tags).uniq!
    end

    def tags
      @tags ||= []
    end

    def is_postgres?
      connection.adapter_name == 'PostgreSQL'
    end

    def has_postgres_proc?(procname)
      connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='#{procname}'").to_i != 0
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

  def runnable?
    !migration.respond_to?(:runnable?) || migration.runnable?
  end

  def load_migration
    load(filename)
    @migration = name.constantize
    raise "#{self.name} (#{self.version}) is not tagged as predeploy or postdeploy!" if (@migration.tags & ActiveRecord::Migration::DEPLOY_TAGS).empty? && self.version > 20120217214153
    @migration
  end
end

class ActiveRecord::Migrator
  def self.migrations_paths
    @@migration_paths ||= []
  end

  def migrations
    @@migrations ||= begin
      files = ([@migrations_path].compact + self.class.migrations_paths).uniq.
        map { |p| Dir["#{p}/[0-9]*_*.rb"] }.flatten

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

  def pending_migrations_with_runnable
    pending_migrations_without_runnable.reject { |m| !m.runnable? }
  end
  alias_method_chain :pending_migrations, :runnable

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
      next if !migration.runnable?

      begin
        if down? && !Rails.env.test? && !$confirmed_migrate_down
          require 'highline'
          if HighLine.new.ask("Revert migration #{migration.name} (#{migration.version}) ? [y/N/a] > ") !~ /^([ya])/i
            raise("Revert not confirmed")
          end
          $confirmed_migrate_down = true if $1.downcase == 'a'
        end

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

  # in anticipation of having to re-run migrations due to integrity violations or
  # killing stuff that is holding locks too long
  def add_foreign_key_if_not_exists(from_table, to_table, options = {})
    column  = options[:column] || "#{to_table.to_s.singularize}_id"
    case self.adapter_name
    when 'SQLite'; return
    when 'PostgreSQL'
      foreign_key_name = foreign_key_name(from_table, column, options)
      and_valid = " AND convalidated" if supports_delayed_constraint_validation?
      return if select_value("SELECT conname FROM pg_constraint INNER JOIN pg_namespace ON pg_namespace.oid=connamespace WHERE conname='#{foreign_key_name}' AND nspname=current_schema()#{and_valid}")
      add_foreign_key(from_table, to_table, options)
    else
      foreign_key_name = foreign_key_name(from_table, column, options)
      return if foreign_keys(from_table).find { |k| k.options[:name] == foreign_key_name }
      add_foreign_key(from_table, to_table, options)
    end
  end

  def remove_foreign_key_if_exists(table, options = {})
    begin
      remove_foreign_key(table, options)
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message =~ /PG(?:::)?Error: ERROR:.+does not exist|Mysql2?::Error: Error on rename/
    end
  end
end
