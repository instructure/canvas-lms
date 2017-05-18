#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/users_specs')

describe "sub account users" do
  describe "shared users specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:url) { "/accounts/#{account.id}/users" }
    let(:opts) { {:name => 'student'} }
    include_examples "users basic tests"

    it "does not show the add user link for sub-accounts", priority: '2', test_id: 854797 do
      course_with_admin_logged_in
      get url
      expect(f('#right-side')).not_to contain_css('.add_user_link')
    end
  end
end
