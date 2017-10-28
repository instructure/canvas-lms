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
      expect(InstFS.authenticated_url(@attachment, {}))
        .to match("#{@app_host}/files/#{@attachment.instfs_uuid}")
    end

    it "passes download param" do
      expect(InstFS.authenticated_url(@attachment, download: true)).to match(/download=1/)
    end

    it "includes a properly signed token" do
      url = InstFS.authenticated_url(@attachment, {})
      expect(url).to match(/token=/)
      token = url.split(/token=/).last
      expect(->{
        Canvas::Security.decode_jwt(token, [ @secret ])
      }).not_to raise_error
    end

    it "includes an expiration on the token" do
      url = InstFS.authenticated_url(@attachment, expires_in: 1.hour)
      token = url.split(/token=/).last
      Timecop.freeze(2.hours.from_now) do
        expect(->{
          Canvas::Security.decode_jwt(token, [ @secret ])
        }).to raise_error(Canvas::Security::TokenExpired)
      end
    end
  end

  context "authenticated_thumbnail_url" do
    before :each do
      @attachment = attachment_with_context(user_model)
      @attachment.instfs_uuid = 1
      @attachment.filename = "test.txt"
    end

    it "constructs url properly" do
      expect(InstFS.authenticated_thumbnail_url(@attachment))
        .to match("#{@app_host}/thumbnails/#{@attachment.instfs_uuid}")
    end

    it "passes geometry param" do
      expect(InstFS.authenticated_thumbnail_url(@attachment, geometry: '256x256'))
        .to match(/geometry=256x256/)
    end

    it "includes a properly signed token" do
      url = InstFS.authenticated_thumbnail_url(@attachment)
      expect(url).to match(/token=/)
      token = url.split(/token=/).last
      expect(->{
        Canvas::Security.decode_jwt(token, [ @secret ])
      }).not_to raise_error
    end

    it "includes an expiration on the token" do
      url = InstFS.authenticated_thumbnail_url(@attachment, expires_in: 1.hour)
      token = url.split(/token=/).last
      Timecop.freeze(2.hours.from_now) do
        expect(->{
          Canvas::Security.decode_jwt(token, [ @secret ])
        }).to raise_error(Canvas::Security::TokenExpired)
      end
    end
  end

  context "upload_preflight_json" do
    let(:context) { instance_double("Course", id: 1, global_id: 101) }
    let(:user) { instance_double("User", id: 2, global_id: 102) }
    let(:folder) { instance_double("Folder", id: 3, global_id: 103) }
    let(:filename) { 'test.txt' }
    let(:content_type) { 'text/plain' }
    let(:quota_exempt) { true }
    let(:on_duplicate) { 'rename' }
    let(:capture_url) { 'http://canvas.host/api/v1/files/capture' }

    let(:preflight_json) do
      InstFS.upload_preflight_json(
        context: context,
        user: user,
        folder: folder,
        filename: filename,
        content_type: content_type,
        quota_exempt: quota_exempt,
        on_duplicate: on_duplicate,
        capture_url: capture_url,
      )
    end

    it "includes a static 'file' file_param" do
      expect(preflight_json[:file_param]).to eq 'file'
    end

    it "includes an upload_url pointing at the service" do
      expect(preflight_json[:upload_url]).to match @app_host
      upload_url = URI.parse(preflight_json[:upload_url])
      expect(upload_url.path).to eq '/files'
    end

    it "include a JWT in the query param of the upload_url" do
      upload_url = URI.parse(preflight_json[:upload_url])
      expect(upload_url.query).to match %r{token=[^&]+}
      token = upload_url.query.split('=').last
      expect(->{
        Canvas::Security.decode_jwt(token, [ @secret ])
      }).not_to raise_error
    end

    describe "the upload JWT" do
      let(:jwt) do
        token = preflight_json[:upload_url].split('token=').last
        Canvas::Security.decode_jwt(token, [ @secret ])
      end

      it "embeds a capture_url in the token" do
        expect(jwt['capture_url']).to eq capture_url
      end

      it "embeds a capture_params hash in the token" do
        expect(jwt['capture_params']).to be_a(Hash)
      end

      describe "the capture_params" do
        let(:capture_params) { jwt['capture_params'] }

        it "include the context" do
          expect(capture_params['context_type']).to eq context.class.to_s
          expect(capture_params['context_id']).to eq context.global_id.to_s
        end

        it "include the user" do
          expect(capture_params['user_id']).to eq user.global_id.to_s
        end

        it "include the folder" do
          expect(capture_params['folder_id']).to eq folder.global_id.to_s
        end

        it "include the quota_exempt flag" do
          expect(capture_params['quota_exempt']).to eq quota_exempt
        end

        it "include the on_duplicate method" do
          expect(capture_params['on_duplicate']).to eq on_duplicate
        end
      end
    end

    it "includes an upload_params hash" do
      expect(preflight_json[:upload_params]).to be_a(Hash)
    end

    describe "the upload_params" do
      let(:upload_params) { preflight_json[:upload_params] }

      it "include the filename" do
        expect(upload_params[:filename]).to eq filename
      end

      it "include the content_type" do
        expect(upload_params[:content_type]).to eq content_type
      end
    end
  end
end
