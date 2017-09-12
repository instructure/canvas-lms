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
#

require 'spec_helper'

describe InstFS do

  before do
    @app_host = 'http://test.host'
    @secret = "supersecretyup"
    allow(Canvas::DynamicSettings).to receive(:find).with(any_args).and_call_original
    allow(Canvas::DynamicSettings).to receive(:find).
      with(service: "inst-fs", default_ttl: 5.minutes).
      and_return({
        'app-host' => @app_host,
        'secret' => Base64.encode64(@secret)
      })
  end

  it "returns decoded base 64 secret" do
    expect(InstFS.jwt_secret).to eq(@secret)
  end

  context "authenticated_url" do

    before :each do
      @attachment = attachment_with_context(user_model)
      @attachment.instfs_uuid = 1
      @attachment.filename = "test.txt"
    end

    it "constructs url properly" do
      expect(InstFS.authenticated_url(@attachment, {})).to match("#{@app_host}/#{@attachment.instfs_uuid}")
    end

    it "passes download param" do
      expect(InstFS.authenticated_url(@attachment, {:download => true})).to match(/download=1/)

    end
  end
end
