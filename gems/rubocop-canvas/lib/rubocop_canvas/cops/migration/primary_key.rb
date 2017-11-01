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

require 'parser/current'

module RuboCop
  module Cop
    module Migration
      class PrimaryKey < Cop
        MSG = "Please always include a primary key"

        def on_send(node)
          _receiver, method_name, *args = *node
          if method_name == :create_table
            check_create_table(node, args)
          end
        end

        NO_PK = Parser::CurrentRuby.parse("{ id: false }").children.first

        def check_create_table(node, args)
          options = args.last
          return unless options.hash_type?

          if options.children.find { |pair| pair == NO_PK }
            add_offense(node, message: MSG, severity: :warning)
          end
        end
      end
    end
  end
end
