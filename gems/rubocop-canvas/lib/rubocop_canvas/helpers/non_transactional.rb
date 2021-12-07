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

module RuboCop::Canvas
  module NonTransactional
    extend RuboCop::NodePattern::Macros

    # usage example:
    #
    # def on_class(node)
    #   @non_transactional = non_transactional?(node)
    # end

    def_node_search :non_transactional?, <<~PATTERN
      (send nil? :disable_ddl_transaction! ...)
    PATTERN
  end
end
