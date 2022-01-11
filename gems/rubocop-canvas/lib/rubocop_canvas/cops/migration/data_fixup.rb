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
      class DataFixup < Cop
        include RuboCop::Canvas::MigrationTags

        MSG = "Data fixups should be done in postdeploy migrations"

        def_node_matcher :datafix?, <<~PATTERN
          (send
            (const
              (const nil? :DataFixup) _) :run)
        PATTERN

        RESTRICT_ON_SEND = [:tag, :run].freeze

        def on_send(node)
          super

          return if @tags.include? :postdeploy

          add_offense(node, severity: :convention) if datafix?(node)
        end
      end
    end
  end
end
