require 'active_support/callbacks/suspension'

class ActiveRecord::Base
  self.cache_timestamp_format = :usec

  public :write_attribute

  class << self
    delegate :distinct_on, :find_ids_in_batches, to: :all

    def find_ids_in_ranges(opts={}, &block)
      opts.reverse_merge(:loose => true)
      all.find_ids_in_ranges(opts, &block)
    end

    attr_accessor :in_migration
  end

  def read_or_initialize_attribute(attr_name, default_value)
    # have to read the attribute again because serialized attributes in Rails 4.2 get duped
    read_attribute(attr_name) || (write_attribute(attr_name, default_value) && read_attribute(attr_name))
  end

  alias :clone :dup

  def serializable_hash(options = nil)
    result = super
    if result.present?
      result = result.with_indifferent_access
      user_content_fields = options[:user_content] || []
      result.keys.each do |name|
        if user_content_fields.include?(name.to_s)
          result[name] = UserContent.escape(result[name])
        end
      end
    end
    if options && options[:include_root]
      result = {self.class.base_class.model_name.element => result}
    end
    result
  end

  # See ActiveModel#serializable_add_includes
  def serializable_add_includes(options = {}, &block)
    super(options) do |association, records, opts|
      yield association, records, opts.reverse_merge(:include_root => options[:include_root])
    end
  end

  def feed_code
    id = self.uuid rescue self.id
    "#{self.class.reflection_type_name}_#{id}"
  end

  def self.all_models
    return @all_models if @all_models.present?
    @all_models = (ActiveRecord::Base.models_from_files +
                   [Version]).compact.uniq.reject { |model|
      (model < Tableless) ||
      model.abstract_class?
    }
  end

  def self.models_from_files
    @from_files ||= begin
      Dir[
        "#{Rails.root}/app/models/**/*.rb",
        "#{Rails.root}/vendor/plugins/*/app/models/**/*.rb",
        "#{Rails.root}/gems/plugins/*/app/models/**/*.rb",
      ].sort.each do |file|
        next if const_defined?(file.sub(%r{.*/app/models/(.*)\.rb$}, '\1').camelize)
        ActiveSupport::Dependencies.require_or_load(file)
      end
      ActiveRecord::Base.descendants
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
      next result if asset_types && !asset_types.include?(klass)
      result.concat((klass.constantize.where(id: id_pairs.map(&:last)).to_a rescue []))
    end
  end

  # takes an asset string list, like "course_5,user_7" and turns it into an
  # array of [class_name, id] like [ ["Course", 5], ["User", 7] ]
  def self.parse_asset_string_list(asset_string_list)
    asset_string_list.to_s.split(",").map { |str| parse_asset_string(str) }
  end

  def self.parse_asset_string(str)
    code = asset_string_components(str)
    [convert_class_name(code.first), code.last.try(:to_i)]
  end

  def self.asset_string_components(str)
    components = str.split('_', -1)
    id = components.pop
    [components.join('_'), id.presence]
  end

  def self.convert_class_name(str)
    namespaces = str.split(':')
    class_name = namespaces.pop
    (namespaces.map(&:camelize) + [class_name.try(:classify)]).join('::')
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
    asset.id == send("#{field}_id") && asset.class.base_class.name == send("#{field}_type")
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
      self.context_type.constantize.where(id: self.context_id).update_all(updated_at: Time.now.utc)
    end
  rescue
    Canvas::Errors.capture_exception(:touch_context, $ERROR_INFO)
  end

  def touch_user
    if self.respond_to?(:user_id) && self.user_id
      User.connection.after_transaction_commit do
        User.where(:id => self.user_id).update_all(:updated_at => Time.now.utc)
      end
    end
    true
  rescue
    Canvas::Errors.capture_exception(:touch_user, $ERROR_INFO)
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
    except = Array(except).dup
    except.concat(self.class.serialization_excludes) if self.class.respond_to?(:serialization_excludes)
    except.concat(self.serialization_excludes) if self.respond_to?(:serialization_excludes)
    except.uniq!

    methods = options.delete(:methods) || []
    methods = Array(methods).dup
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

    # ^hahahahahahaha
    unless options.key?(:include_root)
      options[:include_root] = true
    end

    hash = serializable_hash(options)

    if options[:permissions]
      obj_hash = options[:include_root] ? hash[self.class.base_class.model_name.element] : hash
      if self.respond_to?(:filter_attributes_for_user)
        self.filter_attributes_for_user(obj_hash, options[:permissions][:user], options[:permissions][:session])
      end
      unless options[:permissions][:include_permissions] == false
        permissions_hash = self.rights_status(options[:permissions][:user], options[:permissions][:session], *options[:permissions][:policies])
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

  def self.reflection_type_name
    base_class.name.underscore
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

  def self.coalesced_wildcard(*args)
    value = args.pop
    value = wildcard_pattern(value)
    cols = coalesce_chain(args)
    sanitize_sql_array ["(#{like_condition(cols, '?', false)})", value]
  end

  def self.coalesce_chain(cols)
    "(#{cols.map{|col| coalesce_clause(col)}.join(" || ' ' || ")})"
  end

  def self.coalesce_clause(column)
    "COALESCE(LOWER(#{column}), '')"
  end

  def self.like_condition(value, pattern = '?', downcase = true)
    value = "LOWER(#{value})" if downcase
    "#{value} LIKE #{pattern}"
  end

  def self.best_unicode_collation_key(col)
    if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'postgresql'
      # For PostgreSQL, we can't trust a simple LOWER(column), with any collation, since
      # Postgres just defers to the C library which is different for each platform. The best
      # choice is the collkey function from pg_collkey which uses ICU to get a full unicode sort.
      # If that extension isn't around, casting to a bytea sucks for international characters,
      # but at least it's consistent, and orders commas before letters so you don't end up with
      # Johnson, Bob sorting before Johns, Jimmy
      unless instance_variable_defined?(:@collkey)
        @collkey = connection.extension_installed?(:pg_collkey)
      end
      if @collkey
        "#{@collkey}.collkey(#{col}, '#{Canvas::ICU.locale_for_collation}', false, 0, true)"
      else
        "CAST(LOWER(replace(#{col}, '\\', '\\\\')) AS bytea)"
      end
    else
      col
    end
  end

  def self.count_by_date(options = {})
    column = options[:column] || "created_at"
    max_date = (options[:max_date] || Time.zone.now).midnight
    num_days = options[:num_days] || 20
    min_date = (options[:min_date] || max_date.advance(:days => -(num_days-1))).midnight

    offset = max_date.utc_offset

    expression = "((#{column} || '-00')::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.tzinfo.name}')::DATE"

    result = where(
        "#{column} >= ? AND #{column} < ?",
        min_date,
        max_date.advance(:days => 1)
      ).
      group(expression).
      order(expression).
      count

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

  def self.distinct_values(column, include_nil: false)
    column = column.to_s

    result = if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'postgresql'
      sql = ''
      sql << "SELECT NULL AS #{column} WHERE EXISTS (SELECT * FROM #{quoted_table_name} WHERE #{column} IS NULL) UNION ALL (" if include_nil
      sql << <<-SQL
        WITH RECURSIVE t AS (
          SELECT MIN(#{column}) AS #{column} FROM #{quoted_table_name}
          UNION ALL
          SELECT (SELECT MIN(#{column}) FROM #{quoted_table_name} WHERE #{column} > t.#{column})
          FROM t
          WHERE t.#{column} IS NOT NULL
        )
        SELECT #{column} FROM t WHERE #{column} IS NOT NULL
      SQL
      sql << ")" if include_nil
      find_by_sql(sql)
    else
      conditions = "#{column} IS NOT NULL" unless include_nil
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

  # set up class-specific getters/setters for a polymorphic association, e.g.
  #   belongs_to :context, polymorphic: [:course, :account]
  def self.belongs_to(name, scope = nil, options={})
    options = scope if scope.is_a?(Hash)
    polymorphic_prefix = options.delete(:polymorphic_prefix)
    exhaustive = options.delete(:exhaustive)

    reflection = super[name.to_s]

    if reflection.options[:polymorphic].is_a?(Array) ||
        reflection.options[:polymorphic].is_a?(Hash)
      reflection.options[:exhaustive] = exhaustive
      reflection.options[:polymorphic_prefix] = polymorphic_prefix
      add_polymorph_methods(reflection)
    end
    reflection
  end

  def self.add_polymorph_methods(reflection)
    unless @polymorph_module
      @polymorph_module = Module.new
      include(@polymorph_module)
    end

    specifics = []
    Array.wrap(reflection.options[:polymorphic]).map do |name|
      if name.is_a?(Hash)
        specifics.concat(name.to_a)
      else
        specifics << [name, name.to_s.camelize]
      end
    end

    unless reflection.options[:exhaustive] == false
      specific_classes = specifics.map(&:last).sort
      validates reflection.foreign_type, inclusion: { in: specific_classes }, allow_nil: true

      @polymorph_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{reflection.name}=(record)
          if record && [#{specific_classes.join(', ')}].none? { |klass| record.is_a?(klass) }
            message = "one of #{specific_classes.join(', ')} expected, got \#{record.class}"
            raise ActiveRecord::AssociationTypeMismatch, message
          end
          super
        end
      RUBY
    end

    if reflection.options[:polymorphic_prefix] == true
      prefix = "#{reflection.name}_"
    elsif reflection.options[:polymorphic_prefix]
      prefix = "#{reflection.options[:polymorphic_prefix]}_"
    end

    specifics.each do |(name, class_name)|
      # ensure we capture this class's table name
      table_name = self.table_name
      belongs_to :"#{prefix}#{name}", -> { where(table_name => { reflection.foreign_type => class_name }) },
                 foreign_key: reflection.foreign_key,
                 class_name: class_name

      correct_type = "#{reflection.foreign_type} && self.class.send(:compute_type, #{reflection.foreign_type}) <= #{class_name}"

      @polymorph_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{prefix}#{name}
        #{reflection.name} if #{correct_type}
      end

      def #{prefix}#{name}=(record)
        # we don't want to unset it if it's currently some other type, i.e.
        # foo.bar = Bar.new
        # foo.baz = nil
        # foo.bar.should_not be_nil
        return if record.nil? && !(#{correct_type})
        association(:#{prefix}#{name}).send(:raise_on_type_mismatch!, record) if record

        self.#{reflection.name} = record
      end

      RUBY
    end
  end

  def self.unique_constraint_retry(retries = 1)
    # runs the block in a (possibly nested) transaction. if a unique constraint
    # violation occurs, it will run it "retries" more times. the nested
    # transaction (savepoint) ensures we don't mess up things for the outer
    # transaction. useful for possible race conditions where we don't want to
    # take a lock (e.g. when we create a submission).
    retries.times do |retry_count|
      begin
        result = transaction(:requires_new => true) { uncached { yield(retry_count) } }
        connection.clear_query_cache
        return result
      rescue ActiveRecord::RecordNotUnique
      end
    end
    result = transaction(:requires_new => true) { uncached { yield(retries) } }
    connection.clear_query_cache
    result
  end

  def self.current_xlog_location
    Shard.current(shard_category).database_server.unshackle do
      Shackles.activate(:master) do
        connection.select_value("SELECT pg_current_xlog_location()")
      end
    end
  end

  def self.wait_for_replication(start: nil)
    return unless Shackles.activate(:slave) { connection.readonly? }

    start ||= current_xlog_location
    Shackles.activate(:slave) do
      while connection.select_value("SELECT pg_last_xlog_replay_location()") < start
        sleep 0.1
      end
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
    suspend_callbacks(kind: [:validation, :save, (new_record? ? :create : :update)]) { save }
  end

  def self.touch_all_records
    self.find_ids_in_ranges do |min_id, max_id|
      self.where(primary_key => min_id..max_id).touch_all
    end
  end
end

ActiveRecord::Relation.class_eval do
  def includes(*args)
    return super if args.empty? || args == [nil]
    raise "Use preload or eager_load instead of includes"
  end

  def where!(*args)
    raise "where!.not doesn't work in Rails 4.2" if args.empty?
    super
  end

  def select_values_necessitate_temp_table?
    return false unless select_values.present?
    selects = select_values.flat_map{|sel| sel.to_s.split(",").map(&:strip) }
    id_keys = [primary_key, "*", "#{table_name}.#{primary_key}", "#{table_name}.*"]
    id_keys.all?{|k| !selects.include?(k) }
  end
  private :select_values_necessitate_temp_table?

  def find_in_batches_needs_temp_table?
    order_values.any? ||
      group_values.any? ||
      select_values.to_s =~ /DISTINCT/i ||
      uniq_value ||
      select_values_necessitate_temp_table?
  end
  private :find_in_batches_needs_temp_table?

  def find_in_batches_with_usefulness(options = {}, &block)
    # already in a transaction (or transactions don't matter); cursor is fine
    if can_use_cursor? && !options[:start]
      self.activate { find_in_batches_with_cursor(options, &block) }
    elsif find_in_batches_needs_temp_table?
      raise ArgumentError.new("GROUP and ORDER are incompatible with :start, as is an explicit select without the primary key") if options[:start]
      self.activate { find_in_batches_with_temp_table(options, &block) }
    else
      find_in_batches_without_usefulness(options, &block)
    end
  end
  alias_method_chain :find_in_batches, :usefulness

  def can_use_cursor?
    (connection.adapter_name == 'PostgreSQL' &&
      (Shackles.environment == :slave ||
        connection.readonly? ||
        (!Rails.env.test? && connection.open_transactions > 0) ||
        in_transaction_in_test?))
  end

  def find_in_batches_with_cursor(options = {})
    batch_size = options[:batch_size] || 1000
    klass.transaction do
      begin
        sql = to_sql
        cursor = "#{table_name}_in_batches_cursor_#{sql.hash.abs.to_s(36)}"
        connection.execute("DECLARE #{cursor} CURSOR FOR #{sql}")
        includes = includes_values + preload_values
        klass.unscoped do
          batch = connection.uncached { klass.find_by_sql("FETCH FORWARD #{batch_size} FROM #{cursor}") }
          while !batch.empty?
            ActiveRecord::Associations::Preloader.new.preload(batch, includes) if includes
            yield batch
            break if batch.size < batch_size
            batch = connection.uncached { klass.find_by_sql("FETCH FORWARD #{batch_size} FROM #{cursor}") }
          end
        end
      ensure
        unless $!.is_a?(ActiveRecord::StatementInvalid)
          connection.execute("CLOSE #{cursor}")
        end
      end
    end
  end

  # determines if someone started a transaction in addition to the spec fixture transaction
  # impossible to just count open transactions, cause by default it won't nest a transaction
  # unless specifically requested
  def in_transaction_in_test?
    return false unless Rails.env.test?
    transaction_method = ActiveRecord::ConnectionAdapters::DatabaseStatements.instance_method(:transaction).source_location.first
    transaction_regex = /\A#{Regexp.escape(transaction_method)}:\d+:in `transaction'\z/.freeze
    # transactions due to spec fixtures are _not_in the callstack, so we only need to find 1
    !!caller.find { |s| s =~ transaction_regex && !s.include?('spec_helper.rb') }
  end

  def find_in_batches_with_temp_table(options = {})
    can_do_it = Rails.env.production? || ActiveRecord::Base.in_migration || in_transaction_in_test?
    raise "find_in_batches_with_temp_table probably won't work outside a migration
           and outside a transaction. Unfortunately, it's impossible to automatically
           determine a better way to do it that will work correctly. You can try
           switching to slave first (then switching to master if you modify anything
           inside your loop), wrapping in a transaction (but be wary of locking records
           for the duration of your query if you do any writes in your loop), or not
           forcing find_in_batches to use a temp table (avoiding custom selects,
           group, or order)." unless can_do_it

    if options[:pluck]
      pluck = Array(options[:pluck])
      pluck_for_select = pluck.map do |column_name|
        if column_name.is_a?(Symbol) && column_names.include?(column_name.to_s)
          "#{connection.quote_local_table_name(table_name)}.#{connection.quote_column_name(column_name)}"
        else
          column_name.to_s
        end
      end
      pluck = pluck.map(&:to_s)
    end
    batch_size = options[:batch_size] || 1000
    if pluck
      sql = select(pluck_for_select).to_sql
    else
      sql = to_sql
    end
    table = "#{table_name}_find_in_batches_temp_table_#{sql.hash.abs.to_s(36)}"
    table = table[-63..-1] if table.length > 63
    connection.execute "CREATE TEMPORARY TABLE #{table} AS #{sql}"
    begin
      index = "temp_primary_key"
      case connection.adapter_name
        when 'PostgreSQL'
          begin
            old_proc = connection.raw_connection.set_notice_processor {}
            if pluck && pluck.any?{|p| p == primary_key.to_s}
              connection.execute("CREATE INDEX #{connection.quote_local_table_name(index)} ON #{connection.quote_local_table_name(table)}(#{connection.quote_column_name(primary_key)})")
              index = primary_key.to_s
            else
              pluck.unshift(index) if pluck
              connection.execute "ALTER TABLE #{table}
                               ADD temp_primary_key SERIAL PRIMARY KEY"
            end
          ensure
            connection.raw_connection.set_notice_processor(&old_proc) if old_proc
          end
        else
          raise "Temp tables not supported!"
      end

      includes = includes_values + preload_values
      klass.unscoped do

        quoted_plucks = pluck && pluck.map do |column_name|
          # Rails 4.2 is going to try to quote them anyway but unfortunately not to the temp table, so just make it explicit
          column_names.include?(column_name) ?
            "#{connection.quote_local_table_name(table)}.#{connection.quote_column_name(column_name)}" : column_name
        end

        if pluck
          batch = klass.from(table).order(index).limit(batch_size).pluck(*quoted_plucks)
        else
          sql = "SELECT * FROM #{table} ORDER BY #{index} LIMIT #{batch_size}"
          batch = klass.find_by_sql(sql)
        end
        while !batch.empty?
          ActiveRecord::Associations::Preloader.new.preload(batch, includes) if includes
          yield batch
          break if batch.size < batch_size

          if pluck
            last_value = pluck.length == 1 ? batch.last : batch.last[pluck.index(index)]
            batch = klass.from(table).order(index).where("#{index} > ?", last_value).limit(batch_size).pluck(*quoted_plucks)
          else
            last_value = batch.last[index]
            sql = "SELECT *
               FROM #{table}
               WHERE #{index} > #{last_value}
               ORDER BY #{index} ASC
               LIMIT #{batch_size}"
            batch = klass.find_by_sql(sql)
          end
        end
      end
    ensure
      if !$!.is_a?(ActiveRecord::StatementInvalid) || connection.open_transactions == 0
        connection.execute "DROP TABLE #{table}"
      end
    end
  end

  def lock_with_exclusive_smarts(lock_type = true)
    if lock_type == :no_key_update
      postgres_9_3_or_above = connection.adapter_name == 'PostgreSQL' &&
        connection.send(:postgresql_version) >= 90300
      lock_type = true
      lock_type = 'FOR NO KEY UPDATE' if postgres_9_3_or_above
    end
    lock_without_exclusive_smarts(lock_type)
  end
  alias_method_chain :lock, :exclusive_smarts

  def polymorphic_where(args)
    raise ArgumentError unless args.length == 1

    column = args.first.first
    values = args.first.last
    original_length = values.length
    values = values.compact

    sql = (["(#{column}_id=? AND #{column}_type=?)"] * values.length).join(" OR ")
    sql << " OR (#{column}_id IS NULL AND #{column}_type IS NULL)" if values.length < original_length
    where(sql, *values.map { |value| [value, value.class.base_class.name] }.flatten)
  end

  def not_recently_touched
    scope = self
    if((personal_space = Setting.get('touch_personal_space', 0).to_i) != 0)
      personal_space -= 1
      # truncate to seconds
      bound = Time.at(Time.now.to_i - personal_space).utc
      scope = scope.where("#{connection.quote_local_table_name(table_name)}.updated_at<?", bound)
    end
    scope
  end

  def touch_all
    self.activate do |relation|
      relation.transaction do
        ids_to_touch = relation.not_recently_touched.lock(:no_key_update).order(:id).pluck(:id)
        unscoped.where(id: ids_to_touch).update_all(updated_at: Time.now.utc) if ids_to_touch.any?
      end
    end
  end

  def distinct_on(*args)
    args.map! do |column_name|
      if column_name.is_a?(Symbol) && column_names.include?(column_name.to_s)
        "#{connection.quote_local_table_name(table_name)}.#{connection.quote_column_name(column_name)}"
      else
        column_name.to_s
      end
    end

    relation = clone
    old_select = relation.select_values
    relation.select_values = ["DISTINCT ON (#{args.join(', ')}) "]
    relation.distinct_value = false

    if old_select.empty?
      relation.select_values.first << "*"
    else
      relation.select_values.first << old_select.uniq.join(', ')
    end

    relation
  end

  # if this sql is constructed on one shard then executed on another it wont work
  # dont use it for cross shard queries
  def union(*scopes)
    uniq_identifier = "#{table_name}.#{primary_key}"
    scopes << self
    sub_query = (scopes).map {|s| s.except(:select, :order).select(uniq_identifier).to_sql}.join(" UNION ALL ")
    engine.where("#{uniq_identifier} IN (#{sub_query})")
  end

  # returns batch_size ids at a time, working through the primary key from
  # smallest to largest.
  #
  # note this does a raw connection.select_values, so it doesn't work with scopes
  def find_ids_in_batches(options = {})
    batch_size = options[:batch_size] || 1000
    key = "#{quoted_table_name}.#{primary_key}"
    scope = except(:select).select(key).reorder(key).limit(batch_size)
    ids = connection.select_values(scope.to_sql)
    ids = ids.map(&:to_i) unless options[:no_integer_cast]
    while ids.present?
      yield ids
      break if ids.size < batch_size
      last_value = ids.last
      ids = connection.select_values(scope.where("#{key}>?", last_value).to_sql)
      ids = ids.map(&:to_i) unless options[:no_integer_cast]
    end
  end

  # returns 2 ids at a time (the min and the max of a range), working through
  # the primary key from smallest to largest.
  def find_ids_in_ranges(options = {})
    is_integer = columns_hash[primary_key.to_s].type == :integer
    loose_mode = options[:loose] && is_integer
    # loose_mode: if we don't care about getting exactly batch_size ids in between
    # don't get the max - just get the min and add batch_size so we get that many _at most_
    values = loose_mode ? "min(id)" : "min(id), max(id)"

    batch_size = options[:batch_size].try(:to_i) || 1000
    subquery_scope = except(:select).select("#{quoted_table_name}.#{primary_key} as id").reorder(primary_key).limit(loose_mode ? 1 : batch_size)
    subquery_scope = subquery_scope.where("#{quoted_table_name}.#{primary_key} <= ?", options[:end_at]) if options[:end_at]

    first_subquery_scope = options[:start_at] ? subquery_scope.where("#{quoted_table_name}.#{primary_key} >= ?", options[:start_at]) : subquery_scope

    ids = connection.select_rows("select #{values} from (#{first_subquery_scope.to_sql}) as subquery").first

    while ids.first.present?
      ids.map!(&:to_i) if is_integer
      ids << ids.first + batch_size if loose_mode

      yield(*ids)
      last_value = ids.last
      next_subquery_scope = subquery_scope.where(["#{quoted_table_name}.#{primary_key}>?", last_value])
      ids = connection.select_rows("select #{values} from (#{next_subquery_scope.to_sql}) as subquery").first
    end
  end
end

module UpdateAndDeleteWithJoins
  def deconstruct_joins(joins_sql=nil)
    unless joins_sql
      joins_sql = ''
      add_joins!(joins_sql, nil)
    end
    tables = []
    join_conditions = []
    joins_sql.strip.split('INNER JOIN')[1..-1].each do |join|
      # this could probably be improved
      raise "PostgreSQL update_all/delete_all only supports INNER JOIN" unless join.strip =~ /([a-zA-Z0-9'"_\.]+(?:(?:\s+[aA][sS])?\s+[a-zA-Z0-9'"_]+)?)\s+ON\s+(.*)/
      tables << $1
      join_conditions << $2
    end
    [tables, join_conditions]
  end

  def update_all(updates, *args)
    if joins_values.any?
      case connection.adapter_name
        when 'PostgreSQL'
          stmt = Arel::UpdateManager.new(arel.engine)

          stmt.set Arel.sql(@klass.send(:sanitize_sql_for_assignment, updates))
          from = from_value.try(:first)
          stmt.table(from ? Arel::Nodes::SqlLiteral.new(from) : table)
          stmt.key = table[primary_key]

          sql = stmt.to_sql

          collector = Arel::Collectors::Bind.new
          arel.join_sources.each do |node|
            connection.visitor.accept(node, collector)
          end
          join_sql = collector.compile(arel.bind_values.map{|bvs| connection.quote(*bvs.reverse)})
          tables, join_conditions = deconstruct_joins(join_sql)

          unless tables.empty?
            sql.concat(' FROM ')
            sql.concat(tables.join(', '))
            sql.concat(' ')
          end

          scope = self
          join_conditions.each { |join| scope = scope.where(join) }
          binds = scope.bind_values.dup
          sql_string = Arel::Collectors::Bind.new
          scope.arel.constraints.map do |node|
            connection.visitor.accept(node, sql_string)
          end
          sql.concat('WHERE ' + sql_string.compile(binds.map{|bvs| connection.quote(*bvs.reverse)}))

          connection.update(sql, "#{name} Update")
        else
          super
      end
    else
      super
    end
  end

  def delete_all(conditions = nil, *args)
    if joins_values.any?
      if conditions
        where(conditions).delete_all
      else
        case connection.adapter_name
          when 'PostgreSQL'
            sql = "DELETE FROM #{quoted_table_name} "

            join_sql = arel.join_sources.map(&:to_sql).join(" ")
            tables, join_conditions = deconstruct_joins(join_sql)

            sql.concat('USING ')
            sql.concat(tables.join(', '))
            sql.concat(' ')

            scope = self
            join_conditions.each { |join| scope = scope.where(join) }

            binds = scope.bind_values.dup
            sql_string = Arel::Collectors::Bind.new
            scope.arel.constraints.map do |node|
              connection.visitor.accept(node, sql_string)
            end
            sql.concat('WHERE ' + sql_string.compile(binds.map{|bvs| connection.quote(*bvs.reverse)}))
          else
            raise "Joins in delete not supported!"
        end

        connection.exec_query(sql, "#{name} Delete all", scope.bind_values)
      end
    else
      super
    end
  end
end
ActiveRecord::Relation.prepend(UpdateAndDeleteWithJoins)

module DeleteAllWithLimit
  def delete_all(*args)
    if limit_value || offset_value
      scope = except(:select).select("#{quoted_table_name}.#{primary_key}")
      return unscoped.where(primary_key => scope).delete_all
    end
    super
  end
end
ActiveRecord::Relation.prepend(DeleteAllWithLimit)

ActiveRecord::Associations::CollectionProxy.class_eval do
  def respond_to?(name, include_private = false)
    return super if [:marshal_dump, :_dump, 'marshal_dump', '_dump'].include?(name)
    super ||
      (load_target && target.respond_to?(name, include_private)) ||
      proxy_association.klass.respond_to?(name, include_private)
  end

  def temp_record(*args)
    # creates a record with attributes like a child record but is not added to the collection for autosaving
    klass.unscoped.merge(scope).new(*args)
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
end

ActiveRecord::Associations::HasOneAssociation.class_eval do
  def create_scope
    scope = self.scope.scope_for_create.stringify_keys
    scope = scope.except(klass.primary_key) unless klass.primary_key.to_s == reflection.foreign_key.to_s
    scope
  end
end

class ActiveRecord::Migration
  VALID_TAGS = [:predeploy, :postdeploy, :cassandra]
  # at least one of these tags is required
  DEPLOY_TAGS = [:predeploy, :postdeploy]

  class << self
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

  def connection
    if self.class.respond_to?(:connection)
      return self.class.connection
    else
      @connection || ActiveRecord::Base.connection
    end
  end

  def tags
    self.class.tags
  end
end

class ActiveRecord::MigrationProxy
  delegate :connection, :tags, to: :migration

  def runnable?
    !migration.respond_to?(:runnable?) || migration.runnable?
  end

  def load_migration
    load(filename)
    @migration = name.constantize
    raise "#{self.name} (#{self.version}) is not tagged as exactly one of predeploy or postdeploy!" unless (@migration.tags & ActiveRecord::Migration::DEPLOY_TAGS).length == 1
    @migration
  end
end

module MigratorCache
  def migrations(paths)
    @@migrations_hash ||= {}
    @@migrations_hash[paths] ||= super
  end

  def migrations_paths
    @@migrations_paths ||= [File.join(Rails.root, "db/migrate")]
  end
end
ActiveRecord::Migrator.singleton_class.prepend(MigratorCache)

module Migrator
  def skipped_migrations
    pending_migrations(call_super: true).reject(&:runnable?)
  end

  def pending_migrations(call_super: false)
    return super() if call_super
    super().select(&:runnable?)
  end

  def runnable
    super.select(&:runnable?)
  end

  def execute_migration_in_transaction(migration, direct)
    old_in_migration, ActiveRecord::Base.in_migration = ActiveRecord::Base.in_migration, true
    if defined?(Marginalia)
      old_migration_name, Marginalia::Comment.migration = Marginalia::Comment.migration, migration.name
    end
    if down? && !Rails.env.test? && !$confirmed_migrate_down
      require 'highline'
      if HighLine.new.ask("Revert migration #{migration.name} (#{migration.version}) ? [y/N/a] > ") !~ /^([ya])/i
        raise("Revert not confirmed")
      end
      $confirmed_migrate_down = true if $1.downcase == 'a'
    end

    super
  ensure
    ActiveRecord::Base.in_migration = old_in_migration
    Marginalia::Comment.migration = old_migration_name if defined?(Marginalia)
  end
end
ActiveRecord::Migrator.prepend(Migrator)

ActiveRecord::Migrator.migrations_paths.concat Dir[Rails.root.join('gems', 'plugins', '*', 'db', 'migrate')]

ActiveRecord::Tasks::DatabaseTasks.migrations_paths = ActiveRecord::Migrator.migrations_paths

ActiveRecord::ConnectionAdapters::SchemaStatements.class_eval do
  def add_index_with_length_raise(table_name, column_name, options = {})
    unless options[:name].to_s =~ /^temp_/
      column_names = Array(column_name)
      index_name = index_name(table_name, :column => column_names)
      index_name = options[:name].to_s if options[:name]
      if index_name.length > index_name_length
        raise(ArgumentError, "Index name '#{index_name}' on table '#{table_name}' is too long; the limit is #{index_name_length} characters.")
      end
      if index_exists?(table_name, column_names, :name => index_name)
        raise(ArgumentError, "Index name '#{index_name}' on table '#{table_name}' already exists.")
      end
    end
    add_index_without_length_raise(table_name, column_name, options)
  end
  alias_method_chain :add_index, :length_raise

  # in anticipation of having to re-run migrations due to integrity violations or
  # killing stuff that is holding locks too long
  def add_foreign_key_if_not_exists(from_table, to_table, options = {})
    options[:column] ||= "#{to_table.to_s.singularize}_id"
    column = options[:column]
    case self.adapter_name
    when 'PostgreSQL'
      foreign_key_name = foreign_key_name(from_table, options)
      query = supports_delayed_constraint_validation? ? 'convalidated' : 'conname'
      schema = @config[:use_qualified_names] ? quote(shard.name) : 'current_schema()'
      value = select_value("SELECT #{query} FROM pg_constraint INNER JOIN pg_namespace ON pg_namespace.oid=connamespace WHERE conname='#{foreign_key_name}' AND nspname=#{schema}")
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
      raise unless e.message =~ /PG(?:::)?Error: ERROR:.+does not exist/
    end
  end

  # does a query first to make the actual constraint adding fast
  def change_column_null_with_less_locking(table, column)
    execute("SELECT COUNT(*) FROM #{quote_table_name(table)} WHERE #{column} IS NULL") if open_transactions == 0
    change_column_null table, column, false
  end
end

ActiveRecord::Associations::CollectionAssociation.class_eval do
  # CollectionAssociation implements uniq for :uniq option, in its
  # own special way. re-implement, but as a relation
  def distinct
    scope.distinct
  end
end

module UnscopeCallbacks
  def __run_callbacks__(*args)
    scope = self.class.base_class.unscoped
    scope.scoping { super }
  end
end
ActiveRecord::Base.send(:include, UnscopeCallbacks)

ActiveRecord::DynamicMatchers::Method.class_eval do
  class << self
    def match_with_discard(model, name)
      result = match_without_discard(model, name)
      return nil if result && !result.is_a?(ActiveRecord::DynamicMatchers::FindBy)
      result
    end
    alias_method_chain :match, :discard
  end
end

# see https://github.com/rails/rails/issues/18659
class AttributesDefiner
  # defines attribute methods when loaded through Marshal
  def initialize(klass)
    @klass = klass
  end

  def marshal_dump
    @klass
  end

  def marshal_load(klass)
    klass.define_attribute_methods
    @klass = klass
  end
end

module DefineAttributeMethods
  def init_internals
    @define_attributes_helper = AttributesDefiner.new(self.class)
    super
  end
end
ActiveRecord::Base.include(DefineAttributeMethods)

module SkipTouchCallbacks
  module Base
    def skip_touch_callbacks(name)
      @skip_touch_callbacks ||= Set.new
      if @skip_touch_callbacks.include?(name)
        yield
      else
        @skip_touch_callbacks << name
        yield
        @skip_touch_callbacks.delete(name)
      end
    end

    def touch_callbacks_skipped?(name)
      (@skip_touch_callbacks && @skip_touch_callbacks.include?(name)) ||
        (self.superclass < ActiveRecord::Base && self.superclass.touch_callbacks_skipped?(name))
    end
  end

  module BelongsTo
    def touch_record(o, foreign_key, name, *args)
      return if o.class.touch_callbacks_skipped?(name)
      super
    end
  end
end
ActiveRecord::Base.singleton_class.include(SkipTouchCallbacks::Base)
ActiveRecord::Associations::Builder::BelongsTo.singleton_class.prepend(SkipTouchCallbacks::BelongsTo)

module ReadonlyCloning
  def calculate_changes_from_defaults
    super unless @readonly_clone # no reason to do this if we're creating a readonly clone - can take a long time with serialized columns
  end
end
ActiveRecord::Base.prepend(ReadonlyCloning)
