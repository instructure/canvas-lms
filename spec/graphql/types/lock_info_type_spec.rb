#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::LockInfoType do
  def lock_info_type(lock_info)
    GraphQLTypeTester.new(Types::LockInfoType, lock_info)
  end

  it "works when lock_info is false" do
    expect(lock_info_type(false).isLocked).to eq false

    %i[lockedObject module lockAt unlockAt canView].each { |field|
      expect(
        lock_info_type(false).send(field)
      ).to eq nil
    }
  end

  it "works when lock_info is a hash" do
    lock_info = {object: "a", module: "b", canView: true}
    lock_type = lock_info_type(lock_info)

    expect(lock_type.isLocked).to eq true
    expect(lock_type.lockedObject).to eq lock_info[:object]
    expect(lock_type.module).to eq lock_info[:module]
    expect(lock_type.canView).to eq lock_info[:can_view]
  end
end
