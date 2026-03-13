# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module Factories
  def institutional_tag_model(opts = {})
    account = opts.delete(:account) || @account || account_model
    category = opts.delete(:category) || institutional_tag_category_model(account:)
    name = opts.delete(:name) || "Test Tag"
    description = opts.delete(:description) || "A test tag"

    InstitutionalTag.create!({
      name:,
      description:,
      category:,
    }.merge(opts))
  end
end
