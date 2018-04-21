#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Factories
  VALID_GROUP_CATEGORY_ATTRIBUTES = [:name, :context, :group_limit, :sis_source_id]

  def group_category(opts = {})
    opts[:name] = opts[:name].present? ? opts[:name] : 'foo'
    context = opts[:context] || @course
    @group_category = context.group_categories.create! opts.slice(*VALID_GROUP_CATEGORY_ATTRIBUTES)
  end
end
