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
      @mo.any_instantiation.expects(:media_sources).returns(nil)
      content = "one track mind"
      post 'create', :media_object_id => @mo.media_id, :kind => 'subtitles', :locale => 'en', :content => content
      expect(response).to be_success
      track = @mo.media_tracks.last
      expect(track.content).to eq content
    end
  end

  describe "#show" do
    it "should show a track" do
      track = @mo.media_tracks.create!(kind: 'subtitles', locale: 'en', content: "subs")
      get 'show', :media_object_id => @mo.media_id, :id => track.id
      expect(response).to be_success
      expect(response.body).to eq track.content
    end
  end

  describe "#destroy" do
    it "should destroy a track" do
      @mo.any_instantiation.expects(:media_sources).returns(nil)
      track = @mo.media_tracks.create!(kind: 'subtitles', locale: 'en', content: "subs")
      delete 'destroy', :media_object_id => @mo.media_id, :media_track_id => track.id
      expect(MediaTrack.where(:id => track.id).first).to be_nil
    end
  end
end
