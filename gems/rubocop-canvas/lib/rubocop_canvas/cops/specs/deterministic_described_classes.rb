#
# Copyright (C) 2017 - present Instructure, Inc.
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

module RuboCop
  module Cop
    module Specs
      class DeterministicDescribedClasses < Cop
        def on_send(node)
          receiver, method_name, *args = *node
          return unless receiver.nil?
          first_arg = args.first
          return unless first_arg
          if DESCRIBE_METHOD_NAMES.include?(method_name)
            process_describe first_arg
          elsif REQUIRE_METHOD_NAMES.include?(method_name)
            require_nodes << node
          end
        end

        DESCRIBE_METHOD_NAMES = %i[describe context].freeze
        REQUIRE_METHOD_NAMES = %i[require require_dependency require_relative].freeze

        private

        def require_nodes
          @require_nodes ||= []
        end

        def require_dependency_calls
          require_nodes.each_with_object([]) do |node, result|
            _receiver, method_name, *args = *node
            next unless method_name == :require_dependency
            next unless args.first && args.first.str_type?
            result << args.first.to_a.first
          end
        end

        def process_describe(arg)
          return unless arg && arg.const_type?
          nesting = module_nesting(arg) # find outer modules/classes
          return if nesting.empty?

          const_parts, top_level = extract_mod_parts(arg)
          return if top_level # this is weird, but whatevs: module Foo; describe ::Bar

          full_name = nesting + const_parts
          return if require_dependency_calls.include? full_name.join("::").underscore

          add_offense(arg,
            message: error_message(nesting, const_parts),
            severity: :warning)
        end

        def error_message(nesting, const_parts)
          const_name = const_parts.join("::")
          nesting_name = nesting.join("::")
          full_name = (nesting + const_parts).join("::")
          full_path = full_name.underscore

          "`#{const_name}` appears to be an auto-loaded constant nested in " \
          "`#{nesting_name}`, but you are not explicitly requiring it.`\n\n" \
          \
          "You should `require_dependency #{full_path.inspect}` to ensure that " \
          "`described_class` is really what you think it is. Otherwise auto-" \
          "loading roulette could break your specs if there's another module/" \
          "class of the same name at a higher nesting (e.g. " \
          "`::#{const_name}`)\n\n" \
          \
          "Alternatively, get rid of the outer `module`(s) and just do " \
          "`describe #{full_name}`"
        end

        # Return an array of module nesting names for the given node in
        # the AST,
        #
        # e.g.
        #
        # module Foo::Bar
        #   module Baz
        #     describe Lol # <- the node
        #
        # => [:Foo, :Bar, :Baz]
        def module_nesting(node)
          node.ancestors.each_with_object([]) do |parent, result|
            next unless parent.module_type? || parent.class_type?
            mod_name = parent.to_a[0]
            next unless mod_name && mod_name.const_type?
            mod_segments, top_level = extract_mod_parts(mod_name)
            result.unshift(*mod_segments)
            return result if top_level # disregard any further/outer nesting
          end
        end

        # Return an array of symbols representing the module name parts of
        # given const node, and a bool indicating whether it's explicitly
        # top-level e.g.
        #
        # # given Foo::Bar::Baz
        # (const, (const, (const nil :Foo) :Bar) :Baz)
        # => [[:Foo, :Bar, :Baz], false]
        #
        # # given ::Foo::Bar::Baz
        # (const (const (const (cbase) :Foo) :Bar) :Baz)
        # => [[:Foo, :Bar, :Baz], true]
        def extract_mod_parts(mod_name)
          mod_name_parts = mod_name.to_a
          result = [mod_name_parts[1]]
          top_level = false
          if parent = mod_name_parts[0]
            if parent.cbase_type?
              top_level = true
            elsif parent.const_type?
              parts, top_level = *extract_mod_parts(parent)
              result.unshift(parts)
            else # TODO: do we care? this would be stuff like `some_var::MyConst`
              result = []
            end
          end
          [result, top_level]
        end

        def autocorrect(node)
          nesting = module_nesting(node)
          const_parts, _top_level = extract_mod_parts(node)
          full_name = (nesting + const_parts).join("::")
          full_path = full_name.underscore
          lambda do |corrector|
            corrector.insert_after(require_nodes.last.loc.expression, "\nrequire_dependency #{full_path.inspect}")
          end
        end
      end
    end
  end
end
