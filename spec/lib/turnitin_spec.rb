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
    @assignment.save!
  end

  def turnitin_submission
    expects_job_with_tag('Submission#submit_to_turnitin') do
      @submission = @assignment.submit_homework(@user, :submission_type => 'online_upload', :attachments => [attachment_model(:context => @user, :content_type => 'text/plain')])
    end
    @submission.reload
  end

  describe "initialize" do
    it "should default to using api.turnitin.com" do
      Turnitin::Client.new('test_account', 'sekret').host.should == "api.turnitin.com"
    end

    it "should allow the endpoint to be configurable" do
      Turnitin::Client.new('test_account', 'sekret', 'www.blah.com').host.should == "www.blah.com"
    end
  end

  describe 'class methods' do
    before(:each) do
      @default_settings = {
        :originality_report_visibility => 'immediate',
        :s_paper_check => '1',
        :internet_check => '1',
        :journal_check => '1',
        :exclude_biblio => '1',
        :exclude_quoted => '1',
        :exclude_type => '0',
        :exclude_value => '',
        :submit_papers_to => '1'
      }
    end

    it 'should have correct default assignment settings' do
      Turnitin::Client.default_assignment_turnitin_settings.should == @default_settings
    end

    it 'should normalize assignment settings' do
      @default_settings[:originality_report_visibility] = 'never'
      @default_settings[:exclude_type] = '1'
      @default_settings[:exclude_value] = '50'
      normalized_settings = Turnitin::Client.normalize_assignment_turnitin_settings(@default_settings)
      normalized_settings.should == {
        :originality_report_visibility=>"never",
        :s_paper_check=>"1",
        :internet_check=>"1",
        :journal_check=>"1",
        :exclude_biblio=>"1",
        :exclude_quoted=>"1",
        :exclude_type=>"1",
        :exclude_value=>"50",
        :submit_papers_to=>"1",
        :s_view_report=>"0" }
    end

    it 'should determine student visibility' do
      Turnitin::Client.determine_student_visibility('after_grading').should == '1'
      Turnitin::Client.determine_student_visibility('never').should == '0'
    end
  end

  describe "create assignment" do
    before(:each) do
      turnitin_assignment
      @turnitin_api = Turnitin::Client.new('test_account', 'sekret')
      @assignment.context.expects(:turnitin_settings).at_least(1).returns([:placeholder])
      Turnitin::Client.expects(:new).with(:placeholder).returns(@turnitin_api)

      @sample_turnitin_settings = {
        :originality_report_visibility => 'after_grading',
        :s_paper_check => '0',
        :internet_check => '0',
        :journal_check => '0',
        :exclude_biblio => '0',
        :exclude_quoted => '0',
        :exclude_type => '1',
        :exclude_value => '5'
      }
      @assignment.update_attributes(:turnitin_settings => @sample_turnitin_settings)
    end

    it "should mark assignment as created an current on success" do
      # doesn't matter what the assignmentid is, it's existance is simply used as a request success test
      @turnitin_api.expects(:sendRequest).with(:create_assignment, '2', has_entries(@sample_turnitin_settings)).returns(Nokogiri('<assignmentid>12345</assignmentid>'))
      status = @assignment.create_in_turnitin

      status.should be_true
      @assignment.reload.turnitin_settings.should eql @sample_turnitin_settings.merge({ :created => true, :current => true, :s_view_report => "1", :submit_papers_to => '0'})
    end

    it "should store error code and message on failure" do
      # doesn't matter what the assignmentid is, it's existance is simply used as a request success test
      example_error = '<rerror><rcode>123</rcode><rmessage>You cannot create this assignment right now</rmessage></rerror>'
      @turnitin_api.expects(:sendRequest).with(:create_assignment, '2', has_entries(@sample_turnitin_settings)).returns(Nokogiri(example_error))
      status = @assignment.create_in_turnitin

      status.should be_false
      @assignment.reload.turnitin_settings.should eql @sample_turnitin_settings.merge({
        :s_view_report => "1",
        :submit_papers_to => '0',
        :error => {
          :error_code => 123,
          :error_message => 'You cannot create this assignment right now',
          :public_error_message => 'There was an error submitting to turnitin. Please try resubmitting the file before contacting support.'
        }
      })
    end

    it "should not make api call if assignment is marked current" do
      @turnitin_api.expects(:sendRequest).with(:create_assignment, '2', has_entries(@sample_turnitin_settings)).returns(Nokogiri('<assignmentid>12345</assignmentid>'))
      @assignment.create_in_turnitin
      status = @assignment.create_in_turnitin

      status.should be_true
      @assignment.reload.turnitin_settings.should eql @sample_turnitin_settings.merge({ :created => true, :current => true, :s_view_report => "1", :submit_papers_to => '0'})
    end

    it "should set s_view_report to 0 if originality_report_visibility is 'never'" do
      @sample_turnitin_settings[:originality_report_visibility] = 'never'
      @assignment.update_attributes(:turnitin_settings => @sample_turnitin_settings)
      @turnitin_api.expects(:sendRequest).returns(Nokogiri('<assignmentid>12345</assignmentid>'))
      @assignment.create_in_turnitin

      @assignment.reload.turnitin_settings.should eql @sample_turnitin_settings.merge({ :created => true, :current => true, :s_view_report => '0', :submit_papers_to => '0'})
    end
  end

  describe "submit paper" do
    before(:each) do
      turnitin_assignment
      turnitin_submission
      @turnitin_api = Turnitin::Client.new('test_account', 'sekret')

      @submission.context.expects(:turnitin_settings).at_least(1).returns([:placeholder])
      Turnitin::Client.expects(:new).at_least(1).with(:placeholder).returns(@turnitin_api)
      @turnitin_api.expects(:enrollStudent).with(@course, @user).returns(true)
      @turnitin_api.expects(:createOrUpdateAssignment).with(@assignment, @assignment.turnitin_settings).returns({ :assignment_id => "1234" })
      Attachment.stubs(:instantiate).returns(@attachment)
      @attachment.expects(:open).returns(:my_stub)
    end

    it "should submit attached files to turnitin" do
      @turnitin_api.expects(:sendRequest).with(:submit_paper, '2', has_entries(:pdata => :my_stub)).returns(Nokogiri('<objectID>12345</objectID>'))
      status = @submission.submit_to_turnitin

      status.should be_true
      @submission.turnitin_data[@attachment.asset_string][:object_id].should eql "12345"
    end

    it "should store errors in the turnitin_data hash" do
      example_error = '<rerror><rcode>216</rcode><rmessage>I am a random turnitin error message.</rmessage></rerror>'
      @turnitin_api.expects(:sendRequest).with(:submit_paper, '2', has_entries(:pdata => :my_stub)).returns(Nokogiri(example_error))
      status = @submission.submit_to_turnitin

      status.should be_false
      @submission.turnitin_data[@attachment.asset_string][:object_id].should be_nil
      @submission.turnitin_data[@attachment.asset_string][:error_code].should eql 216
      @submission.turnitin_data[@attachment.asset_string][:error_message].should eql "I am a random turnitin error message."
      @submission.turnitin_data[@attachment.asset_string][:public_error_message].should eql "The student limit for this account has been reached. Please contact your account administrator."
    end
  end

  describe "#prepare_params" do
    before(:each) do
      turnitin_assignment
      turnitin_submission
      @turnitin_api = Turnitin::Client.new('test_account', 'sekret')
      @turnitin_submit_args = {
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

      post_params = @turnitin_api.prepare_params(:submit_paper, '2', @turnitin_submit_args)
      post_params[:ptl].should eql(CGI.escape(@turnitin_submit_args[:ptl])) # escape % signs
      post_params[:tem].should eql(CGI.escape(@turnitin_submit_args[:tem])) # escape @ signs
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

      post_params = @turnitin_api.prepare_params(:submit_paper, '2', @turnitin_submit_args)

      md5_params = {}
      post_params.each do |key, value|
        md5_params[key] = URI.unescape(value) unless key == :md5
      end

      @turnitin_api.request_md5(md5_params).should eql(post_params[:md5])
    end

    it "should get a first and last name for users" do
      args = @turnitin_submit_args.clone
      args[:user].name = "User"

      params = @turnitin_api.prepare_params(:create_user, '2', args)

      params[:ufn].should=="User"
      params[:uln].should_not be_empty

      args = @turnitin_submit_args.clone
      args[:user].name = "First Last"
      args[:user].sortable_name = "Last, First"

      params = @turnitin_api.prepare_params(:create_user, '2', args)
      params[:ufn].should=="First"
      params[:uln].should=="Last"
    end
  end

  describe "#request_md5" do
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
end
