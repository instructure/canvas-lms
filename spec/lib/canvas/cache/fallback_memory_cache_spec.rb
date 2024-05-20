# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

describe Canvas::Cache::FallbackMemoryCache do
  it "does not crash in dev when loading objects from memory that were loaded under an older code load" do
    allow(Rails.env).to receive(:development?).and_return true
    cache = Canvas::Cache::FallbackMemoryCache.new
    cache.write("role_override_key", teacher_role)
    Object.send(:remove_const, "Role") # rubocop:disable RSpec/RemoveConst
    load(Rails.root.join("app/models/role.rb"))
    expect { cache.fetch("role_override_key") }.not_to raise_error
  end
end
