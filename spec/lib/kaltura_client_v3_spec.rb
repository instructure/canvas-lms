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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "Kaltura::ClientV3" do
  before(:each) do
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
    })

    @kaltura = Kaltura::ClientV3.new
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
end
