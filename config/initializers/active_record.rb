# frozen_string_literal: true

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

require "active_support/callbacks/suspension"

class ActiveRecord::Base
  self.cache_timestamp_format = :usec

  public :write_attribute

  class << self
    delegate :distinct_on, :find_ids_in_batches, :explain, to: :all

    def find_ids_in_ranges(loose: true, **kwargs, &block)
      all.find_ids_in_ranges(loose:, **kwargs, &block)
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
          regex = /\A#{Regexp.escape(method.source_location.first)}:\d+:in `#{Regexp.escape(method.name)}'\z/
          stacktrace.index { |s| s =~ regex }
        end
      end

      if transaction_index
        # we wrap a transaction around controller actions, so try to see if this call came from that
        if wrap_index && (transaction_index..wrap_index).all? { |i| stacktrace[i].match?(/transaction|synchronize|unguard/) }
          false
        else
          # check if this is being run through an after_transaction_commit since the last transaction
          !(after_index && after_index < transaction_index)
        end
      else
        false
      end
    end

    def vacuum
      # can't vacuum in a transaction
      return if Rails.env.test?

      GuardRail.activate(:deploy) do
        connection.vacuum(table_name, analyze: true)
      end
    end
  end

  def read_or_initialize_attribute(attr_name, default_value)
    # have to read the attribute again because serialized attributes in Rails 4.2 get duped
    read_attribute(attr_name) || (write_attribute(attr_name, default_value) && read_attribute(attr_name))
  end

  alias_method :clone, :dup

  # See ActiveModel#serializable_add_includes
  def serializable_add_includes(options = {})
    super(options) do |association, records, opts|
      yield association, records, opts.reverse_merge(include_root: options[:include_root])
    end
  end

  def feed_code
    id = uuid rescue self.id
    "#{self.class.reflection_type_name}_#{id}"
  end

  def self.global_id?(id)
    !!id && id.to_i > Shard::IDS_PER_SHARD
  end

  def self.maximum_text_length
    @maximum_text_length ||= 64.kilobytes - 1
  end

  def self.maximum_long_text_length
    @maximum_long_text_length ||= 500.kilobytes - 1
  end

  def self.maximum_string_length
    255
  end

  def self.find_by_asset_string(string, asset_types = nil)
    find_all_by_asset_string([string], asset_types)[0]
  end

  def self.find_all_by_asset_string(strings, asset_types = nil)
    assets = strings.is_a?(Hash) ? strings : parse_asset_string_list(strings)

    assets.filter_map do |klass, ids|
      next if asset_types&.exclude?(klass)

      begin
        klass = klass.constantize
      rescue NameError
        next
      end
      next unless klass < ActiveRecord::Base

      klass.where(id: ids).to_a
    end.flatten
  end

  # takes an asset string list, like "course_5,user_7,course_9" and turns it into an
  # hash of { class_name => [ id ] } like { "Course" => [5, 9], "User" => [7] }
  def self.parse_asset_string_list(asset_string_list)
    asset_strings = asset_string_list.is_a?(Array) ? asset_string_list : asset_string_list.to_s.split(",")
    result = {}
    asset_strings.each do |str|
      type, id = parse_asset_string(str)
      (result[type] ||= []) << id
    end
    result
  end

  def self.parse_asset_string(str)
    code = asset_string_components(str)
    [convert_class_name(code.first), code.last.try(:to_i)]
  end

  def self.asset_string_components(str)
    components = str.split("_", -1)
    id = components.pop
    [components.join("_"), id.presence]
  end

  def self.convert_class_name(str)
    namespaces = str.split(":")
    class_name = namespaces.pop
    (namespaces.map(&:camelize) + [class_name.try(:classify)]).join("::")
  end

  def self.asset_string(id)
    "#{reflection_type_name}_#{id}"
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
    asset&.id == send(:"#{field}_id") && asset.class.polymorphic_name == send(:"#{field}_type")
  end

  def context_string(field = :context)
    send(:"#{field}_type").underscore + "_" + send(:"#{field}_id").to_s if send(:"#{field}_type")
  end

  def self.asset_string_backcompat_module
    @asset_string_backcompat_module ||= Module.new.tap { |m| prepend(m) }
  end

  def self.define_asset_string_backcompat_method(string_version_name, association_version_name = string_version_name, method = nil)
    # just chain to the two methods
    unless method
      # this is weird, but gets the instance methods defined so they can be chained
      begin
        new.send(:"#{association_version_name}_id")
      rescue
        # the db doesn't exist yet; no need to bother with backcompat methods anyway
        return
      end
      define_asset_string_backcompat_method(string_version_name, association_version_name, "id")
      define_asset_string_backcompat_method(string_version_name, association_version_name, "type")
      return
    end

    asset_string_backcompat_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
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
    RUBY
  end

  def export_columns
    self.class.content_columns.map(&:name)
  end

  def to_row
    export_columns.map { |c| send(c) }
  end

  def is_a_context?
    false
  end

  def cached_context_short_name
    if respond_to?(:context)
      code = respond_to?(:context_code) ? context_code : context.asset_string
      @cached_context_name ||= Rails.cache.fetch(["short_name_lookup", code].cache_key) do
        context.short_name rescue ""
      end
    else
      raise "Can only call cached_context_short_name on items with a context"
    end
  end

  def self.skip_touch_context(skip = true)
    @@skip_touch_context = skip
  end

  def save_without_touching_context
    @skip_touch_context = true
    save
    @skip_touch_context = false
  end

  def touch_context
    return if @@skip_touch_context ||= false || @skip_touch_context ||= false

    self.class.connection.after_transaction_commit do
      if respond_to?(:context_type) && respond_to?(:context_id) && context_type && context_id
        context_type.constantize.where(id: context_id).update_all(updated_at: Time.now.utc)
      end
    end
  rescue
    Canvas::Errors.capture_exception(:touch_context, $ERROR_INFO)
  end

  def touch_user
    if respond_to?(:user_id) && user_id
      User.connection.after_transaction_commit do
        User.where(id: user_id).update_all(updated_at: Time.now.utc)
      end
    end
    true
  rescue
    Canvas::Errors.capture_exception(:touch_user, $ERROR_INFO)
    false
  end

  def context_url_prefix
    "#{context_type.downcase.pluralize}/#{context_id}"
  end

  # Example:
  # obj.to_json(:permissions => {:user => u, :policies => [:read, :write, :update]})
  def as_json(options = nil)
    options = options.try(:dup) || {}

    set_serialization_options if respond_to?(:set_serialization_options)

    except = options.delete(:except) || []
    except = Array(except).dup
    except.concat(self.class.serialization_excludes) if self.class.respond_to?(:serialization_excludes)
    except.concat(serialization_excludes) if respond_to?(:serialization_excludes)
    except.uniq!

    methods = options.delete(:methods) || []
    methods = Array(methods).dup
    methods.concat(self.class.serialization_methods) if self.class.respond_to?(:serialization_methods)
    methods.concat(serialization_methods) if respond_to?(:serialization_methods)
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
      obj_hash = options[:include_root] ? hash[self.class.serialization_root_key] : hash

      if respond_to?(:filter_attributes_for_user)
        filter_attributes_for_user(obj_hash, options[:permissions][:user], options[:permissions][:session])
      end
      unless options[:permissions][:include_permissions] == false
        permissions_hash = rights_status(options[:permissions][:user], options[:permissions][:session], *options[:permissions][:policies])
        if respond_to?(:serialize_permissions)
          permissions_hash = serialize_permissions(permissions_hash, options[:permissions][:user], options[:permissions][:session])
        end
        obj_hash["permissions"] = permissions_hash
      end
    end

    revert_from_serialization_options if respond_to?(:revert_from_serialization_options)

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

  def self.serialization_root_key
    base_class.model_name.element
  end

  def self.url_context_class
    base_class
  end

  ruby2_keywords def wildcard(*args)
    self.class.wildcard(*args)
  end

  def self.wildcard(*args, type: :full, delimiter: nil, case_sensitive: false)
    value = args.pop
    if delimiter
      type = :full
      value = delimiter + value + delimiter
      delimiter = connection.quote(delimiter)
      column_str = "#{delimiter} || %s || #{delimiter}"
      args = args.map { |a| column_str % a.to_s }
    end

    value = wildcard_pattern(value, case_sensitive:, type:)
    cols = args.map { |col| like_condition(col, "?", !case_sensitive) }
    sanitize_sql_array ["(#{cols.join(" OR ")})", *([value] * cols.size)]
  end

  def self.wildcard_pattern(value, case_sensitive: false, type: :full)
    value = value.to_s
    value = value.downcase unless case_sensitive
    value = value.gsub("\\", "\\\\\\\\").gsub("%", "\\%").gsub("_", "\\_")
    value = "%#{value}" unless type == :right
    value += "%" unless type == :left
    value
  end

  def self.coalesced_wildcard(*args)
    value = args.pop
    value = wildcard_pattern(value)
    cols = coalesce_chain(args)
    sanitize_sql_array ["(#{like_condition(cols, "?", false)})", value]
  end

  def self.coalesce_chain(cols)
    "(#{cols.map { |col| coalesce_clause(col) }.join(" || ' ' || ")})"
  end

  def self.coalesce_clause(column)
    "COALESCE(LOWER(#{column}), '')"
  end

  def self.like_condition(value, pattern = "?", downcase = true)
    value = "LOWER(#{value})" if downcase
    "#{value} LIKE #{pattern}"
  end

  def self.best_unicode_collation_key(col)
    val =
      # For PostgreSQL, we can't trust a simple LOWER(column), with any collation, since
      # Postgres just defers to the C library which is different for each platform. The best
      # choice is to use an ICU collation to get a full unicode sort.
      # If the collations aren't around, casting to a bytea sucks for international characters,
      # but at least it's consistent, and orders commas before letters so you don't end up with
      # Johnson, Bob sorting before Johns, Jimmy
      if (collation = Canvas::ICU.choose_pg12_collation(connection.icu_collations))
        "(#{col} COLLATE #{collation})"
      else
        "CAST(LOWER(replace(#{col}, '\\', '\\\\')) AS bytea)"
      end
    Arel.sql(val)
  end

  def self.count_by_date(options = {})
    column = options[:column] || "created_at"
    max_date = (options[:max_date] || Time.zone.now).midnight
    num_days = options[:num_days] || 20
    min_date = (options[:min_date] || max_date.advance(days: -(num_days - 1))).midnight

    expression = "((#{column} || '-00')::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.tzinfo.name}')::DATE"

    result = where("#{column} >= ? AND #{column} < ?",
                   min_date,
                   max_date.advance(days: 1))
             .group(expression)
             .order(Arel.sql(expression))
             .count

    return result if result.keys.first.is_a?(Date)

    result.transform_keys do |date|
      Time.zone.parse(date).to_date
    end
  end

  def self.rank_sql(ary, col)
    sql = ary.each_with_index.inject(+"CASE ") do |string, (values, i)|
      string << "WHEN #{col} IN (" << Array(values).map { |value| connection.quote(value) }.join(", ") << ") THEN #{i} "
    end << "ELSE #{ary.size} END"
    Arel.sql(sql)
  end

  def self.rank_hash(ary)
    ary.each_with_index.with_object(Hash.new(ary.size + 1)) do |(values, i), hash|
      Array(values).each { |value| hash[value] = i + 1 }
    end
  end

  def self.distinct_values(column, include_nil: false)
    column = column.to_s

    sql = +""
    sql << "SELECT NULL AS #{column} WHERE EXISTS (SELECT * FROM #{quoted_table_name} WHERE #{column} IS NULL) UNION ALL (" if include_nil
    sql << <<~SQL.squish
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
    result = find_by_sql(sql)
    result.map(&column.to_sym)
  end

  # direction is nil, :asc, or :desc
  def self.nulls(first_or_last, column, direction = nil)
    clause = if first_or_last == :first && direction != :desc
               " NULLS FIRST"
             elsif first_or_last == :last && direction == :desc
               " NULLS LAST"
             end

    Arel.sql("#{column} #{direction.to_s.upcase}#{clause}".strip)
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

    if name.to_s == "developer_key"
      reflection.instance_eval do
        def association_class
          DeveloperKey::CacheOnAssociation
        end
      end
    end

    include Canvas::RootAccountCacher if name.to_s == "root_account"
    Canvas::AccountCacher.apply_to_reflections(self)

    if reflection.options[:polymorphic].is_a?(Array) ||
       reflection.options[:polymorphic].is_a?(Hash)
      reflection.options[:exhaustive] = exhaustive
      reflection.options[:polymorphic_prefix] = polymorphic_prefix
      add_polymorph_methods(reflection)
    end
    reflection
  end

  def self.canonicalize_polymorph_list(list)
    specifics = []
    Array.wrap(list).each do |name|
      if name.is_a?(Hash)
        specifics.concat(name.to_a)
      else
        specifics << [name, name.to_s.camelize]
      end
    end
    specifics
  end

  def self.add_polymorph_methods(reflection)
    unless @polymorph_module
      @polymorph_module = Module.new
      include(@polymorph_module)
    end

    specifics = canonicalize_polymorph_list(reflection.options[:polymorphic])

    unless reflection.options[:exhaustive] == false
      specific_classes = specifics.map(&:last).sort
      validates reflection.foreign_type, inclusion: { in: specific_classes }, allow_nil: true

      @polymorph_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{reflection.name}=(record)
          if record && [#{specific_classes.join(", ")}].none? { |klass| record.is_a?(klass) }
            message = "one of #{specific_classes.join(", ")} expected, got \#{record.class}"
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
      belongs_to(:"#{prefix}#{name}",
                 -> { where(table_name => { reflection.foreign_type => class_name }) },
                 foreign_key: reflection.foreign_key,
                 class_name:) # rubocop:disable Rails/ReflectionClassName

      correct_type = "#{reflection.foreign_type} && self.class.send(:compute_type, #{reflection.foreign_type}) <= #{class_name}"

      @polymorph_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
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

  # Returns the class for the provided +name+.
  #
  # It is used to find the class correspondent to the value stored in the polymorphic type column.
  def self.polymorphic_class_for(name)
    case name
    when "Assignment"
      # Let's be consistent with the way AR handles things by default for STI. If name is "Assignment"
      # we'll fetch the Assignment or SubAssignment through its base class (AbstractAssignment).
      super("AbstractAssignment")
    else
      super
    end
  end

  def self.unique_constraint_retry(retries = 1)
    # runs the block in a (possibly nested) transaction. if a unique constraint
    # violation occurs, it will run it "retries" more times. the nested
    # transaction (savepoint) ensures we don't mess up things for the outer
    # transaction. useful for possible race conditions where we don't want to
    # take a lock (e.g. when we create a submission).
    retries.times do |retry_count|
      result = transaction(requires_new: true) { uncached { yield(retry_count) } }
      connection.clear_query_cache
      return result
    rescue ActiveRecord::RecordNotUnique
      next
    end
    GuardRail.activate(:primary) do
      result = transaction(requires_new: true) { uncached { yield(retries) } }
      connection.clear_query_cache
      result
    end
  end

  def self.current_xlog_location
    Shard.current(connection_class_for_self).database_server.unguard do
      GuardRail.activate(:primary) do
        if Rails.env.test? ? in_transaction_in_test? : connection.open_transactions > 0
          raise "don't run current_xlog_location in a transaction"
        else
          connection.current_wal_lsn
        end
      end
    end
  end

  def self.wait_for_replication(start: nil, timeout: nil, use_report: false)
    return true unless GuardRail.activate(:secondary) { connection.readonly? }

    replica = use_report ? :report : :secondary
    start ||= current_xlog_location
    GuardRail.activate(replica) do
      # positive == first value greater, negative == second value greater
      start_time = Time.now.utc
      while connection.wal_lsn_diff(start, :last_replay) >= 0
        return false if timeout && Time.now.utc > start_time + timeout

        sleep 0.1
      end
    end
    true
  end

  def self.bulk_insert_objects(objects, excluded_columns: ["primary_key"])
    return if objects.empty?

    excluded_columns << objects.first.class.primary_key if excluded_columns.delete("primary_key")
    hashed_objects = objects.map do |object|
      object.attributes.except(excluded_columns.join(",")).to_h do |name, value|
        if (type = object.class.attribute_types[name]).is_a?(ActiveRecord::Type::Serialized)
          value = type.serialize(value)
        end
        [name, value]
      end
    end
    objects.first.class.bulk_insert(hashed_objects)
  end

  def self.bulk_insert(records)
    return if records.empty?

    array_columns = records.first.select { |_k, v| v.is_a?(Array) }.keys
    array_columns.each do |column_name|
      cast_type = connection.send(:lookup_cast_type_from_column, columns_hash[column_name.to_s])
      records.each do |row|
        row[column_name] = cast_type.serialize(row[column_name])
      end
    end

    if respond_to?(:attrs_in_partition_groups)
      # this model is partitioned, we need to send a separate
      # insert statement for each partition represented
      # in the input records
      attrs_in_partition_groups(records) do |partition_name, partition_records|
        transaction do
          connection.bulk_insert(partition_name, partition_records)
        end
      end
    else
      transaction do
        connection.bulk_insert(table_name, records)
      end
    end
  end

  include ActiveSupport::Callbacks::Suspension

  def self.touch_all_records
    find_ids_in_ranges do |min_id, max_id|
      where(primary_key => min_id..max_id).touch_all
    end
  end

  def self.create_and_ignore_on_duplicate(*args)
    # FIXME: handle array fields and setting of nulls where those are not the default
    model = new(*args)
    attributes = []
    values = []

    model.run_callbacks :validation do
      raise model.errors.full_messages.first unless model.valid?
    end

    model.run_callbacks :create do
      timestamps = %w[created_at updated_at]
      model.attributes.each do |attribute, value|
        value = "NOW()" if timestamps.include? attribute
        next if (model[attribute].nil? && !(timestamps.include? attribute)) || value.is_a?(Array)

        values << connection.quote(value)
        attributes << connection.quote_column_name(attribute)
      end

      insert_sql = <<~SQL.squish
        WITH new_row AS (
          INSERT INTO #{quoted_table_name}
                      (#{attributes.join(",")})
              VALUES (#{values.join(",")})
          ON CONFLICT DO NOTHING
          RETURNING *
        )
        SELECT * FROM new_row
        UNION
        #{except(:select).where(*args).to_sql}
      SQL

      find_by_sql(insert_sql).first
    end
  end

  # skips validations, callbacks, and a transaction
  # do _NOT_ improve in the future to handle validations and callbacks - make
  # it a separate method or optional functionality. some callers explicitly
  # rely on no callbacks or validations
  def save_without_transaction(touch: true)
    return unless changed?

    self.updated_at = Time.now.utc if touch
    if new_record?
      self.created_at = updated_at if touch
      if Rails.version < "7.1"
        self.id = self.class._insert_record(
          attributes_with_values(attribute_names_for_partial_inserts)
            .transform_values { |attr| attr.is_a?(ActiveModel::Attribute) ? attr.value : attr }
        )
      else
        returning_columns = self.class._returning_columns_for_insert
        returning_values = self.class._insert_record(
          attributes_with_values(attribute_names_for_partial_inserts)
            .transform_values { |attr| attr.is_a?(ActiveModel::Attribute) ? attr.value : attr },
          returning_columns
        )

        if returning_values
          returning_columns.zip(returning_values).each do |column, value|
            _write_attribute(column, value) unless _read_attribute(column)
          end
        end
      end
      @new_record = false
      @previously_new_record = true
    else
      update_columns(
        attributes_with_values(attribute_names_for_partial_updates)
          .transform_values { |attr| attr.is_a?(ActiveModel::Attribute) ? attr.value : attr }
      )
    end
    changes_applied
  end

  def self.override_db_configs(override)
    configurations.configurations.each do |config|
      config.instance_variable_set(:@configuration_hash, config.configuration_hash.merge(override).freeze)
    end
    clear_all_connections!(nil)

    # Just return something that isn't an ar connection object so consoles don't explode
    override
  end

  def self.with_pgvector(&)
    vector_schema = connection.extension("vector").schema
    connection.add_schema_to_search_path(vector_schema, &)
  end
end

module UsefulFindInBatches
  # add the strategy param
  def find_each(start: nil, finish: nil, order: :asc, **kwargs, &block)
    if block
      find_in_batches(start:, finish:, order:, **kwargs) do |records|
        records.each(&block)
      end
    else
      enum_for(:find_each, start:, finish:, order:, **kwargs) do
        relation = self
        order = build_batch_orders(order) if $canvas_rails == "7.1"
        apply_limits(relation, start, finish, order).size
      end
    end
  end

  # add the strategy param
  def find_in_batches(batch_size: 1000, start: nil, finish: nil, order: :asc, **kwargs)
    relation = self
    unless block_given?
      return to_enum(:find_in_batches, start:, finish:, order:, batch_size:, **kwargs) do
        order = build_batch_orders(order) if $canvas_rails == "7.1"
        total = apply_limits(relation, start, finish, order).size
        (total - 1).div(batch_size) + 1
      end
    end

    in_batches(of: batch_size, start:, finish:, order:, load: true, **kwargs) do |batch|
      yield batch.to_a
    end
  end

  def in_batches(strategy: nil, start: nil, finish: nil, order: :asc, **kwargs, &block)
    unless block
      return ActiveRecord::Batches::BatchEnumerator.new(strategy:, start:, relation: self, **kwargs)
    end

    unless [:asc, :desc].include?(order)
      raise ArgumentError, ":order must be :asc or :desc, got #{order.inspect}"
    end

    strategy ||= infer_in_batches_strategy

    # TODO: should we add the `act_on_ignored_order(error_on_ignore)` snippet

    if strategy == :id
      raise ArgumentError, "GROUP BY is incompatible with :id batches strategy" unless group_values.empty?

      return activate { |r| r.call_super(:in_batches, UsefulFindInBatches, start:, finish:, order:, **kwargs, &block) }
    end

    kwargs.delete(:error_on_ignore)
    activate do |r|
      r.send(:"in_batches_with_#{strategy}", start:, finish:, order:, **kwargs, &block)
      nil
    end
  end

  def in_batches_needs_temp_table?
    order_values.any? ||
      group_values.any? ||
      select_values.to_s =~ /DISTINCT/i ||
      distinct_value ||
      in_batches_select_values_necessitate_temp_table?
  end

  def infer_in_batches_strategy
    strategy ||= :copy if in_batches_can_use_copy?
    strategy ||= :cursor if in_batches_can_use_cursor?
    strategy ||= :temp_table if in_batches_needs_temp_table?
    strategy || :id
  end

  private

  def in_batches_can_use_copy?
    connection.open_transactions == 0 && eager_load_values.empty? && !ActiveRecord::Base.in_migration
  end

  def in_batches_can_use_cursor?
    eager_load_values.empty? && (GuardRail.environment == :secondary || connection.readonly?)
  end

  def in_batches_select_values_necessitate_temp_table?
    return false if select_values.blank?

    selects = select_values.flat_map { |sel| sel.to_s.split(",").map(&:strip) }
    id_keys = [primary_key, "*", "#{table_name}.#{primary_key}", "#{table_name}.*"]
    id_keys.all? { |k| !selects.include?(k) }
  end

  def in_batches_with_cursor(of: 1000, start: nil, finish: nil, order: :asc, load: false)
    klass.transaction do
      order = build_batch_orders(order) if $canvas_rails == "7.1"
      relation = apply_limits(clone, start, finish, order)

      relation.skip_query_cache!
      unless load
        relation = relation.except(:select).select(primary_key)
      end
      sql = relation.to_sql
      cursor = "#{table_name}_in_batches_cursor_#{sql.hash.abs.to_s(36)}"
      connection.execute("DECLARE #{cursor} CURSOR FOR #{sql}")

      loop do
        if load
          records = connection.uncached { klass.find_by_sql("FETCH FORWARD #{of} FROM #{cursor}") }
          ids = records.map(&:id)
          preload_associations(records)
          yielded_relation = where(primary_key => ids).preload(includes_values + preload_values)
          yielded_relation.send(:load_records, records)
        else
          ids = connection.uncached { connection.select_values("FETCH FORWARD #{of} FROM #{cursor}") }
          yielded_relation = where(primary_key => ids).preload(includes_values + preload_values)
          yielded_relation = yielded_relation.extending(BatchWithColumnsPreloaded).set_values(ids)
        end

        break if ids.empty?

        yield yielded_relation

        break if ids.size < of
      end
    ensure
      unless $!.is_a?(ActiveRecord::StatementInvalid)
        connection.execute("CLOSE #{cursor}")
      end
    end
  end

  def in_batches_with_copy(of: 1000, start: nil, finish: nil, order: :asc, load: false)
    limited_query = limit(0).to_sql

    relation = self
    order = build_batch_orders(order) if $canvas_rails == "7.1"
    relation_for_copy = apply_limits(relation, start, finish, order)
    unless load
      relation_for_copy = relation_for_copy.except(:select).select(primary_key)
    end
    full_query = "COPY (#{relation_for_copy.to_sql}) TO STDOUT"
    conn = connection
    full_query = conn.annotate_sql(full_query) if defined?(Marginalia)
    pool = conn.pool
    # remove the connection from the pool so that any queries executed
    # while we're running this will get a new connection
    pool.remove(conn)

    checkin = lambda do
      pool&.restore_connection(conn)
      pool = nil
    end

    # make sure to log _something_, even if the dbtime is totally off
    conn.send(:log, full_query, "#{klass.name} Load") do
      decoder = if load
                  # set up all our metadata based on a dummy query (COPY doesn't return any metadata)
                  result = conn.raw_connection.exec(limited_query)
                  type_map = conn.raw_connection.type_map_for_results.build_column_map(result)
                  # see PostgreSQLAdapter#exec_query
                  types = {}
                  fields = result.fields
                  fields.each_with_index do |fname, i|
                    ftype = result.ftype i
                    fmod = result.fmod i
                    types[fname] = conn.send(:get_oid_type, ftype, fmod, fname)
                  end

                  column_types = types.dup
                  columns_hash.each_key { |k| column_types.delete k }

                  PG::TextDecoder::CopyRow.new(type_map:)
                else
                  pkey_oid = columns_hash[primary_key].sql_type_metadata.oid
                  # this is really dumb that we have to manually search through this, but
                  # PG::TypeMapByOid doesn't have a direct lookup method
                  coder = conn.raw_connection.type_map_for_results.coders.find { |c| c.oid == pkey_oid }

                  PG::TextDecoder::CopyRow.new(type_map: PG::TypeMapByColumn.new([coder]))
                end

      rows = []

      build_relation = lambda do
        if load
          records = ActiveRecord::Result.new(fields, rows, types).map { |record| instantiate(record, column_types) }
          ids = records.map(&:id)
          yielded_relation = relation.where(primary_key => ids)
          preload_associations(records)
          yielded_relation.send(:load_records, records)
        else
          ids = rows.map(&:first)
          yielded_relation = relation.where(primary_key => ids)
          yielded_relation = yielded_relation.extending(BatchWithColumnsPreloaded).set_values(ids)
        end
        yielded_relation
      end

      conn.raw_connection.copy_data(full_query, decoder) do
        while (row = conn.raw_connection.get_copy_data)
          rows << row
          if rows.size == of
            yield build_relation.call
            rows = []
          end
        end
      end
      # return the connection now, in case there was only 1 batch, we can avoid a separate connection if the block needs it
      checkin.call

      unless rows.empty?
        yield build_relation.call
      end
    end
    nil
  ensure
    # put the connection back in the pool for reuse
    checkin&.call
  end

  # in some cases we're doing a lot of work inside
  # the yielded block, and holding open a transaction
  # or even a connection while we do all that work can
  # be a problem for the database, especially if a lot
  # of these are happening at once.  This strategy
  # makes one query to hold onto all the IDs needed for the
  # iteration (make sure they'll fit in memory, or you could be sad)
  # and yields the objects in batches in the same order as the scope specified
  # so the DB connection can be fully recycled during each block.
  def in_batches_with_pluck_ids(of: 1000, start: nil, finish: nil, order: :asc, load: false)
    order = build_batch_orders(order) if $canvas_rails == "7.1"
    relation = apply_limits(self, start, finish, order)
    all_object_ids = relation.pluck(:id)
    current_order_values = order_values
    all_object_ids.in_groups_of(of) do |id_batch|
      object_batch = klass.unscoped.where(id: id_batch).order(current_order_values).preload(includes_values + preload_values)
      yield object_batch
    end
  end

  def in_batches_with_temp_table(of: 1000, start: nil, finish: nil, load: false, order: :asc, ignore_transaction: false)
    Shard.current.database_server.unguard do
      can_do_it = ignore_transaction ||
                  Rails.env.production? ||
                  ActiveRecord::Base.in_migration ||
                  GuardRail.environment == :deploy ||
                  (!Rails.env.test? && connection.open_transactions > 0) ||
                  ActiveRecord::Base.in_transaction_in_test?
      unless can_do_it
        raise ArgumentError, "in_batches with temp_table probably won't work outside a migration
             and outside a transaction. Unfortunately, it's impossible to automatically
             determine a better way to do it that will work correctly. You can try
             switching to secondary first (then switching to primary if you modify anything
             inside your loop), wrapping in a transaction (but be wary of locking records
             for the duration of your query if you do any writes in your loop), or not
             forcing in_batches to use a temp table (avoiding custom selects,
             group, or order)."
      end

      order = build_batch_orders(order) if $canvas_rails == "7.1"
      relation = apply_limits(self, start, finish, order)
      sql = relation.to_sql
      table = "#{table_name}_in_batches_temp_table_#{sql.hash.abs.to_s(36)}"
      table = table[-63..] if table.length > 63

      remaining = connection.update("CREATE TEMPORARY TABLE #{table} AS #{sql}")

      begin
        return if remaining.zero?

        if remaining > of
          begin
            old_proc = connection.raw_connection.set_notice_processor { nil }
            index = if (select_values.empty? || select_values.any? { |v| v.to_s == primary_key.to_s }) && order_values.empty?
                      connection.execute(%{CREATE INDEX "temp_primary_key" ON #{connection.quote_local_table_name(table)}(#{connection.quote_column_name(primary_key)})})
                      primary_key.to_s
                    else
                      connection.execute "ALTER TABLE #{table} ADD temp_primary_key SERIAL PRIMARY KEY"
                      "temp_primary_key"
                    end
          ensure
            connection.raw_connection.set_notice_processor(&old_proc) if old_proc
          end
        end

        base_class = klass.base_class
        base_class.unscoped do
          # Ensure we don't enumerate columns on the temp table, because the temp table may not have the same columns as the base class
          ignored_columns_was = base_class.ignored_columns
          enumerate_columns_was = base_class.enumerate_columns_in_select_statements
          base_class.enumerate_columns_in_select_statements = false
          base_class.ignored_columns = [] # rubocop:disable Rails/IgnoredColumnsAssignment
          batch_relation = base_class.from("#{connection.quote_column_name(table)} as #{connection.quote_column_name(base_class.table_name)}").limit(of).preload(includes_values + preload_values)
          batch_relation = batch_relation.order(Arel.sql(connection.quote_column_name(index))) if index
          yielded_relation = batch_relation
          loop do
            yield yielded_relation

            remaining -= of
            break if remaining <= 0

            last_value = if yielded_relation.loaded?
                           yielded_relation.last[index]
                         else
                           yielded_relation.offset(of - 1).limit(1).pick(index)
                         end
            break if last_value.nil?

            yielded_relation = batch_relation.where("#{connection.quote_column_name(index)} > ?", last_value)
          end
        ensure
          base_class.ignored_columns = ignored_columns_was # rubocop:disable Rails/IgnoredColumnsAssignment
          base_class.enumerate_columns_in_select_statements = enumerate_columns_was
        end
      ensure
        if !$!.is_a?(ActiveRecord::StatementInvalid) || connection.open_transactions == 0
          connection.execute "DROP TABLE #{table}"
        end
      end
    end
  end
end
ActiveRecord::Relation.prepend(UsefulFindInBatches)

module UsefulBatchEnumerator
  def initialize(strategy: nil, **kwargs)
    @strategy = strategy
    @kwargs = kwargs.except(:relation)
    super(**kwargs.slice(:of, :start, :finish, :relation))
  end

  def each_record(&block)
    return to_enum(:each_record) unless block

    @relation.to_enum(:in_batches, strategy: @strategy, load: true, **@kwargs).each do |relation|
      relation.records.each(&block)
    end
  end

  def delete_all
    sum = 0
    if @strategy.nil? && !@relation.in_batches_needs_temp_table?
      loop do
        current = nil
        @relation.connection.with_max_update_limit(@of) do
          current = @relation.limit(@of).delete_all
        end
        sum += current
        break unless current == @of
      end
      return sum
    end

    strategy = @strategy || @relation.infer_in_batches_strategy
    @relation.in_batches(strategy:, load: false, **@kwargs) do |relation|
      @relation.connection.with_max_update_limit(@of) do
        sum += relation.delete_all
      end
    end
    sum
  end

  def update_all(updates)
    sum = 0
    if @strategy.nil? && !@relation.in_batches_needs_temp_table? && relation_has_condition_on_updates?(updates)
      loop do
        current = nil
        @relation.connection.with_max_update_limit(@of) do
          current = @relation.limit(@of).update_all(updates)
        end
        sum += current
        break unless current == @of
      end
      return sum
    end

    strategy = @strategy || @relation.infer_in_batches_strategy
    @relation.in_batches(strategy:, load: false, **@kwargs) do |relation|
      @relation.connection.with_max_update_limit(@of) do
        sum += relation.update_all(updates)
      end
    end
    sum
  end

  # not implementing relation_has_condition_on_updates logic because this method is not used in places
  # where that would be useful.  If that changes no reason we couldn't implement it here
  def update_all_locked_in_order(lock_type: :no_key_update, **updates)
    sum = 0
    strategy = @strategy || @relation.infer_in_batches_strategy
    @relation.in_batches(strategy:, load: false, **@kwargs) do |relation|
      @relation.connection.with_max_update_limit(@of) do
        sum += relation.update_all_locked_in_order(lock_type:, **updates)
      end
    end
    sum
  end

  def touch_all(*names, time: nil)
    update_all_locked_in_order(**relation.klass.touch_attributes_with_time(*names, time:))
  end

  def destroy_all
    @relation.in_batches(strategy: @strategy, load: true, **@kwargs, &:destroy_all)
  end

  def each(&block)
    enum = @relation.to_enum(:in_batches, strategy: @strategy, load: true, **@kwargs)
    return enum.each(&block) if block

    enum
  end

  def pluck(*args)
    return to_enum(:pluck, *args) unless block_given?

    @relation.except(:select)
             .select(*args)
             .in_batches(strategy: @strategy, load: false, **@kwargs) do |relation|
      yield relation.pluck(*args)
    end
  end

  private

  def relation_has_condition_on_updates?(updates)
    return false unless updates.is_a?(Hash)
    return false if updates.empty?

    # is the column we're updating mentioned in the where clause?
    predicates = @relation.where_clause.send(:predicates)
    return false if predicates.empty?

    @relation.send(:_substitute_values, updates).any? do |(attr, update)|
      found_match = false
      predicates.any? do |pred|
        next unless pred.is_a?(Arel::Nodes::Binary) || pred.is_a?(Arel::Nodes::HomogeneousIn)
        next unless pred.left == attr

        found_match = true

        raw_update = update.value.is_a?(ActiveModel::Attribute) ? update.value.value_before_type_cast : update.value
        # we want to check exact class here, not ancestry, since we want to ignore
        # subclasses we don't understand
        if pred.instance_of?(Arel::Nodes::Equality)
          update != pred.right
        elsif pred.instance_of?(Arel::Nodes::NotEqual)
          update == pred.right
        elsif pred.instance_of?(Arel::Nodes::GreaterThanOrEqual)
          raw_update < (pred.right.value.is_a?(ActiveModel::Attribute) ? pred.right.value.value_before_type_cast : pred.right.value)
        elsif pred.instance_of?(Arel::Nodes::GreaterThan)
          raw_update <= (pred.right.value.is_a?(ActiveModel::Attribute) ? pred.right.value.value_before_type_cast : pred.right.value)
        elsif pred.instance_of?(Arel::Nodes::LessThanOrEqual)
          raw_update >= (pred.right.value.is_a?(ActiveModel::Attribute) ? pred.right.value.value_before_type_cast : pred.right.value)
        elsif pred.instance_of?(Arel::Nodes::LessThan)
          raw_update > (pred.right.value.is_a?(ActiveModel::Attribute) ? pred.right.value.value_before_type_cast : pred.right.value)
        elsif pred.instance_of?(Arel::Nodes::Between)
          raw_update < (pred.right.left.value.is_a?(ActiveModel::Attribute) ? pred.right.left.value.value_before_type_cast : pred.right.left.value) ||
            raw_update > (pred.right.right.value.is_a?(ActiveModel::Attribute) ? pred.right.right.value.value_before_type_cast : pred.right.right.value)
        elsif pred.instance_of?(Arel::Nodes::In) && pred.right.is_a?(Array)
          pred.right.exclude?(update)
        elsif pred.instance_of?(Arel::Nodes::NotIn) && pred.right.is_a?(Array)
          pred.right.include?(update)
        elsif pred.instance_of?(Arel::Nodes::HomogeneousIn)
          case pred.type
          when :in
            pred.right.map(&:value).exclude?(update.value.is_a?(ActiveModel::Attribute) ? update.value.value : update.value)
          when :notin
            pred.right.map(&:value).include?(update.value.is_a?(ActiveModel::Attribute) ? update.value.value : update.value)
          end
        end
      end && found_match
    end
  end
end
ActiveRecord::Batches::BatchEnumerator.prepend(UsefulBatchEnumerator)

module BatchWithColumnsPreloaded
  def set_values(values)
    @loaded_values = values
    self
  end

  def pluck(*args)
    return @loaded_values if args == [primary_key.to_sym] && @loaded_values

    super
  end
end

module LockForNoKeyUpdate
  def lock(lock_type = true)
    super(lock_type_clause(lock_type))
  end

  private

  def lock_type_clause(lock_type)
    return "FOR NO KEY UPDATE" if lock_type == :no_key_update
    return "FOR NO KEY UPDATE SKIP LOCKED" if lock_type == :no_key_update_skip_locked
    return "FOR UPDATE" if lock_type == true

    lock_type
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

  def not_recently_touched
    scope = self
    if (personal_space = Setting.get("touch_personal_space", 0).to_i) != 0
      personal_space -= 1
      # truncate to seconds
      bound = Time.at(Time.now.to_i - personal_space).utc
      scope = scope.where("#{connection.quote_local_table_name(table_name)}.updated_at<?", bound)
    end
    scope
  end

  def update_all_locked_in_order(lock_type: :no_key_update, **updates)
    locked_scope = lock_for_subquery_update(lock_type).order(primary_key.to_sym)
    base_class.unscoped.where(primary_key => locked_scope).update_all(updates)
  end

  def touch_all(*names, time: nil)
    activate do |relation|
      relation.update_all_locked_in_order(**relation.klass.touch_attributes_with_time(*names, time:))
    end
  end

  def touch_all_skip_locked(*names, time: nil)
    activate do |relation|
      relation.update_all_locked_in_order(**relation.klass.touch_attributes_with_time(*names, time:), lock_type: :no_key_update_skip_locked)
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
    relation.select_values = [+"DISTINCT ON (#{args.join(", ")}) "]
    relation.distinct_value = false

    relation.select_values.first << (old_select.empty? ? "*" : old_select.uniq.join(", "))

    relation
  end

  def union(*scopes, from: false)
    table = connection.quote_local_table_name(table_name)
    scopes.unshift(self)
    scopes = scopes.reject(&:null_relation?)
    return scopes.first if scopes.length == 1
    return self if scopes.empty?

    primary_shards = scopes.map(&:primary_shard).uniq

    raise "multiple shard values passed to union: #{primary_shards}" if primary_shards.count > 1

    primary_shards.first.activate do
      sub_query = scopes.map do |scope|
        scope = scope.except(:select, :order).select(primary_key) unless from
        "(#{scope.to_sql})"
      end.join(" UNION ALL ")
      return unscoped.where("#{table}.#{connection.quote_column_name(primary_key)} IN (#{sub_query})") unless from

      sub_query = +"(#{sub_query}) #{(from == true) ? table : from}"
      unscoped.from(sub_query)
    end
  end

  # returns batch_size ids at a time, working through the primary key from
  # smallest to largest.
  #
  # note this does a raw connection.select_values, so it doesn't work with scopes
  def find_ids_in_batches(batch_size: 1000, no_integer_cast: false)
    key = "#{quoted_table_name}.#{primary_key}"
    scope = except(:select).select(key).reorder(Arel.sql(key)).limit(batch_size)
    ids = connection.select_values(scope.to_sql)
    ids = ids.map(&:to_i) unless no_integer_cast
    while ids.present?
      yield ids
      break if ids.size < batch_size

      last_value = ids.last
      ids = connection.select_values(scope.where("#{key}>?", last_value).to_sql)
      ids = ids.map(&:to_i) unless no_integer_cast
    end
  end

  # returns 2 ids at a time (the min and the max of a range), working through
  # the primary key from smallest to largest.
  def find_ids_in_ranges(loose: false, batch_size: 1000, end_at: nil, start_at: nil)
    is_integer = columns_hash[primary_key.to_s].type == :integer
    loose_mode = loose && is_integer
    # loose_mode: if we don't care about getting exactly batch_size ids in between
    # don't get the max - just get the min and add batch_size so we get that many _at most_
    values = loose_mode ? "MIN(id)" : "MIN(id), MAX(id)"

    quoted_primary_key = "#{klass.connection.quote_local_table_name(table_name)}.#{klass.connection.quote_column_name(primary_key)}"
    as_id = " AS id" unless primary_key == "id"
    subquery_scope = except(:select).select("#{quoted_primary_key}#{as_id}").reorder(primary_key.to_sym).limit(loose_mode ? 1 : batch_size)
    subquery_scope = subquery_scope.where("#{quoted_primary_key} <= ?", end_at) if end_at

    first_subquery_scope = start_at ? subquery_scope.where("#{quoted_primary_key} >= ?", start_at) : subquery_scope

    ids = connection.select_rows("SELECT #{values} FROM (#{first_subquery_scope.to_sql}) AS subquery").first

    while ids.first.present?
      ids.map!(&:to_i) if is_integer
      ids << (ids.first + batch_size) if loose_mode

      yield(*ids)
      last_value = ids.last
      next_subquery_scope = subquery_scope.where(["#{quoted_primary_key}>?", last_value])
      ids = connection.select_rows("SELECT #{values} FROM (#{next_subquery_scope.to_sql}) AS subquery").first
    end
  end
end

module UpdateAndDeleteWithJoins
  def deconstruct_joins(joins_sql = nil)
    unless joins_sql
      joins_sql = ""
      add_joins!(joins_sql, nil)
    end
    tables = []
    join_conditions = []
    joins_sql.strip.split("INNER JOIN")[1..].each do |join|
      # this could probably be improved
      raise "PostgreSQL update_all/delete_all only supports INNER JOIN" unless join.strip =~ /([a-zA-Z0-9'"_.]+(?:(?:\s+[aA][sS])?\s+[a-zA-Z0-9'"_]+)?)\s+ON\s+(.*)/m

      tables << $1
      join_conditions << $2
    end
    [tables, join_conditions]
  end

  def update_all(updates, *args)
    if joins_values.empty?
      Shard.current.database_server.unguard { return super }
    end

    stmt = Arel::UpdateManager.new

    stmt.set Arel.sql(@klass.send(:sanitize_sql_for_assignment, updates))
    from = from_clause.value
    stmt.table(from ? Arel::Nodes::SqlLiteral.new(from) : table)
    stmt.key = table[primary_key]

    sql = stmt.to_sql

    collector = connection.send(:collector)
    arel.join_sources.each do |node|
      connection.visitor.accept(node, collector)
    end
    join_sql = collector.value

    tables, join_conditions = deconstruct_joins(join_sql)

    unless tables.empty?
      sql.concat(" FROM ")
      sql.concat(tables.join(", "))
      sql.concat(" ")
    end

    scope = self
    join_conditions.each { |join| scope = scope.where(join) }

    # skip any binds that are used in the join
    collector = connection.send(:collector)
    scope.arel.constraints.each do |node|
      connection.visitor.accept(node, collector)
    end
    where_sql = collector.value
    sql.concat("WHERE " + where_sql)
    Shard.current.database_server.unguard { connection.update(sql, "#{name} Update") }
  end

  def delete_all
    return super if joins_values.empty?

    sql = +"DELETE FROM #{quoted_table_name} "

    join_sql = arel.join_sources.map(&:to_sql).join(" ")
    tables, join_conditions = deconstruct_joins(join_sql)

    sql.concat("USING ")
    sql.concat(tables.join(", "))
    sql.concat(" ")

    scope = self
    join_conditions.each { |join| scope = scope.where(join) }

    collector = connection.send(:collector)
    scope.arel.constraints.each do |node|
      connection.visitor.accept(node, collector)
    end
    where_sql = collector.value
    sql.concat("WHERE " + where_sql)

    connection.delete(sql, "SQL", [])
  end
end
Switchman::ActiveRecord::Relation.include(UpdateAndDeleteWithJoins)

module UpdateAndDeleteAllWithLimit
  def delete_all(*args)
    if limit_value || offset_value
      scope = lock_for_subquery_update.except(:select).select(primary_key)
      return base_class.unscoped.where(primary_key => scope).delete_all
    end
    super
  end

  def update_all(updates, *args)
    if limit_value || offset_value
      scope = lock_for_subquery_update.except(:select).select(primary_key)
      return base_class.unscoped.where(primary_key => scope).update_all(updates)
    end
    super
  end

  private

  def lock_for_subquery_update(lock_type = true)
    return lock(lock_type) if !lock_type || joins_values.empty?

    # make sure to lock the proper table
    lock("#{lock_type_clause(lock_type)} OF #{connection.quote_local_table_name(klass.table_name)}")
  end
end
Switchman::ActiveRecord::Relation.include(UpdateAndDeleteAllWithLimit)

ActiveRecord::Associations::CollectionProxy.class_eval do
  def respond_to?(name, include_private = false)
    return super if [:marshal_dump, :_dump, "marshal_dump", "_dump"].include?(name)

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
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
  def bulk_insert(table_name, records)
    keys = records.first.keys
    quoted_keys = keys.map { |k| quote_column_name(k) }.join(", ")
    records.each do |record|
      execute <<~SQL.squish
        INSERT INTO #{quote_table_name(table_name)}
          (#{quoted_keys})
        VALUES
          (#{keys.map { |k| quote(record[k]) }.join(", ")})
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
    "#{name}(#{args.map { |arg| func_arg_esc(arg) }.join(", ")})"
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
    columns.map do |col|
      if col.respond_to?(:columns)
        col.columns.map do |c|
          "#{col.quoted_table_name}.#{quote_column_name(c.name)}"
        end
      else
        col
      end
    end
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
  # at least one of these tags is required
  DEPLOY_TAGS = [:predeploy, :postdeploy].freeze

  class << self
    def is_postgres?
      connection.adapter_name == "PostgreSQL"
    end

    def has_postgres_proc?(procname)
      connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='#{procname}'").to_i != 0
    end
  end

  def connection
    if self.class.respond_to?(:connection)
      self.class.connection
    else
      @connection || ActiveRecord::Base.connection
    end
  end

  def tags
    self.class.tags
  end
end

class ActiveRecord::MigrationProxy
  delegate :connection, :cassandra_cluster, to: :migration

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
    raise "#{name} (#{version}) is not tagged as exactly one of predeploy or postdeploy!" unless (@migration.tags & ActiveRecord::Migration::DEPLOY_TAGS).length == 1

    @migration
  end
end

module MigratorCache
  def migrations(paths)
    @@migrations_hash ||= {}
    @@migrations_hash[paths] ||= super
  end

  def migrations_paths
    @@migrations_paths ||= [Rails.root.join("db/migrate")]
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

  def execute_migration_in_transaction(migration)
    old_in_migration, ActiveRecord::Base.in_migration = ActiveRecord::Base.in_migration, true
    if defined?(Marginalia)
      old_migration_name, Marginalia::Comment.migration = Marginalia::Comment.migration, migration.name
    end
    if down? && !Rails.env.test? && !$confirmed_migrate_down
      require "highline"
      if HighLine.new.ask("Revert migration #{migration.name} (#{migration.version}) ? [y/N/a] > ") !~ /^([ya])/i
        raise("Revert not confirmed")
      end

      $confirmed_migrate_down = true if $1.casecmp?("a")
    end

    super
  ensure
    ActiveRecord::Base.in_migration = old_in_migration
    Marginalia::Comment.migration = old_migration_name if defined?(Marginalia)
  end
end
ActiveRecord::Migrator.prepend(Migrator)

ActiveRecord::Migrator.migrations_paths.concat Dir[Rails.root.join("gems/plugins/*/db/migrate")]

ActiveRecord::Tasks::DatabaseTasks.migrations_paths = ActiveRecord::Migrator.migrations_paths

ActiveRecord::ConnectionAdapters::SchemaStatements.class_eval do
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

  def foreign_key_for(from_table, **options)
    return unless supports_foreign_keys?

    fks = foreign_keys(from_table).select { |fk| fk.defined_for?(**options) }
    # prefer a FK on a column named after the table
    if options[:to_table]
      column = (Rails.version < "7.1") ? foreign_key_column_for(options[:to_table]) : foreign_key_column_for(options[:to_table], "id")
      return fks.find { |fk| fk.column == column } || fks.first
    end
    fks.first
  end

  def remove_foreign_key(from_table, to_table = nil, **options)
    return unless supports_foreign_keys?

    if options.delete(:if_exists)
      fk_name_to_delete = foreign_key_for(from_table, to_table:, **options)&.name
      return if fk_name_to_delete.nil?
    else
      fk_name_to_delete = foreign_key_for!(from_table, to_table:, **options).name
    end

    at = create_alter_table from_table
    at.drop_foreign_key fk_name_to_delete

    execute schema_creation.accept(at)
  end
end

# yes, various versions of rails supports various if_exists/if_not_exists options,
# but _none_ of them (as of writing) will invert them on reversion. Some will
# purposely strip the option, but most don't do anything.
module ExistenceInversions
  %w[index foreign_key column].each do |type|
    # these methods purposely pull the flag from the incoming args,
    # and assign to the outgoing args, not relying on it getting
    # passed through. and sometimes they even modify args.
    class_eval <<~RUBY, __FILE__, __LINE__ + 1
      def invert_add_#{type}(args)
        orig_args = args.map(&:dup)
        result = super
        if orig_args.last.is_a?(Hash) && orig_args.last[:if_not_exists]
          result[1] << {} unless result[1].last.is_a?(Hash)
          result[1].last[:if_exists] = orig_args.last[:if_not_exists]
          result[1].last.delete(:if_not_exists)
        end
        result
      end

      def invert_remove_#{type}(args)
        orig_args = args.map(&:dup)
        result = super
        if orig_args.last.is_a?(Hash) && orig_args.last[:if_exists]
          result[1] << {} unless result[1].last.is_a?(Hash)
          result[1].last[:if_not_exists] = orig_args.last[:if_exists]
          result[1].last.delete(:if_exists)
        end
        result
      end
    RUBY
  end
end

ActiveRecord::Migration::CommandRecorder.prepend(ExistenceInversions)

ActiveRecord::Associations::CollectionAssociation.class_eval do
  # CollectionAssociation implements uniq for :uniq option, in its
  # own special way. re-implement, but as a relation
  delegate :distinct, to: :scope
end

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
      @skip_touch_callbacks&.include?(name) ||
        (superclass < ActiveRecord::Base && superclass.touch_callbacks_skipped?(name))
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
ActiveModel::AttributeMutationTracker.prepend(DupArraysInMutationTracker)

module IgnoreOutOfSequenceMigrationDates
  def current_migration_number(dirname)
    migration_lookup_at(dirname).filter_map do |file|
      digits = File.basename(file).split("_").first
      next if ActiveRecord.timestamped_migrations && digits.length != 14

      digits.to_i
    end.max.to_i
  end
end
Autoextend.hook(:"ActiveRecord::Generators::MigrationGenerator",
                IgnoreOutOfSequenceMigrationDates,
                singleton: true,
                method: :prepend,
                optional: true)

module AlwaysUseMigrationDates
  def next_migration_number(number)
    if ActiveRecord.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      SchemaMigration.normalize_migration_number(number)
    end
  end
end
ActiveRecord::Migration.prepend(AlwaysUseMigrationDates)

module ExplainAnalyze
  def exec_explain(queries, analyze: false)
    # :nodoc:
    str = queries.map do |sql, binds|
      msg = "EXPLAIN #{"ANALYZE " if analyze}for: #{sql}"
      unless binds.empty?
        msg << " "
        msg << binds.map { |attr| render_bind(attr) }.inspect
      end
      msg << "\n"
      msg << connection.explain(sql, binds, analyze:)
    end.join("\n")

    # Overriding inspect to be more human readable, especially in the console.
    def str.inspect
      self
    end

    str
  end

  def explain(analyze: false)
    # TODO: Fix for binds.
    exec_explain(collecting_queries_for_explain do
      if block_given?
        yield
      else
        # fold in switchman's override
        activate { |relation| relation.send(:exec_queries) }
      end
    end,
                 analyze:)
  end
end
ActiveRecord::Relation.prepend(ExplainAnalyze)

# fake Rails into grabbing correct column information for a table rename in-progress
module TableRename
  RENAMES = {}.freeze

  if Rails.version < "7.1"
    def columns(table_name)
      if (old_name = RENAMES[table_name]) && connection.table_exists?(old_name)
        table_name = old_name
      end
      super
    end
  else
    def columns(connection, table_name)
      if (old_name = RENAMES[table_name]) && connection.table_exists?(old_name)
        table_name = old_name
      end
      super
    end
  end
end

module DefeatInspectionFilterMarshalling
  def inspect
    result = super
    @inspection_filter = nil
    result
  end

  def pretty_print(_pp)
    super
    @inspection_filter = nil
  end
end

ActiveRecord::ConnectionAdapters::SchemaCache.prepend(TableRename)

ActiveRecord::Base.prepend(DefeatInspectionFilterMarshalling)
ActiveRecord::Base.prepend(ActiveRecord::CacheRegister::Base)
ActiveRecord::Base.singleton_class.prepend(ActiveRecord::CacheRegister::Base::ClassMethods)
ActiveRecord::Relation.prepend(ActiveRecord::CacheRegister::Relation)

module PreserveShardAfterTransaction
  def after_transaction_commit(&)
    shards = Shard.send(:active_shards)
    shards[Delayed::Backend::ActiveRecord::AbstractJob] = Shard.current.delayed_jobs_shard if ::ActiveRecord::Migration.open_migrations.positive?
    super { Shard.activate(shards, &) }
  end
end
ActiveRecord::ConnectionAdapters::Transaction.prepend(PreserveShardAfterTransaction)

module ConnectionWithMaxRuntime
  def initialize(*)
    super
    @created_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def runtime
    # Sometimes connections seem to lose their created_at, so just set it to the present
    # That way the connection still eventually expires
    @created_at ||= Process.clock_gettime(Process::CLOCK_MONOTONIC)

    Process.clock_gettime(Process::CLOCK_MONOTONIC) - @created_at
  end
end
ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(ConnectionWithMaxRuntime)

module RestoreConnectionConnectionPool
  def restore_connection(conn)
    # If the connection got closed before we restored it, don't try to return it
    return unless conn.active?

    synchronize do
      adopt_connection(conn)
      # check if a new connection was checked out in the meantime, and check it back in
      if (old_conn = @thread_cached_conns[connection_cache_key(current_thread)]) && old_conn != conn
        # this is just the necessary parts of #checkin
        old_conn.lock.synchronize do
          old_conn._run_checkin_callbacks do
            old_conn.expire
          end

          @available.add old_conn
        end
      end
      @thread_cached_conns[connection_cache_key(current_thread)] = conn
    end
  end
end
ActiveRecord::ConnectionAdapters::ConnectionPool.prepend(RestoreConnectionConnectionPool)

module MaxRuntimeConnectionPool
  def max_runtime
    db_config.configuration_hash[:max_runtime]
  end

  def acquire_connection(*)
    loop do
      conn = super
      return conn unless max_runtime && conn.runtime >= max_runtime

      @connections.delete(conn)
      conn.disconnect!
    end
  end

  def checkin(conn)
    return super unless max_runtime && conn.runtime >= max_runtime

    conn.lock.synchronize do
      synchronize do
        remove_connection_from_thread_cache conn

        @connections.delete(conn)
        conn.disconnect!
      end
    end
  end

  def flush(*)
    super
    return unless max_runtime

    old_connections = synchronize do
      # TODO: Rails 6.1 adds a `discarded?` method instead of checking this directly
      return unless @connections

      @connections.select do |conn|
        !conn.in_use? && conn.runtime >= max_runtime
      end.each do |conn|
        conn.lease
        @available.delete conn
        @connections.delete conn
      end
    end

    old_connections.each(&:disconnect!)
  end
end
ActiveRecord::ConnectionAdapters::ConnectionPool.prepend(MaxRuntimeConnectionPool)

module ClearableAssociationCache
  def clear_association_cache
    @association_cache = {}
  end
end
# Ensure it makes it onto activerecord::base even if associations are already attached to base
ActiveRecord::Associations.prepend(ClearableAssociationCache)
ActiveRecord::Base.prepend(ClearableAssociationCache)

module VersionAgnosticPreloader
  def preload(records, associations, preload_scope = nil)
    ActiveRecord::Associations::Preloader.new(records: Array.wrap(records).compact, associations:, scope: preload_scope).call
  end
end
ActiveRecord::Associations.singleton_class.include(VersionAgnosticPreloader)

Rails.application.config.after_initialize do
  ActiveSupport.on_load(:active_record) do
    cache = MultiCache.fetch("schema_cache")
    next if cache.nil?

    if $canvas_rails == "7.1"
      connection_pool.schema_reflection.set_schema_cache(cache)
    else
      connection_pool.set_schema_cache(cache)
    end
    LoadAccount.schema_cache_loaded!
  end
end

module UserContentSerialization
  def serializable_hash(options = nil)
    result = super
    if result.present?
      result = result.with_indifferent_access
      user_content_fields = options[:user_content] || []
      result.each_key do |name|
        if user_content_fields.include?(name.to_s)
          result[name] = UserContent.escape(result[name])
        end
      end
    end
    if options && options[:include_root]
      result = { self.class.serialization_root_key => result }.with_indifferent_access
    end
    result
  end
end
ActiveRecord::Base.include(UserContentSerialization)

if Rails.version >= "6.1" && Rails.version < "7.1"
  # Hopefully this can be removed with https://github.com/rails/rails/commit/6beee45c3f071c6a17149be0fabb1697609edbe8
  # having made a released version of rails; if not bump the rails version in this comment and leave the comment to be revisited
  # on the next rails bump

  # This code is direcly copied from rails except the INST commented line, hence the rubocop disables
  # rubocop:disable Lint/RescueException
  # rubocop:disable Naming/RescuedExceptionsVariableName
  require "active_record/connection_adapters/abstract/transaction"
  module ActiveRecord
    module ConnectionAdapters
      class TransactionManager
        def within_new_transaction(isolation: nil, joinable: true)
          @connection.lock.synchronize do
            transaction = begin_transaction(isolation:, joinable:)
            ret = yield
            completed = true
            ret
          rescue Exception => error
            if transaction
              # INST: The one functional change, since on postgres this is unnecessary, and the above-linked commit disables it
              # transaction.state.invalidate! if error.is_a? ActiveRecord::TransactionRollbackError
              rollback_transaction
              after_failure_actions(transaction, error)
            end

            raise
          ensure
            if transaction
              if error
                # @connection still holds an open or invalid transaction, so we must not
                # put it back in the pool for reuse.
                @connection.throw_away! unless transaction.state.rolledback?
              elsif Thread.current.status == "aborting" || (!completed && transaction.written)
                # The transaction is still open but the block returned earlier.
                #
                # The block could return early because of a timeout or because the thread is aborting,
                # so we are rolling back to make sure the timeout didn't caused the transaction to be
                # committed incompletely.
                rollback_transaction
              else
                begin
                  commit_transaction
                rescue Exception
                  rollback_transaction(transaction) unless transaction.state.completed?
                  raise
                end
              end
            end
          end
        end
      end
    end
  end
  # rubocop:enable Lint/RescueException
  # rubocop:enable Naming/RescuedExceptionsVariableName
end

module AdditionalIgnoredColumns
  def self.included(klass)
    klass.extend(ClassMethods)
    klass.prepend(InstanceMethods)

    klass.reset_ignored_columns!

    ::Canvas::Reloader.on_reload do
      klass.reset_ignored_columns!
    end
  end

  module InstanceMethods
    def ignored_columns
      return super unless superclass <= ActiveRecord::Base && !abstract_class?

      cache_class = ActiveRecord::Base.singleton_class
      return super unless cache_class.columns_to_ignore_enabled

      # Ensure table_name doesn't error out
      set_base_class

      cache_class.columns_to_ignore_cache[table_name] ||= DynamicSettings.find("activerecord/ignored_columns", tree: :store, ignore_fallback_overrides: true)[table_name, failsafe: ""]&.split(",") || []
      super + cache_class.columns_to_ignore_cache[table_name]
    end
  end

  module ClassMethods
    attr_accessor :columns_to_ignore_cache, :columns_to_ignore_enabled

    def reset_ignored_columns!
      @columns_to_ignore_cache = {}
      @columns_to_ignore_enabled = !ActiveModel::Type::Boolean.new.cast(DynamicSettings.find("activerecord", tree: :store, ignore_fallback_overrides: true)["ignored_columns_disabled", failsafe: false])
    end
  end
end
ActiveRecord::Base.singleton_class.include(AdditionalIgnoredColumns)

if $canvas_rails == "7.0"
  module SerializeCompat
    def serialize(attr_name, *args, coder: nil, type: Object, **kwargs)
      args = [coder || type] if args.empty?
      super(attr_name, *args, **kwargs)
    end
  end
  ActiveRecord::Base.singleton_class.prepend(SerializeCompat)

  ActiveRecord::Relation.send(:public, :null_relation?)
end

module CreateIcuCollationsBeforeMigrations
  def migrate_without_lock(*)
    c = ($canvas_rails == "7.1") ? connection : ActiveRecord::Base.connection
    c.create_icu_collations if up?

    super
  end
end
ActiveRecord::Migrator.prepend(CreateIcuCollationsBeforeMigrations)

module RollbackIgnoreNonDatedMigrations
  def move(direction, steps)
    if direction == :down
      # we need to back up over any migrations that are not dated
      steps += migrations.count { |migration| migration.version.to_s.length > 14 && migration.runnable? }
      args = [direction, migrations, schema_migration]
      args << internal_metadata if $canvas_rails == "7.1"
      migrator = ActiveRecord::Migrator.new(*args)

      if current_version != 0 && !migrator.current_migration
        raise ActiveRecord::UnknownMigrationVersionError, current_version
      end

      start_index =
        if current_version == 0
          0
        else
          migrator.migrations.index(migrator.current_migration) || 0
        end

      finish = migrator.migrations[start_index + steps]
      version = finish ? finish.version : 0
      return public_send(direction, version) do |migration|
        # but don't actually run the non-dated migrations
        migration.version.to_s.length <= 14
      end
    end

    super
  end
end
ActiveRecord::MigrationContext.prepend(RollbackIgnoreNonDatedMigrations)
