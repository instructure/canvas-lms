#
# Copyright (C) 2014 Instructure, Inc.
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
    attachment_model locked: true
    get :show, course_id: @course.id, file_id: @attachment.id
    response.status.should == 401
  end

  it "should 404 if the file doesn't exist" do
    attachment_model
    file_id = @attachment.id
    @attachment.destroy!
    get :show, course_id: @course.id, file_id: file_id
    response.status.should == 404
  end

  it "should redirect to crododoc_url if available and params[:annotate] is given" do
    Attachment.any_instance.stubs(:crocodoc_url).returns('http://example.com/fake_crocodoc_url')
    Attachment.any_instance.stubs(:canvadoc_url).returns('http://example.com/fake_canvadoc_url')
    attachment_model content_type: 'application/msword'
    get :show, course_id: @course.id, file_id: @attachment.id, annotate: 1
    response.should redirect_to @attachment.crocodoc_url
  end

  it "should redirect to canvadocs_url if available" do
    Attachment.any_instance.stubs(:crocodoc_url).returns('http://example.com/fake_crocodoc_url')
    Attachment.any_instance.stubs(:canvadoc_url).returns('http://example.com/fake_canvadoc_url')
    attachment_model content_type: 'application/msword'
    get :show, course_id: @course.id, file_id: @attachment.id
    response.should redirect_to @attachment.canvadoc_url
  end

  it "should redirect to a google doc preview if available" do
    Attachment.any_instance.stubs(:crocodoc_url).returns(nil)
    Attachment.any_instance.stubs(:canvadoc_url).returns(nil)
    attachment_model content_type: 'application/msword'
    get :show, course_id: @course.id, file_id: @attachment.id
    response.should be_redirect
    response.location.should =~ %r{\A//docs.google.com/viewer}
  end

  it "should render a download link if no previews are available" do
    Attachment.any_instance.stubs(:crocodoc_url).returns(nil)
    Attachment.any_instance.stubs(:canvadoc_url).returns(nil)
    @account.disable_service(:google_docs_previews)
    @account.save!
    attachment_model content_type: 'application/msword'
    get :show, course_id: @course.id, file_id: @attachment.id
    response.status.should == 200
    response.should render_template 'no_preview'
  end

  it "should render an img element for image types" do
    attachment_model content_type: 'image/png'
    get :show, course_id: @course.id, file_id: @attachment.id
    response.status.should == 200
    response.should render_template 'img_preview'
  end

  it "should render a media tag for media types" do
    attachment_model content_type: 'video/mp4'
    get :show, course_id: @course.id, file_id: @attachment.id
    response.status.should == 200
    response.should render_template 'media_preview'
  end

  it "should fulfill module completion requirements" do
    @course.enable_feature!(:draft_state)
    attachment_model content_type: 'application/msword'
    mod = @course.context_modules.create!(:name => "some module")
    tag = mod.add_item(:id => @attachment.id, :type => 'attachment')
    mod.completion_requirements = { tag.id => {:type => 'must_view'} }
    mod.save!
    mod.evaluate_for(@user).workflow_state.should == "unlocked"
    get :show, course_id: @course.id, file_id: @attachment.id
    mod.evaluate_for(@user).workflow_state.should == "completed"
  end
end
