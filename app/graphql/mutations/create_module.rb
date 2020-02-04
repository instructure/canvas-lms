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

class Mutations::CreateModule < Mutations::BaseMutation
  graphql_name "CreateModule"

  argument :name, String, required: true
  argument :course_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")

  field :module, Types::ModuleType, null: true, resolver_method: :will_not_be_called
  def will_not_be_called
    # This is a silly workaround for https://github.com/rmosolgo/graphql-ruby/issues/2723
  end

  def resolve(input:)
    course_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:course_id], "Course")
    course = Course.find(course_id)
    verify_authorized_action!(course.context_modules.temp_record, :create)
    mod = course.context_modules.build(name: input[:name])
    mod.require_presence_of_name = true
    if mod.save
      {module: mod}
    else
      errors_for(mod)
    end
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
