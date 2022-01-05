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
      class ChangeColumnNull < Cop
        include RuboCop::Canvas::CurrentDef
        include RuboCop::Canvas::NonTransactional

        NON_TRANSACTIONAL_MSG = "Use `disable_ddl_transaction!` when adding a NOT NULL constraint"
        BACKFILL_NULLS_MSG = "Use `DataFixup::BackfillNulls` to ensure no null rows exist before adding a NOT NULL constraint"

        def_node_matcher :change_column_not_null?, <<~PATTERN
          (send nil? :change_column_null _ _ false)
        PATTERN

        # NOTE: since this takes the AR class name rather than the table name, and arguments to this
        # and change_column_null are often dynamic, it isn't really possible to verify this is called
        # _correctly_ with a static linter. but we can at least see that it's there.
        def_node_search :backfill_nulls?, <<~PATTERN
          (send (const (const nil? :DataFixup) :BackfillNulls) :run ...)
        PATTERN

        def on_class(node)
          @class_node = node
          @backfill_nulls = backfill_nulls?(node)
          @non_transactional = non_transactional?(node)
        end

        def on_send(node)
          return if @current_def == :down

          if change_column_not_null?(node)
            add_offense node, message: BACKFILL_NULLS_MSG, severity: :warning unless @backfill_nulls
            add_offense @class_node || node, message: NON_TRANSACTIONAL_MSG, severity: :warning unless @non_transactional
          end
        end
      end
    end
  end
end
