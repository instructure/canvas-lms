# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
# more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

##
# The following little bit of monkey patching exists to set a postgres
# statement_timeout for queries that happen during GraphQL execution.  In
# the past, we simply wrapped calls to CanvasSchema.execute in a transaction
# with the appropriate statement_timeout, but that doesn't work for
# mutations.
#
# Each selection on Mutation needs to run in its own transaction so that a
# failure in one doesn't affect the others (the code to do that lives
# separately in +MutationTransactionInstrumenter+)
#
# I wish this could be done without monkey-patching but there isn't a way to
# do that since Rails transactions must happen in a block.

module QueryPgTimeout
  def run_queries(schema, queries, **kwargs)
    # we don't multiplex queries in Canvas right now, but if we start to do
    # that someday, this code will need to be adjusted
    # (it should fail if queries and mutations are mixed)
    raise "multiplexing is not supported" if queries.size > 1

    # mutations are handled separately in +MutationTransactionInstrumenter+
    if queries[0].mutation?
      super
    else
      GraphQLPostgresTimeout.wrap(queries[0]) do
        super
      end
    end
  end
end

GraphQL::Execution::Multiplex.singleton_class.prepend(QueryPgTimeout)
