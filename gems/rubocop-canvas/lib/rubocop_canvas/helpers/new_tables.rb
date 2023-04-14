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

module RuboCop::Canvas
  module NewTables
    extend RuboCop::NodePattern::Macros

    # usage example:
    #
    # def on_class(node)
    #   @new_tables = new_tables(node)
    # end

    def new_tables(class_node)
      new_tables_impl(class_node).map(&:indifferent)
    end

    def_node_search :new_tables_impl, <<~PATTERN
      (send nil? :create_table $_ ...)
    PATTERN
  end
end
