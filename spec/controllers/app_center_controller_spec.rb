#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AppCenterController do
  describe "#map_tools_to_apps!" do
    it "maps tools" do
      course_model
      tool1 = @course.account.context_external_tools.create(:tool_id => 'tool1', :name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "google.com")
      tool2 = @course.context_external_tools.create(:tool_id => 'tool2', :name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "google.com")
      apps = [
          {'short_name' => tool1.tool_id},
          {'short_name' => tool2.tool_id},
          {'short_name' => 'not_installed'}
      ]

      controller.map_tools_to_apps!(@course, apps)

      expect(apps).to include({'short_name' => tool1.tool_id, 'is_installed' => true})
      expect(apps).to include({'short_name' => tool2.tool_id, 'is_installed' => true})
      expect(apps).to include({'short_name' => 'not_installed'})
    end
  end
end
