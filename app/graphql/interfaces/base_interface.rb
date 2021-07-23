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

# Create a GraphQL interface (https://graphql-ruby.org/type_definitions/interfaces)
# by including this module in your interface module.  In addition to the standard
# GraphQL field declarations, this will allow you to attach `@key` and `@external`
# directives to your interface for integration with other services' data graphs in a
# federated supergraph. See: https://github.com/Gusto/apollo-federation-ruby#usage
module Interfaces::BaseInterface
  include GraphQL::Schema::Interface
  include ApolloFederation::Interface

  field_class Types::BaseField
end
