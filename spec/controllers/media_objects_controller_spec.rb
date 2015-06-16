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
    before do
      # We don't actually want to ping kaltura during these tests
      MediaObject.stubs(:media_id_exists?).returns(true)
      MediaObject.any_instance.stubs(:media_sources).returns([])
    end
    
    it "should create a MediaObject if necessary on request" do
      # this test is purposely run with no user logged in to make sure it works in public courses

      missing_media_id = "0_12345678"
      expect(MediaObject.by_media_id(missing_media_id)).to be_empty

      get 'show', :media_object_id => missing_media_id
      expect(json_parse(response.body)).to eq({
              'can_add_captions' => false,
              'media_tracks' => [],
              'media_sources' => []
      })
      expect(MediaObject.by_media_id(missing_media_id).first.media_id).to eq missing_media_id
    end
    
    it "should retrieve info about a 'deleted' MediaObject" do
      deleted_media_id = '0_deadbeef'
      course
      media_object = course.media_objects.build :media_id => deleted_media_id
      media_object.workflow_state = 'deleted'
      media_object.save!
      
      get 'show', :media_object_id => deleted_media_id
      expect(json_parse(response.body)).to eq({
          'can_add_captions' => false,
          'media_tracks' => [],
          'media_sources' => []
      })
    end
  end
end
