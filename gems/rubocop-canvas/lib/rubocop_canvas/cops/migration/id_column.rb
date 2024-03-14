# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
      class IdColumn < Cop
        include RuboCop::Canvas::CurrentDef

        MSG = "Use `:bigint` for id columns"

        def_node_matcher :add_integer_column, <<~PATTERN
          (send nil? :add_column _ (sym $_) (sym {:integer | :int}) ...)
        PATTERN

        def_node_matcher :t_integer, <<~PATTERN
          (send lvar {:integer | :int} (sym $_) ...)
        PATTERN

        def_node_matcher :t_column_integer, <<~PATTERN
          (send lvar :column (sym $_) (sym {:integer | :int}) ...)
        PATTERN

        RESTRICT_ON_SEND = %i[add_column column integer int].freeze

        def on_send(node)
          return if @current_def == :down

          column_name = add_integer_column(node) || t_integer(node) || t_column_integer(node)
          return unless column_name&.to_s&.end_with?("_id")

          add_offense(node, severity: :warning)
        end
      end
    end
  end
end
