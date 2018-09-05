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

require 'active_support/callbacks/suspension'

class ActiveRecord::Base
  self.cache_timestamp_format = :usec

  public :write_attribute

  class << self
    delegate :distinct_on, :find_ids_in_batches, :explain, to: :all

    def find_ids_in_ranges(opts={}, &block)
      opts.reverse_merge!(:loose => true)
      all.find_ids_in_ranges(opts, &block)
    end

    attr_accessor :in_migration

    # determines if someone started a transaction in addition to the spec fixture transaction
    # impossible to just count open transactions, cause by default it won't nest a transaction
    # unless specifically requested
    def in_transaction_in_test?
      return false unless Rails.env.test?
      stacktrace = caller

      transaction_index, wrap_index, after_index = [
        ActiveRecord::ConnectionAdapters::DatabaseStatements.instance_method(:transaction),
        defined?(SpecTransactionWrapper) && SpecTransactionWrapper.method(:wrap_block_in_transaction),
        AfterTransactionCommit::Transaction.instance_method(:commit_records)
      ].map do |method|
        if method
          regex = /\A#{Regexp.escape(method.source_location.first)}:\d+:in `#{Regexp.escape(method.name)}'\z/.freeze
          stacktrace.index{|s| s =~ regex}
        end
      end

      if transaction_index
        # we wrap a transaction around controller actions, so try to see if this call came from that
        if wrap_index && (transaction_index..wrap_index).all?{|i| stacktrace[i].match?(/transaction|mon_synchronize/)}
          false
        else
          # check if this is being run through an after_transaction_commit since the last transaction
          !(after_index && after_index < transaction_index)
        end
      else
        false
      end
    end

    def default_scope(*)
      raise "please don't ever use default_scope. it may seem like a great solution, but I promise, it isn't"
    end
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

  def self.asset_string(id)
    "#{self.reflection_type_name}_#{id}"
  end

  def asset_string
    @asset_string ||= {}
    @asset_string[Shard.current] ||= self.class.asset_string(id)
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

  def self.asset_string_backcompat_module
    @asset_string_backcompat_module ||= Module.new.tap { |m| prepend(m) }
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

    asset_string_backcompat_module.class_eval <<-CODE, __FILE__, __LINE__ + 1
      def #{association_version_name}_#{method}
        res = super
        if !res && #{string_version_name}.present?
          type, id = ActiveRecord::Base.parse_asset_string(#{string_version_name})
          write_attribute(:#{association_version_name}_type, type)
          write_attribute(:#{association_version_name}_id, id)
          res = super
        end
        res
      end
    CODE
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
    val = if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'postgresql'
      # For PostgreSQL, we can't trust a simple LOWER(column), with any collation, since
      # Postgres just defers to the C library which is different for each platform. The best
      # choice is the collkey function from pg_collkey which uses ICU to get a full unicode sort.
      # If that extension isn't around, casting to a bytea sucks for international characters,
      # but at least it's consistent, and orders commas before letters so you don't end up with
      # Johnson, Bob sorting before Johns, Jimmy
      unless @collkey&.key?(Shard.current.database_server.id)
        @collkey ||= {}
        @collkey[Shard.current.database_server.id] = connection.extension_installed?(:pg_collkey)
      end
      if (schema = @collkey[Shard.current.database_server.id])
        # The collation level of 3 is the default, but is explicitly specified here and means that
        # case, accents and base characters are all taken into account when creating a collation key
        # for a string - more at https://pgxn.org/dist/pg_collkey/0.5.1/
        # if you change these arguments, you need to rebuild all db indexes that use them,
        # and you should also match the settings with Canvas::ICU::Collator and natcompare.js
        "#{schema}.collkey(#{col}, '#{Canvas::ICU.locale_for_collation}', false, 3, true)"
      else
        "CAST(LOWER(replace(#{col}, '\\', '\\\\')) AS bytea)"
      end
    else
      col
    end
    Arel.sql(val)
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
      order(Arel.sql(expression)).
      count

    return result if result.keys.first.is_a?(Date)
    Hash[result.map { |date, count|
      [Time.zone.parse(date).to_date, count]
    }]
  end

  def self.rank_sql(ary, col)
    sql = ary.each_with_index.inject('CASE '){ |string, (values, i)|
      string << "WHEN #{col} IN (" << Array(values).map{ |value| connection.quote(value) }.join(', ') << ") THEN #{i} "
    } << "ELSE #{ary.size} END"
    Arel.sql(sql)
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
      Arel.sql("#{column} #{direction.to_s.upcase}#{clause}".strip)
    else
      Arel.sql("#{column} IS#{" NOT" unless first_or_last == :last} NULL, #{column} #{direction.to_s.upcase}".strip)
    end
  end

  # set up class-specific getters/setters for a polymorphic association, e.g.
  #   belongs_to :context, polymorphic: [:course, :account]
  def self.belongs_to(name, scope = nil, **options)
    if options[:polymorphic] == true
      raise "Please pass an array of valid types for polymorphic associations. Use exhaustive: false if you really don't want to validate them"
    end

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
        if Rails.env.test? ? self.in_transaction_in_test? : connection.open_transactions > 0
          raise "don't run current_xlog_location in a transaction"
        elsif connection.send(:postgresql_version) >= 100000
          connection.select_value("SELECT pg_current_wal_lsn()")
        else
          connection.select_value("SELECT pg_current_xlog_location()")
        end
      end
    end
  end

  def self.wait_for_replication(start: nil, timeout: nil)
    return true unless Shackles.activate(:slave) { connection.readonly? }

    start ||= current_xlog_location
    Shackles.activate(:slave) do
      diff_fn = connection.send(:postgresql_version) >= 100000 ?
        "pg_wal_lsn_diff" :
        "pg_xlog_location_diff"
      fn = connection.send(:postgresql_version) >= 100000 ?
        "pg_last_wal_replay_lsn()" :
        "pg_last_xlog_replay_location()"
      # positive == first value greater, negative == second value greater
      # SELECT pg_xlog_location_diff(<START>, pg_last_xlog_replay_location())
      start_time = Time.now
      while connection.select_value("SELECT #{diff_fn}(#{connection.quote(start)}, #{fn})").to_i >= 0
        return false if timeout && Time.now > start_time + timeout
        sleep 0.1
      end
    end
    true
  end

  def self.bulk_insert(records)
    return if records.empty?
    transaction do
      connection.bulk_insert(table_name, records)
    end
  end

  include ActiveSupport::Callbacks::Suspension

  def self.touch_all_records
    self.find_ids_in_ranges do |min_id, max_id|
      self.where(primary_key => min_id..max_id).touch_all
    end
  end
end

module UsefulFindInBatches
  def find_in_batches(options = {}, &block)
    # prefer copy unless we're in a transaction (which would be bad,
    # because we might open a separate connection in the block, and not
    # see the contents of our current transaction)
    if connection.open_transactions == 0 && !options[:start] && eager_load_values.empty? && !ActiveRecord::Base.in_migration
      self.activate { |r| r.find_in_batches_with_copy(options, &block) }
    elsif should_use_cursor? && !options[:start] && eager_load_values.empty?
      self.activate { |r| r.find_in_batches_with_cursor(options, &block) }
    elsif find_in_batches_needs_temp_table?
      if options[:start]
        raise ArgumentError.new("GROUP and ORDER are incompatible with :start, as is an explicit select without the primary key")
      end
      unless eager_load_values.empty?
        raise ArgumentError.new("GROUP and ORDER are incompatible with `eager_load`, as is an explicit select without the primary key")
      end
      self.activate { |r| r.find_in_batches_with_temp_table(options, &block) }
    else
      super
    end
  end
end
ActiveRecord::Relation.prepend(UsefulFindInBatches)

module LockForNoKeyUpdate
  def lock(lock_type = true)
    lock_type = 'FOR NO KEY UPDATE' if lock_type == :no_key_update
    super(lock_type)
  end
end
ActiveRecord::Relation.prepend(LockForNoKeyUpdate)

ActiveRecord::Relation.class_eval do
  def includes(*args)
    return super if args.empty? || args == [nil]
    raise "Use preload or eager_load instead of includes"
  end

  def where!(*args)
    raise "where!.not doesn't work in Rails 4.2" if args.empty?
    super
  end

  def uniq(*args)
    raise "use #distinct instead of #uniq on relations (Rails 5.1 will delegate uniq to to_a)"
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
      distinct_value ||
      select_values_necessitate_temp_table?
  end
  private :find_in_batches_needs_temp_table?

  def should_use_cursor?
    (Shackles.environment == :slave || connection.readonly?)
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

  def find_in_batches_with_copy(options = {})
    # implement the start option as an offset
    return offset(options[:start]).find_in_batches_with_copy(options.merge(start: 0)) if options[:start].to_i != 0

    limited_query = limit(0).to_sql
    full_query = "COPY (#{to_sql}) TO STDOUT"
    conn = connection
    full_query = conn.annotate_sql(full_query) if defined?(Marginalia)
    pool = conn.pool
    # remove the connection from the pool so that any queries executed
    # while we're running this will get a new connection
    pool.remove(conn)


    # make sure to log _something_, even if the dbtime is totally off
    conn.send(:log, full_query, "#{klass.name} Load") do
      # set up all our metadata based on a dummy query (COPY doesn't return any metadata)
      result = conn.raw_connection.exec(limited_query)
      type_map = conn.raw_connection.type_map_for_results.build_column_map(result)
      deco = PG::TextDecoder::CopyRow.new(type_map: type_map)
      # see PostgreSQLAdapter#exec_query
      types = {}
      fields = result.fields
      fields.each_with_index do |fname, i|
        ftype = result.ftype i
        fmod  = result.fmod i
        types[fname] = conn.send(:get_oid_type, ftype, fmod, fname)
      end

      column_types = types.dup
      columns_hash.each_key { |k| column_types.delete k }

      includes = includes_values + preload_values

      rows = []
      batch_size = options[:batch_size] || 1000

      conn.raw_connection.copy_data(full_query, deco) do
        while (row = conn.raw_connection.get_copy_data)
          rows << row
          if rows.size == batch_size
            batch = ActiveRecord::Result.new(fields, rows, types).map { |record| instantiate(record, column_types) }
            ActiveRecord::Associations::Preloader.new.preload(batch, includes) if includes
            yield batch
            rows = []
          end
        end
      end
      # return the connection now, in case there was only 1 batch, we can avoid a separate connection if the block needs it
      pool.synchronize do
        pool.send(:adopt_connection, conn)
        pool.checkin(conn)
      end
      pool = nil

      unless rows.empty?
        batch = ActiveRecord::Result.new(fields, rows, types).map { |record| instantiate(record, column_types) }
        ActiveRecord::Associations::Preloader.new.preload(batch, includes) if includes
        yield batch
      end
    end
    nil
  ensure
    if pool
      # put the connection back in the pool for reuse
      pool.synchronize do
        pool.send(:adopt_connection, conn)
        pool.checkin(conn)
      end
    end
  end

  def find_in_batches_with_temp_table(options = {})
    can_do_it = Rails.env.production? ||
      ActiveRecord::Base.in_migration ||
      (!Rails.env.test? && connection.open_transactions > 0) ||
      ActiveRecord::Base.in_transaction_in_test?
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
            Arel.sql("#{connection.quote_local_table_name(table)}.#{connection.quote_column_name(column_name)}") : column_name
        end

        if pluck
          batch = klass.from(table).order(Arel.sql(index)).limit(batch_size).pluck(*quoted_plucks)
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
            batch = klass.from(table).order(Arel.sql(index)).where("#{index} > ?", last_value).limit(batch_size).pluck(*quoted_plucks)
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

  def polymorphic_where(args)
    raise ArgumentError unless args.length == 1

    column = args.first.first
    values = Array(args.first.last)
    original_length = values.length
    values = values.compact
    raise ArgumentError, "need to call polymorphic_where with at least one object" if values.empty?

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
    unscoped.where("#{uniq_identifier} IN (#{sub_query})")
  end

  # returns batch_size ids at a time, working through the primary key from
  # smallest to largest.
  #
  # note this does a raw connection.select_values, so it doesn't work with scopes
  def find_ids_in_batches(options = {})
    batch_size = options[:batch_size] || 1000
    key = "#{quoted_table_name}.#{primary_key}"
    scope = except(:select).select(key).reorder(Arel.sql(key)).limit(batch_size)
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
    values = loose_mode ? "MIN(id)" : "MIN(id), MAX(id)"

    batch_size = options[:batch_size].try(:to_i) || 1000
    quoted_primary_key = "#{klass.connection.quote_local_table_name(table_name)}.#{klass.connection.quote_column_name(primary_key)}"
    as_id = " AS id" unless primary_key == 'id'
    subquery_scope = except(:select).select("#{quoted_primary_key}#{as_id}").reorder(primary_key.to_sym).limit(loose_mode ? 1 : batch_size)
    subquery_scope = subquery_scope.where("#{quoted_primary_key} <= ?", options[:end_at]) if options[:end_at]

    first_subquery_scope = options[:start_at] ? subquery_scope.where("#{quoted_primary_key} >= ?", options[:start_at]) : subquery_scope

    ids = connection.select_rows("SELECT #{values} FROM (#{first_subquery_scope.to_sql}) AS subquery").first

    while ids.first.present?
      ids.map!(&:to_i) if is_integer
      ids << ids.first + batch_size if loose_mode

      yield(*ids)
      last_value = ids.last
      next_subquery_scope = subquery_scope.where(["#{quoted_primary_key}>?", last_value])
      ids = connection.select_rows("SELECT #{values} FROM (#{next_subquery_scope.to_sql}) AS subquery").first
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
    return super if joins_values.empty?

    stmt = Arel::UpdateManager.new

    stmt.set Arel.sql(@klass.send(:sanitize_sql_for_assignment, updates))
    from = from_clause.value
    stmt.table(from ? Arel::Nodes::SqlLiteral.new(from) : table)
    stmt.key = table[primary_key]

    sql = stmt.to_sql

    if CANVAS_RAILS5_1
      binds = bound_attributes.map(&:value_for_database)
      binds.map! { |value| connection.quote(value) }
      collector = Arel::Collectors::Bind.new
      arel.join_sources.each do |node|
        connection.visitor.accept(node, collector)
      end
      binds_in_join = collector.value.count { |x| x.is_a?(Arel::Nodes::BindParam) }
      join_sql = collector.substitute_binds(binds).join
    else
      collector = connection.send(:collector)
      arel.join_sources.each do |node|
        connection.visitor.accept(node, collector)
      end
      join_sql = collector.value
    end

    tables, join_conditions = deconstruct_joins(join_sql)

    unless tables.empty?
      sql.concat(' FROM ')
      sql.concat(tables.join(', '))
      sql.concat(' ')
    end

    scope = self
    join_conditions.each { |join| scope = scope.where(join) }

    # skip any binds that are used in the join
    if CANVAS_RAILS5_1
      binds = scope.bound_attributes[binds_in_join..-1]
      binds = binds.map(&:value_for_database)
      binds.map! { |value| connection.quote(value) }
      sql_string = Arel::Collectors::Bind.new
      scope.arel.constraints.each do |node|
        connection.visitor.accept(node, sql_string)
      end
      where_sql = sql_string.substitute_binds(binds).join
    else
      collector = connection.send(:collector)
      scope.arel.constraints.each do |node|
        connection.visitor.accept(node, collector)
      end
      where_sql = collector.value
    end
    sql.concat('WHERE ' + where_sql)
    connection.update(sql, "#{name} Update")
  end

  def delete_all
    return super if joins_values.empty?

    sql = "DELETE FROM #{quoted_table_name} "

    join_sql = arel.join_sources.map(&:to_sql).join(" ")
    tables, join_conditions = deconstruct_joins(join_sql)

    sql.concat('USING ')
    sql.concat(tables.join(', '))
    sql.concat(' ')

    scope = self
    join_conditions.each { |join| scope = scope.where(join) }

    if CANVAS_RAILS5_1
      binds = scope.bound_attributes
      binds = binds.map(&:value_for_database)
      binds.map! { |value| connection.quote(value) }
      sql_string = Arel::Collectors::Bind.new
      scope.arel.constraints.each do |node|
        connection.visitor.accept(node, sql_string)
      end
      where_sql = sql_string.substitute_binds(binds).join
    else
      collector = connection.send(:collector)
      scope.arel.constraints.each do |node|
        connection.visitor.accept(node, collector)
      end
      where_sql = collector.value
    end
    sql.concat('WHERE ' + where_sql)

    connection.delete(sql, "SQL", CANVAS_RAILS5_1 ? scope.bind_values : [])
  end
end
ActiveRecord::Relation.prepend(UpdateAndDeleteWithJoins)

module UpdateAndDeleteAllWithLimit
  def delete_all(*args)
    if limit_value || offset_value
      scope = except(:select).select("#{quoted_table_name}.#{primary_key}")
      return unscoped.where(primary_key => scope).delete_all
    end
    super
  end

  def update_all(updates, *args)
    if limit_value || offset_value
      scope = except(:select).select("#{quoted_table_name}.#{primary_key}")
      return unscoped.where(primary_key => scope).update_all(updates)
    end
    super
  end
end
ActiveRecord::Relation.prepend(UpdateAndDeleteAllWithLimit)

ActiveRecord::Associations::CollectionProxy.class_eval do
  def respond_to?(name, include_private = false)
    return super if [:marshal_dump, :_dump, 'marshal_dump', '_dump'].include?(name)
    super ||
      (load_target && target.respond_to?(name, include_private)) ||
      proxy_association.klass.respond_to?(name, include_private)
  end

  def temp_record(*args)
    # creates a record with attributes like a child record but is not added to the collection for autosaving
    record = klass.unscoped.merge(scope).new(*args)
    @association.set_inverse_instance(record)
    record
  end

  def uniq(*args)
    raise "use #distinct instead of #uniq on relations (Rails 5.1 will delegate uniq to to_a)"
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
  delegate :connection, :tags, :cassandra_cluster, to: :migration

  def initialize(*)
    super
    if version&.to_s&.length == 14 && version.to_s > Time.now.utc.strftime("%Y%m%d%H%M%S")
      raise "please don't create migrations with a version number in the future: #{name} #{version}"
    end
  end

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
  # in anticipation of having to re-run migrations due to integrity violations or
  # killing stuff that is holding locks too long
  def add_foreign_key_if_not_exists(from_table, to_table, options = {})
    options[:column] ||= "#{to_table.to_s.singularize}_id"
    column = options[:column]
    case self.adapter_name
    when 'PostgreSQL'
      foreign_key_name = foreign_key_name(from_table, options)
      schema = @config[:use_qualified_names] ? quote(shard.name) : 'current_schema()'
      value = select_value("SELECT convalidated FROM pg_constraint INNER JOIN pg_namespace ON pg_namespace.oid=connamespace WHERE conname='#{foreign_key_name}' AND nspname=#{schema}")
      if value == 'f'
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

  def find_foreign_key(from_table, to_table, column: nil)
    column ||= "#{to_table.to_s.singularize}_id"
    foreign_keys(from_table).find do |key|
      key.to_table == to_table.to_s && key.column == column.to_s
    end&.name
  end

  def alter_constraint(table, constraint, new_name: nil, deferrable: nil)
    raise ArgumentError, "must specify deferrable or a new name" if new_name.nil? && deferrable.nil?

    # can't rename and alter options in the same statement, so do the rename first
    if new_name && new_name != constraint
      execute("ALTER TABLE #{quote_table_name(table)}
               RENAME CONSTRAINT #{quote_column_name(constraint)} TO #{quote_column_name(new_name)}")
      constraint = new_name
    end

    unless deferrable.nil?
      options = deferrable ? "DEFERRABLE" : "NOT DEFERRABLE"
      execute("ALTER TABLE #{quote_table_name(table)}
               ALTER CONSTRAINT #{quote_column_name(constraint)} #{options}")
    end
  end

  def remove_foreign_key_if_exists(table, options = {})
    return unless foreign_key_exists?(table, options)
    remove_foreign_key(table, options)
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
  def run_callbacks(*args)
    scope = self.class.all.klass.unscoped
    scope.scoping { super }
  end
end
ActiveRecord::Base.send(:include, UnscopeCallbacks)

module MatchWithDiscard
  def match(model, name)
    result = super
    return nil if result && !result.is_a?(ActiveRecord::DynamicMatchers::FindBy)
    result
  end
end
ActiveRecord::DynamicMatchers::Method.singleton_class.prepend(MatchWithDiscard)

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
    def touch_record(o, _changes, _foreign_key, name, *)
      return if o.class.touch_callbacks_skipped?(name)
      super
    end
  end
end
ActiveRecord::Base.singleton_class.include(SkipTouchCallbacks::Base)
ActiveRecord::Associations::Builder::BelongsTo.singleton_class.prepend(SkipTouchCallbacks::BelongsTo)

module ReadonlyCloning
  def calculate_changes_from_defaults
    if @readonly_clone
      @changed_attributes = @changed_attributes.dup if @changed_attributes # otherwise changes to the clone will dirty the original
    else
      super # no reason to do this if we're creating a readonly clone - can take a long time with serialized columns
    end
  end
end
ActiveRecord::Base.prepend(ReadonlyCloning)

module DupArraysInMutationTracker
  # setting a serialized attribute to an array of hashes shouldn't change all the hashes to indifferent access
  # when the array gets stored in the indifferent access hash inside the mutation tracker
  # not that it really matters too much but having some consistency is nice
  def change_to_attribute(*args)
    change = super
    if change
      val = change[1]
      change[1] = val.dup if val.is_a?(Array)
    end
    change
  end
end
if CANVAS_RAILS5_1
  ActiveRecord::AttributeMutationTracker.prepend(DupArraysInMutationTracker)
else
  ActiveModel::AttributeMutationTracker.prepend(DupArraysInMutationTracker)
end

module IgnoreOutOfSequenceMigrationDates
  def current_migration_number(dirname)
    migration_lookup_at(dirname).map do |file|
      digits = File.basename(file).split("_").first
      next if ActiveRecord::Base.timestamped_migrations && digits.length != 14
      digits.to_i
    end.compact.max.to_i
  end
end
# Thor doesn't call `super` in its `inherited` method, so hook in so that we can hook in later :)
Thor::Group.singleton_class.prepend(Autoextend::ClassMethods)
Autoextend.hook(:"ActiveRecord::Generators::MigrationGenerator",
                IgnoreOutOfSequenceMigrationDates,
                singleton: true,
                method: :prepend,
                optional: true)

module AlwaysUseMigrationDates
  def next_migration_number(number)
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      SchemaMigration.normalize_migration_number(number)
    end
  end
end
ActiveRecord::Migration.prepend(AlwaysUseMigrationDates)

module ExplainAnalyze
  def exec_explain(queries, analyze: false) # :nodoc:
    str = queries.map do |sql, binds|
      msg = "EXPLAIN #{"ANALYZE " if analyze}for: #{sql}"
      unless binds.empty?
        msg << " "
        msg << binds.map { |attr| render_bind(attr) }.inspect
      end
      msg << "\n"
      msg << connection.explain(sql, binds, analyze: analyze)
    end.join("\n")

    # Overriding inspect to be more human readable, especially in the console.
    def str.inspect
      self
    end

    str
  end

  def explain(analyze: false)
    #TODO: Fix for binds.
    exec_explain(collecting_queries_for_explain do
      if block_given?
        yield
      else
        # fold in switchman's override
        self.activate { |relation| relation.send(:exec_queries) }
      end
    end, analyze: analyze)
  end
end
ActiveRecord::Relation.prepend(ExplainAnalyze)

if CANVAS_RAILS5_1
  ActiveRecord::AttributeMethods::Dirty.module_eval do
    def emit_warning_if_needed(method_name, new_method_name)
      unless mutation_tracker.equal?(mutations_from_database)
        raise <<-EOW.squish
                The behavior of `#{method_name}` inside of after callbacks will
                be changing in the next version of Rails. The new return value will reflect the
                behavior of calling the method after `save` returned (e.g. the opposite of what
                it returns now). To maintain the current behavior, use `#{new_method_name}`
                instead.
        EOW
      end
    end
  end
end

# fake Rails into grabbing correct column information for a table rename in-progress
module TableRename
  RENAMES = { 'authentication_providers' => 'account_authorization_configs' }.freeze

  def columns(table_name)
    if (old_name = RENAMES[table_name])
      table_name = old_name if connection.table_exists?(old_name)
    end
    super
  end
end

ActiveRecord::ConnectionAdapters::SchemaCache.prepend(TableRename)


if CANVAS_RAILS5_1
  module EnforceRawSqlWhitelist
    COLUMN_NAME_ORDER_WHITELIST = /
        \A
        (?:\w+\.)?
        \w+
        (?:\s+asc|\s+desc)?
        (?:\s+nulls\s+(?:first|last))?
        \z
      /ix

    def enforce_raw_sql_whitelist(args, whitelist: COLUMN_NAME_WHITELIST) # :nodoc:
      unexpected = args.reject do |arg|
        arg.kind_of?(Arel::Node) ||
          arg.is_a?(Arel::Nodes::SqlLiteral) ||
          arg.is_a?(Arel::Attributes::Attribute) ||
          arg.to_s.split(/\s*,\s*/).all? { |part| whitelist.match?(part) }
      end

      return if unexpected.none?

      raise(
            "Query method called with non-attribute argument(s): " +
              unexpected.map(&:inspect).join(", ")
      )
    end

    def validate_order_args(order_args)
      enforce_raw_sql_whitelist(
        order_args.flat_map { |a| a.is_a?(Hash) ? a.keys : a },
        whitelist: COLUMN_NAME_ORDER_WHITELIST
      )
      super
    end
  end

  ActiveRecord::Relation.prepend(EnforceRawSqlWhitelist)
end
