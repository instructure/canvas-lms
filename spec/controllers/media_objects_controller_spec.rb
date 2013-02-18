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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MediaObjectsController do

  describe "GET 'show'" do
    it "should create a MediaObject if necessary on request" do
      # this test is purposely ran with no user logged in to make sure it works in public courses

      missing_media_id = "0_12345678"
      MediaObject.by_media_id(missing_media_id).should be_empty

      # We don't actually want to ping kaltura during this test
      MediaObject.stubs(:media_id_exists?).returns(true)
      MediaObject.any_instance.stubs(:media_sources).returns([])

      get 'show', :media_object_id => missing_media_id
      json_parse(response.body).should == {
              'can_add_captions' => false,
              'media_tracks' => [],
              'media_sources' => []
      }
      MediaObject.by_media_id(missing_media_id).first.media_id.should == missing_media_id
    end

  end
end