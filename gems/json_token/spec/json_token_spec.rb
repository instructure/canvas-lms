#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'spec_helper'

describe JSONToken do
  it 'should encode' do
    expect(JSONToken.encode({a: 123, b: [1, 2, '13']})).to eq "eyJhIjoxMjMsImIiOlsxLDIsIjEzIl19"
  end

  it 'should decode' do
    expect(JSONToken.decode("eyJhIjoxMjMsImIiOlsxLDIsIjEzIl19")).to eq({"a" => 123, "b" => [1, 2, "13"]})
  end

  it 'should handle binary strings' do
    messy = "\xD1\x9B\x86".force_encoding("ASCII-8BIT")
    expect(JSONToken.decode(JSONToken.encode(messy))).to eq messy
  end
end
