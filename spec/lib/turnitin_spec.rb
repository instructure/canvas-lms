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
  def turnitin_assignment
    course_with_student(:active_all => true)
    @assignment = @course.assignments.new(:title => "some assignment")
    @assignment.workflow_state = "published"
    @assignment.turnitin_enabled = true
    @assignment.save
  end

  it "should submit attached files to turnitin" do
    turnitin_assignment
    @submission = @assignment.submit_homework(@user, :submission_type => 'online_upload', :attachments => [attachment_model(:context => @user, :content_type => 'text/plain')])
    @submission.reload
    @submission.context.should_receive(:turnitin_settings).at_least(:once).and_return([:my_settings])
    job = Delayed::Job.last(:conditions => { :tag => 'Submission#submit_to_turnitin'})
    job.should_not be_nil

    api = Turnitin::Client.new('test_account', 'sekret')
    Turnitin::Client.should_receive(:new).with(:my_settings).and_return(api)
    api.should_receive(:createOrUpdateAssignment).with(@assignment).and_return(true)
    api.should_receive(:enrollStudent).with(@course, @user).and_return(true)
    Attachment.stub!(:instantiate).and_return(@attachment)
    @attachment.should_receive(:open).and_return(:my_stub)
    api.should_receive(:sendRequest).with(:submit_paper, '2', hash_including(:pdata => :my_stub))
    @submission.submit_to_turnitin
  end

  it "should use the assignment's turnitin settings" do
    turnitin_assignment
    settings = {
      :originality_report_visibility => 'after_grading',
      :s_paper_check => '0',
      :internet_check => '0',
      :journal_check => '0',
      :exclude_biblio => '0',
      :exclude_quoted => '0',
      :exclude_type => '1',
      :exclude_value => '5'
    }
    @assignment.update_attributes(:turnitin_settings => settings)
    @submission = @assignment.submit_homework(@user, :submission_type => 'online_upload', :attachments => [attachment_model(:context => @user, :content_type => 'text/plain')])
    @submission.reload
    @submission.context.should_receive(:turnitin_settings).at_least(:once).and_return([:my_settings])
    job = Delayed::Job.last(:conditions => { :tag => 'Submission#submit_to_turnitin'})
    job.should_not be_nil

    api = Turnitin::Client.new('test_account', 'sekret')
    Turnitin::Client.should_receive(:new).with(:my_settings).and_return(api)
    api.should_receive(:sendRequest).with(:create_assignment, '2', hash_including(settings)).and_return(Nokogiri('<assignmentid>12345</assignmentid>'))
    api.should_receive(:enrollStudent).with(@course, @user).and_return(true)
    Attachment.stub!(:instantiate).and_return(@attachment)
    @attachment.should_receive(:open).and_return(:my_stub)
    api.should_receive(:sendRequest).with(:submit_paper, '2', hash_including(:pdata => :my_stub))
    @submission.submit_to_turnitin
  end
end
