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

class GraphQLTypeTester
  def initialize(type, test_object, user=nil)
    @type = type.is_a?(GraphQL::ObjectType) ? type : CanvasSchema.types[type]
    @obj = test_object
    @current_user = user
    @context = {current_user: @current_user}

    @type.fields.each { |name, field|
      # can't do id because the builtin relay helper provided by GraphQL::Relay
      # references the schema by grabbing it off ctx.query (which obv doesn't
      # exist)
      #
      # if we felt strongly about being able to run "id" we will want to not
      # use the builtin helper
      next if name == "id"

      if respond_to?(name)
        raise "error: trying to overwrite existing method #{name}"
      end

      define_singleton_method name do |ctx={}|
        args = ctx.delete(:args) || {}
        GraphQL::Batch.batch {
          field.resolve(@obj, args, @context.merge(ctx))
        }
      end
    }
  end
end
