# frozen_string_literal: true

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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Services API", type: :request do
  before :once do
    user_with_pseudonym(:active_all => true)
  end

  before :each do
    @kal = double('CanvasKaltura::ClientV3')
    allow(CanvasKaltura::ClientV3).to receive(:config).and_return({
      'domain' => 'kaltura.fake.local',
      'resource_domain' => 'cdn.kaltura.fake.local',
      'rtmp_domain' => 'rtmp-kaltura.fake.local',
      'partner_id' => '420',
    })
  end
  
  it "should check for auth" do
    get("/api/v1/services/kaltura")
    assert_status(401)
  end
  
  it "should return the config information for kaltura" do
    json = api_call(:get, "/api/v1/services/kaltura",
              :controller => "services_api", :action => "show_kaltura_config", :format => "json")
    expect(json).to eq({
      'enabled' => true,
      'domain' => 'kaltura.fake.local',
      'resource_domain' => 'cdn.kaltura.fake.local',
      'rtmp_domain' => 'rtmp-kaltura.fake.local',
      'partner_id' => '420',
    })
  end
  
  it "should degrade gracefully if kaltura is disabled or not configured" do
    allow(CanvasKaltura::ClientV3).to receive(:config).and_return(nil)
    json = api_call(:get, "/api/v1/services/kaltura",
              :controller => "services_api", :action => "show_kaltura_config", :format => "json")
    expect(json).to eq({
      'enabled' => false,
    })
  end

  it "should return a new kaltura session" do
    stub_kaltura
    kal = double('CanvasKaltura::ClientV3')
    expect(kal).to receive(:startSession).and_return "new_session_id_here"
    allow(CanvasKaltura::ClientV3).to receive(:new).and_return(kal)
    json = api_call(:post, "/api/v1/services/kaltura_session",
                    :controller => "services_api", :action => "start_kaltura_session", :format => "json")
    expect(json.delete_if { |k| %w(serverTime).include?(k) }).to eq({
      'ks' => "new_session_id_here",
      'subp_id' => '10000',
      'partner_id' => '100',
      'uid' => "#{@user.id}_#{Account.default.id}",
    })
  end

  it "should return a new kaltura session with upload config if param provided" do
    stub_kaltura
    kal = double('CanvasKaltura::ClientV3')
    expect(kal).to receive(:startSession).and_return "new_session_id_here"
    allow(CanvasKaltura::ClientV3).to receive(:new).and_return(kal)
    json = api_call(:post, "/api/v1/services/kaltura_session",
                    :controller => "services_api", :action => "start_kaltura_session",
                    :format => "json", :include_upload_config => 1)
    expect(json.delete_if { |k| %w(serverTime).include?(k) }).to eq({
      'ks' => "new_session_id_here",
      'subp_id' => '10000',
      'partner_id' => '100',
      'uid' => "#{@user.id}_#{Account.default.id}",
      'kaltura_setting' => {
        'domain'=>'kaltura.example.com',
        'kcw_ui_conf'=>'1',
        'partner_id'=>'100',
        'player_ui_conf'=>'1',
        'resource_domain'=>'kaltura.example.com',
        'subpartner_id'=>'10000',
        'upload_ui_conf'=>'1',
        'entryUrl' => 'http:///index.php/partnerservices2/addEntry',
        'uiconfUrl' => 'http:///index.php/partnerservices2/getuiconf',
        'uploadUrl' => 'http:///index.php/partnerservices2/upload',
        'partner_data' => {
          'root_account_id'=>@user.account.root_account.id,
          'sis_source_id'=>nil,
          'sis_user_id'=>nil
        },
      },
    })
  end
end
