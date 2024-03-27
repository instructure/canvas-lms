# frozen_string_literal: true

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
      class SetReplicaIdentityInSeparateTransaction < Cop
        MSG = <<~TEXT
          When setting replica identity, do it in a separate migration than the
          `create_table` call.
        TEXT

        include RuboCop::Canvas::CurrentDef
        include RuboCop::Canvas::NewTables

        def_node_search :set_replica_identity, <<~PATTERN
          (send _ ${:set_replica_identity} $_ ...)
        PATTERN

        def on_class(node)
          @new_tables = new_tables(node)
        end

        def on_send(node)
          return if @current_def == :down

          set_replica_identity(node) do |_method, table|
            table = table.indifferent
            add_offense(node, severity: :error) if @new_tables.include?(table)
          end
        end
      end
    end
  end
end
