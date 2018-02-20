#
# Copyright (C) 2015 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/profile_common')

describe 'profile_pics' do
  include_context "in-process server selenium tests"
  include_context "profile common"

  context 'as an admin' do
    before do
      admin_logged_in
    end

    it_behaves_like 'profile_settings_page', :admin

    it_behaves_like 'profile_user_about_page', :admin

    it_behaves_like 'user settings page change pic window', :admin

    it_behaves_like 'user settings change pic cancel', :admin

    it_behaves_like 'with gravatar settings', :admin

  end
end
