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
      class ChangeColumn < Cop
        MSG = "Changing column names or types usually requires a multi-deploy process; see https://instructure.atlassian.net/l/c/mArfa4cn"

        def_node_matcher :change_column?, <<~PATTERN
          (send nil? :change_column ...)
        PATTERN

        def_node_matcher :rename_column?, <<~PATTERN
          (send nil? :rename_column ...)
        PATTERN

        RESTRICT_ON_SEND = [:change_column, :rename_column].freeze

        def on_send(node)
          add_offense(node, severity: :warning) if change_column?(node) || rename_column?(node)
        end
      end
    end
  end
end
