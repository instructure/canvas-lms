# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Types
  class ApplicationObjectType < GraphQL::Schema::Object
    # this is using graphql-ruby's built-in authorization framework
    #
    # we are purposely not using it anywhere else in the app for performance
    # reasons (we don't want to accidentally run permission checks on a long
    # list of objects, for example)
    def self.authorized?(_value, context)
      super && AuthenticationMethods.graphql_type_authorized?(context[:access_token], graphql_name)
    end

    def current_user
      context[:current_user]
    end

    def session
      context[:session]
    end

    def load_association(assoc)
      Loaders::AssociationLoader.for(object.class, assoc).load(object)
    end
  end
end
