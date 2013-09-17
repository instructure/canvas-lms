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

  describe "caching" do
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
      @kaltura.media_sources('hi')
    end
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

  describe "startSession" do
    it "should call sendRequest with proper parameters for a user" do
      user_id = 12345
      session_type = Kaltura::SessionType::USER

      @kaltura.expects(:sendRequest).with(
        :session, :start, {
          :secret => Kaltura::ClientV3.config['user_secret_key'],
          :partnerId => '100',
          :userId => user_id,
          :type => session_type
        }
      ).returns(Nokogiri::XML("<ks>some_kaltura_session</ks>"))

      @kaltura.startSession(session_type, user_id)
    end

    it "should call sendRequest with proper parameters for a admin" do
      session_type = Kaltura::SessionType::ADMIN

      @kaltura.expects(:sendRequest).with(
        :session, :start, {
          :secret => Kaltura::ClientV3.config['secret_key'],
          :partnerId => '100',
          :userId => nil,
          :type => session_type
        }
      ).returns(Nokogiri::XML("<ks>some_kaltura_session</ks>"))

      @kaltura.startSession(session_type)
    end

    it "should set ks properly" do
      ks = "ks_from_kaltura"
      @kaltura.stubs(:sendRequest).returns(Nokogiri::XML("<ks>#{ks}</ks>"))

      @kaltura.startSession

      @kaltura.ks.should == ks
    end
  end

  describe "mediaGet" do
    it "should call sendRequest with proper parameters" do
      entry_id = 12345

      @kaltura.expects(:sendRequest).with(
        :media, :get, {:ks => nil, :entryId => entry_id}
      ).returns(stub(:children => []))

      @kaltura.mediaGet(entry_id)
    end

    it "should properly create an items hash" do
      media_name = "Movie on 1-31-13 at 7.27 PM.mov"
      @kaltura.stubs(:sendRequest).returns(Nokogiri::XML("<name>#{media_name}</name>"))

      media_info = @kaltura.mediaGet(0)

      media_info[:name].should == "Movie on 1-31-13 at 7.27 PM.mov"
    end

  end

  describe "mediaUpdate" do
    it "should call sendRequest with proper parameters" do
      @kaltura.expects(:sendRequest).with(
        :media, :update, {
          :ks => nil,
          :entryId => 12345,
          'mediaEntry:key' => 'value'
      }).returns(stub(:children => []))

      @kaltura.mediaUpdate(12345, {"key" => "value"})
    end

    it "should return a properly formatted item" do
      media_name = "Movie on 2-31-13 at 7.27 PM.mov"
      @kaltura.stubs(:sendRequest).returns(Nokogiri::XML("<name>#{media_name}</name>"))

      media_info = @kaltura.mediaUpdate(0,{})

      media_info[:name].should == media_name
    end
  end

  describe "mediaDelete" do
    it "should call sendRequest with proper parameters" do
      @kaltura.expects(:sendRequest).with(
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

    it "should defailt to video" do
      @kaltura.mediaTypeToSymbol(rand(10)+6).should == :video
    end
  end

  describe "bulkUploadGet" do
    it "should call sendRequest with proper parameters" do
      @kaltura.stubs(:parseBulkUpload)

      @kaltura.expects(:sendRequest).with(
        :bulkUpload, :get, {:ks => nil, :id => 12345}
      )

      @kaltura.bulkUploadGet(12345)
    end

    # Implicit test of parseBulkUpload
    it "should return properly formatted bulkUpload information" do
      bulk_upload_id = 123
      log_file_url = "http://example.com/bulk_upload_123.csv"
      status = 5
      name = "theName"
      entryId = "theEntryId"
      originalId = "theOriginalId"

      @kaltura.stubs(:sendRequest).returns(Nokogiri::XML(
        "<result>
        <logFileUrl>#{log_file_url}</logFileUrl>
        <id>#{bulk_upload_id}</id>
        <status>#{status}</status>
        </result>"
      ))
      Canvas::HTTP.stubs(:get).with(log_file_url).returns(stub(
        :body => "#{name},,,,,,,,,#{entryId},,#{originalId}"
      ))

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
    it "should call kaltura's bulkupload add with the CSV" do
      csv = "some,csv,data,about,a,bulk,upload"
      @kaltura.stubs(:parseBulkUpload)

      @kaltura.expects(:postRequest).with do |controller, action, params|
        controller.should == :bulkUpload
        action.should == :add
        params[:csvFileData].read.should == csv
      end

      @kaltura.bulkUploadCsv(csv)
    end

    # parseBulkUpload behavior verified above
    it "should call parseBulkUpload" do
      @kaltura.stubs(:postRequest).returns(:test)
      @kaltura.expects(:parseBulkUpload).with(:test)
      @kaltura.bulkUploadCsv("test")
    end
  end

  describe "bulkUploadAdd" do
   it "should format rows properly" do
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

      @kaltura.assetSwfUrl(1).should == "http://domain/kwidget/wid/_partner_id/uiconf_id/player_ui_conf/entry_id/1"
    end
  end

  describe "postRequest" do
    it "should make the API call" do
      response = stub('Net::HTTPOK')
      Net::HTTP.stubs(:request).returns(response)

      @kaltura.send(:postRequest,:media,:get,{}).class.should == Nokogiri::XML::Element
    end

    it "should raise a timeout error if res is nil" do
      Net::HTTP.stubs(:start)
      lambda {
        @kaltura.send(:postRequest,:media,:get,{})
      }.should raise_error(Timeout::Error)
    end
  end

  describe "sendRequest" do
    it "should make the API call" do
      response = stub('Net::HTTPOK')
      Net::HTTP.stubs(:request).returns(response)

      @kaltura.send(:sendRequest,:media,:get,{}).class.should == Nokogiri::XML::Element
    end

    it "should raise a timeout error if res is nil" do
      Net::HTTP.stubs(:get_response)
      lambda {
        @kaltura.send(:sendRequest,:media,:get,{})
      }.should raise_error(Timeout::Error)
    end
  end
end
