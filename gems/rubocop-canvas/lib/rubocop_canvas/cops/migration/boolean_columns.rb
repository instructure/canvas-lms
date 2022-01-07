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
      class BooleanColumns < Cop
        include RuboCop::Canvas::CurrentDef

        MSG = "Boolean columns should be NOT NULL and have a default value"

        def_node_matcher :add_column?, <<~PATTERN
          (send nil? :add_column _ _ (sym {:boolean | :bool}) ...)
        PATTERN

        def_node_matcher :t_boolean?, <<~PATTERN
          (send lvar {:boolean | :bool} _ ...)
        PATTERN

        def_node_matcher :t_column?, <<~PATTERN
          (send lvar :column _ (sym {:boolean | :bool}) ...)
        PATTERN

        def_node_search :default_value?, <<~PATTERN
          (pair (sym :default) {true | false})
        PATTERN

        def_node_search :not_null?, <<~PATTERN
          (pair (sym :null) false)
        PATTERN

        RESTRICT_ON_SEND = %i[add_column column boolean bool].freeze

        def on_send(node)
          return if @current_def == :down

          if add_column?(node) || t_boolean?(node) || t_column?(node)
            add_offense(node) unless default_value?(node) && not_null?(node)
          end
        end
      end
    end
  end
end
