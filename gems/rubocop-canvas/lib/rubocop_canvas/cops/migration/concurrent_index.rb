#
# Copyright (C) 2015 - present Instructure, Inc.
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
    module Migration
      class ConcurrentIndex < Cop
        def on_send(node)
          _receiver, method_name, *args = *node

          case method_name
          when :disable_ddl_transaction!
            @disable_ddl_transaction = true
          when :add_index
            check_add_index(node, args)
          end
        end

        ALGORITHM = AST::Node.new(:sym, [:algorithm])

        def check_add_index(node, args)
          options = args.last
          return unless options.hash_type?

          algorithm = options.children.find do |pair|
            pair.children.first == ALGORITHM
          end
          return unless algorithm
          algorithm_name = algorithm.children.last.children.first

          add_offenses(node, algorithm_name)
        end

        private

        def add_offenses(node, algorithm_name)
          if algorithm_name != :concurrently
            add_offense(node,
              message: "Unknown algorithm name `#{algorithm_name}`, did you mean `:concurrently`?",
              severity: :warning)
          end

          if algorithm_name == :concurrently && !@disable_ddl_transaction
            add_offense(node,
              message: "Concurrent index adds require `disable_ddl_transaction!`",
              severity: :warning)
          end
        end
      end
    end
  end
end
