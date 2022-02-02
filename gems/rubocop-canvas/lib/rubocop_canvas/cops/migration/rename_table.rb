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
      class RenameTable < Cop
        include RuboCop::Canvas::CurrentDef

        MSG = "Renaming a table requires a multi-deploy process; see https://instructure.atlassian.net/l/c/mArfa4cn"

        def_node_matcher :rename_table, <<~PATTERN
          (send nil? :rename_table _ $_)
        PATTERN

        def drop_view?(str)
          str.strip.downcase == "drop view"
        end

        def_node_search :drop_view_name, <<~PATTERN
          (send nil? :execute
            (dstr
              (str #drop_view?)
              (begin
                (send
                  (send nil? :connection)
                    :quote_table_name $_))))
        PATTERN

        RESTRICT_ON_SEND = %i[rename_table].freeze

        def on_class(node)
          @drop_view_name = drop_view_name(node).first&.value&.to_s
        end

        def on_send(node)
          return if @current_def == :down

          new_table_name = rename_table(node)&.value&.to_s
          add_offense(node, severity: :warning) if new_table_name && new_table_name != @drop_view_name
        end
      end
    end
  end
end
