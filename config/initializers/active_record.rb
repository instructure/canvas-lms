require 'active_support/callbacks/suspension'

class ActiveRecord::Base
  # XXX: Rails3 There are lots of issues with these patches in Rails3 still

  unless CANVAS_RAILS2
    class << self
      def preload_associations(records, associations, preload_options={})
        ActiveRecord::Associations::Preloader.new(records, associations, preload_options).run
      end
    end

    def write_attribute(*args)
      value = super
      value.is_a?(ActiveRecord::AttributeMethods::Serialization::Attribute) ? value.value : value
    end

    alias :clone :dup

    def serializable_hash(options = nil)
      if options && options[:include_root]
        {self.class.base_ar_class.model_name.element => super(options)}
      else
        super
      end
    end

    # See ActiveModel#serializable_add_includes
    def serializable_add_includes(options = {}, &block)
      super(options) do |association, records, opts|
        yield association, records, opts.reverse_merge(:include_root => options[:include_root])
      end
    end
  end

  if CANVAS_RAILS2
    if instance_method(:transaction).arity == 0
      def transaction(options = {}, &block)
        self.class.transaction(options, &block)
      end
    end

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
    "#{self.class.reflection_type_name}_#{id.to_s}"
  end

  def self.all_models
    return @all_models if @all_models.present?
    @all_models = (ActiveRecord::Base.send(:subclasses) +
                   ActiveRecord::Base.models_from_files +
                   [Version]).compact.uniq.reject { |model|
      !(model.superclass == ActiveRecord::Base || model.superclass.abstract_class?) ||
      (model.respond_to?(:tableless?) && model.tableless?) ||
      model.abstract_class?
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
    @asset_string[Shard.current] ||= "#{self.class.reflection_type_name}_#{id}"
  end

  def global_asset_string
    @global_asset_string ||= "#{self.class.reflection_type_name}_#{global_id}"
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
    except.concat(self.serialization_excludes) if self.respond_to?(:serialization_excludes)
    except.uniq!

    methods = options.delete(:methods) || []
    methods = Array(methods)
    methods.concat(self.class.serialization_methods) if self.class.respond_to?(:serialization_methods)
    methods.concat(self.serialization_methods) if self.respond_to?(:serialization_methods)
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

    hash = CANVAS_RAILS2 ? Serializer.new(self, options).serializable_record : serializable_hash(options)

    if options[:permissions]
      obj_hash = options[:include_root] ? hash[self.class.base_ar_class.model_name.element] : hash
      if self.respond_to?(:filter_attributes_for_user)
        self.filter_attributes_for_user(obj_hash, options[:permissions][:user], options[:permissions][:session])
      end
      unless options[:permissions][:include_permissions] == false
        permissions_hash = self.grants_rights?(options[:permissions][:user], options[:permissions][:session], *options[:permissions][:policies])
        if self.respond_to?(:serialize_permissions)
          permissions_hash = self.serialize_permissions(permissions_hash, options[:permissions][:user], options[:permissions][:session])
        end
        obj_hash["permissions"] = permissions_hash
      end
    end

    self.revert_from_serialization_options if self.respond_to?(:revert_from_serialization_options)

    hash.with_indifferent_access
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

  def self.reflection_type_name
    base_ar_class.name.underscore
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
        "collkey(#{col}, '#{Canvas::ICU.locale_for_collation}', false, 0, true)"
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
      "((#{column} || '-00')::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.tzinfo.name}')::DATE"
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
    columns = Array(columns)
    bad_options = options.keys - [:select, :order]
    if bad_options.present?
      # while it's possible to make this work with :limit, it would be gross
      # for non-native, so we don't allow it
      raise "can't use #{bad_options.join(', ')} with distinct on"
    end

    native = (connection.adapter_name == 'PostgreSQL')
    options[:select] = "DISTINCT ON (#{columns.join(', ')}) " + (options[:select] || '*') if native
    raise "distinct on columns must match the leftmost part of the order-by clause" unless options[:order] && options[:order] =~ /\A#{columns.map{ |c| Regexp.escape(c) }.join(' *(?:asc|desc)?, *')}/i

    scope = self
    scope = scope.select(options[:select]) if options[:select]
    scope = scope.order(options[:order]) if options[:order]
    result = scope.all

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

  # direction is nil, :asc, or :desc
  def self.nulls(first_or_last, column, direction = nil)
    if connection.adapter_name == 'PostgreSQL'
      clause = if first_or_last == :first && direction != :desc
                 " NULLS FIRST"
               elsif first_or_last == :last && direction == :desc
                 " NULLS LAST"
               end
      "#{column} #{direction.to_s.upcase}#{clause}".strip
    else
      "#{column} IS#{" NOT" unless first_or_last == :last} NULL, #{column} #{direction.to_s.upcase}".strip
    end
  end

  if CANVAS_RAILS2
  def self.find_in_batches_with_usefulness(options = {}, &block)
    # already in a transaction (or transactions don't matter); cursor is fine
    if (connection.adapter_name == 'PostgreSQL' && (Shackles.environment == :slave || connection.open_transactions > (Rails.env.test? ? 1 : 0))) && !options[:start]
      shard = scope(:find, :shard)
      if shard
        shard.activate(shard_category) { find_in_batches_with_cursor(options, &block) }
      else
        find_in_batches_with_cursor(options, &block)
      end
    elsif scope(:find, :order) || scope(:find, :group) || scope(:find, :select).to_s =~ /DISTINCT/i
      raise ArgumentError.new("GROUP and ORDER are incompatible with :start") if options[:start]
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
        scope = scope(:find)
        scope = scope ? scope.dup : {}
        scope.delete(:include)
        sql = with_exclusive_scope(find: scope) { scoped.to_sql }
        cursor = "#{table_name}_in_batches_cursor_#{sql.hash.abs.to_s(36)}"
        connection.execute("DECLARE #{cursor} CURSOR FOR #{sql}")
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
        # not ensure; if the transaction rolls back due to another exception, it will
        # automatically close
        connection.execute("CLOSE #{cursor}")
      end
    end
  end

  def self.find_in_batches_with_temp_table(options = {})
    batch_size = options[:batch_size] || 1000
    table = "#{table_name}_find_in_batches_temporary_table"
    scope = scope(:find)
    scope = scope ? scope.dup : {}
    scope.delete(:include)
    sql = with_exclusive_scope(find: scope) { scoped.to_sql }
    if %w{MySQL Mysql2}.include?(connection.adapter_name)
      table_options = " (temp_primary_key MEDIUMINT NOT NULL AUTO_INCREMENT PRIMARY KEY)"
    end
    connection.execute "CREATE TEMPORARY TABLE #{table}#{table_options} AS #{sql}"
    begin
      index = "temp_primary_key"
      case connection.adapter_name
      when 'PostgreSQL'
        begin
          old_proc = connection.raw_connection.set_notice_processor {}
          connection.execute "ALTER TABLE #{table}
                               ADD temp_primary_key SERIAL PRIMARY KEY"
        ensure
          connection.raw_connection.set_notice_processor(&old_proc) if old_proc
        end
      when 'MySQL', 'Mysql2'
        # created as part of the temp table
      when 'SQLite'
        # Sqlite always has an implicit primary key
        index = 'rowid'
      else
        raise "Temp tables not supported!"
      end

      includes = scope(:find, :include)
      sql = "SELECT *
             FROM #{table}
             ORDER BY #{index} ASC
             LIMIT #{batch_size}"
      with_exclusive_scope do
        batch = find_by_sql(sql)
        while !batch.empty?
          preload_associations(batch, includes) if includes
          yield batch
          break if batch.size < batch_size
          last_value = batch.last[index]

          sql = "SELECT *
               FROM #{table}
               WHERE #{index} > #{last_value}
               ORDER BY #{index} ASC
               LIMIT #{batch_size}"
          batch = find_by_sql(sql)
        end
      end
    ensure
      temporary = "TEMPORARY " if connection.adapter_name == 'Mysql2'
      connection.execute "DROP #{temporary}TABLE #{table}"
    end
  end
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
        result = transaction(:requires_new => true) { uncached { yield } }
        connection.clear_query_cache
        return result
      rescue UniqueConstraintViolation
      end
    end
    result = transaction(:requires_new => true) { uncached { yield } }
    connection.clear_query_cache
    result
  end

  # returns batch_size ids at a time, working through the primary key from
  # smallest to largest.
  #
  # note this does a raw connection.select_values, so it doesn't work with scopes
  def self.find_ids_in_batches(options = {})
    batch_size = options[:batch_size] || 1000
    if CANVAS_RAILS2
      scope = scope(:find) || {}
      scope[:select] = primary_key
      scope[:order] = primary_key
      scope[:limit] = batch_size
      ids = nil
      with_exclusive_scope(find: scope) do
        ids = connection.select_values(scoped.to_sql)
      end
    else
      scope = except(:select).select(primary_key).reorder(primary_key).limit(batch_size)
      ids = connection.select_values(scope.to_sql)
    end
    ids = ids.map(&:to_i) unless options[:no_integer_cast]
    while ids.present?
      yield ids
      break if ids.size < batch_size
      last_value = ids.last
      if CANVAS_RAILS2
        with_exclusive_scope(find: scope) do
          ids = connection.select_values(where("#{primary_key}>?", last_value).to_sql)
        end
      else
        ids = connection.select_values(scope.where("#{primary_key}>?", last_value).to_sql)
      end
      ids = ids.map(&:to_i) unless options[:no_integer_cast]
    end
  end

  # returns 2 ids at a time (the min and the max of a range), working through
  # the primary key from smallest to largest.
  def self.find_ids_in_ranges(options = {})
    batch_size = options[:batch_size].try(:to_i) || 1000
    subquery_scope = self.scoped.except(:select).select("#{quoted_table_name}.#{primary_key} as id").reorder(primary_key).limit(batch_size)
    ids = connection.select_rows("select min(id), max(id) from (#{subquery_scope.to_sql}) as subquery").first
    while ids.first.present?
      ids.map!(&:to_i) if columns_hash[primary_key.to_s].type == :integer
      yield(*ids)
      last_value = ids.last
      next_subquery_scope = subquery_scope.where(["#{quoted_table_name}.#{primary_key}>?", last_value])
      ids = connection.select_rows("select min(id), max(id) from (#{next_subquery_scope.to_sql}) as subquery").first
    end
  end

  class << self
    def deconstruct_joins(joins_sql=nil)
      unless joins_sql
        joins_sql = ''
        add_joins!(joins_sql, nil)
      end
      tables = []
      join_conditions = []
      joins_sql.strip.split('INNER JOIN')[1..-1].each do |join|
        # this could probably be improved
        raise "PostgreSQL update_all/delete_all only supports INNER JOIN" unless join.strip =~ /([a-zA-Z0-9'"_]+(?:(?:\s+[aA][sS])?\s+[a-zA-Z0-9'"_]+)?)\s+ON\s+(.*)/
        tables << $1
        join_conditions << $2
      end
      [tables, join_conditions]
    end

    if CANVAS_RAILS2
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

    def delete_all_with_limit(conditions = nil)
      scope = scope(:find)
      if scope && scope[:limit]
        case connection.adapter_name
        when 'MySQL', 'Mysql2'
          scope = scope(:find)
          sql = "DELETE FROM #{quoted_table_name} "
          add_conditions!(sql, conditions, scope)
          add_order!(sql, nil, scope)
          add_limit!(sql, {}, scope)
          return connection.delete(sql, "#{name} Delete all")
        else
          # I would just use a relation in the where below, but
          # it gets confused with the with_exclusive_scope, and
          # doesn't apply current_scoped_methods_when_defined
          # so just serialize it here (carefully, to avoid
          # method_missing magic causing the scope to be multiplied)
          scope = scope(:find) || {}
          scope[:select] = "#{quoted_table_name}.#{connection.quote_column_name(primary_key)}"
          sql = with_exclusive_scope(find: scope) { to_sql }
          with_exclusive_scope do
            return where("#{connection.quote_column_name(primary_key)} IN (#{sql})").delete_all
          end
        end
      end
      delete_all_without_limit(conditions)
    end
    alias_method_chain :delete_all, :limit
  end
  end

  def self.bulk_insert(records)
    return if records.empty?
    transaction do
      connection.bulk_insert(table_name, records)
    end
  end

  include ActiveSupport::Callbacks::Suspension

  # saves the record with all its save callbacks suspended.
  def save_without_callbacks
    if CANVAS_RAILS2
      new_record? ? create_without_callbacks : update_without_callbacks
    else
      suspend_callbacks(kind: [:validation, :save, (new_record? ? :create : :update)]) { save }
    end
  end

  if Rails.version < '4'
    if CANVAS_RAILS2
      named_scope :none, lambda { where("?", false) }
    else
      scope :none, lambda { {:conditions => ["?", false]} }
    end
  end
end

unless CANVAS_RAILS2
  # join dependencies in AR 3 insert the conditions right away, but because we have
  # some reflection conditions that rely on joined tables, we need to insert them later on

  # e.g.: LEFT OUTER JOIN "enrollments" ON "enrollments"."user_id" = "users"."id"
  #       AND courses.workflow_state='available'
  #       LEFT OUTER JOIN "courses" ON "courses"."id" = "enrollments"."course_id"

  # to:   LEFT OUTER JOIN "enrollments" ON "enrollments"."user_id" = "users"."id"
  #       LEFT OUTER JOIN "courses" ON "courses"."id" = "enrollments"."course_id"
  #       WHERE courses.workflow_state='available'
  ActiveRecord::Associations::JoinDependency::JoinAssociation.class_eval do
    def conditions
      unless @conditions
        @conditions = reflection.conditions.reverse
        chain.reverse.each_with_index do |reflection, i|
          if reflection.options[:joins]
            @join_conditions ||= []
            @join_conditions << sanitize(@conditions[i], @tables[i])
            @conditions[i] = []
          end
        end
      end
      @conditions
    end

    def join_to_with_join_conditions(*args)
      relation = join_to_without_join_conditions(*args)
      relation = relation.where(@join_conditions) if @join_conditions.present?
      @join_conditions = []
      relation
    end
    alias_method_chain :join_to, :join_conditions
  end

  ActiveRecord::Associations::Preloader::Association.class_eval do
    def build_scope_with_joins
      build_scope_without_joins.joins(preload_options[:joins] || options[:joins])
    end
    alias_method_chain :build_scope, :joins
  end

  ActiveRecord::Relation.class_eval do
    def find_in_batches_with_usefulness(options = {}, &block)
      # already in a transaction (or transactions don't matter); cursor is fine
      if (connection.adapter_name == 'PostgreSQL' && (Shackles.environment == :slave || connection.open_transactions > (Rails.env.test? ? 1 : 0))) && !options[:start]
        self.activate { find_in_batches_with_cursor(options, &block) }
      elsif order_values.any? || group_values.any? || select_values.to_s =~ /DISTINCT/i || uniq_value
        raise ArgumentError.new("GROUP and ORDER are incompatible with :start") if options[:start]
        self.activate { find_in_batches_with_temp_table(options, &block) }
      else
        find_in_batches_without_usefulness(options) do |batch|
          klass.send(:with_exclusive_scope) { yield batch }
        end
      end
    end
    alias_method_chain :find_in_batches, :usefulness

    def find_in_batches_with_cursor(options = {}, &block)
      batch_size = options[:batch_size] || 1000
      klass.transaction do
        begin
          cursor = "#{table_name}_in_batches_cursor"
          connection.execute("DECLARE #{cursor} CURSOR FOR #{to_sql}")
          includes = includes_values
          klass.send(:with_exclusive_scope) do
            batch = connection.uncached { klass.find_by_sql("FETCH FORWARD #{batch_size} FROM #{cursor}") }
            while !batch.empty?
              ActiveRecord::Associations::Preloader.new(batch, includes).run if includes
              yield batch
              break if batch.size < batch_size
              batch = connection.uncached { klass.find_by_sql("FETCH FORWARD #{batch_size} FROM #{cursor}") }
            end
          end
          # not ensure; if the transaction rolls back due to another exception, it will
          # automatically close
          connection.execute("CLOSE #{cursor}")
        end
      end
    end

    def find_in_batches_with_temp_table(options = {})
      batch_size = options[:batch_size] || 1000
      table = "#{table_name}_find_in_batches_temporary_table"
      connection.execute "CREATE TEMPORARY TABLE #{table} AS #{to_sql}"
      begin
        index = "temp_primary_key"
        case connection.adapter_name
          when 'PostgreSQL'
            begin
              old_proc = connection.raw_connection.set_notice_processor {}
              connection.execute "ALTER TABLE #{table}
                               ADD temp_primary_key SERIAL PRIMARY KEY"
            ensure
              connection.raw_connection.set_notice_processor(&old_proc) if old_proc
            end
          when 'MySQL', 'Mysql2'
            connection.execute "ALTER TABLE #{table}
                               ADD temp_primary_key MEDIUMINT NOT NULL PRIMARY KEY AUTO_INCREMENT"
          when 'SQLite'
            # Sqlite always has an implicit primary key
            index = 'rowid'
          else
            raise "Temp tables not supported!"
        end

        includes = includes_values
        sql = "SELECT *
             FROM #{table}
             ORDER BY #{index} ASC
             LIMIT #{batch_size}"
        klass.send(:with_exclusive_scope) do
          batch = klass.find_by_sql(sql)
          while !batch.empty?
            ActiveRecord::Associations::Preloader.new(batch, includes).run if includes
            yield batch
            break if batch.size < batch_size
            last_value = batch.last[index]

            sql = "SELECT *
               FROM #{table}
               WHERE #{index} > #{last_value}
               ORDER BY #{index} ASC
               LIMIT #{batch_size}"
            batch = klass.find_by_sql(sql)
          end
        end
      ensure
        temporary = "TEMPORARY " if connection.adapter_name == 'Mysql2'
        connection.execute "DROP #{temporary}TABLE #{table}"
      end
    end

    def update_all_with_joins(updates, conditions = nil, options = {})
      if joins_values.any?
        if conditions
          where(conditions).update_all
        else
          case connection.adapter_name
          when 'PostgreSQL'
            stmt = Arel::UpdateManager.new(arel.engine)

            stmt.set Arel.sql(@klass.send(:sanitize_sql_for_assignment, updates))
            stmt.table(table)
            stmt.key = table[primary_key]

            sql = stmt.to_sql

            tables, join_conditions = deconstruct_joins(arel.join_sql.to_s)

            unless tables.empty?
              sql.concat(' FROM ')
              sql.concat(tables.join(', '))
              sql.concat(' ')
            end

            sql.concat(where(join_conditions).arel.where_sql.to_s)
            connection.update(sql, "#{name} Update")
          else
            update_all_without_joins(updates, conditions, options)
          end
        end
      else
        update_all_without_joins(updates, conditions, options)
      end
    end
    alias_method_chain :update_all, :joins

    def delete_all_with_joins(conditions = nil)
      if joins_values.any?
        if conditions
          where(conditions).delete_all
        else
          case connection.adapter_name
          when 'PostgreSQL'
            sql = "DELETE FROM #{quoted_table_name} "

            tables, join_conditions = deconstruct_joins(arel.join_sql.to_s)

            sql.concat('USING ')
            sql.concat(tables.join(', '))
            sql.concat(' ')

            sql.concat(where(join_conditions).arel.where_sql.to_s)
          when 'MySQL', 'Mysql2'
            sql = "DELETE #{quoted_table_name} FROM #{quoted_table_name} #{arel.join_sql.to_s} #{arel.where_sql.to_s}"
          else
            raise "Joins in delete not supported!"
          end

          connection.delete(sql, "#{name} Delete all")
        end
      else
        delete_all_without_joins(conditions)
      end
    end
    alias_method_chain :delete_all, :joins

    def delete_all_with_limit(conditions = nil)
      if limit_value
        case connection.adapter_name
        when 'MySQL', 'Mysql2'
          v = arel.visitor
          sql = "DELETE #{quoted_table_name} FROM #{quoted_table_name} #{arel.where_sql.to_s}
              ORDER BY #{arel.orders.map { |x| v.send(:visit, x) }.join(', ')} LIMIT #{v.send(:visit, arel.limit)}"
          return connection.delete(sql, "#{name} Delete all")
        else
          scope = scoped.select(primary_key)
          return unscoped.where(primary_key => scope).delete_all
        end
      end
      delete_all_without_limit(conditions)
    end
    alias_method_chain :delete_all, :limit

    def with_each_shard(*args)
      scope = self
      if self.respond_to?(:proxy_association) && (owner = self.proxy_association.try(:owner)) && self.shard_category != :explicit
        scope = scope.shard(owner)
      end
      scope = scope.shard(args) if args.any?
      if block_given?
        ret = scope.activate{ |rel|
          yield(rel)
        }
        Array(ret)
      else
        scope.to_a
      end
    end
  end

  ActiveRecord::Associations::CollectionProxy.class_eval do
    delegate :with_each_shard, :to => :scoped

    def respond_to?(name, include_private = false)
      return super if [:marshal_dump, :_dump, 'marshal_dump', '_dump'].include?(name)
      super ||
        (load_target && target.respond_to?(name, include_private)) ||
        proxy_association.klass.respond_to?(name, include_private)
    end
  end

  ActiveRecord::Associations::CollectionAssociation.class_eval do
    def scoped
      scope = super
      proxy_association = self
      scope.extending do
        define_method(:proxy_association) { proxy_association }
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
  def bulk_insert(table_name, records)
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
    if open_transactions <= (Rails.env.test? ? 1 : 0)
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
    run_transaction_commit_callbacks
  end

  # this will only be chained in in Rails.env.test?, but we still
  # sometimes stub Rails.env.test? in specs to specifically
  # test behavior like this, so leave the check in this code
  def release_savepoint_with_callbacks
    release_savepoint_without_callbacks
    return unless Rails.env.test?
    return if open_transactions > 1
    run_transaction_commit_callbacks
  end

  def rollback_db_transaction_with_callbacks
    rollback_db_transaction_without_callbacks
    @after_transaction_commit = [] if @after_transaction_commit
  end

  def run_transaction_commit_callbacks
    return unless @after_transaction_commit.present?
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
end

module MySQLAdapterExtensions
  def self.included(klass)
    klass::NATIVE_DATABASE_TYPES[:primary_key] = "bigint DEFAULT NULL auto_increment PRIMARY KEY".freeze
    klass.alias_method_chain :add_column, :foreign_key_check if CANVAS_RAILS2
    klass.alias_method_chain :configure_connection, :pg_compat
    klass.alias_method_chain :commit_db_transaction, :callbacks
    klass.alias_method_chain :rollback_db_transaction, :callbacks
    klass.alias_method_chain :release_savepoint, :callbacks if Rails.env.test?
  end

  def rename_index(table_name, old_name, new_name)
    if version[0] >= 5 && version[1] >= 7
      return execute "ALTER TABLE #{quote_table_name(table_name)} RENAME INDEX #{quote_column_name(old_name)} TO #{quote_table_name(new_name)}";
    else
      old_index_def = indexes(table_name).detect { |i| i.name == old_name }
      return unless old_index_def
      add_index(table_name, old_index_def.columns, :name => new_name, :unique => old_index_def.unique)
      remove_index(table_name, :name => old_name)
    end
  end

  def bulk_insert(table_name, records)
    keys = records.first.keys
    quoted_keys = keys.map{ |k| quote_column_name(k) }.join(', ')
    execute "INSERT INTO #{quote_table_name(table_name)} (#{quoted_keys}) VALUES" <<
                records.map{ |record| "(#{keys.map{ |k| quote(record[k]) }.join(', ')})" }.join(',')
  end

  def add_column_with_foreign_key_check(table, name, type, options = {})
    Canvas.active_record_foreign_key_check(name, type, options) unless adapter_name == 'Sqlite'
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
      keys = records.first.keys
      quoted_keys = keys.map{ |k| quote_column_name(k) }.join(', ')
      execute "COPY #{quote_table_name(table_name)} (#{quoted_keys}) FROM STDIN"
      raw_connection.put_copy_data records.inject(''){ |result, record|
        result << keys.map{ |k| quote_text(record[k]) }.join("\t") << "\n"
      }
      ActiveRecord::Base.connection.clear_query_cache
      raw_connection.put_copy_end
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

    def rename_index(table_name, old_name, new_name)
      return execute "ALTER INDEX #{quote_column_name(old_name)} RENAME TO #{quote_table_name(new_name)}";
    end

    # have to replace the entire method to support concurrent
    def add_index(table_name, column_name, options = {})
      column_names = Array(column_name)
      index_name   = index_name(table_name, :column => column_names)

      if Hash === options # legacy support, since this param was a string
        index_type = options[:unique] ? "UNIQUE" : ""
        index_name = options[:name].to_s if options[:name]
        concurrently = "CONCURRENTLY " if options[:algorithm] == :concurrently && self.open_transactions == 0
        conditions = options[:where]
        if conditions
          if CANVAS_RAILS2
            conditions = " WHERE #{ActiveRecord::Base.send(:sanitize_sql, conditions, table_name.to_s.dup)}"
          else
            model_class = ActiveRecord::Base.all_models.detect{|m| m.table_name.to_s == table_name.to_s} || ActiveRecord::Base
            conditions = " WHERE #{model_class.send(:sanitize_sql, conditions, table_name.to_s.dup)}"
          end
        end
      else
        index_type = options
      end

      if index_name.length > index_name_length
        warning = "Index name '#{index_name}' on table '#{table_name}' is too long; the limit is #{index_name_length} characters. Skipping."
        @logger.warn(warning)
        raise warning unless Rails.env.production?
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

    # we always use the default sequence name, so override it to not actually query the db
    # (also, it doesn't matter if you're using PG 8.2+)
    def default_sequence_name(table, pk)
      "#{table}_#{pk}_seq"
    end
  end

end

if CANVAS_RAILS2
  ActiveRecord::Associations::AssociationProxy.class_eval do
    def respond_to?(*args)
      return proxy_respond_to?(*args) if [:marshal_dump, :_dump, 'marshal_dump', '_dump'].include?(args.first)
      proxy_respond_to?(*args) || (load_target && @target.respond_to?(*args))
    end
  end
end

unless CANVAS_RAILS2
  ActiveRecord::Associations::Builder::HasMany.valid_options << :joins

  ActiveRecord::Associations::HasOneAssociation.class_eval do
    def create_scope
      scope = scoped.scope_for_create.stringify_keys
      scope = scope.except(klass.primary_key) unless klass.primary_key.to_s == reflection.foreign_key.to_s
      scope
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

if CANVAS_RAILS2
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
    # SQLite isn't a first class supported db, but some specs still use it as an extra shard,
    # and it implements column changes by recreating, so just ignore this for SQLite
    Canvas.active_record_foreign_key_check(name, type, options) unless @base.adapter_name == 'SQLite'
    column_without_foreign_key_check(name, type, options)
  end
  alias_method_chain :column, :foreign_key_check
end
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

if defined?(ActiveRecord::ConnectionAdapters::SQLiteAdapter)
  ActiveRecord::ConnectionAdapters::SQLiteAdapter.class_eval do
    alias_method_chain :commit_db_transaction, :callbacks
    alias_method_chain :rollback_db_transaction, :callbacks
    alias_method_chain :release_savepoint, :callbacks if Rails.env.test?
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

    unless CANVAS_RAILS2
      # ActiveRecord 3.2 ignores indexes if it cannot parse the column names
      # (for instance when using functions like LOWER)
      # this will lead to problems if we try to remove the index (index_exists? will return false)
      def indexes(table_name)
        result = query(<<-SQL, 'SCHEMA')
           SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid
           FROM pg_class t
           INNER JOIN pg_index d ON t.oid = d.indrelid
           INNER JOIN pg_class i ON d.indexrelid = i.oid
           WHERE i.relkind = 'i'
             AND d.indisprimary = 'f'
             AND t.relname = '#{table_name}'
             AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = ANY (current_schemas(false)) )
          ORDER BY i.relname
        SQL

        result.map do |row|
          index_name = row[0]
          unique = row[1] == 't'
          indkey = row[2].split(" ")
          inddef = row[3]
          oid = row[4]

          columns = Hash[query(<<-SQL, "SCHEMA")]
          SELECT a.attnum, a.attname
          FROM pg_attribute a
          WHERE a.attrelid = #{oid}
          AND a.attnum IN (#{indkey.join(",")})
          SQL

          column_names = columns.values_at(*indkey).compact

          # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
          desc_order_columns = inddef.scan(/(\w+) DESC/).flatten
          orders = desc_order_columns.any? ? Hash[desc_order_columns.map {|order_column| [order_column, :desc]}] : {}

          ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, index_name, unique, column_names, [], orders)
        end
      end
    end

    alias_method_chain :commit_db_transaction, :callbacks
    alias_method_chain :rollback_db_transaction, :callbacks
    alias_method_chain :release_savepoint, :callbacks if Rails.env.test?
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

    def disable_ddl_transaction!
      @transactional = false
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

  unless CANVAS_RAILS2
    def connection
      if self.class.respond_to?(:connection)
        return self.class.connection
      else
        @connection || ActiveRecord::Base.connection
      end
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
  cattr_accessor :migrated_versions

  def self.migrations_paths
    @@migration_paths ||= []
  end

  def migrations
    @@migrations ||= begin
      @migrations_path ||= File.join(Rails.root, 'db/migrate')
      files = ([@migrations_path].compact + self.class.migrations_paths).uniq.
        map { |p| Dir["#{p}/[0-9]*_*.rb"] }.flatten

      migrations = files.inject([]) do |klasses, file|
        version, name, scope = file.scan(/([0-9]+)_([_a-z0-9]*)\.?([_a-z0-9]*)?\.rb\z/).first

        raise ActiveRecord::IllegalMigrationNameError.new(file) unless version
        version = version.to_i

        if klasses.detect { |m| m.version == version }
          raise ActiveRecord::DuplicateMigrationVersionError.new(version)
        end

        if klasses.detect { |m| m.name == name.camelize }
          raise ActiveRecord::DuplicateMigrationNameError.new(name.camelize)
        end

        if CANVAS_RAILS2
          klasses << (ActiveRecord::MigrationProxy.new).tap do |migration|
            migration.name     = name.camelize
            migration.version  = version
            migration.filename = file
          end
        else
          klasses << ActiveRecord::MigrationProxy.new(name.camelize, version, file, scope)
        end
        klasses
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
          self.class.migrated_versions = @migrated_versions
          migration.migrate(@direction)
          @migrated_versions = self.class.migrated_versions
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
      query = supports_delayed_constraint_validation? ? 'convalidated' : 'conname'
      value = select_value("SELECT #{query} FROM pg_constraint INNER JOIN pg_namespace ON pg_namespace.oid=connamespace WHERE conname='#{foreign_key_name}' AND nspname=current_schema()")
      if supports_delayed_constraint_validation? && value == 'f'
        execute("ALTER TABLE #{quote_table_name(from_table)} DROP CONSTRAINT #{quote_table_name(foreign_key_name)}")
      elsif value
        return
      end

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

  # does a query first to make the actual constraint adding fast
  def change_column_null_with_less_locking(table, column)
    execute("SELECT COUNT(*) FROM #{table} WHERE #{column} IS NULL") if open_transactions == 0
    change_column_null table, column, false
  end

  unless CANVAS_RAILS2
    def index_exists_with_options?(table_name, column_name, options = {})
      if options.is_a?(Hash)
        index_exists_without_options?(table_name, column_name, options)
      else
        # in ActiveRecord 2.3, the second argument is index_name
        name = column_name.to_s
        index_exists_without_options?(table_name, nil, {:name => name})
      end
    end
    alias_method_chain :index_exists?, :options

    # in ActiveRecord 3.2, it will raise an ArgumentError if the index doesn't exist
    def remove_index(table_name, options)
      name = index_name(table_name, options)
      unless index_exists?(table_name, nil, {:name => name})
        @logger.warn("Index name '#{name}' on table '#{table_name}' does not exist. Skipping.")
        return
      end
      remove_index!(table_name, name)
    end
  end

end

unless CANVAS_RAILS2
  ActiveRecord::AttributeMethods::Serialization::Attribute.class_eval do
    def unserialize
      self.state = :unserialized
      if value.nil?
        nil
      else
        self.value = coder.load(value)
      end
    end

    def serialized_value
      return nil if value.nil?
      unserialize if state == :serialized
      coder.dump(value)
    end

    def serialize
      serialized_value
    end
  end

  ActiveRecord::Associations::CollectionAssociation.class_eval do
    # CollectionAssociation implements uniq for :uniq option, in its
    # own special way. re-implement, but as a relation if it's not an
    # internal use of it
    def uniq(records = true)
      if records.is_a?(Array)
        records.uniq
      else
        scoped.uniq(records)
      end
    end
  end
end

if Rails.version >= '3' && Rails.version < '4'
  ActiveRecord::Sanitization::ClassMethods.module_eval do
    def quote_bound_value_with_relations(value, c = connection)
      if ActiveRecord::Relation === value
        value.to_sql
      else
        quote_bound_value_without_relations(value, c)
      end
    end
    alias_method_chain :quote_bound_value, :relations
  end
end

if Rails.version < '4'
  klass = ActiveRecord::ConnectionAdapters::Mysql2Column if defined?(ActiveRecord::ConnectionAdapters::Mysql2Column)
  klass = ActiveRecord::ConnectionAdapter::AbstractMysqlAdapter::Column if defined?(ActiveRecord::ConnectionAdapter::AbstractMysqlAdapter::Column)
  if klass
    klass.class_eval do
      def extract_default(default)
        if sql_type =~ /blob/i || type == :text
          if default.blank?
            # CHANGED - don't believe the '' default
            return nil
          else
            raise ArgumentError, "#{type} columns cannot have a default value: #{default.inspect}"
          end
        elsif missing_default_forged_as_empty_string?(default)
          nil
        else
          super
        end
      end
    end
  end
end
