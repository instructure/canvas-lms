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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')

describe "Groups API", :type => :integration do
  context "group files" do
    it_should_behave_like "file uploads api with folders"

    before do
      group_model
      @group.add_user(user_with_pseudonym)
    end

    def preflight(preflight_params)
      api_call(:post, "/api/v1/groups/#{@group.id}/files",
        { :controller => "groups", :action => "create_file", :format => "json", :group_id => @group.to_param, },
        preflight_params)
    end

    def context
      @group
    end
  end
end
