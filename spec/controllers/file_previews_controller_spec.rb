# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "webmock/rspec"

describe FilePreviewsController do
  before(:once) do
    @account = Account.default
    @account.enable_service(:google_docs_previews)
    course_with_student(account: @account, active_all: true)
  end

  before do
    user_session(@student)
  end

  describe "with JWT access token" do
    include_context "InstAccess setup"

    before do
      attachment_model.update!(file_state: "hidden", instfs_uuid: "stuff")
      user_with_pseudonym
      jwt_payload = {
        resource: "/courses/#{@course.id}/files/#{@attachment.id}?instfs_id=stuff",
        aud: [@course.root_account.uuid],
        sub: @user.uuid,
        tenant_auth: { location: "location" },
        iss: "instructure:inst_access",
        exp: 1.hour.from_now.to_i,
        iat: Time.now.to_i
      }
      @token_string = InstAccess::Token.send(:new, jwt_payload).to_unencrypted_token_string
      allow(Canvadocs).to receive(:enabled?).and_return(true)
      allow(InstFS).to receive_messages(enabled?: true, app_host: "http://instfs.test")
      stub_request(:get, "http://instfs.test/files/stuff/metadata").to_return(status: 200, body: { url: "http://instfs.test/stuff" }.to_json)
    end

    it "allows access" do
      get :show, params: { course_id: @course.id, file_id: @attachment.id, access_token: @token_string, instfs_id: "stuff" }
      expect(response).to be_successful
    end

    it "does not allow access if the file doesn't match" do
      attachment_model.update!(file_state: "hidden", instfs_uuid: "otherstuff")
      get :show, params: { course_id: @course.id, file_id: @attachment.id, access_token: @token_string, instfs_id: "stuff" }
      expect(response).to be_unauthorized
    end
  end

  it "requires authorization to view the file" do
    course_model
    attachment_model
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    expect(response).to have_http_status :unauthorized
  end

  it "accepts a valid verifier token" do
    course_model
    attachment_model
    get :show, params: { course_id: @course.id, file_id: @attachment.id, verifier: @attachment.uuid }
    expect(response).to have_http_status :ok
  end

  it "does not accept an invalid verifier token" do
    course_model
    attachment_model
    get :show, params: { course_id: @course.id, file_id: @attachment.id, verifier: "nope" }
    expect(response).to have_http_status :unauthorized
  end

  it "renders lock information for the file" do
    attachment_model locked: true
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    expect(response).to render_template "lock_explanation"
  end

  it "404s (w/o canvas chrome) if the file doesn't exist" do
    attachment_model
    file_id = @attachment.id
    @attachment.destroy_permanently!
    get :show, params: { course_id: @course.id, file_id: }
    expect(response).to have_http_status :not_found
    expect(assigns["headers"]).to be false
    expect(assigns["show_left_side"]).to be false
  end

  it "redirects to crododoc_url if available and params[:annotate] is given" do
    allow_any_instance_of(Attachment).to receive(:crocodoc_url).and_return("http://example.com/fake_crocodoc_url")
    allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return("http://example.com/fake_canvadoc_url")
    attachment_model content_type: "application/msword"
    get :show, params: { course_id: @course.id, file_id: @attachment.id, annotate: 1 }
    expect(response).to redirect_to @attachment.crocodoc_url
  end

  it "redirects to canvadocs_url if available" do
    allow_any_instance_of(Attachment).to receive(:crocodoc_url).and_return("http://example.com/fake_crocodoc_url")
    allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return("http://example.com/fake_canvadoc_url")
    attachment_model content_type: "application/msword"
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    expect(response).to redirect_to @attachment.canvadoc_url
  end

  it "redirects to a google doc preview if available" do
    allow_any_instance_of(Attachment).to receive(:crocodoc_url).and_return(nil)
    allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return(nil)
    attachment_model content_type: "application/msword"
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    expect(response).to be_redirect
    expect(response.location).to match %r{\A//docs.google.com/viewer}
  end

  it "redirects to file if it's html" do
    allow_any_instance_of(Attachment).to receive(:crocodoc_url).and_return(nil)
    allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return(nil)
    attachment_model content_type: "text/html"
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    expect(response).to be_redirect
    expect(response.location).to match %r{/courses/#{@course.id}/files/#{@attachment.id}/preview}
  end

  it "renders a download link if no previews are available" do
    allow_any_instance_of(Attachment).to receive(:crocodoc_url).and_return(nil)
    allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return(nil)
    @account.disable_service(:google_docs_previews)
    @account.save!
    attachment_model content_type: "application/msword"
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    expect(response).to have_http_status :ok
    expect(response).to render_template "no_preview"
  end

  it "renders an img element for image types" do
    attachment_model content_type: "image/png"
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    expect(response).to have_http_status :ok
    expect(response).to render_template "img_preview"
  end

  it "renders a media tag for media types" do
    attachment_model content_type: "video/mp4"
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    expect(response).to have_http_status :ok
    expect(response).to render_template "media_preview"
  end

  it "fulfills module completion requirements" do
    attachment_model content_type: "application/msword"
    mod = @course.context_modules.create!(name: "some module")
    tag = mod.add_item(id: @attachment.id, type: "attachment")
    mod.completion_requirements = { tag.id => { type: "must_view" } }
    mod.save!
    expect(mod.evaluate_for(@user).workflow_state).to eq "unlocked"
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    expect(mod.evaluate_for(@user).workflow_state).to eq "completed"
  end

  it "logs asset accesses when previewable" do
    Setting.set("enable_page_views", "db")
    attachment_model content_type: "image/png"
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    access = AssetUserAccess.for_user(@user).first
    expect(access.asset).to eq @attachment
  end

  it "does not log asset accesses when not previewable" do
    Setting.set("enable_page_views", "db")
    attachment_model content_type: "unknown/unknown"
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    access = AssetUserAccess.for_user(@user)
    expect(access).to be_empty
  end

  it "works with hidden files" do
    attachment_model content_type: "image/png"
    @attachment.update_attribute(:file_state, "hidden")
    get :show, params: { course_id: @course.id, file_id: @attachment.id }
    expect(response).to be_successful
  end

  context "student in limited access account" do
    before do
      @account.root_account.enable_feature!(:allow_limited_access_for_students)
      @account.settings[:enable_limited_access_for_students] = true
      @account.save!
    end

    it "allows students to see individual files" do
      course_model
      attachment_model
      get :show, params: { course_id: @course.id, file_id: @attachment.id, verifier: @attachment.uuid }
      expect(response).to have_http_status :ok
    end
  end
end
