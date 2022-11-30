# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe "Rack::Utils" do
  it "raises an exception if the params are too deep" do
    len = Rack::Utils.param_depth_limit

    expect do
      Rack::Utils.parse_nested_query("foo#{"[a]" * len}=bar")
    end.to raise_error(RangeError)

    expect do
      Rack::Utils.parse_nested_query("foo#{"[a]" * (len - 1)}=bar")
    end.to_not raise_error
  end
end
