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
  def initialize(test_object, context = {})
    @obj = test_object
    @context = context
  end

  def resolve(field_and_subfields, context = {})
    field_context = @context.merge(context)
    type = CanvasSchema.resolve_type(@obj, field_context) or
      raise "couldn't resolve type for #{@obj.inspect}"
    field = extract_field(field_and_subfields, type)
    variables = {
      id: CanvasSchema.id_from_object(@obj, type, field_context)
    }

    result = CanvasSchema.execute(<<~GQL, context: field_context, variables: variables)
      query($id: ID!) {
        node(id: $id) {
          ... on #{type} {
            #{field_and_subfields}
          }
        }
      }
    GQL

    if result["errors"]
      raise "QraphQL query error: #{result["errors"].inspect}"
    else
      extract_results(result)
    end
  end

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
    return result unless result.respond_to?(:reduce)
    result.reduce(nil) do |result, (k, v)|
      case v
      when Hash then extract_results(v)
      when Array then v.map { |x| extract_results(x) }
      else v
      end
    end
  end
end
