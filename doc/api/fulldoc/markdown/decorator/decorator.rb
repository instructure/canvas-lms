# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "gitbook_decorator"

# There are cases when Markdown doesn't provide enough flexibility to
# create the desired output. In such instances, we can use the
# Decorator module to add custom tags to the Markdown content, which
# are understood and rendered by the Markdown engine.
#
# If someone wants to implement a new decorator, they can do so by
# creating a new module and implementing the functions provided by the
# Decorator module. Additionally, replace `include GitbookDecorator`
# with your implementation below.
module Decorator
  include GitbookDecorator
end
