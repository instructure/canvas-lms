#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe UserProfile do
  context "tabs available" do
    it "should show the profile tab when profiles are enabled" do
      student_in_course(:active_all => true)
      tabs = @student.profile.
        tabs_available(@user, :root_account => Account.default)
      expect(tabs.map { |t| t[:id] }).not_to include UserProfile::TAB_PROFILE

      Account.default.update_attribute :settings, :enable_profiles => true
      tabs = @student.profile(true).
        tabs_available(@user, :root_account => Account.default)
      expect(tabs.map { |t| t[:id] }).to include UserProfile::TAB_PROFILE
    end
  end
end
