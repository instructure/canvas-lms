#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
    @assignment = @course.assignments.new(:title => "some assignment")
    @assignment.workflow_state = "published"
    @assignment.turnitin_enabled = true
    @assignment.save!
  end

  def turnitin_submission
    @submission = @assignment.submit_homework(@user, :submission_type => 'online_upload', :attachments => [attachment_model(:context => @user, :content_type => 'text/plain')])
    @submission.reload
  end

  FakeHTTPResponse = Struct.new(:body)
  def stub_net_http_to_return(partial_body, return_code = 1)
    body = "<returndata>#{ partial_body }<rcode>#{return_code}</rcode></returndata>"
    fake_response = FakeHTTPResponse.new(body)
    Net::HTTP.any_instance.expects(:start).returns(fake_response)
  end

  describe "initialize" do
    it "defaults to using api.turnitin.com" do
      expect(Turnitin::Client.new('test_account', 'sekret').host).to eq "api.turnitin.com"
    end

    it "allows the endpoint to be configurable" do
      expect(Turnitin::Client.new('test_account', 'sekret', 'www.blah.com').host).to eq "www.blah.com"
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

    it 'has correct default assignment settings' do
      expect(Turnitin::Client.default_assignment_turnitin_settings).to eq @default_settings
    end

    it 'normalizes assignment settings' do
      @default_settings[:originality_report_visibility] = 'never'
      @default_settings[:exclude_type] = '1'
      @default_settings[:exclude_value] = '50'
      normalized_settings = Turnitin::Client.normalize_assignment_turnitin_settings(@default_settings)
      expect(normalized_settings).to eq({
        :originality_report_visibility=>"never",
        :s_paper_check=>"1",
        :internet_check=>"1",
        :journal_check=>"1",
        :exclude_biblio=>"1",
        :exclude_quoted=>"1",
        :exclude_type=>"1",
        :exclude_value=>"50",
        :submit_papers_to=>"1",
        :s_view_report=>"0" })
    end

    it 'determines student visibility' do
      expect(Turnitin::Client.determine_student_visibility('after_grading')).to eq '1'
      expect(Turnitin::Client.determine_student_visibility('never')).to eq '0'
    end
  end

  describe "create assignment" do
    before(:each) do
      course_with_student(:active_all => true)
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

    it "marks assignment as created and current on success" do
      # doesn't matter what the assignmentid is, it's existance is simply used as a request success test
      stub_net_http_to_return('<assignmentid>12345</assignmentid>')
      status = @assignment.create_in_turnitin

      expect(status).to be_truthy
      expect(@assignment.reload.turnitin_settings).to eql @sample_turnitin_settings.merge({ :created => true, :current => true, :s_view_report => "1", :submit_papers_to => '0'})
    end

    it "stores error code and message on failure" do
      # doesn't matter what the assignmentid is, it's existance is simply used as a request success test
      stub_net_http_to_return '<rcode>123</rcode><rmessage>You cannot create this assignment right now</rmessage>'
      status = @assignment.create_in_turnitin

      expect(status).to be_falsey
      expect(@assignment.reload.turnitin_settings).to eql @sample_turnitin_settings.merge({
        :s_view_report => "1",
        :submit_papers_to => '0',
        :error => {
          :error_code => 123,
          :error_message => 'You cannot create this assignment right now',
          :public_error_message => 'There was an error submitting to turnitin. Please try resubmitting the file before contacting support.'
        }
      })
    end

    it "does not make api call if assignment is marked current" do
      stub_net_http_to_return('<assignmentid>12345</assignmentid')
      @assignment.create_in_turnitin
      status = @assignment.create_in_turnitin

      expect(status).to be_truthy
      expect(@assignment.reload.turnitin_settings).to eql @sample_turnitin_settings.merge({ :created => true, :current => true, :s_view_report => "1", :submit_papers_to => '0'})
    end

    it "sets s_view_report to 0 if originality_report_visibility is 'never'" do
      @sample_turnitin_settings[:originality_report_visibility] = 'never'
      @assignment.update_attributes(:turnitin_settings => @sample_turnitin_settings)
      stub_net_http_to_return('<assignmentid>12345</assignmentid>')
      @assignment.create_in_turnitin

      expect(@assignment.reload.turnitin_settings).to eql @sample_turnitin_settings.merge({ :created => true, :current => true, :s_view_report => '0', :submit_papers_to => '0'})
    end
  end

  describe "submit paper" do
    before(:each) do
      course_with_student(:active_all => true)
      turnitin_assignment
      turnitin_submission
      @turnitin_api = Turnitin::Client.new('test_account', 'sekret')

      @submission.context.expects(:turnitin_settings).at_least(1).returns([:placeholder])
      Turnitin::Client.expects(:new).at_least(1).with(:placeholder).returns(@turnitin_api)
      @turnitin_api.expects(:enrollStudent).with(@course, @user).returns(stub(:success? => true))
      @turnitin_api.expects(:createOrUpdateAssignment).with(@assignment, @assignment.turnitin_settings).returns({ :assignment_id => "1234" })
      Attachment.stubs(:instantiate).returns(@attachment)
      @attachment.expects(:open).returns(:my_stub)
    end

    it "submits attached files to turnitin" do
      stub_net_http_to_return('<objectID>12345</objectID>')
      status = @submission.submit_to_turnitin

      expect(status).to be_truthy
      expect(@submission.turnitin_data[@attachment.asset_string][:object_id]).to eql "12345"
    end

    it "stores errors in the turnitin_data hash" do
      stub_net_http_to_return('<rmessage>I am a random turnitin error message.</rmessage>', 216)
      status = @submission.submit_to_turnitin

      expect(status).to be_falsey
      expect(@submission.turnitin_data[@attachment.asset_string][:object_id]).to be_nil
      expect(@submission.turnitin_data[@attachment.asset_string][:error_code]).to eql 216
      expect(@submission.turnitin_data[@attachment.asset_string][:error_message]).to eql "I am a random turnitin error message."
      expect(@submission.turnitin_data[@attachment.asset_string][:public_error_message]).to eql "The student limit for this account has been reached. Please contact your account administrator."
    end
  end

  describe "#prepare_params" do
    before(:each) do
      course_with_student(:active_all => true)
      turnitin_assignment
      turnitin_submission
      @turnitin_api = Turnitin::Client.new('test_account', 'sekret')
    end

    let(:turnitin_submit_args) do
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

    context "when submitting a paper" do

      let(:teacher_email_arg) { turnitin_submit_args[:tem] }
      let(:paper_title_arg) { turnitin_submit_args[:ptl] }

      let(:processed_params) { @turnitin_api.prepare_params(:submit_paper, '2', turnitin_submit_args) }

      let(:processed_teacher_email) { processed_params[:tem] }
      let(:processed_paper_title) { processed_params[:ptl] }
      let(:processed_user_first_name) { processed_params[:ufn] }
      let(:processed_md5) { processed_params[:md5] }

      context "when escaping parameters" do

        it "escapes '%' signs" do
          @attachment.display_name = "Awkward%20Name.txt"
          expect(paper_title_arg).to include("%") # sanity check

          expect(processed_paper_title).to eql(CGI.escape(paper_title_arg))
        end

        it "escapes '@' signs" do
          expect(teacher_email_arg).to include("@") # sanity check
          expect(processed_teacher_email).to eql(CGI.escape(teacher_email_arg))
        end

        it "escapes spaces with '%20', not '+'" do
          @attachment.display_name = "My Submission With Spaces.txt"
          expect(processed_paper_title).to eql(@attachment.display_name.gsub(" ", "%20"))
        end

        # we can't test an actual md5 returned from turnitin without putting our
        # credentials in the test code (since the credentials are part of the string
        # from which the md5 is generated). So the next best thing is to check what
        # we're assuming turnitin does, which is to first unescape and then compute
        # md5.
        it "generates the md5 before escaping parameters" do
          md5_params = {}
          processed_params.each do |key, value|
            md5_params[key] = URI.unescape(value) unless key == :md5
          end

          expect(@turnitin_api.request_md5(md5_params)).to eql(processed_md5)
        end
      end
    end

    context "when creating a user" do

      let(:processed_params) { @turnitin_api.prepare_params(:create_user, '2', turnitin_submit_args) }

      let(:processed_user_first_name) { processed_params[:ufn] }
      let(:processed_user_last_name) { processed_params[:uln] }

      it "correctly uses the user's first and last names" do
        @student.name = "First Last"
        @student.sortable_name = "Last, First"

        expect(processed_user_first_name).to eq "First"
        expect(processed_user_last_name).to eq "Last"
      end

      it "creates a last name if none is given" do
        @student.name = "User"
        @student.sortable_name = "User"

        expect(processed_user_first_name).to eq "User"
        expect(processed_user_last_name).not_to be_empty
      end

    end

    it "ensures turnitin recieves unique assignment names even if the assignments have the same name" do
      process_title = lambda do |title|
        turnitin_assignment
        @assignment.title = title
        args = turnitin_submit_args.clone # we have to #clone this and call #prepare_params maually because rspec only evaluates 'let' blocks once per test
        args[:assignment] = @assignment

        params = @turnitin_api.prepare_params(:this_param_is_irrelevant_for_this_test, '2', args)

        processed_title = params[:assign]
        processed_title
      end

      processed_title_a = process_title.call("non_unique_title")
      process_title_b = process_title.call("non_unique_title")

      # sanity check
      expect(processed_title_a).to include("non_unique_title")
      expect(process_title_b).to include("non_unique_title")

      expect(processed_title_a).not_to eq process_title_b
    end
  end

  describe "#request_md5" do
    # From the turnitin api docs: the md5 for thess parameters should be
    # calculated by concatenatin aid + diagnostic + encrypt + fcmd + fid + gmtime
    # + uem + ufn + uln + utp + shared secret key:
    #
    # The concatenated string, before md5 is:
    # 1000011200310311john.doe@myschool.eduJohnDoejohn1232hothouse123
    it "follows the turnitin documentation way of generating the md5" do
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
      expect(@turnitin_api.request_md5(doc_sample_params)).to eql(doc_sample_md5)
    end
  end

  describe '#email' do
    it "uses turnitin_id for courses" do
      course_factory
      t = Turnitin::Client.new('blah', 'blah')
      expect(@course.turnitin_id).to be_nil
      expect(t.email(@course)).to eq "course_#{@course.global_id}@null.instructure.example.com"
      expect(@course.turnitin_id).to eql @course.global_id
    end
  end

  describe '#id' do
    it "uses turnitin_id when defined" do
      turnitin = Turnitin::Client.new('blah', 'blah')
      student_in_course active_all: true
      assignment = @course.assignments.create!

      expect(turnitin.id(@course)).to eql "course_#{@course.turnitin_id}"
      expect(turnitin.id(assignment)).to eql "assignment_#{assignment.turnitin_id}"
      expect(turnitin.id(@student)).to eql "user_#{@student.turnitin_id}"
    end
  end
end
