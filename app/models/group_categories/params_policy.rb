# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module GroupCategories

  class ParamsPolicy
    attr_reader :group_category, :context

    def initialize(category, category_context)
      @group_category = category
      @context = category_context
    end

    def populate_with(args, populate_opts={})
      params = Params.new(args, populate_opts)
      group_category.name = (params.name || group_category.name)
      group_category.self_signup = params.self_signup
      group_category.auto_leader = params.auto_leader
      group_category.group_limit = params.group_limit
      group_category.group_by_section = params.group_by_section
      if context.is_a?(Course)
        group_category.create_group_count = params.create_group_count
        group_category.create_group_member_count = params.create_group_member_count
        unless params.assign_async
          group_category.assign_unassigned_members = params.assign_unassigned_members
        end
      end
      group_category
    end

  end

end
