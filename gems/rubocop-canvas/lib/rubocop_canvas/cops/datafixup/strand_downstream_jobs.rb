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
    module Datafixup
      class StrandDownstreamJobs < Cop
        def on_send(node)
          _receiver, method_name, kwargs = *node
          return unless method_name == :delay
          return if kwargs.is_a?(RuboCop::AST::HashNode) &&
                    kwargs.keys.all?(RuboCop::AST::SymbolNode) &&
                    kwargs.keys.map(&:value).intersect?(%i[strand n_strand singleton])

          add_offense(node,
                      message: "when queuing downstream jobs in a datafixup, they need to be a strand or n_strand",
                      severity: :error)
        end
      end
    end
  end
end
