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

describe "MemoryLimit" do
  before do
    stub_const("DEFAULT", 100.gigabytes)
    allow(Process).to receive(:getrlimit).with(:DATA).and_return([DEFAULT, DEFAULT])
  end

  it "applies the memory limit, calls the block, and undoes the change" do
    expect(Process).to receive(:setrlimit).with(:DATA, 2.gigabytes, DEFAULT)

    result = MemoryLimit.apply(2.gigabytes) do
      expect(Process).to receive(:setrlimit).with(:DATA, DEFAULT, DEFAULT)
      123
    end

    expect(result).to eq 123
  end

  it "still calls the block if the OS dislikes the limit" do
    expect(Process).to receive(:setrlimit).with(:DATA, 2.gigabytes, DEFAULT).and_raise(Errno::EINVAL)

    result = MemoryLimit.apply(2.gigabytes) do
      123
    end

    expect(result).to eq 123
  end
end
