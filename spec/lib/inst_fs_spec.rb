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
    allow(InstFS).to receive(:enabled?).and_return(true)
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

    it "includes global user_id claim in the token if user provided" do
      user = user_model
      url = InstFS.authenticated_url(@attachment, user: user)
      token = url.split(/token=/).last
      claims = Canvas::Security.decode_jwt(token, [ @secret ])
      expect(claims[:user_id]).to eql(user.global_id.to_s)
    end

    it "includes distinct global acting_as_user_id claim in the token if acting_as provided" do
      user1 = user_model
      user2 = user_model
      url = InstFS.authenticated_url(@attachment, user: user1, acting_as: user2)
      token = url.split(/token=/).last
      claims = Canvas::Security.decode_jwt(token, [ @secret ])
      expect(claims[:user_id]).to eql(user1.global_id.to_s)
      expect(claims[:acting_as_user_id]).to eql(user2.global_id.to_s)
    end

    it "includes omits user_id claim in the token if no user provided" do
      url = InstFS.authenticated_url(@attachment)
      token = url.split(/token=/).last
      claims = Canvas::Security.decode_jwt(token, [ @secret ])
      expect(claims[:user_id]).to be_nil
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
    let(:context) { instance_double("Course", id: 1, global_id: 101, root_account: Account.default) }
    let(:user) { instance_double("User", id: 2, global_id: 102) }
    let(:acting_as) { instance_double("User", id: 4, global_id: 104) }
    let(:folder) { instance_double("Folder", id: 3, global_id: 103) }
    let(:filename) { 'test.txt' }
    let(:content_type) { 'text/plain' }
    let(:quota_exempt) { true }
    let(:on_duplicate) { 'rename' }
    let(:include_param) { ['avatar'] }
    let(:capture_url) { 'http://canvas.host/api/v1/files/capture' }

    let(:default_args) do
      {
        context: context,
        user: user,
        acting_as: acting_as,
        folder: folder,
        filename: filename,
        content_type: content_type,
        quota_exempt: quota_exempt,
        on_duplicate: on_duplicate,
        capture_url: capture_url,
        include_param: include_param
      }
    end

    let(:preflight_json) do
      InstFS.upload_preflight_json(default_args)
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

      it "embeds the user_id and acting_as_user_id in the token" do
        expect(jwt['user_id']).to eq user.global_id.to_s
        expect(jwt['acting_as_user_id']).to eq acting_as.global_id.to_s
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

        it "include the acting_as user" do
          expect(capture_params['user_id']).to eq acting_as.global_id.to_s
        end

        it "include the folder" do
          expect(capture_params['folder_id']).to eq folder.global_id.to_s
        end

        it "include the root_account_id" do
          expect(capture_params['root_account_id']).to eq context.root_account.global_id.to_s
        end

        it "include the quota_exempt flag" do
          expect(capture_params['quota_exempt']).to eq quota_exempt
        end

        it "include the on_duplicate method" do
          expect(capture_params['on_duplicate']).to eq on_duplicate
        end

        it "include the inlcude options" do
          expect(capture_params['include']).to eq include_param
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

    context "upload via url" do
      it "throw ArgumentError when appropriate" do
        expect { InstFS.upload_preflight_json(default_args.merge({target_url: "foo"})) }.to raise_error(ArgumentError)
        expect { InstFS.upload_preflight_json(default_args.merge({progress_json: {"foo": 1}})) }.to raise_error(ArgumentError)
      end

      it "responds properly when passed target_url and progress_json" do
        progress_json = { id: 1 }
        target_url = "http://www.example.com/"
        preflight_json = InstFS.upload_preflight_json(default_args.merge({target_url: target_url, progress_json: progress_json}))

        token = preflight_json[:upload_url].split('token=').last
        jwt = Canvas::Security.decode_jwt(token, [ @secret ])

        expect(jwt[:capture_params][:progress_id]).to eq(progress_json[:id])
        expect(preflight_json[:file_paran]).to be_nil
        expect(preflight_json[:upload_params][:target_url]).to eq(target_url)
        expect(preflight_json[:progress]).to eq(progress_json)
      end
    end
  end

  context "logout" do
    it "makes a DELETE request against the logout url" do
      expect(CanvasHttp).to receive(:delete).with(match(%r{/session[^/\w]}))
      InstFS.logout(user_model)
    end

    it "includes jwt in DELETE request" do
      expect(CanvasHttp).to receive(:delete).with(match(%r{\?token=}))
      InstFS.logout(user_model)
    end

    it "skips if user absent" do
      expect(CanvasHttp).not_to receive(:delete)
      InstFS.logout(nil)
    end

    it "skips if not enabled" do
      allow(InstFS).to receive(:enabled?).and_return(false)
      expect(CanvasHttp).not_to receive(:delete)
      InstFS.logout(user_model)
    end

    it "logs then ignores error if DELETE request fails" do
      allow(CanvasHttp).to receive(:delete).and_raise(CanvasHttp::Error, "broken request")
      expect(Canvas::Errors).to receive(:capture_exception).once
      InstFS.logout(user_model)
    end
  end

  context "direct upload" do
    it "makes a network request to the inst-fs endpoint" do
      uuid = "1234-abcd"
      allow(CanvasHttp).to receive(:post).and_return(double(
        class: Net::HTTPCreated,
        code: 200,
        body: {uuid: uuid}.to_json
      ))

      res = InstFS.direct_upload(
        file_name: "a.png",
        file_object: File.open("public/images/a.png")
      )
      expect(res).to eq(uuid)
    end
  end
end
