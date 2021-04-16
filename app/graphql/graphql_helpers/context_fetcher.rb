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
#

module GraphQLHelpers::ContextFetcher
  def context_fetcher(input, valid_context_types=[])
    if valid_context_types.exclude?(input[:context_type])
      raise GraphQL::ExecutionError, I18n.t("invalid context type")
    end

    context =
      begin
        context_type = Object.const_get(input[:context_type])
        context_type.find_by(id: input[:context_id])
      rescue
        raise GraphQL::ExecutionError, I18n.t("invalid context type")
      end
    raise GraphQL::ExecutionError, I18n.t("context not found") if context.nil?

    context
  end
end
