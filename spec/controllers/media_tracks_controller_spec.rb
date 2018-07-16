#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe MediaTracksController do

  before :once do
    course_with_teacher(:active_all => true)
    @mo = factory_with_protected_attributes(MediaObject, :media_id => '0_abcdefgh', :old_media_id => '1_01234567', :context => @course)
  end

  before do
    user_session(@teacher)
  end

  describe "#create" do
    it "should create a track" do
      expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
      content = "one track mind"
      post 'create', params: {:media_object_id => @mo.media_id, :kind => 'subtitles', :locale => 'en', :content => content}
      expect(response).to be_successful
      track = @mo.media_tracks.last
      expect(track.content).to eq content
    end
  end

  describe "#show" do
    it "should show a track" do
      track = @mo.media_tracks.create!(kind: 'subtitles', locale: 'en', content: "subs")
      get 'show', params: {:media_object_id => @mo.media_id, :id => track.id}
      expect(response).to be_successful
      expect(response.body).to eq track.content
    end
  end

  describe "#destroy" do
    it "should destroy a track" do
      expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
      track = @mo.media_tracks.create!(kind: 'subtitles', locale: 'en', content: "subs")
      delete 'destroy', params: {:media_object_id => @mo.media_id, :media_track_id => track.id}
      expect(MediaTrack.where(:id => track.id).first).to be_nil
    end
  end
end
