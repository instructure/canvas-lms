# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

# rubocop:disable RSpec/FilePath
describe AuthenticationProvider::Apple do
  it "allows login attribute to be set" do
    expect(described_class.recognized_params).to include(:login_attribute)
  end

  it "allows jit_provisioning to be set" do
    expect(described_class.recognized_params).to include(:jit_provisioning)
  end
end
# rubocop:enable RSpec/FilePath
