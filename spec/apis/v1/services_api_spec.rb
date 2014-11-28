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
    @kal = mock('CanvasKaltura::ClientV3')
    CanvasKaltura::ClientV3.stubs(:config).returns({
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
    CanvasKaltura::ClientV3.stubs(:config).returns(nil)
    json = api_call(:get, "/api/v1/services/kaltura",
              :controller => "services_api", :action => "show_kaltura_config", :format => "json")
    expect(json).to eq({
      'enabled' => false,
    })
  end

  it "should return a new kaltura session" do
    stub_kaltura
    kal = mock('CanvasKaltura::ClientV3')
    kal.expects(:startSession).returns "new_session_id_here"
    CanvasKaltura::ClientV3.stubs(:new).returns(kal)
    json = api_call(:post, "/api/v1/services/kaltura_session",
                    :controller => "services_api", :action => "start_kaltura_session", :format => "json")
    expect(json.delete_if { |k,v| %w(serverTime).include?(k) }).to eq({
      'ks' => "new_session_id_here",
      'subp_id' => '10000',
      'partner_id' => '100',
      'uid' => "#{@user.id}_#{Account.default.id}",
    })
  end
end
