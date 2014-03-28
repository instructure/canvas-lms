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
require_webmock

describe "Kaltura::ClientV3" do
  def create_config(opts={})
    Kaltura::ClientV3.stubs(:config).returns({
      'domain'          => 'www.instructuremedia.com',
      'resource_domain' => 'www.instructuremedia.com',
      'partner_id'      => '100',
      'subpartner_id'   => '10000',
      'secret_key'      => 'fenwl1n23k4123lk4hl321jh4kl321j4kl32j14kl321',
      'user_secret_key' => '1234821hrj3k21hjk4j3kl21j4kl321j4kl3j21kl4j3k2l1',
      'player_ui_conf'  => '1',
      'kcw_ui_conf'     => '1',
      'upload_ui_conf'  => '1'
    }.merge(opts))

    @kaltura = Kaltura::ClientV3.new
  end

  include WebMock::API

  def stub_kaltura_session(options={})
    default_params = {:service => 'session', :action => 'start'}
    query_params   = default_params.merge(options.fetch(:params, {}))
    ks             = options.fetch(:ks, 'fakekalturasession')

    stub_request(:get, "https://www.instructuremedia.com/api_v3/").
      with(:query => hash_including(query_params)).
      to_return(:body => "<result>#{ks}</result>")
  end

  before(:each) do
    create_config
    WebMock.enable!
  end

  after(:each) do
    WebMock.reset!
    WebMock.disable!
  end

  describe 'thumbnail_url' do
    it "should properly sanitize thumbnail parameters" do
      @kaltura.thumbnail_url('0_123<evil>', :width => 'evilwidth',
        :height => 'evilheight', :type => 'eviltype', :bgcolor => 'evilcolor',
        :vid_sec => 'evilsec').should ==
      "https://www.instructuremedia.com/p/100/thumbnail/entry_id/0_123evil/width/0/height/0/bgcolor/ec/type/0/vid_sec/0"
    end
  end

  describe "sort_source_list" do
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

    it "should prefer converted assets to the original" do
      @kaltura.sort_source_list(
          [
              {:fileExt => 'mp4', :bitrate => '200', :isOriginal => '1'},
              {:fileExt => 'flv', :bitrate => '100', :isOriginal => '0'},
              {:fileExt => 'mp3', :bitrate => '100', :isOriginal => '0'},
              {:fileExt => 'mp4', :bitrate => '100', :isOriginal => '0'},
          ]).should ==
          [
              {:fileExt => 'mp4', :bitrate => '100', :isOriginal => '0'},
              {:fileExt => 'mp3', :bitrate => '100', :isOriginal => '0'},
              {:fileExt => 'flv', :bitrate => '100', :isOriginal => '0'},
              {:fileExt => 'mp4', :bitrate => '200', :isOriginal => '1'},
          ]
    end

    it "should prefer assets without conversion warnings" do
      @kaltura.sort_source_list(
          [
              {:fileExt => 'mp4', :bitrate => '200', :isOriginal => '1'},
              {:fileExt => 'flv', :bitrate => '100', :isOriginal => '0', :hasWarnings => true},
              {:fileExt => 'mp3', :bitrate => '100', :isOriginal => '0'},
              {:fileExt => 'mp4', :bitrate => '100', :isOriginal => '0'},
          ]).should ==
          [
              {:fileExt => 'mp4', :bitrate => '100', :isOriginal => '0'},
              {:fileExt => 'mp3', :bitrate => '100', :isOriginal => '0'},
              {:fileExt => 'flv', :bitrate => '100', :isOriginal => '0'},
              {:fileExt => 'mp4', :bitrate => '200', :isOriginal => '1'},
          ]
    end

    it "should prefer assets with conversion warnings over original" do
      @kaltura.sort_source_list(
          [
              {:fileExt => 'mp4', :bitrate => '200', :isOriginal => '1'},
              {:fileExt => 'flv', :bitrate => '100', :isOriginal => '0', :hasWarnings => true},
              {:fileExt => 'mp3', :bitrate => '100', :isOriginal => '0', :hasWarnings => true},
              {:fileExt => 'mp4', :bitrate => '100', :isOriginal => '0', :hasWarnings => true},
          ]).first[:isOriginal].should_not == '1'
    end
  end

  describe 'media_sources' do
    before do
      stub_kaltura_session
    end

    context "caching" do
      def create_config_with_mock(seconds)
        create_config('cache_play_list_seconds' => seconds)
        @source = {:content_type => "video/mp4", :containerFormat => "isom", :url => "https://kaltura.example.com/url", :fileExt=>"mp4"}
        @kaltura.expects(:flavorAssetGetByEntryId).returns([@source.merge({:status => '2'})])
        @kaltura.expects(:flavorAssetGetPlaylistUrl).returns("https://kaltura.example.com/url")
      end

      it "should not cache" do
        enable_cache do
          create_config_with_mock(0)
          @kaltura.media_sources('hi')
          Rails.cache.read(['media_sources2', 'hi', 0].cache_key).should be_nil
        end
      end

      it "should cache for set length" do
        create_config_with_mock(2)
        m = mock()
        m.expects(:write).with(['media_sources2', 'hi', 2].cache_key, [@source], {:expires_in => 2})
        m.expects(:read)
        Rails.stubs(:cache).returns(m)
        @kaltura.media_sources('hi')
      end

      it "should cache indefinitely" do
        create_config_with_mock(nil)
        m = mock()
        m.expects(:write).with(['media_sources2', 'hi', nil].cache_key, [@source])
        m.expects(:read)
        Rails.stubs(:cache).returns(m)
        @kaltura.media_sources('hi') end
    end

    it "should skip empty urls" do
      create_config
      @source = {:content_type => "video/mp4", :containerFormat => "isom", :url => nil, :fileExt => "mp4", :status => '2', :id => "1"}
      @kaltura.expects(:flavorAssetGetByEntryId).returns([@source, @source.merge({:fileExt => "wav", :id => '2'})])
      @kaltura.stubs(:flavorAssetGetPlaylistUrl)
      @kaltura.stubs(:flavorAssetGetDownloadUrl)

      res = @kaltura.media_sources('hi')
      res.should == []
    end

    it "should skip unknown types" do
      create_config
      @source = {:content_type => "video/mp4", :containerFormat => "isom", :url => nil, :fileExt => "wav", :status => '2', :id => "1"}
      @kaltura.expects(:flavorAssetGetByEntryId).returns([@source])
      @kaltura.stubs(:flavorAssetGetPlaylistUrl)

      res = @kaltura.media_sources('hi')
      res.should == []
    end
  end

  describe "startSession" do
    it "should send Kaltura a request with proper parameters for a user" do
      user_id = 12345
      session_type = Kaltura::SessionType::USER

      kaltura_stub = stub_kaltura_session(
        :params => {
          :secret => Kaltura::ClientV3.config['user_secret_key'],
          :partnerId => '100',
          :userId => user_id.to_s,
          :type => session_type.to_s
        }
      )

      @kaltura.startSession(session_type, user_id)

      kaltura_stub.should have_been_requested
    end

    it "should send Kaltura a request with proper parameters for an admin" do
      session_type = Kaltura::SessionType::ADMIN

      kaltura_stub = stub_kaltura_session(
        :params => {
          :secret => Kaltura::ClientV3.config['secret_key'],
          :partnerId => '100',
          :type => session_type.to_s
        }
      )

      @kaltura.startSession(session_type)

      kaltura_stub.should have_been_requested
    end

    it "should set ks properly" do
      session_type = Kaltura::SessionType::USER

      stub_kaltura_session(
        :ks     => 'ks_from_kaltura',
        :params => {
          :secret => Kaltura::ClientV3.config['user_secret_key'],
          :partnerId => '100',
          :type => session_type.to_s
        }
      )

      @kaltura.startSession

      @kaltura.ks.should == 'ks_from_kaltura'
    end
  end

  describe "mediaGet" do
    it "should call getRequest with proper parameters" do
      entry_id = 12345

      @kaltura.expects(:getRequest).with(
        :media, :get, {:ks => nil, :entryId => entry_id}
      ).returns(stub(:children => []))

      @kaltura.mediaGet(entry_id)
    end

    it "should properly create an items hash" do
      media_name = "Movie on 1-31-13 at 7.27 PM.mov"
      @kaltura.stubs(:getRequest).returns(Nokogiri::XML("<name>#{media_name}</name>"))

      media_info = @kaltura.mediaGet(0)

      media_info[:name].should == "Movie on 1-31-13 at 7.27 PM.mov"
    end

  end

  describe "mediaUpdate" do
    it "should call getRequest with proper parameters" do
      @kaltura.expects(:getRequest).with(
        :media, :update, {
          :ks => nil,
          :entryId => 12345,
          'mediaEntry:key' => 'value'
      }).returns(stub(:children => []))

      @kaltura.mediaUpdate(12345, {"key" => "value"})
    end

    it "should return a properly formatted item" do
      media_name = "Movie on 2-31-13 at 7.27 PM.mov"
      @kaltura.stubs(:getRequest).returns(Nokogiri::XML("<name>#{media_name}</name>"))

      media_info = @kaltura.mediaUpdate(0,{})

      media_info[:name].should == media_name
    end
  end

  describe "mediaDelete" do
    it "should call getRequest with proper parameters" do
      @kaltura.expects(:getRequest).with(
        :media, :delete, {:ks => nil, :entryId => 12345}
      )

      @kaltura.mediaDelete(12345)
    end
  end

  describe "mediaTypeToSymbol" do
    it "should return the proper symbol" do
      vid = @kaltura.mediaTypeToSymbol(1)
      img = @kaltura.mediaTypeToSymbol(2)
      aud = @kaltura.mediaTypeToSymbol(5)

      [vid,img,aud].should == [:video,:image,:audio]
    end

    it "should default to video" do
      @kaltura.mediaTypeToSymbol(rand(10)+6).should == :video
    end
  end

  describe "bulkUploadGet" do
    it "returns properly formatted bulkUpload information" do
      bulk_upload_id = 123
      log_file_url = "http://example.com/bulk_upload_123.csv"
      status = 5
      name = "theName"
      entryId = "theEntryId"
      originalId = "theOriginalId"

      stub_request(:get, "https://www.instructuremedia.com/api_v3/").
        with(:query => hash_including(:service => 'bulkUpload', :action => 'get')).
        to_return(:body => <<-XML)
          <result>
            <logFileUrl>#{log_file_url}</logFileUrl>
            <id>#{bulk_upload_id}</id>
            <status>#{status}</status>
          </result>
        XML

      stub_request(:get, log_file_url).
        to_return(:body => "#{name},,,,,,,,,#{entryId},,#{originalId}")

      bulk_upload_result = @kaltura.bulkUploadGet(bulk_upload_id)

      bulk_upload_result[:id].should == bulk_upload_id.to_s
      bulk_upload_result[:status].should == status.to_s
      bulk_upload_result[:entries].should == [{
        :name => name,
        :entryId => entryId,
        :originalId => originalId
      }]
    end
  end

  describe "bulkUploadCsv" do
    it "given a string of csv, posts that csv to kaltura, then fetches the status of the created job" do
      log_file_url = "https://www.instructuremedia.com/bulk_uploads/12345.log"
      bulk_upload_add_stub = stub_request(:post, "https://www.instructuremedia.com/api_v3/").
        with(:query => hash_including(:service => 'bulkUpload', :action => 'add')).
        with{ |request| request.headers['Content-Type'] =~ /\Amultipart\/form-data/ }.
        to_return(:body => <<-XML)
          <result>
            <id>batch_job_12345</id>
            <status>ready</status>
            <logFileUrl>#{log_file_url}</logFileUrl>
          </result>
        XML

      log_file_stub = stub_request(:get, log_file_url).
        to_return(:body => "aName,,,,,,,,,anEntryId,,anOriginalId")

      parsed_bulk_upload = @kaltura.bulkUploadCsv("csv,data,with,bulk,upload,info")

      bulk_upload_add_stub.should have_been_requested
      log_file_stub.should        have_been_requested

      parsed_bulk_upload[:id      ].should == 'batch_job_12345'
      parsed_bulk_upload[:status  ].should == 'ready'
      parsed_bulk_upload[:ready   ].should == true
      parsed_bulk_upload[:entries ].should == [{:name => 'aName', :entryId => 'anEntryId', :originalId => 'anOriginalId'} ]
    end
  end

  describe "bulkUploadAdd" do
   it "accepts data about files to upload and passes them as CSV to bulkUploadCsv" do
      files = [{
        :name => "the_name",
        :description => "the_desc",
        :tags => "the_tags",
        :media_type => "the_media_type",
        :partner_data => "the_partner_data",
        :url => "the_url"
      }]

      @kaltura.expects(:bulkUploadCsv).with(
        %Q[the_name,the_desc,the_tags,the_url,the_media_type,"","","","","","",the_partner_data\n]
      )

      @kaltura.bulkUploadAdd(files)
    end
  end

  describe "assetSwfUrl" do
    it "should return a properly formatted url" do
      config_result = {
       "domain" => "domain",
       "partner_id" => "partner_id",
       "player_ui_conf" => "player_ui_conf"
      }
      Kaltura::ClientV3.stubs(:config).returns(config_result)

      entry_id = "f_73gebd8"
      @kaltura.assetSwfUrl(entry_id).should == "https://domain/kwidget/wid/_partner_id/uiconf_id/player_ui_conf/entry_id/#{entry_id}"
    end
  end

  describe "flavorAssetGetPlaylistUrl" do
    it "fetches the 'playlist' for a given URL, and returns the media URL parsed from the playlist" do
      entry_id     = "f_34gd4d4"
      flavor_id    = "x_9347g93g"
      media_url    = "https://resources.example.com/path/to/media.mp4"
      playlist_url = "https://www.instructuremedia.com/p/100/playManifest/entryId/#{entry_id}/flavorId/#{flavor_id}"

      stub_request(:get, playlist_url).
        to_return(:body => <<-XML)
          <manifest>
            <media url="#{media_url}" />
            </media>
          </manifest>
        XML

      @kaltura.flavorAssetGetPlaylistUrl(entry_id, flavor_id).should == media_url
    end
  end
end
