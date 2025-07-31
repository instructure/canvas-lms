# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
#

module Analyzers
  class CanvasAntiabuseAnalyzer < BaseAnalyzer
    def initialize(subject)
      super
      @alias_count = 0
      @directive_count = 0
    end

    def on_leave_field(node, _parent, _visitor)
      @alias_count += 1 if node.alias
      @directive_count += node.directives.length unless node.directives.empty?
    end

    def result
      if @alias_count > GraphQLTuning.max_query_aliases
        log_to_sentry("GraphQL: max query aliases exceeded", alias_count: @alias_count)
        return GraphQL::AnalysisError.new("max query aliases exceeded")
      end

      if @directive_count > GraphQLTuning.max_query_directives
        log_to_sentry("GraphQL: max query directives exceeded", directive_count: @directive_count)
        GraphQL::AnalysisError.new("max query directives exceeded")
      end
    end
  end
end
