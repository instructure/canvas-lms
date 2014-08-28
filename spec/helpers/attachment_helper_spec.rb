#
# Copyright (C) 2013 Instructure, Inc.
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

describe AttachmentHelper do
  include ApplicationHelper
  include AttachmentHelper

  def user_file_inline_view_url(context, att_id)
    "expected_context_url"
  end

  def user_file_scribd_render_url(context, att_id)
    "expected_scribd_render_url"
  end

  before :once do
    course_with_student
    @att = attachment_model(:context => @user)
  end

  before :each do
    @att.stubs(:scribdable?).returns(true)
    @att.stubs(:scribd_doc).returns({})
  end

  it "should generate data element for expected context" do
    doc_preview_attributes(@att).should =~ %r{data-attachment_view_inline_ping_url=expected_context_url}
  end

  it "should leave out inline data element for unexpected context" do
    asmnt = @course.assignments.create!(:title => "some assignment", :submission_types => 'online_upload')
    @att.context = asmnt
    @att.save!
    doc_preview_attributes(@att).should_not =~ %r{data-attachment_view_inline_ping_url}
  end

  it "should indicate when the file preview is processing" do
    @att.workflow_state = 'processing'
    attrs = doc_preview_attributes(@att)
    attrs.should be_include('data-attachment_preview_processing=true')
    attrs.should_not be_include('data-attachment_scribd_render_url')
  end

  it "should include a rerender url if the scribd doc is missing" do
    @att.workflow_state = 'deleted'
    @att.stubs(:scribd_doc).returns(nil)
    attrs = doc_preview_attributes(@att)
    attrs.should be_include('data-attachment_scribd_render_url=expected_scribd_render_url')
    attrs.should_not be_include('data-attachment_preview_processing')
  end
end
