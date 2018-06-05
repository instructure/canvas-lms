#
# Copyright (C) 2013 - present Instructure, Inc.
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

  before :once do
    course_with_student
    @att = attachment_model(:context => @user)
  end

  it "should return a valid crocodoc session url" do
    @current_user = @student
    allow(@att).to receive(:crocodoc_available?).and_return(true)
    attrs = doc_preview_attributes(@att)
    expect(attrs).to match /crocodoc_session/
    expect(attrs).to match /#{@current_user.id}/
    expect(attrs).to match /#{@att.id}/
  end

  it "should return a valid canvadoc session url" do
    @current_user = @student
    allow(@att).to receive(:canvadocable?).and_return(true)
    attrs = doc_preview_attributes(@att)
    expect(attrs).to match /canvadoc_session/
    expect(attrs).to match /#{@current_user.id}/
    expect(attrs).to match /#{@att.id}/
  end

  it "includes anonymous_instructor_annotations in canvadoc url" do
    @current_user = @teacher
    allow(@att).to receive(:canvadocable?).and_return(true)
    attrs = doc_preview_attributes(@att, { anonymous_instructor_annotations: true })
    expect(attrs).to match "anonymous_instructor_annotations%22:true"
  end

  it "includes enrollment_type in canvadoc url when annotations are enabled" do
    @current_user = @teacher
    allow(@att).to receive(:canvadocable?).and_return(true)
    attrs = doc_preview_attributes(@att, { enable_annotations: true, enrollment_type: "teacher" })
    expect(attrs).to match "enrollment_type%22:%22teacher"
  end

  describe "set_cache_header" do
    it "should not allow caching of instfs redirects" do
      allow(@att).to receive(:instfs_hosted?).and_return(true)
      expect(self).to receive(:cancel_cache_buster).never
      set_cache_header(@att, false)
      expect(response.headers).not_to have_key('Cache-Control')
    end
  end
end
