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
      response.should be_redirect
      assigns[:submission].should_not be_nil
      assigns[:submission].user_id.should eql(@user.id)
      assigns[:submission].assignment_id.should eql(@assignment.id)
      assigns[:submission].submission_type.should eql("online_url")
      assigns[:submission].url.should eql("http://url")
    end

    it "should use the appropriate group based on the assignment's category and the current user" do
      course_with_student_logged_in(:active_all => true)
      group_category = @course.group_categories.create(:name => "Category")
      @group = @course.groups.create(:name => "Group", :group_category => group_category)
      @group.add_user(@user)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload", :group_category => @group.group_category)

      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}
      response.should be_redirect
      assigns[:group].should_not be_nil
      assigns[:group].id.should eql(@group.id)
    end

    it "should not use a group if the assignment has no category" do
      course_with_student_logged_in(:active_all => true)
      group_category = @course.group_categories.create(:name => "Category")
      @group = @course.groups.create(:name => "Group", :group_category => group_category)
      @group.add_user(@user)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")

      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}
      response.should be_redirect
      assigns[:group].should be_nil
    end

    it "should allow attaching multiple files to the submission" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      data1 = fixture_file_upload("scribd_docs/doc.doc", "application/msword", true)
      data2 = fixture_file_upload("scribd_docs/xls.xls", "application/vnd.ms-excel", true)
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_upload"}, :attachments => {"0" => {:uploaded_data => data1}, "1" => {:uploaded_data => data2}}
      response.should be_redirect
      assigns[:submission].should_not be_nil
      assigns[:submission].user_id.should eql(@user.id)
      assigns[:submission].assignment_id.should eql(@assignment.id)
      assigns[:submission].submission_type.should eql("online_upload")
      assigns[:submission].attachments.should_not be_empty
      assigns[:submission].attachments.length.should eql(2)
      assigns[:submission].attachments.map{|a| a.display_name}.should be_include("doc.doc")
      assigns[:submission].attachments.map{|a| a.display_name}.should be_include("xls.xls")
    end

    it "should fail but not raise when the submission is invalid" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url")
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => ""} # blank url not allowed
      response.should be_redirect
      flash[:error].should_not be_nil
      assigns[:submission].should be_nil
    end

    it "should strip leading/trailing whitespace off url submissions" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url")
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => " http://www.google.com "}
      response.should be_redirect
      assigns[:submission].should_not be_nil
      assigns[:submission].url.should eql("http://www.google.com")
    end

    describe 'when submitting a text response for the answer' do
      let(:assignment) { @course.assignments.create!(:title => "some assignment", :submission_types => "online_text_entry") }
      let(:submission_params) { {:submission_type => "online_url", :body => "My Answer"} }

      before do
        Setting.set('enable_page_views', 'db')
        course_with_student_logged_in :active_all => true
        post 'create', :course_id => @course.id, :assignment_id => assignment.id, :submission => submission_params
      end

      after do
        Setting.set('enable_page_views', 'false')
      end

      it 'should redirect me to the course assignment' do
        response.should be_redirect
      end

      it 'saves a submission object' do
        submission = assigns[:submission]
        submission.id.should_not be_nil
        submission.user_id.should == @user.id
        submission.body.should == submission_params[:body]
      end

      it 'logs an asset access for the assignment' do
        accessed_asset = assigns[:accessed_asset]
        accessed_asset[:level].should == 'submit'
      end

      it 'registers a page view' do
        page_view = assigns[:page_view]
        page_view.should_not be_nil
        page_view.http_method.should == 'post'
        page_view.url.should =~ %r{^http://test\.host/courses/\d+/assignments/\d+/submissions}
        page_view.participated.should be_true
      end

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
        subs.size.should == 2
        subs.all.sum{ |s| s.submission_comments.size }.should eql 1
      end

      it "should send a comment to the entire group if requested" do
        post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => 'online_text_entry', :body => 'blah', :comment => "some comment", :group_comment => '1'}
        subs = @assignment.submissions
        subs.size.should == 2
        subs.all.sum{ |s| s.submission_comments.size }.should eql 2
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
      end

      it "should not save if domain restriction prevents it" do
        google_docs = mock
        GoogleDocs.expects(:new).returns(google_docs)

        google_docs.expects(:download).returns([Net::HTTPOK.new(200, {}, ''), 'title', 'pdf'])
        post(:create, course_id: @course.id, assignment_id: @assignment.id,
             submission: { submission_type: 'google_doc' },
             google_doc: { document_id: '12345' })
        response.should be_redirect
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
      response.should be_redirect
      assigns[:submission].should eql(@submission)
      assigns[:submission].submission_comments.length.should eql(1)
      assigns[:submission].submission_comments[0].comment.should eql("some comment")
    end

    it "should allow a non-enrolled admin to add comments" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      site_admin_user
      user_session(@user)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @student.id, :submission => {:comment => "some comment"}
      response.should be_redirect
      assigns[:submission].should eql(@submission)
      assigns[:submission].submission_comments.length.should eql(1)
      assigns[:submission].submission_comments[0].comment.should eql("some comment")
      assigns[:submission].submission_comments[0].should_not be_hidden
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
      response.should be_redirect
      assigns[:submission].should eql(@submission)
      assigns[:submission].submission_comments.length.should eql(1)
      assigns[:submission].submission_comments[0].comment.should eql("some comment")
      assigns[:submission].submission_comments[0].should be_hidden
    end

    it "should comment as the current user for all submissions in the group" do
      course_with_student_logged_in(:active_all => true)
      @u1 = @user
      student_in_course(:course => @course)
      @u2 = @user
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "discussion_topic", :group_category => GroupCategory.create!(:name => "groups", :context => @course), :grade_group_students_individually => true)
      @group = @assignment.group_category.groups.create!(:name => 'g1', :context => @course)
      @group.users << @u1
      @group.users << @user
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @u1.id, :submission => {:comment => "some comment", :group_comment => '1'}
      subs = @assignment.submissions
      subs.size.should == 2
      subs.each do |s|
        s.submission_comments.size.should == 1
        s.submission_comments.first.author.should == @u1
      end
    end
    
    it "should allow attaching files to the comment" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      data1 = fixture_file_upload("scribd_docs/doc.doc", "application/msword", true)
      data2 = fixture_file_upload("scribd_docs/xls.xls", "application/vnd.ms-excel", true)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @user.id, :submission => {:comment => "some comment"}, :attachments => {"0" => {:uploaded_data => data1}, "1" => {:uploaded_data => data2}}
      response.should be_redirect
      assigns[:submission].should eql(@submission)
      assigns[:submission].submission_comments.length.should eql(1)
      assigns[:submission].submission_comments[0].comment.should eql("some comment")
      assigns[:submission].submission_comments[0].attachments.length.should eql(2)
      assigns[:submission].submission_comments[0].attachments.map{|a| a.display_name}.should be_include("doc.doc")
      assigns[:submission].submission_comments[0].attachments.map{|a| a.display_name}.should be_include("xls.xls")
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
      @submission.reload.student_entered_score.should == 2.0
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
      @submission.reload.student_entered_score.should == 2.0
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
      response.should be_success

      a = Attachment.last
      a.user.should == @teacher
      a.workflow_state.should == 'to_be_zipped'
      a.update_attribute('workflow_state', 'zipped')
      a.stubs('full_filename').returns(File.expand_path(__FILE__)) # just need a valid file
      a.stubs('content_type').returns('test/file')
      Attachment.stubs(:instantiate).returns(a)

      get 'index', { :course_id => @course.id, :assignment_id => @assignment.id, :zip => '1' }, 'HTTP_ACCEPT' => '*/*'
      response.should be_success
      response.content_type.should == 'test/file'
    end
  end

  describe "GET show" do
    it "should not expose muted assignment's scores" do
      course_with_student_and_submitted_homework

      get "show", :id => @submission.to_param, :assignment_id => @assignment.to_param, :course_id => @course.to_param
      response.should be_success

      %w(score published_grade published_score grade).each do |secret_attr|
        assigns[:submission].send(secret_attr).should be_nil
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
      response.should be_success

      assigns[:visible_rubric_assessments].should == [@assessment]
    end
  end

  describe 'GET turnitin_report' do

    it 'returns 400 if submission_id is not integer' do
      assignment = assignment_model
      get 'turnitin_report', :course_id => assignment.context_id, :assignment_id => assignment.id, :submission_id => '{{ user_id }}', :asset_string => '123'
      response.response_code.should == 400
    end

  end

  describe 'POST resubmit_to_turnitin' do

    it 'returns 400 if submission_id is not integer' do
      assignment = assignment_model
      post 'resubmit_to_turnitin', :course_id => assignment.context_id, :assignment_id => assignment.id, :submission_id => '{{ user_id }}'
      response.response_code.should == 400
    end

  end
end
