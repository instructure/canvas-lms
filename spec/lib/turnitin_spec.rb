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

    @submission = @assignment.submit_homework(@user, :submission_type => 'online_upload', :attachments => [attachment_model(:context => @user, :content_type => 'text/plain')])
    @submission.reload

    @turnitin_api = Turnitin::Client.new('test_account', 'sekret')
  end

  it "should submit attached files to turnitin" do
    turnitin_assignment
    @submission.context.expects(:turnitin_settings).at_least(1).returns([:my_settings])
    job = Delayed::Job.last(:conditions => { :tag => 'Submission#submit_to_turnitin'})
    job.should_not be_nil

    Turnitin::Client.expects(:new).with(:my_settings).returns(@turnitin_api)
    @turnitin_api.expects(:createOrUpdateAssignment).with(@assignment).returns(true)
    @turnitin_api.expects(:enrollStudent).with(@course, @user).returns(true)
    Attachment.stubs(:instantiate).returns(@attachment)
    @attachment.expects(:open).returns(:my_stub)
    @turnitin_api.expects(:sendRequest).with(:submit_paper, '2', has_entries(:pdata => :my_stub))
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
    @submission.context.expects(:turnitin_settings).at_least(1).returns([:my_settings])
    job = Delayed::Job.last(:conditions => { :tag => 'Submission#submit_to_turnitin'})
    job.should_not be_nil

    Turnitin::Client.expects(:new).with(:my_settings).returns(@turnitin_api)
    @turnitin_api.expects(:sendRequest).with(:create_assignment, '2', has_entries(settings)).returns(Nokogiri('<assignmentid>12345</assignmentid>'))
    @turnitin_api.expects(:enrollStudent).with(@course, @user).returns(true)
    Attachment.stubs(:instantiate).returns(@attachment)
    @attachment.expects(:open).returns(:my_stub)
    @turnitin_api.expects(:sendRequest).with(:submit_paper, '2', has_entries(:pdata => :my_stub))
    @submission.submit_to_turnitin
    @assignment.reload.turnitin_settings.should eql({
      :originality_report_visibility => 'after_grading',
      :s_paper_check => '0',
      :internet_check => '0',
      :journal_check => '0',
      :exclude_biblio => '0',
      :exclude_quoted => '0',
      :exclude_type => '1',
      :exclude_value => '5',
      :created => true,
      :current => true
    })
  end

  def turnitin_submit_args
    {
      :post => true, 
      :utp => '1', 
      :ptl => @attachment.display_name, 
      :ptype => "2", 
      :user => @student, 
      :course => @course, 
      :assignment => @assignment, 
      :tem => "spec@null.instructure.example.com"
    }
  end

  it "should escape post params" do
    turnitin_assignment
    @attachment.display_name = "Bad%20Name.txt"

    post_params = @turnitin_api.prepare_params(:submit_paper, '2', turnitin_submit_args)
    post_params[:ptl].should eql(CGI.escape(turnitin_submit_args[:ptl])) # escape % signs
    post_params[:tem].should eql(CGI.escape(turnitin_submit_args[:tem])) # escape @ signs
    post_params[:ufn].should eql(@student.name.gsub(" ", "%20")) # escape space with %20, not +
  end

  # we can't test an actual md5 returned from turnitin without putting our
  # credentials in the test code (since the credentials are part of the string
  # from which the md5 is generated). So the next best thing is to check what
  # we're assuming turnitin does, which is to first unescape and then compute
  # md5.
  it "should generate the md5 before escaping parameters" do
    turnitin_assignment
    @attachment.display_name = "Bad%20Name.txt"

    post_params = @turnitin_api.prepare_params(:submit_paper, '2', turnitin_submit_args)

    md5_params = {}
    post_params.each do |key, value|
      md5_params[key] = URI.unescape(value) unless key == :md5
    end
    
    @turnitin_api.request_md5(md5_params).should eql(post_params[:md5])
  end

  # From the turnitin api docs: the md5 for thess parameters should be
  # calculated by concatenatin aid + diagnostic + encrypt + fcmd + fid + gmtime
  # + uem + ufn + uln + utp + shared secret key:
  #
  # The concatenated string, before md5 is:
  # 1000011200310311john.doe@myschool.eduJohnDoejohn1232hothouse123
  it "should follow the turnitin documentation way of generating the md5" do
    doc_sample_account_id = "100"
    doc_sample_shared_secret = "hothouse123"
    doc_sample_params = {
      :gmtime => "200310311",
      :fid => "1",
      :fcmd  => "1",
      :encrypt => "0",
      :aid => doc_sample_account_id,
      :diagnostic => "0",
      :uem => "john.doe@myschool.edu",
      :upw => "john123",
      :ufn => "John",
      :uln => "Doe",
      :utp => "2"
    }
    doc_sample_md5 = "12a4e7b0bfc5f55b4b1ef252b1b05919"

    @turnitin_api = Turnitin::Client.new(doc_sample_account_id, doc_sample_shared_secret)
    @turnitin_api.request_md5(doc_sample_params).should eql(doc_sample_md5)
  end
end
