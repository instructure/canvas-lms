# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
# = Base Canvas Mutation class
#
# The most fundamental change this class makes compared to
# +GraphQL::Schema::Mutation+ is that it facilitates conveniently following
# the convention of always taking a single input argument and returning a
# unique payload per mutation.
#
# Any arguments defined in a mutation descended from this class will be
# hoisted into a custom input object.  Fields on the mutation will similarly
# be hoisted into a custom payload object.
#
# An +errors+ field will be added to all payloads for validation errors.
class Mutations::BaseMutation < GraphQL::Schema::Mutation
  include GraphQL::Schema::HasSingleInputArgument

  field :errors, [Types::ValidationErrorType], null: true

  def current_user
    context[:current_user]
  end

  def resolve_with_support(**input)
    # our resolvers generally expect a hash, not GraphQL objects, so just transform it here
    input_hash = input.deep_transform_values { |v| v.is_a?(GraphQL::Schema::InputObject) ? v.to_h : v }

    super(input: input_hash)
  end

  def session
    context[:session]
  end

  def verify_authorized_action!(obj, perm)
    raise GraphQL::ExecutionError, "not found" unless obj.grants_right?(current_user, session, perm)
  end

  # TODO: replace this with model validation where applicable
  def validation_error(message, attribute: "message")
    {
      errors: {
        attribute.to_sym => message
      }
    }
  end

  private

  # returns validation errors in a consistent format (`Types::ValidationError`)
  #
  # validation errors on an attribute that match one of the mutation's input
  # fields will be returned with that attribute specified (otherwise
  # `attribute` will be null)
  #
  # `override_keys` is a hash where the key is the field at the table and the value
  # is the alias of the field; the keys and values need to be set as symbols.
  def errors_for(model, override_keys = {})
    input_fields = self.class.arguments.values.to_h { |a| [a.keyword, a.name] }

    {
      errors: model.errors.entries.map do |attribute, message|
        key = override_keys.key?(attribute) ? override_keys[attribute] : attribute
        [input_fields[key], message]
      end
    }
  end
end
