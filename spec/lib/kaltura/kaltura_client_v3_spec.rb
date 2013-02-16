#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "Kaltura::ClientV3" do
  def create_config(opts={})
    Kaltura::ClientV3.stubs(:config).returns({
      'domain' => 'www.instructuremedia.com',
      'resource_domain' => 'www.instructuremedia.com',
      'partner_id' => '100',
      'subpartner_id' => '10000',
      'secret_key' => 'fenwl1n23k4123lk4hl321jh4kl321j4kl32j14kl321',
      'user_secret_key' => '1234821hrj3k21hjk4j3kl21j4kl321j4kl3j21kl4j3k2l1',
      'player_ui_conf' => '1',
      'kcw_ui_conf' => '1',
      'upload_ui_conf' => '1'
    }.merge(opts))

    @kaltura = Kaltura::ClientV3.new
  end

  before(:each) do
    create_config
  end

  it "should properly sanitize thumbnail parameters" do
    @kaltura.thumbnail_url('0_123<evil>', :width => 'evilwidth',
      :height => 'evilheight', :type => 'eviltype',
      :protocol => 'ssh', :bgcolor => 'evilcolor',
      :vid_sec => 'evilsec').should ==
    "//www.instructuremedia.com/p/100/thumbnail/entry_id/0_123evil/width/0/height/0/bgcolor/ec/type/0/vid_sec/0"
  end

  it "should use the correct protocol when specified" do
    @kaltura.thumbnail_url('0_abcdefg', :protocol => 'http').should ==
      "http://www.instructuremedia.com/p/100/thumbnail/entry_id/0_abcdefg/width/140/height/100/bgcolor/ffffff/type/2/vid_sec/5"
    @kaltura.thumbnail_url('0_abcdefg', :protocol => 'https').should ==
      "https://www.instructuremedia.com/p/100/thumbnail/entry_id/0_abcdefg/width/140/height/100/bgcolor/ffffff/type/2/vid_sec/5"
    @kaltura.thumbnail_url('0_abcdefg', :protocol => '').should ==
      "//www.instructuremedia.com/p/100/thumbnail/entry_id/0_abcdefg/width/140/height/100/bgcolor/ffffff/type/2/vid_sec/5"
  end

  describe "source sorting" do
    it "should work on an empty array" do
      @kaltura.sort_source_list([]).should == []
    end

    it "should work with an empty file extension" do
      @kaltura.sort_source_list(
              [
                      {:fileExt => '', :bitrate => '128'}
              ]).should ==
              [
                      {:fileExt => '', :bitrate => '128'}
              ]
    end

    it "should sort bitrates properly as numbers, and not as strings" do
      @kaltura.sort_source_list(
              [
                      {:fileExt => 'mp4', :bitrate => '2'},
                      {:fileExt => 'mp4', :bitrate => '100'},
              ]).should ==
              [
                      {:fileExt => 'mp4', :bitrate => '100'},
                      {:fileExt => 'mp4', :bitrate => '2'},
              ]
    end

    it "should work with unknown file types, and sort them last" do
      @kaltura.sort_source_list(
              [
                      {:fileExt => 'unknown', :bitrate => '100'},
                      {:fileExt => 'mp4', :bitrate => '100'},
              ]).should ==
              [
                      {:fileExt => 'mp4', :bitrate => '100'},
                      {:fileExt => 'unknown', :bitrate => '100'},
              ]
    end

    it "should sort by preferred file types" do
      @kaltura.sort_source_list(
              [
                      {:fileExt => 'flv', :bitrate => '100'},
                      {:fileExt => 'mp3', :bitrate => '100'},
                      {:fileExt => 'mp4', :bitrate => '100'},
              ]).should ==
              [
                      {:fileExt => 'mp4', :bitrate => '100'},
                      {:fileExt => 'mp3', :bitrate => '100'},
                      {:fileExt => 'flv', :bitrate => '100'},
              ]
    end
  end

  describe "caching" do
    def create_config_with_mock(seconds)
      create_config('cache_play_list_seconds' => seconds)
      @source = {:height => "240", :bitrate => "382", :isOriginal => "0", :width => "336", :content_type => "video/mp4",
                                                   :containerFormat => "isom", :url => "https://kaltura.example.com/url", :size =>"204", :fileExt=>"mp4"}
      @kaltura.expects(:flavorAssetGetByEntryId).returns([@source.merge({:status => '2'})])
      @kaltura.expects(:flavorAssetGetPlaylistUrl).returns("https://kaltura.example.com/url")
    end

    it "should not cache" do
      enable_cache do
        create_config_with_mock(0)
        @kaltura.media_sources('hi')
        Rails.cache.read(['media_sources', 'hi', 0].cache_key).should be_nil
      end
    end

    it "should cache for set length" do
      create_config_with_mock(2)
      m = mock()
      m.expects(:write).with(['media_sources', 'hi', 2].cache_key, [@source], {:expires_in => 2})
      m.expects(:read).returns(nil)
      Rails.stubs(:cache).returns(m)
      @kaltura.media_sources('hi')
    end

    it "should cache indefinitely" do
      create_config_with_mock(nil)
      m = mock()
      m.expects(:write).with(['media_sources', 'hi', nil].cache_key, [@source])
      m.expects(:read).returns(nil)
      Rails.stubs(:cache).returns(m)
      @kaltura.media_sources('hi')
    end

  end

end
