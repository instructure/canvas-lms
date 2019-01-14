#
# Copyright (C) 2019 - present Instructure, Inc.
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

class MutationTransactionInstrumenter
  def instrument(type, field)
    if type.name == "Mutation"
      field.redefine(resolve: MutationWrapper.new(field.resolve_proc))
    else
      field
    end
  end

  class MutationWrapper
    def initialize(original_resolver)
      @original_resolver = original_resolver
    end

    def call(obj, args, ctx)
      GraphQLPostgresTimeout.wrap(ctx.query) do
        @original_resolver.call(obj, args, ctx)
      end
    end
  end
end
