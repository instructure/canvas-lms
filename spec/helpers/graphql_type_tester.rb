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

##
# = Convenience class for testing graphql types.
#
# This class provides a more convenient workflow for writing graphql queries
# and inspecting their results.  Consider the following example:
#
#   user_type = GraphQLTypeTester.new(@student, current_user: @teacher)
#   expect(user_type.resolve("_id")).to eq @student.id.to_s
#
# this is equivalent to constructing the following query by hand:
#
#   res = CanvasSchema.execute(<<~GQL, context: {current_user: @teacher})
#     node(id: "asdfasdf") {
#       ... on User {
#         _id
#       }
#     }
#   GQL
#   expect(res["data"]["node"]["_id"]).to eq @student.id.to_s
#
class GraphQLTypeTester
  # _test_object_ is the backing object for a GraphQL type.  It must implement
  # +GraphQL::Types::Relay::Node+ (otherwise you'll need to reach down the
  # graph from a parent object).
  #
  # _context_ is an optional default context that will be passed to the query.
  def initialize(test_object, context = {})
    @obj = test_object
    @context = context
    @extract_result = true
  end

  attr_accessor :extract_result

  # _extract_result_ is an boolean to call extract_result function or return raw result.

  # returns the value (or list of values) for the resolved field.  This can be
  # any fragment of graphql, but ultimately should only select a single scalar
  # field:
  #
  # [good]  * <tt>id</tt>
  #         * <tt>foo(bar: BAZ)</tt>
  #         * <tt>userConnection { edges { node { name } } }</tt> In this case,
  #           the return value of resolve will be a list of names
  #         * <tt>course { updatedAt }</tt>
  # [bad]   * <tt>id, name</tt> selecting multiple fields is not allowed
  #         * <tt>userConnection</tt> must select scalars (not compound types)
  #
  # _context_ represents additional context to pass to the query (or to
  # override the context supplied in the constructor).  This will typically be
  # used to pass the _current_user_.
  def resolve(field_and_subfields, context = {})
    field_context = @context.merge(context)
    type = CanvasSchema.resolve_type(nil, @obj, field_context) or
      raise "couldn't resolve type for #{@obj.inspect}"
    variables = {
      id: CanvasSchema.id_from_object(@obj, type, field_context)
    }

    query = <<~GQL
      query($id: ID!) {
        node(id: $id) {
          ... on #{type.graphql_name} {
            #{field_and_subfields}
          }
        }
      }
    GQL
    result = CanvasSchema.execute(query, context: field_context, variables:)

    if result["errors"]
      raise Error, result["errors"].inspect
    else
      return extract_results(result) if @extract_result

      result["data"]["node"]
    end
  end

  Error = Class.new(StandardError)

  private

  def extract_field(field_and_subfields, type)
    field_and_subfields =~ /\A(\w+)/
    field = $1
    if !field || !type.fields[field]
      raise "couldn't find field #{field} for #{type}"
    end

    field
  end

  def extract_results(result)
    result = result.to_hash if result.respond_to?(:to_hash)
    return result unless result.is_a?(Hash)

    # return the last value of the last pair of a hash, recursively
    v = result.to_a.last.last
    case v
    when Hash then extract_results(v)
    when Array then v.map { |x| extract_results(x) }
    else v
    end
  end
end
