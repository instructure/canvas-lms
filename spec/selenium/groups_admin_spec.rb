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

require_relative 'common'
require_relative 'helpers/groups_common'

describe 'account groups' do
  include_context 'in-process server selenium tests'
  include GroupsCommon

  describe 'as an admin' do
    it 'should list uncategorized groups' do
      a = Account.default
      admin_logged_in
      # no group category means uncategorized
      group = a.groups.create(name: 'anugroup', context: a)
      group.add_user @user

      get "/accounts/#{a.id}/groups/"
      expect(f("body")).to include_text("anugroup")
    end
  end
end

