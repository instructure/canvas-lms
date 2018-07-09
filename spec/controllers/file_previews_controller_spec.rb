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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FilePreviewsController do
  before(:once) do
    @account = Account.default
    @account.enable_service(:google_docs_previews)
    course_with_student(account: @account, active_all: true)
  end

  before(:each) do
    user_session(@student)
  end

  it "should require authorization to view the file" do
    course_model
    attachment_model
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    expect(response.status).to eq 401
  end

  it "should render lock information for the file" do
    attachment_model locked: true
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    expect(response).to render_template 'lock_explanation'
  end

  it "should 404 (w/o canvas chrome) if the file doesn't exist" do
    attachment_model
    file_id = @attachment.id
    @attachment.destroy_permanently!
    get :show, params: {course_id: @course.id, file_id: file_id}
    expect(response.status).to eq 404
    expect(assigns['headers']).to eq false
    expect(assigns['show_left_side']).to eq false
  end

  it "should redirect to crododoc_url if available and params[:annotate] is given" do
    allow_any_instance_of(Attachment).to receive(:crocodoc_url).and_return('http://example.com/fake_crocodoc_url')
    allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return('http://example.com/fake_canvadoc_url')
    attachment_model content_type: 'application/msword'
    get :show, params: {course_id: @course.id, file_id: @attachment.id, annotate: 1}
    expect(response).to redirect_to @attachment.crocodoc_url
  end

  it "should redirect to canvadocs_url if available" do
    allow_any_instance_of(Attachment).to receive(:crocodoc_url).and_return('http://example.com/fake_crocodoc_url')
    allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return('http://example.com/fake_canvadoc_url')
    attachment_model content_type: 'application/msword'
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    expect(response).to redirect_to @attachment.canvadoc_url
  end

  it "should redirect to a google doc preview if available" do
    allow_any_instance_of(Attachment).to receive(:crocodoc_url).and_return(nil)
    allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return(nil)
    attachment_model content_type: 'application/msword'
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    expect(response).to be_redirect
    expect(response.location).to match %r{\A//docs.google.com/viewer}
  end

  it "should redirect to file if it's html" do
    allow_any_instance_of(Attachment).to receive(:crocodoc_url).and_return(nil)
    allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return(nil)
    attachment_model content_type: 'text/html'
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    expect(response).to be_redirect
    expect(response.location).to match %r{/courses/#{@course.id}/files/#{@attachment.id}/preview}
  end

  it "should render a download link if no previews are available" do
    allow_any_instance_of(Attachment).to receive(:crocodoc_url).and_return(nil)
    allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return(nil)
    @account.disable_service(:google_docs_previews)
    @account.save!
    attachment_model content_type: 'application/msword'
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    expect(response.status).to eq 200
    expect(response).to render_template 'no_preview'
  end

  it "should render an img element for image types" do
    attachment_model content_type: 'image/png'
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    expect(response.status).to eq 200
    expect(response).to render_template 'img_preview'
  end

  it "should render a media tag for media types" do
    attachment_model content_type: 'video/mp4'
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    expect(response.status).to eq 200
    expect(response).to render_template 'media_preview'
  end

  it "should fulfill module completion requirements" do
    attachment_model content_type: 'application/msword'
    mod = @course.context_modules.create!(:name => "some module")
    tag = mod.add_item(:id => @attachment.id, :type => 'attachment')
    mod.completion_requirements = { tag.id => {:type => 'must_view'} }
    mod.save!
    expect(mod.evaluate_for(@user).workflow_state).to eq "unlocked"
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    expect(mod.evaluate_for(@user).workflow_state).to eq "completed"
  end

  it "should log asset accesses when previewable" do
    Setting.set('enable_page_views', 'db')
    attachment_model content_type: 'image/png'
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    access = AssetUserAccess.for_user(@user).first
    expect(access.asset).to eq @attachment
  end

  it "should not log asset accesses when not previewable" do
    Setting.set('enable_page_views', 'db')
    attachment_model content_type: 'unknown/unknown'
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    access = AssetUserAccess.for_user(@user)
    expect(access).to be_empty
  end

  it "should work with hidden files" do
    attachment_model content_type: 'image/png'
    @attachment.update_attribute(:file_state, 'hidden')
    get :show, params: {course_id: @course.id, file_id: @attachment.id}
    expect(response).to be_successful
  end
end
