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

describe "Hash#deep_sort_values" do
  it "can handle top-level arrays" do
    expect({ "a" => [3, 2, 1] }.deep_sort_values).to eq({ "a" => [1, 2, 3] })
  end

  it "can handle nested arrays" do
    expect({ "a" => { "b" => [3, 2, 1] } }.deep_sort_values).to eq({ "a" => { "b" => [1, 2, 3] } })
  end

  it "can handle nested hashes with arrays" do
    expect({ "a" => { "b" => [3, 2, 1], "c" => [6, 5, 4] } }.deep_sort_values)
      .to eq({ "a" => { "b" => [1, 2, 3], "c" => [4, 5, 6] } })
  end
end
