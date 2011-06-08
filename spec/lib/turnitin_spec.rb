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

describe Turnitin::Client do
  it "should submit attached files to turnitin" do
    course_with_student(:active_all => true)
    @assignment = @course.assignments.new(:title => "some assignment")
    @assignment.workflow_state = "published"
    @assignment.turnitin_enabled = true
    @assignment.save
    @submission = @assignment.submit_homework(@user, :submission_type => 'online_upload', :attachments => [attachment_model(:context => @user, :content_type => 'text/plain')])
    @submission.reload
    @submission.context.should_receive(:turnitin_settings).at_least(:once).and_return([:my_settings])
    job = Delayed::Job.last(:conditions => { :tag => 'Submission#submit_to_turnitin'})
    job.should_not be_nil

    api = Turnitin::Client.new('test_account', 'sekret')
    Turnitin::Client.should_receive(:new).with(:my_settings).and_return(api)
    api.should_receive(:createAssignment).with(@assignment).and_return(true)
    api.should_receive(:enrollStudent).with(@course, @user).and_return(true)
    Attachment.stub!(:instantiate).and_return(@attachment)
    @attachment.should_receive(:open).and_return(:my_stub)
    api.should_receive(:sendRequest).with(:submit_paper, '2', hash_including(:pdata => :my_stub))
    @submission.submit_to_turnitin
  end
end
