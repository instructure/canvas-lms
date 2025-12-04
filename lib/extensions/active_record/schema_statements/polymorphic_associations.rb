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
#

module Extensions
  module ActiveRecord
    module SchemaStatements
      module PolymorphicAssociations
        def add_reference(table_name,
                          ref_name,
                          polymorphic: false,
                          null: true,
                          index: true,
                          if_not_exists: false,
                          delay_validation: true,
                          check_constraint: true,
                          **)
          return super(table_name, ref_name, null:, index:, if_not_exists:, **) unless polymorphic.is_a?(Array)

          polymorphic.each do |sub_ref_name|
            sub_index = if index.is_a?(Hash)
                          index.dup
                        elsif index || index.nil?
                          {}
                        else
                          index
                        end

            if sub_index
              sub_index[:where] = if sub_index[:where]
                                    "#{sub_index[:where]} AND #{sub_ref_name}_id IS NOT NULL"
                                  else
                                    "#{sub_ref_name}_id IS NOT NULL"
                                  end
            end

            add_reference(table_name, sub_ref_name, index: sub_index, if_not_exists:, **)
          end

          add_polymorphic_check_constraint(table_name, ref_name, polymorphic, if_not_exists:, delay_validation:, null:) if check_constraint
        end

        def rename_constraint(table_name, old_name, new_name, if_exists: false)
          return if if_exists && !check_constraint_exists?(table_name, name: old_name)

          execute("ALTER TABLE #{quote_table_name(table_name)} RENAME CONSTRAINT #{old_name} TO #{new_name}")
        end

        def add_polymorphic_check_constraint(table_name,
                                             ref_name,
                                             polymorphic,
                                             polymorphic_was: nil,
                                             replace: false,
                                             if_not_exists: false,
                                             delay_validation: true,
                                             null: true)
          check_sql, check_name = polymorphic_check_constraint_sql(ref_name, polymorphic, null:)

          if replace
            replaced_name = "#{check_name}_old"
            current_name = (replace == true) ? check_name : replace
            unless check_constraint_exists?(table_name, name: replaced_name)
              rename_constraint(table_name, current_name, replaced_name, if_exists: if_not_exists)
            end
          end
          # don't use if_not_exists directly, because it will make sure validated matches
          unless if_not_exists && check_constraint_exists?(table_name, name: check_name)
            add_check_constraint(table_name, check_sql, name: check_name, validate: !delay_validation)
          end

          validate_constraint(table_name, check_name) if delay_validation

          remove_check_constraint(table_name, name: replaced_name, if_exists: replace) if replaced_name
        end

        def polymorphic_check_constraint_sql(ref_name, polymorphic, null: true)
          check_clauses = polymorphic.map do |sub_ref_name|
            "(#{sub_ref_name}_id IS NOT NULL)::int"
          end
          check_sql = "(#{check_clauses.join(" + ")}) #{null ? "<=" : "="} 1"
          check_name = if null
                         "chk_#{ref_name}_disjunction"
                       else
                         "chk_require_#{ref_name}"
                       end
          [check_sql, check_name]
        end

        def remove_reference(table_name,
                             ref_name,
                             polymorphic: false,
                             if_exists: false,
                             null: true,
                             delay_validation: true,
                             **)
          return super unless polymorphic.is_a?(Array)

          check_name = if null
                         "chk_#{ref_name}_disjunction"
                       else
                         "chk_require_#{ref_name}"
                       end
          remove_check_constraint(table_name, name: check_name, if_exists:)

          polymorphic.each do |sub_ref_name|
            remove_reference(table_name, sub_ref_name, if_exists:, **)
          end
        end

        module TableDefinition
          def references(*args,
                         polymorphic: false,
                         null: true,
                         index: true,
                         foreign_key: false,
                         check_constraint: true,
                         **)
            return super(*args, polymorphic:, null:, index:, foreign_key:, **) unless polymorphic.is_a?(Array)

            args.each do |ref_name|
              polymorphic.each do |sub_ref_name|
                sub_index = if index.is_a?(Hash)
                              index.dup
                            elsif index
                              {}
                            else
                              index
                            end

                if sub_index
                  sub_index[:where] = if sub_index[:where]
                                        "#{sub_index[:where]} AND #{sub_ref_name}_id IS NOT NULL"
                                      else
                                        "#{sub_ref_name}_id IS NOT NULL"
                                      end
                end

                ::ActiveRecord::ConnectionAdapters::ReferenceDefinition.new(sub_ref_name, index: sub_index, **).add_to(self)
              end

              if check_constraint
                sql, name = @conn.polymorphic_check_constraint_sql(ref_name, polymorphic, null:)
                check_constraint(sql, name:)
              end
            end
          end
        end
      end
    end
  end
end
