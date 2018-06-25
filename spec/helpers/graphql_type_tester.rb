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
    @type = case
            when GraphQL::ObjectType === type then type
            when type < GraphQL::Schema::Object then type.graphql_definition
            else CanvasSchema.types[type]
            end
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
          if GraphQL::ObjectType === type
            # 1.7 class node-style api
            field.resolve(@obj, args, @context.merge(ctx))
          else
            # 1.8 class api
            type_obj = type.new(@obj, @context.merge(ctx))
            method_str = field.metadata[:type_class].method_str
            if type_obj.respond_to?(method_str)
              if args.present?
                type_obj.send(method_str, **args)
              else
                type_obj.send(method_str)
              end
            end
          end
        }
      end
    }
  end
end
