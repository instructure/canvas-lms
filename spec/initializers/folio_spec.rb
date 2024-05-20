# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe Folio do
  it "skips the count for a grouped query that takes a long time" do
    stub_const("Folio::PAGINATION_COUNT_TIMEOUT", "5ms")
    User.create!
    User.create!
    result = User.group(:id).where("pg_sleep(0.1) IS NOT NULL").paginate(per_page: 1)
    expect(result.length).to eq 1
    expect(result.total_entries).to be_nil
  end

  it "skips the count for a regular query that takes a long time" do
    stub_const("Folio::PAGINATION_COUNT_TIMEOUT", "5ms")
    User.create!
    User.create!
    result = User.where("pg_sleep(0.1) IS NOT NULL").paginate(per_page: 1)
    expect(result.length).to eq 1
    expect(result.total_entries).to be_nil
  end
end
