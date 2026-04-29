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
    module PolymorphicAssociations
      module ClassMethods
        # set up class-specific getters/setters for a polymorphic association, e.g.
        #   belongs_to :context, polymorphic: [:course, :account] OR
        def belongs_to(name,
                       scope = nil,
                       polymorphic: nil,
                       polymorphic_prefix: nil,
                       exhaustive: true,
                       separate_columns: false,
                       **options)
          if polymorphic == true && exhaustive
            raise ArgumentError, "Please pass an array of valid types for polymorphic associations. Use exhaustive: false if you really don't want to validate them"
          end

          polymorphic = canonicalize_polymorph_list(polymorphic)
          options_for_polymorphic = separate_columns ? options.merge(inverse_of: nil) : options
          reflection = super(name, scope, polymorphic:, **options_for_polymorphic)[name.to_sym]

          if name.to_s == "developer_key"
            reflection.instance_eval do
              def association_class
                DeveloperKey::CacheOnAssociation
              end
            end
          end

          include Canvas::RootAccountCacher if name.to_s == "root_account"
          Canvas::AccountCacher.apply_to_reflections(self)

          if polymorphic.is_a?(Hash)
            reflection.options[:exhaustive] = exhaustive
            reflection.options[:polymorphic_prefix] = polymorphic_prefix
            reflection.options[:separate_columns] = separate_columns

            if separate_columns
              raise ArgumentError, "Cannot use exhaustive: false with separate_columns" unless exhaustive
              raise ArgumentError, "Cannot use scope with separate_columns" if scope
              # we probably could, but we'd have to do work to build the column name; for now if you
              # need this, use the hash form
              raise ArgumentError, "Cannot (yet?) use polymorphic_prefix with separate_columns" if polymorphic_prefix

              add_polymorph_associations(reflection, **options)
            else
              add_polymorph_methods(reflection)
            end
          end
          reflection
        end

        def canonicalize_polymorph_list(list)
          if list.is_a?(Array) || list.is_a?(Hash)
            specifics = []
            Array.wrap(list).each do |name|
              if name.is_a?(Hash)
                specifics.concat(name.invert.to_a)
              else
                specifics << [name.to_s.camelize, name]
              end
            end
            list = specifics.sort_by(&:last).to_h.freeze
          end
          list
        end

        private

        def polymorph_module
          @polymorph_module ||= Module.new.tap { |m| include m }
        end

        def add_polymorph_methods(reflection)
          specifics = reflection.options[:polymorphic]

          unless reflection.options[:exhaustive] == false
            specific_classes = specifics.keys.sort
            validates reflection.foreign_type, inclusion: { in: specific_classes }, allow_nil: true

            polymorph_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{reflection.name}=(record)                                                        # def context=(record)
                if record && [#{specific_classes.join(", ")}].none? { |klass| record.is_a?(klass) }  #   if record & [Course, Account].none? { |klass| record.is_a?(klass) }
                  message = "one of #{specific_classes.join(", ")} expected, got \#{record.class}"   #   message = "one of Course, Account expected, got \#{record.class}".
                  raise ::ActiveRecord::AssociationTypeMismatch, message                             #   raise ::ActiveRecord::AssociationTypeMismatch, message
                end                                                                                  #   end
                super                                                                                #   super
              end                                                                                    # end
            RUBY
          end

          if reflection.options[:polymorphic_prefix] == true
            prefix = "#{reflection.name}_"
          elsif reflection.options[:polymorphic_prefix]
            prefix = "#{reflection.options[:polymorphic_prefix]}_"
          end

          specifics.each do |(class_name, name)|
            # ensure we capture this class's table name
            table_name = self.table_name
            belongs_to(:"#{prefix}#{name}",
                       -> { where(table_name => { reflection.foreign_type => class_name }) },
                       foreign_key: reflection.foreign_key,
                       class_name:) # rubocop:disable Rails/ReflectionClassName

            correct_type = "#{reflection.foreign_type} && self.class.send(:compute_type, #{reflection.foreign_type}) <= #{class_name}"

            polymorph_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{prefix}#{name}                                                               # def course
                #{reflection.name} if #{correct_type}                                            #  context if self.context_type && self.class.send(:compute_type, self.context_type) <= Course
              end                                                                                # end
                                                                                                 #
              def #{prefix}#{name}=(record)                                                      # def course=(record)
                # we don't want to unset it if it's currently some other type, i.e.              #   # we don't want to unset it if it's currently some other type, i.e.
                # foo.bar = Bar.new                                                              #   # foo.bar = Bar.new
                # foo.baz = nil                                                                  #   # foo.baz = nil
                # foo.bar.should_not be_nil                                                      #   # foo.bar.should_not be_nil
                return if record.nil? && !(#{correct_type})                                      #   return if record.nil? && !(self.context_type && self.class.send(:compute_type, self.context_type) <= Course)
                association(:#{prefix}#{name}).send(:raise_on_type_mismatch!, record) if record  #   association(:course).send(:raise_on_type_mismatch!, record) if record
                                                                                                 #
                self.#{reflection.name} = record                                                 #   self.context = record
              end                                                                                # end

            RUBY
          end
        end

        def add_polymorph_associations(reflection, optional: nil, **)
          specifics = reflection.options[:polymorphic]

          required = if optional.nil?
                       belongs_to_required_by_default
                     else
                       !optional
                     end

          validate :"validate_#{reflection.name}_presence"

          assignment_cases = specifics.map do |(class_name, name)|
            <<~RUBY
              when #{class_name}
                self.#{name} = object
            RUBY
          end
                                      .join("\n")

          # def context
          #   account || course || group
          # end
          #
          # def context=(object)
          #   case object
          #   when nil
          #   when Account
          #     self.account = object
          #   when Course
          #     self.course = object
          #   when Group
          #     self.group = object
          #   else
          #     raise TypeError, "#{object.class} is not one of Course, Group"
          #   end
          # end
          #
          # def context_id
          #   account_id || course_id || group_id
          # end
          #
          # def context_type
          #   if account_id
          #     "Account"
          #   elsif course_id
          #     "Course"
          #   elsif group_id
          #     "Group"
          #   end
          # end
          #
          # private def validate_context_presence
          #   unless [((a = association(:account)).loaded? && a.target) || account_id, ((a = association(:course)).loaded? && a.target) || course_id, ((a = association(:group)).loaded? && a.target) || group_id].compact.size == 1
          #     errors.add(:base, "Exactly one context must be present")
          #   end
          # end
          polymorph_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
            def #{reflection.name}
              #{specifics.values.join(" || ")}
            end

            def #{reflection.name}=(object)
              case object
              when nil
              #{assignment_cases}
              else
                raise TypeError, "\#{object.class} is not one of #{specifics.keys.join(", ")}"
              end
            end

            def #{reflection.name}_id
              #{specifics.values.map { |name| "#{name}_id" }.join(" || ")}
            end

            def #{reflection.name}_type
              #{specifics.map { |class_name, name| "if #{name}_id\n  #{class_name.inspect}" }.join("\n  els")}
              end
            end

            private def validate_#{reflection.name}_presence
              unless [#{specifics.map { "((a = association(:#{_2})).loaded? && a.target) || #{_2}_id" }.join(", ")}].compact.size #{required ? "==" : "<="} 1
                errors.add(:base, "#{required ? "Exactly one" : "At most one"} #{reflection.name} must be present")
              end
            end
          RUBY

          specifics.each do |(class_name, name)|
            belongs_to(name, class_name:, optional: true, **) # rubocop:disable Rails/ReflectionClassName

            # def account=(object)
            #   super
            #   self.course = nil unless course_id.nil?
            #   self.group = nil unless group_id.nil?
            # end
            polymorph_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
              def #{name}=(object)
                super
                #{specifics.filter_map { "self.#{_2} = nil unless #{_2}_id.nil?" unless _2 == name }.join("\n  ")}
              end
            RUBY
          end
        end
      end

      module PolymorphicArrayValue
        def queries
          return super if values.empty? || !associated_table.polymorphic_association?
          return super unless (reflection = associated_table.send(:reflection)).options[:separate_columns]

          specifics = reflection.options[:polymorphic]
          type_to_ids_mapping.map do |type, ids|
            if type
              { specifics[type] => ids }
            else
              # no type? then _all_ foreign keys must match
              # (this is used when passing nil, but will also catch other degenerate cases)
              specifics.to_h { |_, name| [name, ids] }
            end
          end
        end
      end
    end
  end
end
