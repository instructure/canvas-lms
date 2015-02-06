require 'active_record'

class ActiveRecord::Base
  def self.polymorphic_names
    [self.base_class.name]
  end
end

module ActiveRecord
  class Relation
    # this method prevents ActiveRecord from attempting to constantize the polymorphic_names array as part of the build_associations process
    def scope_for_create_with_polymorphic_names
      scope = scope_for_create_without_polymorphic_names
      if default_scoped?
        reflect_on_polymorphic_associations.each do |assoc|
          # since all class names in are returned in select queries (via self.polymorphic_names) it is ok to just take the first element of the array (rather than trying to constantize the array itself)
          # still, in future it would be better to devise some way of declaring a canonical form for the create scope
          # (e.g. select queries should retrieve all instances of PreRefactoredClassName and PostRefactoredClassName, but insert queries should always prefer the latter)
          scope[assoc.foreign_type] = scope[assoc.foreign_type].first if scope[assoc.foreign_type].is_a?(Array)
        end
      end
      scope
    end
    alias_method_chain :scope_for_create, :polymorphic_names

    def reflect_on_polymorphic_associations
      reflect_on_all_associations.select{ |assoc| assoc.options[:polymorphic] }
    end
  end

  class Associations::AssociationScope
    def add_constraints(scope)
      tables = construct_tables

      chain.each_with_index do |reflection, i|
        table, foreign_table = tables.shift, tables.first

        if reflection.source_macro == :has_and_belongs_to_many
          join_table = tables.shift

          scope = scope.joins(join(
            join_table,
            table[reflection.association_primary_key].
              eq(join_table[reflection.association_foreign_key])
          ))

          table, foreign_table = join_table, tables.first
        end

        if reflection.source_macro == :belongs_to
          if reflection.options[:polymorphic]
            key = reflection.association_primary_key(klass)
          else
            key = reflection.association_primary_key
          end

          foreign_key = reflection.foreign_key
        else
          key         = reflection.foreign_key
          foreign_key = reflection.active_record_primary_key
        end

        conditions = CANVAS_RAILS3 ? self.conditions[i] : []

        if reflection == chain.last
          bind_val = CANVAS_RAILS3 ? owner[foreign_key] :
              bind(scope, table.table_name, key.to_s, owner[foreign_key])
          scope = scope.where(table[key].eq(bind_val))

          if reflection.type
            types = owner.class.polymorphic_names
            types = types.first if types.length == 1
            scope = scope.where(table.name => {table[reflection.type].name => types})
          end

          conditions.each do |condition|
            if options[:through] && condition.is_a?(Hash)
              condition = disambiguate_condition(table, condition)
            end

            scope = scope.where(interpolate(condition))
          end

        else
          constraint = table[key].eq(foreign_table[foreign_key])

          if reflection.type
            types = chain[i + 1].klass.polymorphic_names
            types = types.first if types.length == 1
            constraint = constraint.and(table.name => {table[reflection.type].name => types})
          end

          scope = scope.joins(join(foreign_table, constraint))

          unless conditions.empty?
            scope = scope.where(sanitize(conditions, table))
          end
        end

        unless CANVAS_RAILS3
          is_first_chain = i == 0
          klass = is_first_chain ? self.klass : reflection.klass

          # Exclude the scope of the association itself, because that
          # was already merged in the #scope method.
          scope_chain[i].each do |scope_chain_item|
            item  = eval_scope(klass, scope_chain_item)

            if scope_chain_item == self.reflection.scope
              scope.merge! item.except(:where, :includes)
            end

            if is_first_chain
              scope.includes! item.includes_values
            end

            scope.where_values += item.where_values
            scope.order_values |= item.order_values
          end
        end
      end

      scope
    end
  end
end
