# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
      class FunctionUnqualifiedTable < Cop
        include RuboCop::Canvas::CurrentDef

        MSG = <<~'TEXT'.tr("\n", " ")
          Use unqualified table names in function creation to be compatible with beta/test refresh.
          (ie: `folders` and not `#{Folder.quoted_table_name}`))
        TEXT

        def create_or_replace_function?(string)
          @execute_string += string
          @execute_string.match(/(create|replace)\s+function/i)
        end

        def_node_search :create_function?, <<~PATTERN
          $(str #create_or_replace_function?)
        PATTERN

        def_node_search :qualified_name, <<~PATTERN
          $(send _ :quoted_table_name)
        PATTERN

        RESTRICT_ON_SEND = [:execute].freeze

        def on_send(node)
          @execute_string = ""
          return if @current_def == :down

          qualified_name = qualified_name(node).first
          add_offense(qualified_name, severity: :error) if create_function?(node) && !qualified_name.nil?
        end
      end
    end
  end
end
