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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SubmissionsController do
  describe "POST create" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}
      assert_unauthorized
    end

    it "should allow submitting homework" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].user_id).to eql(@user.id)
      expect(assigns[:submission].assignment_id).to eql(@assignment.id)
      expect(assigns[:submission].submission_type).to eql("online_url")
      expect(assigns[:submission].url).to eql("http://url")
    end

    it "should allow submitting homework as attachments" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_upload")
      att = attachment_model(:context => @user, :uploaded_data => stub_file_data('test.txt', 'asdf', 'text/plain'))
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_upload", :attachment_ids => att.id}, :attachments => { "0" => { :uploaded_data => "" }, "-1" => { :uploaded_data => "" } }
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].user_id).to eql(@user.id)
      expect(assigns[:submission][:assignment_id].to_i).to eql(@assignment.id)
      expect(assigns[:submission][:submission_type]).to eql("online_upload")
    end

    it "should reject illegal file extensions from submission" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "an additional assignment", :submission_types => "online_upload", :allowed_extensions => ['txt'])
      att = attachment_model(:context => @student, :uploaded_data => stub_file_data('test.m4v', 'asdf', 'video/mp4'))
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_upload", :attachment_ids => att.id}, :attachments => { "0" => { :uploaded_data => "" }, "-1" => { :uploaded_data => "" } }
      expect(response).to be_redirect
      expect(assigns[:submission]).to be_nil
      expect(flash[:error]).not_to be_nil
      expect(flash[:error]).to match(/Invalid file type/)
    end

    it "should use the appropriate group based on the assignment's category and the current user" do
      course_with_student_logged_in(:active_all => true)
      group_category = @course.group_categories.create(:name => "Category")
      @group = @course.groups.create(:name => "Group", :group_category => group_category)
      @group.add_user(@user)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload", :group_category => @group.group_category)

      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}
      expect(response).to be_redirect
      expect(assigns[:group]).not_to be_nil
      expect(assigns[:group].id).to eql(@group.id)
    end

    it "should not use a group if the assignment has no category" do
      course_with_student_logged_in(:active_all => true)
      group_category = @course.group_categories.create(:name => "Category")
      @group = @course.groups.create(:name => "Group", :group_category => group_category)
      @group.add_user(@user)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")

      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}
      expect(response).to be_redirect
      expect(assigns[:group]).to be_nil
    end

    it "should allow attaching multiple files to the submission" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      data1 = fixture_file_upload("scribd_docs/doc.doc", "application/msword", true)
      data2 = fixture_file_upload("scribd_docs/txt.txt", "application/vnd.ms-excel", true)
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_upload"}, :attachments => {"0" => {:uploaded_data => data1}, "1" => {:uploaded_data => data2}}
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].user_id).to eql(@user.id)
      expect(assigns[:submission].assignment_id).to eql(@assignment.id)
      expect(assigns[:submission].submission_type).to eql("online_upload")
      expect(assigns[:submission].attachments).not_to be_empty
      expect(assigns[:submission].attachments.length).to eql(2)
      expect(assigns[:submission].attachments.map{|a| a.display_name}).to be_include("doc.doc")
      expect(assigns[:submission].attachments.map{|a| a.display_name}).to be_include("txt.txt")
    end

    it "should fail but not raise when the submission is invalid" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url")
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => ""} # blank url not allowed
      expect(response).to be_redirect
      expect(flash[:error]).not_to be_nil
      expect(assigns[:submission]).to be_nil
    end

    it "should strip leading/trailing whitespace off url submissions" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url")
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => " http://www.google.com "}
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].url).to eql("http://www.google.com")
    end

    describe 'when submitting a text response for the answer' do
      let(:assignment) { @course.assignments.create!(:title => "some assignment", :submission_types => "online_text_entry") }
      let(:submission_params) { {:submission_type => "online_text_entry", :body => "My Answer"} }

      before do
        Setting.set('enable_page_views', 'db')
        course_with_student_logged_in :active_all => true
        post 'create', :course_id => @course.id, :assignment_id => assignment.id, :submission => submission_params
      end

      after do
        Setting.set('enable_page_views', 'false')
      end

      it 'should redirect me to the course assignment' do
        expect(response).to be_redirect
      end

      it 'saves a submission object' do
        submission = assigns[:submission]
        expect(submission.id).not_to be_nil
        expect(submission.user_id).to eq @user.id
        expect(submission.body).to eq submission_params[:body]
      end

      it 'logs an asset access for the assignment' do
        accessed_asset = assigns[:accessed_asset]
        expect(accessed_asset[:level]).to eq 'submit'
      end

      it 'registers a page view' do
        page_view = assigns[:page_view]
        expect(page_view).not_to be_nil
        expect(page_view.http_method).to eq 'post'
        expect(page_view.url).to match %r{^http://test\.host/courses/\d+/assignments/\d+/submissions}
        expect(page_view.participated).to be_truthy
      end

    end

    it 'rejects an empty text response' do
      course_with_student_logged_in(:active_all => true)
      assignment = @course.assignments.create!(
        :title => 'some assignment',
        :submission_types => 'online_text_entry'
      )
      sub_params = { submission_type: 'online_text_entry', body: '' }
      post 'create', {
        :course_id => @course.id,
        :assignment_id => assignment.id,
        :submission => sub_params
      }
      expect(response).to be_redirect
      expect(flash[:error]).not_to be_nil
      expect(assigns[:submission]).to be_nil
    end

    it 'should build a pageview thats marked as participating' do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url")
    end

    context "group comments" do
      before do
        course_with_student_logged_in(:active_all => true)
        @u1 = @user
        student_in_course(:course => @course)
        @u2 = @user
        @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_text_entry", :group_category => GroupCategory.create!(:name => "groups", :context => @course), :grade_group_students_individually => true)
        @group = @assignment.group_category.groups.create!(:name => 'g1', :context => @course)
        @group.users << @u1
        @group.users << @user
      end

      it "should not send a comment to the entire group by default" do
        post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => 'online_text_entry', :body => 'blah', :comment => "some comment"}
        subs = @assignment.submissions
        expect(subs.size).to eq 2
        expect(subs.all.sum{ |s| s.submission_comments.size }).to eql 1
      end

      it "should send a comment to the entire group if requested" do
        post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => 'online_text_entry', :body => 'blah', :comment => "some comment", :group_comment => '1'}
        subs = @assignment.submissions
        expect(subs.size).to eq 2
        expect(subs.all.sum{ |s| s.submission_comments.size }).to eql 2
      end
    end

    context "google doc" do
      before(:each) do
        course_with_student_logged_in(active_all: true)
        @student.stubs(:gmail).returns('student@does-not-match.com')
        @assignment = @course.assignments.create!(title: 'some assignment', submission_types: 'online_upload')
        account = Account.default
        flag    = FeatureFlag.new
        account.settings[:google_docs_domain] = 'example.com'
        account.save!
        flag.context = account
        flag.feature = 'google_docs_domain_restriction'
        flag.state = 'on'
        flag.save!
        mock_user_service = mock()
        @user.stubs(:user_services).returns(mock_user_service)
        mock_user_service.expects(:where).with(service: "google_docs").returns(stub(first: mock(token: "token", secret: "secret")))
      end

      it "should not save if domain restriction prevents it" do
        google_docs = mock
        GoogleDocs::Connection.expects(:new).returns(google_docs)

        google_docs.expects(:download).returns([Net::HTTPOK.new(200, {}, ''), 'title', 'pdf'])
        post(:create, course_id: @course.id, assignment_id: @assignment.id,
             submission: { submission_type: 'google_doc' },
             google_doc: { document_id: '12345' })
        expect(response).to be_redirect
      end
    end
  end
  
  describe "PUT update" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @user.id, :submission => {:comment => "some comment"}
      assert_unauthorized
    end
    
    it "should require the right student" do
      course_with_student_logged_in(:active_all => true)
      @user2 = User.create!(:name => "some user")
      @course.enroll_user(@user2)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user2)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @user2.id, :submission => {:comment => "some comment"}
      assert_unauthorized
    end
    
    it "should allow updating homework to add comments" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @user.id, :submission => {:comment => "some comment"}
      expect(response).to be_redirect
      expect(assigns[:submission]).to eql(@submission)
      expect(assigns[:submission].submission_comments.length).to eql(1)
      expect(assigns[:submission].submission_comments[0].comment).to eql("some comment")
    end

    it "should allow a non-enrolled admin to add comments" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      site_admin_user
      user_session(@user)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @student.id, :submission => {:comment => "some comment"}
      expect(response).to be_redirect
      expect(assigns[:submission]).to eql(@submission)
      expect(assigns[:submission].submission_comments.length).to eql(1)
      expect(assigns[:submission].submission_comments[0].comment).to eql("some comment")
      expect(assigns[:submission].submission_comments[0]).not_to be_hidden
    end

    it "should allow a non-enrolled admin to add comments on a submission to muted assignment" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      @assignment.muted = true
      @assignment.save!
      site_admin_user
      user_session(@user)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @student.id, :submission => {:comment => "some comment"}
      expect(response).to be_redirect
      expect(assigns[:submission]).to eql(@submission)
      expect(assigns[:submission].submission_comments.length).to eql(1)
      expect(assigns[:submission].submission_comments[0].comment).to eql("some comment")
      expect(assigns[:submission].submission_comments[0]).to be_hidden
    end

    it "should comment as the current user for all submissions in the group" do
      course_with_student_logged_in(:active_all => true)
      @u1 = @user
      student_in_course(:course => @course)
      @u2 = @user
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload", :group_category => GroupCategory.create!(:name => "groups", :context => @course), :grade_group_students_individually => true)
      @group = @assignment.group_category.groups.create!(:name => 'g1', :context => @course)
      @group.users << @u1
      @group.users << @user
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @u1.id, :submission => {:comment => "some comment", :group_comment => '1'}
      subs = @assignment.submissions
      expect(subs.size).to eq 2
      subs.each do |s|
        expect(s.submission_comments.size).to eq 1
        expect(s.submission_comments.first.author).to eq @u1
      end
    end
    
    it "should allow attaching files to the comment" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      data1 = fixture_file_upload("scribd_docs/doc.doc", "application/msword", true)
      data2 = fixture_file_upload("scribd_docs/txt.txt", "text/plain", true)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @user.id, :submission => {:comment => "some comment"}, :attachments => {"0" => {:uploaded_data => data1}, "1" => {:uploaded_data => data2}}
      expect(response).to be_redirect
      expect(assigns[:submission]).to eql(@submission)
      expect(assigns[:submission].submission_comments.length).to eql(1)
      expect(assigns[:submission].submission_comments[0].comment).to eql("some comment")
      expect(assigns[:submission].submission_comments[0].attachments.length).to eql(2)
      expect(assigns[:submission].submission_comments[0].attachments.map{|a| a.display_name}).to be_include("doc.doc")
      expect(assigns[:submission].submission_comments[0].attachments.map{|a| a.display_name}).to be_include("txt.txt")
    end

    it "should allow setting 'student_entered_grade'" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      put 'update', {
        :course_id => @course.id,
        :assignment_id => @assignment.id,
        :id => @user.id,
        :submission => {
          :student_entered_score => '2'
        }
      }
      expect(@submission.reload.student_entered_score).to eq 2.0
    end

    it "should round 'student_entered_grade'" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      put 'update', {
        :course_id => @course.id,
        :assignment_id => @assignment.id,
        :id => @user.id,
        :submission => {
          :student_entered_score => '2.0000000020'
        }
      }
      expect(@submission.reload.student_entered_score).to eq 2.0
    end
  end

  def course_with_student_and_submitted_homework
      course_with_teacher_logged_in(:active_all => true)
      @teacher = @user
      student_in_course
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
  end

  describe "GET zip" do
    it "should zip and download" do
      course_with_student_and_submitted_homework

      get 'index', :course_id => @course.id, :assignment_id => @assignment.id, :zip => '1', :format => 'json'
      expect(response).to be_success

      a = Attachment.last
      expect(a.user).to eq @teacher
      expect(a.workflow_state).to eq 'to_be_zipped'
      a.update_attribute('workflow_state', 'zipped')
      a.stubs('full_filename').returns(File.expand_path(__FILE__)) # just need a valid file
      a.stubs('content_type').returns('test/file')
      Attachment.stubs(:instantiate).returns(a)

      get 'index', { :course_id => @course.id, :assignment_id => @assignment.id, :zip => '1' }, 'HTTP_ACCEPT' => '*/*'
      expect(response).to be_success
      expect(response.content_type).to eq 'test/file'
    end
  end

  describe "GET show" do
    it "should not expose muted assignment's scores" do
      course_with_student_and_submitted_homework

      get "show", :id => @submission.to_param, :assignment_id => @assignment.to_param, :course_id => @course.to_param
      expect(response).to be_success

      %w(score published_grade published_score grade).each do |secret_attr|
        expect(assigns[:submission].send(secret_attr)).to be_nil
      end
    end

    it "should show rubric assessments to peer reviewers" do
      course_with_student_and_submitted_homework

      @assessor = student_in_course.user
      outcome_with_rubric
      @association = @rubric.associate_with @assignment, @course, :purpose => 'grading'
      @assignment.assign_peer_review(@assessor, @submission.user)
      @assessment = @association.assess(:assessor => @assessor, :user => @submission.user, :artifact => @submission, :assessment => { :assessment_type => 'grading'})
      user_session(@assessor)

      get "show", :id => @submission.to_param, :assignment_id => @assignment.to_param, :course_id => @course.to_param
      expect(response).to be_success

      expect(assigns[:visible_rubric_assessments]).to eq [@assessment]
    end

    it "should redirect download requests with the download_frd parameter" do
      # This is because the files controller looks for download_frd to indicate a forced download
      course_with_teacher_logged_in
      assignment = assignment_model(course: @course)
      student_in_course
      att = attachment_model(:uploaded_data => stub_file_data('test.txt', 'asdf', 'text/plain'), :context => @student)
      submission = submission_model(
        course: @course,
        assignment: assignment,
        submission_type: "online_upload",
        attachment_ids: att.id,
        attachments: [att],
        user: @student)
      get 'show', assignment_id: assignment.id, course_id: @course.id, id: @user.id, download: att.id

      expect(response).to be_redirect
      expect(response.headers["Location"]).to match %r{users/#{@student.id}/files/#{att.id}/download\?download_frd=true}
    end
  end

  describe 'GET turnitin_report' do

    it 'returns 400 if submission_id is not integer' do
      assignment = assignment_model
      get 'turnitin_report', :course_id => assignment.context_id, :assignment_id => assignment.id, :submission_id => '{{ user_id }}', :asset_string => '123'
      expect(response.response_code).to eq 400
    end

  end

  describe 'POST resubmit_to_turnitin' do

    it 'returns 400 if submission_id is not integer' do
      assignment = assignment_model
      post 'resubmit_to_turnitin', :course_id => assignment.context_id, :assignment_id => assignment.id, :submission_id => '{{ user_id }}'
      expect(response.response_code).to eq 400
    end

  end
end
