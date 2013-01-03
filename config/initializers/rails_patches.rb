if Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR >= 1
  raise "This patch has been merged into rails 3.1, remove it from our repo"
else
  # bug submitted to rails: https://rails.lighthouseapp.com/projects/8994/tickets/5802-activerecordassociationsassociationcollectionload_target-doesnt-respect-protected-attributes#ticket-5802-1
  # This fix has been merged into rails trunk and will be in the rails 3.1 release.
  class ActiveRecord::Associations::AssociationCollection
    def load_target
      if !@owner.new_record? || foreign_key_present
        begin
          if !loaded?
            if @target.is_a?(Array) && @target.any?
              @target = find_target.map do |f|
                i = @target.index(f)
                if i
                  @target.delete_at(i).tap do |t|
                    keys = ["id"] + t.changes.keys + (f.attribute_names - t.attribute_names)
                    f.attributes.except(*keys).each do |k,v|
                      t.write_attribute(k, v)
                    end
                  end
                else
                  f
                end
              end + @target
            else
              @target = find_target
            end
          end
        rescue ActiveRecord::RecordNotFound
          reset
        end
      end

      loaded if target
      target
    end
  end

  # https://github.com/rails/rails/commit/0e17cf17ebeb70490d7c7cd25c6bf8f9401e44b3
  # https://github.com/rails/rails/commit/63cd9432265a32d222353b535d60333c2a6a5125
  # Backport from Rails 3.1
  ERB::Util.module_eval do
    # Detect whether 1.9 can transcode with XML escaping.
    if '"&gt;&lt;&amp;&quot;"' == ('><&"'.encode('utf-8', :xml => :attr) rescue false)
      def html_escape(s)
        s = s.to_s
        if s.html_safe?
          s
        else
          s.encode(s.encoding, :xml => :attr)[1...-1].html_safe
        end
      end
    else
      def html_escape(s)
        s = s.to_s
        if s.html_safe?
          s
        else
          s.gsub(/[&"><]/n) { |special| ERB::Util::HTML_ESCAPE[special] }.html_safe
        end
      end
    end

    remove_method(:h)
    alias h html_escape

    module_function :h
    module_function :html_escape
  end


  # Fix for has_many :through where the through and target reflections are the
  # same table (the through table needs to be aliased)
  # https://github.com/rails/rails/issues/669 (fixed in rails 3.1)
  ActiveRecord::Associations::HasManyThroughAssociation.module_eval do
    protected

    def aliased_through_table_name
      @reflection.table_name == @reflection.through_reflection.table_name ?
          ActiveRecord::Base.connection.quote_table_name(@reflection.through_reflection.table_name + '_join') :
          ActiveRecord::Base.connection.quote_table_name(@reflection.through_reflection.table_name)
    end

    def construct_conditions
      conditions = construct_quoted_owner_attributes(@reflection.through_reflection).map do |attr, value|
        "#{aliased_through_table_name}.#{attr} = #{value}"
      end
      conditions << sql_conditions if sql_conditions
      "(" + conditions.join(') AND (') + ")"
    end

    def construct_joins(custom_joins = nil)
      polymorphic_join = nil
      if @reflection.source_reflection.macro == :belongs_to
        reflection_primary_key = @reflection.klass.primary_key
        source_primary_key     = @reflection.source_reflection.primary_key_name
        if @reflection.options[:source_type]
          polymorphic_join = "AND %s.%s = %s" % [
            aliased_through_table_name, "#{@reflection.source_reflection.options[:foreign_type]}",
            @owner.class.quote_value(@reflection.options[:source_type])
          ]
        end
      else
        reflection_primary_key = @reflection.source_reflection.primary_key_name
        source_primary_key     = @reflection.through_reflection.klass.primary_key
        if @reflection.source_reflection.options[:as]
          polymorphic_join = "AND %s.%s = %s" % [
            @reflection.quoted_table_name, "#{@reflection.source_reflection.options[:as]}_type",
            @owner.class.quote_value(@reflection.through_reflection.klass.name)
          ]
        end
      end

      "INNER JOIN %s %s ON %s.%s = %s.%s %s #{@reflection.options[:joins]} #{custom_joins}" % [
        @reflection.through_reflection.quoted_table_name,
        aliased_through_table_name,
        @reflection.quoted_table_name, reflection_primary_key,
        aliased_through_table_name, source_primary_key,
        polymorphic_join
      ]
    end
  end

  # ensure that the query cache is cleared on inserts, even if there's a db
  # error. this is fixed in rails 3.1. unfortunately we have to reproduce
  # whole method here and can't just alias it, since it calls super :(
  # https://github.com/rails/rails/commit/1f3d3eb49d16b62250c24e3374cc36de99b397b8
  if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
      remove_method :insert
      def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        # Extract the table from the insert sql. Yuck.
        table = sql.split(" ", 4)[2].gsub('"', '')

        # Try an insert with 'returning id' if available (PG >= 8.2)
        if supports_insert_with_returning?
          pk, sequence_name = *pk_and_sequence_for(table) unless pk
          if pk
            id = select_value("#{sql} RETURNING #{quote_column_name(pk)}")
            return id
          end
        end

        # Otherwise, insert then grab last_insert_id.
        if insert_id = super
          insert_id
        else
          # If neither pk nor sequence name is given, look them up.
          unless pk || sequence_name
            pk, sequence_name = *pk_and_sequence_for(table)
          end

          # If a pk is given, fallback to default sequence name.
          # Don't fetch last insert id for a table without a pk.
          if pk && sequence_name ||= default_sequence_name(table, pk)
            last_insert_id(table, sequence_name)
          end
        end
      end
    end
  end
end

if Rails::VERSION::MAJOR == 2
  module ActiveRecord
    class Base
      # So far a new version of rails 2.3 has not been released to patch this.
      # Hopefully the next minor version (if there is one) will incorporate it
      # and we can add another && Rails::VERSION::MINOR < condition to above
      def self.sanitize_sql_hash_for_conditions(attrs, default_table_name = quoted_table_name, top_level = true)
        attrs = expand_hash_conditions_for_aggregates(attrs)

        conditions = attrs.map do |attr, value|
          table_name = default_table_name

          if not value.is_a?(Hash)
            attr = attr.to_s

            # Extract table name from qualified attribute names.
            if attr.include?('.') and top_level
              attr_table_name, attr = attr.split('.', 2)
              attr_table_name = connection.quote_table_name(attr_table_name)
            else
              attr_table_name = table_name
            end

            attribute_condition("#{attr_table_name}.#{connection.quote_column_name(attr)}", value)
          elsif top_level
            sanitize_sql_hash_for_conditions(value, connection.quote_table_name(attr.to_s), false)
          else
            raise ActiveRecord::StatementInvalid
          end
        end.join(' AND ')

        replace_bind_variables(conditions, expand_range_bind_variables(attrs.values))
      end

      # Fix for CVE-2012-5664
      # An unfortunate load-order problem means that we need to make sure and
      # patch the pre-will_paginate version of this method. The real solution
      # here is to fork Rails 2.3 and directly patch the code, which is in the
      # works.
      raise("will_paginate is expected to already be loaded here") unless method(:method_missing_without_paginate)
      def self.method_missing_without_paginate(method_id, *arguments, &block)
        if match = DynamicFinderMatch.match(method_id)
          attribute_names = match.attribute_names
          super unless all_attributes_exists?(attribute_names)
          if match.finder?
            finder = match.finder
            bang = match.bang?

            self.class_eval <<-EOS, __FILE__, __LINE__ + 1
                  def self.#{method_id}(*args)
                    options = if args.length > #{attribute_names.size}
                                args.extract_options!
                              else
                                {}
                              end
                    attributes = construct_attributes_from_arguments(
                      [:#{attribute_names.join(',:')}],
                      args
                    )
                    finder_options = { :conditions => attributes }
                    validate_find_options(options)
                    set_readonly_option!(options)

                    #{'result = ' if bang}if options[:conditions]
                      with_scope(:find => finder_options) do
                        find(:#{finder}, options)
                      end
                    else
                      find(:#{finder}, options.merge(finder_options))
                    end
                    #{'result || raise(RecordNotFound, "Couldn\'t find #{name} with #{attributes.to_a.collect {|pair| "#{pair.first} = #{pair.second}"}.join(\', \')}")' if bang}
                  end
            EOS
            send(method_id, *arguments)
          elsif match.instantiator?
            instantiator = match.instantiator
            self.class_eval <<-EOS, __FILE__, __LINE__ + 1
                  def self.#{method_id}(*args)
                    attributes = [:#{attribute_names.join(',:')}]
                    protected_attributes_for_create, unprotected_attributes_for_create = {}, {}
                    args.each_with_index do |arg, i|
                      if arg.is_a?(Hash)
                        protected_attributes_for_create = args[i].with_indifferent_access
                      else
                        unprotected_attributes_for_create[attributes[i]] = args[i]
                      end
                    end

                    find_attributes = (protected_attributes_for_create.merge(unprotected_attributes_for_create)).slice(*attributes)

                    options = { :conditions => find_attributes }
                    set_readonly_option!(options)

                    record = find(:first, options)

                    if record.nil?
                      record = self.new do |r|
                        r.send(:attributes=, protected_attributes_for_create, true) unless protected_attributes_for_create.empty?
                        r.send(:attributes=, unprotected_attributes_for_create, false) unless unprotected_attributes_for_create.empty?
                      end
                      #{'yield(record) if block_given?'}
            #{'record.save' if instantiator == :create}
                      record
                    else
                      record
                    end
                  end
            EOS
            send(method_id, *arguments, &block)
          end
        elsif match = DynamicScopeMatch.match(method_id)
          attribute_names = match.attribute_names
          super unless all_attributes_exists?(attribute_names)
          if match.scope?
            self.class_eval <<-EOS, __FILE__, __LINE__ + 1
                  def self.#{method_id}(*args)                        # def self.scoped_by_user_name_and_password(*args)
                    options = args.extract_options!                   #   options = args.extract_options!
                    attributes = construct_attributes_from_arguments( #   attributes = construct_attributes_from_arguments(
                      [:#{attribute_names.join(',:')}], args          #     [:user_name, :password], args
                    )                                                 #   )
                                                                      #
                    scoped(:conditions => attributes)                 #   scoped(:conditions => attributes)
                  end                                                 # end
            EOS
            send(method_id, *arguments)
          end
        else
          super
        end
      end
    end
  end
end
