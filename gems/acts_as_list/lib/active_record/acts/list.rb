module ActiveRecord
  module Acts #:nodoc:
    module List #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      # This +acts_as+ extension provides the capabilities for sorting and reordering a number of objects in a list.
      # The class that has this specified needs to have a +position+ column defined as an integer on
      # the mapped database table.
      #
      # Todo list example:
      #
      #   class TodoList < ActiveRecord::Base
      #     has_many :todo_items, :order => "position"
      #   end
      #
      #   class TodoItem < ActiveRecord::Base
      #     belongs_to :todo_list
      #     acts_as_list :scope => :todo_list
      #   end
      #
      #   todo_list.first.move_to_bottom
      #   todo_list.last.insert_at(2)
      module ClassMethods
        # Configuration options are:
        #
        # * +column+ - specifies the column name to use for keeping the position integer (default: +position+)
        # * +scope+ - restricts what is to be considered a list. Acceptable values are symbols, array of symbols,
        #   or a hash of symbols to values. Pass self as the value to mean it must match the current record.
        #   symbols that match associations are expanded to match the foreign key (polymorphic associations
        #   are supported)
        def acts_as_list(options = {})
          configuration = { :column => "position" }
          configuration.update(options) if options.is_a?(Hash)

          if !configuration[:scope]
            scope_condition_method = <<-RUBY
            def scope_condition
              nil
            end

            def in_scope?
              true
            end

            def list_scope_base
              self.class.base_class.scoped
            end
            RUBY
          else
            scope = configuration[:scope]
            # translate symbols and arrays to hash format
            scope = case scope
                    when Symbol
                      { scope => self }
                    when Array
                      Hash[scope.map { |symbol| [symbol, self]}]
                    when Hash
                      scope
                    else
                      raise InvalidArgument.new("scope must be nil, a symbol, an array, or a hash")
                    end
            # expand assocations to their foreign keys
            new_scope = {}
            scope.each do |k, v|
              if reflection = reflections[k]
                key = reflection.foreign_key
                new_scope[key] = v
                if reflection.options[:polymorphic]
                  key = reflection.foreign_type
                  new_scope[key] = v
                end
              else
                new_scope[k] = v
              end
            end
            scope = new_scope

            # build the conditions hash, using literal values or the attribute if it's self
            conditions = Hash[scope.map { |k, v| [k, v == self ? k : v.inspect]}]
            conditions = conditions.map { |c, v| "#{c}: #{v}" }.join(', ')
            # build the in_scope method, matching literals or requiring a foreign keys
            # to be non-nil
            in_scope_conditions = []
            variable_conditions, constant_conditions = scope.partition { |k, v| v == self }
            in_scope_conditions.concat(variable_conditions.map { |c, v| "!#{c}.nil?" })
            in_scope_conditions.concat(constant_conditions.map do |c, v|
              if v.is_a?(Array)
                "#{v.inspect}.include?(#{c})"
              else
                "#{c} == #{v.inspect}"
              end
            end)

            scope_condition_method = <<-RUBY
              def scope_condition
                { #{conditions} }
              end

              def in_scope?
                #{in_scope_conditions.join(' && ')}
              end

              def list_scope_base
                self.class.base_class.where(scope_condition)
              end
            RUBY
          end

          class_eval <<-RUBY
            include ActiveRecord::Acts::List::InstanceMethods

            def self.position_column
              '#{configuration[:column]}'
            end

            #{scope_condition_method}

            def list_scope
              list_scope_base.order(self.class.nulls(:last, self.class.position_column), self.class.primary_key)
            end

            before_destroy :remove_from_list_for_destroy
            before_create  :add_to_list_bottom
          RUBY

          if position_column != 'position'
            class_eval do
              alias_method :position, self.class.position_column.to_sym
            end
          end
        end
      end

      # All the methods available to a record that has had <tt>acts_as_list</tt> specified. Each method works
      # by assuming the object to be the item in the list, so <tt>chapter.first?</tt> would return +true+ if
      # that chapter is the first in the list of all chapters.
      module InstanceMethods
        # Test if this record is in a list
        def in_list?
          !position.nil? && in_scope?
        end

        # Insert the item at the given position (defaults to the top position).
        def insert_at(position = :top)
          return unless in_scope?
          return move_to_top if position == :top
          current_position = self.position
          return true if in_list? && position == current_position
          transaction do
            if in_list?
              if position < current_position
                list_scope.where(self.class.position_column => position..(current_position - 1)).
                    update_all("#{self.class.position_column} = (#{self.class.position_column} + 1)")
              else
                list_scope.where(self.class.position_column => (current_position + 1)..position).
                    update_all("#{self.class.position_column} = (#{self.class.position_column} - 1)")
              end
            else
              list_scope.where("#{self.class.position_column}>=?", position).
                  update_all("#{self.class.position_column} = (#{self.class.position_column} + 1)")
            end
            self.update_attribute(self.class.position_column, position)
          end
        end

        # Move to the bottom of the list. If the item is already in the list, the items below it have their
        # position adjusted accordingly.
        def move_to_bottom
          return unless in_scope?
          transaction do
            bottom = bottom_position
            if in_list?
              insert_at(bottom)
            else
              update_attribute(self.class.position_column, bottom + 1)
            end
          end
        end

        # Move to the top of the list. If the item is already in the list, the items above it have their
        # position adjusted accordingly.
        def move_to_top
          return unless in_scope?
          transaction do
            top = top_position
            insert_at(top)
          end
        end

        # Removes the item from the list.
        def remove_from_list
          if in_list?
            transaction do
              list_scope.where("#{self.class.position_column}>?", position).
                  update_all("#{self.class.position_column} = (#{self.class.position_column} - 1)")
              update_attribute self.class.position_column, nil
            end
          end
        end

        # Return +true+ if this object is the first in the list.
        def first?
          return false unless in_list?
          position == top_position
        end

        # Return +true+ if this object is the last in the list.
        def last?
          return false unless in_list?
          position == bottom_position
        end

        # Returns the bottom position number in the list.
        #   bottom_position    # => 2
        def bottom_position
          return nil unless in_scope?
          list_scope.maximum(self.class.position_column)
        end

        # Returns the bottom item
        def bottom_item
          return nil unless in_scope?
          list_scope.last
        end

        # Returns the top position number in the list.
        #   top_position    # => 1
        def top_position
          return nil unless in_scope?
          list_scope.minimum(self.class.position_column)
        end

        # Returns the top item
        def top_item
          return nil unless in_scope?
          list_scope.first
        end

        # takes the given ids, and moves them to the beginning of the list. all other elements in the list
        # are moved downwards
        def update_order(ids)
          updates = []
          done_ids = Set.new
          id_column = connection.quote_column_name(self.class.primary_key)
          ids.each do |id|
            id = id.to_i
            next unless id > 0
            next if done_ids.include?(id)
            done_ids << id.to_i
            updates << "WHEN #{id_column}=#{id} THEN #{done_ids.length}"
          end
          return if updates.empty?
          transaction do
            done_ids = done_ids.to_a
            moving_positions = list_scope.where(self.class.primary_key => done_ids).pluck(self.class.position_column.to_sym)
            moving_positions.each_with_index do |position, index|
              next unless position
              updates << "WHEN #{self.class.position_column}<=#{position} THEN #{self.class.position_column}+#{moving_positions.length - index}"
            end
            list_scope.update_all("#{self.class.position_column}=CASE #{updates.join(" ")} ELSE position END")
          end
        end

        # fix conflicts in the list by reassigning all positions to be contiguous
        # the new order will preserve the current ordering based on (position, id)
        def fix_position_conflicts
          transaction do
            offset = 1
            list_scope.select(self.class.primary_key).find_in_batches do |batch|
              updates = []
              batch.each_with_index do |obj, index|
                updates << "WHEN #{obj.id} THEN #{index+offset}"
              end
              offset += batch.length
              list_scope.where(self.class.primary_key => batch).
                  update_all("#{self.class.position_column}=CASE #{self.class.connection.quote_column_name(self.class.primary_key)} #{updates.join(" ")} END")
            end
          end
        end
        # reassign positions to be contiguous, and begin at 1
        alias_method :compact_list, :fix_position_conflicts

        # before_create callback
        def add_to_list_bottom
          return unless in_scope?
          return if in_list?
          self[self.class.position_column] = bottom_position.to_i + 1
        end

        private

          def remove_from_list_for_destroy
            list_scope.where("#{self.class.position_column}>?", position).
                update_all("#{self.class.position_column} = (#{self.class.position_column} - 1)")
          end
      end
    end
  end
end
