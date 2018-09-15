#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe SubmissionsController do
  it_behaves_like 'a submission update action', :submissions

  describe "POST create" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
      assert_unauthorized
    end

    it "should allow submitting homework" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].user_id).to eql(@user.id)
      expect(assigns[:submission].assignment_id).to eql(@assignment.id)
      expect(assigns[:submission].submission_type).to eql("online_url")
      expect(assigns[:submission].url).to eql("http://url")
    end

    it 'should only emit one live event' do
      expect(Canvas::LiveEvents).to receive(:submission_created).once
      expect(Canvas::LiveEvents).not_to receive(:submission_updated)
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
    end

    it "should not double-send notifications to a teacher" do
      course_with_student_logged_in(:active_all => true)
      @teacher = user_with_pseudonym(username: 'teacher@example.com', active_all: 1)
      teacher_in_course(course: @course, user: @teacher, active_all: 1)
      n = Notification.create!(name: 'Assignment Submitted', category: 'TestImmediately')

      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
      expect(response).to be_redirect
      expect(@teacher.messages.count).to eq 1
      expect(@teacher.messages.first.notification).to eq n
    end

    it "should allow submitting homework as attachments" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_upload")
      att = attachment_model(:context => @user, :uploaded_data => stub_file_data('test.txt', 'asdf', 'text/plain'))
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_upload", :attachment_ids => att.id}, :attachments => { "0" => { :uploaded_data => "" }, "-1" => { :uploaded_data => "" } }}
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].user_id).to eql(@user.id)
      expect(assigns[:submission][:assignment_id].to_i).to eql(@assignment.id)
      expect(assigns[:submission][:submission_type]).to eql("online_upload")
    end

    shared_examples "accepts 'eula_agreement_timestamp' params and persists it in the 'turnitin_data'" do
      let(:submission_type) { raise 'set in example' }
      let(:extra_params) { raise 'set in example' }
      let(:timestamp) { Time.now.to_i }

      it "accepts 'eula_agreement_timestamp' params and persists it in the 'turnitin_data'" do
        course_with_student_logged_in(:active_all => true)
        @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => submission_type)
        a1 = attachment_model(:context => @user)
        post 'create',
          params: {
            :course_id => @course.id,
            :assignment_id => @assignment.id,
            :submission => {
              :submission_type => submission_type,
              :attachment_ids => a1.id,
              :eula_agreement_timestamp => timestamp
            }
          }.merge(extra_params)
        expect(assigns[:submission].turnitin_data[:eula_agreement_timestamp]).to eq timestamp.to_s
      end
    end

    context 'online upload' do
      it_behaves_like "accepts 'eula_agreement_timestamp' params and persists it in the 'turnitin_data'" do
        let(:submission_type) { 'online_upload' }
        let(:extra_params) do
          {
            :attachments => {
              "0" => { :uploaded_data => "" },
              "-1" => { :uploaded_data => "" }
            }
          }
        end
      end
    end

    context 'online text entry' do
      it_behaves_like "accepts 'eula_agreement_timestamp' params and persists it in the 'turnitin_data'" do
        let(:submission_type) { 'online_text_entry' }
        let(:extra_params) do
          {
            :submission => {
              submission_type: submission_type,
              eula_agreement_timestamp: timestamp,
              body: 'body text'
            }
          }
        end
      end
    end

    it "should copy attachments to the submissions folder if that feature is enabled" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_upload")
      att = attachment_model(:context => @user, :uploaded_data => stub_file_data('test.txt', 'asdf', 'text/plain'))
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_upload", :attachment_ids => att.id}, :attachments => { "0" => { :uploaded_data => "" }, "-1" => { :uploaded_data => "" } }}
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      att_copy = Attachment.find(assigns[:submission].attachment_ids.to_i)
      expect(att_copy).not_to eq att
      expect(att_copy.root_attachment).to eq att
      expect(att).not_to be_associated_with_submission
      expect(att_copy).to be_associated_with_submission
    end

    it "should reject illegal file extensions from submission" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "an additional assignment", :submission_types => "online_upload", :allowed_extensions => ['txt'])
      att = attachment_model(:context => @student, :uploaded_data => stub_file_data('test.m4v', 'asdf', 'video/mp4'))
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_upload", :attachment_ids => att.id}, :attachments => { "0" => { :uploaded_data => "" }, "-1" => { :uploaded_data => "" } }}
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

      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
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

      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
      expect(response).to be_redirect
      expect(assigns[:group]).to be_nil
    end

    it "should allow attaching multiple files to the submission" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      att1 = attachment_model(:context => @user, :uploaded_data => fixture_file_upload("docs/doc.doc", "application/msword", true))
      att2 = attachment_model(:context => @user, :uploaded_data => fixture_file_upload("docs/txt.txt", "application/vnd.ms-excel", true))
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id,
           :submission => {:submission_type => "online_upload", :attachment_ids => [att1.id, att2.id].join(',')},
           :attachments => {"0" => {:uploaded_data => "doc.doc"}, "1" => {:uploaded_data => "txt.txt"}}}
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
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => ""}} # blank url not allowed
      expect(response).to be_redirect
      expect(flash[:error]).not_to be_nil
      expect(assigns[:submission]).to be_nil
    end

    it "should strip leading/trailing whitespace off url submissions" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url")
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => " http://www.google.com "}}
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].url).to eql("http://www.google.com")
    end

    it 'must accept a basic_lti_launch url when any online submission type is allowed' do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => 'some assignment', :submission_types => 'online_url')
      request.path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions"
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => 'basic_lti_launch', :url => 'http://www.google.com'}}
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].submission_type).to eq 'basic_lti_launch'
      expect(assigns[:submission].url).to eq 'http://www.google.com'
    end

    it 'accepts eula agreement timestamp when api submission' do
      timestamp = Time.zone.now.to_i.to_s
      course_with_student_logged_in(:active_all => true)
      attachment = attachment_model(context: @student)
      @assignment = @course.assignments.create!(:title => 'some assignment', :submission_types => 'online_upload')
      request.path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions"
      params = {
        course_id: @course.id,
        assignment_id: @assignment.id,
        submission: {
          submission_type: 'online_upload',
          file_ids: [attachment.id],
          eula_agreement_timestamp: timestamp
        }
      }
      post 'create', params: params
      expect(assigns[:submission].turnitin_data[:eula_agreement_timestamp]).to eq timestamp
    end

    it "should redirect to the assignment when locked in submit-at-deadline situation" do
      enable_cache do
        now = Time.now.utc
        Timecop.freeze(now) do
          course_with_student_logged_in(:active_all => true)
          @assignment = @course.assignments.create!(
            :title => "some assignment",
            :submission_types => "online_url",
            :lock_at => now + 5.seconds
          )

          # cache permission as true (for 5 minutes)
          expect(@assignment.grants_right?(@student, {}, :submit)).to be_truthy
        end

        # travel past due date (which resets the Assignment#locked_for? cache)
        Timecop.freeze(now + 10.seconds) do
          # now it's locked, but permission is cached, locked_for? is not
          post 'create',
            params: {:course_id => @course.id,
            :assignment_id => @assignment.id,
            :submission => {
              :submission_type => "online_url",
              :url => " http://www.google.com "
            }}
          expect(response).to be_redirect
        end
      end
    end

    describe 'when submitting a text response for the answer' do
      let(:assignment) { @course.assignments.create!(:title => "some assignment", :submission_types => "online_text_entry") }
      let(:submission_params) { {:submission_type => "online_text_entry", :body => "My Answer"} }

      before do
        Setting.set('enable_page_views', 'db')
        course_with_student_logged_in :active_all => true
        post 'create', params: {:course_id => @course.id, :assignment_id => assignment.id, :submission => submission_params}
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
      post 'create', params: {
        :course_id => @course.id,
        :assignment_id => assignment.id,
        :submission => sub_params
      }
      expect(response).to be_redirect
      expect(flash[:error]).not_to be_nil
      expect(assigns[:submission]).to be_nil
    end

    context "group comments" do
      before do
        course_with_student_logged_in(:active_all => true)
        @u1 = @user
        student_in_course(:course => @course)
        @u2 = @user
        @assignment = @course.assignments.create!(
          title: "some assignment",
          submission_types: "online_text_entry",
          group_category: GroupCategory.create!(:name => "groups", :context => @course),
          grade_group_students_individually: false
        )
        @group = @assignment.group_category.groups.create!(:name => 'g1', :context => @course)
        @group.users << @u1
        @group.users << @user
      end

      it "should not send a comment to the entire group by default" do
        post(
          'create',
          params: {:course_id => @course.id,
          :assignment_id => @assignment.id,
          :submission => {
            :submission_type => 'online_text_entry',
            :body => 'blah',
            :comment => "some comment"
          }
        })

        subs = @assignment.submissions
        expect(subs.size).to eq 2
        expect(subs.to_a.sum{ |s| s.submission_comments.size }).to eql 1
      end

      it "should not send a comment to the entire group when false" do
        post(
          'create',
          params: {:course_id => @course.id,
          :assignment_id => @assignment.id,
          :submission => {
            :submission_type => 'online_text_entry',
            :body => 'blah',
            :comment => "some comment",
            :group_comment => '0'
          }
        })

        subs = @assignment.submissions
        expect(subs.size).to eq 2
        expect(subs.to_a.sum{ |s| s.submission_comments.size }).to eql 1
      end

      it "should send a comment to the entire group if requested" do
        post(
          'create',
          params: {:course_id => @course.id,
          :assignment_id => @assignment.id,
          :submission => {
            :submission_type => 'online_text_entry',
            :body => 'blah',
            :comment => "some comment",
            :group_comment => '1'
          }
        })

        subs = @assignment.submissions
        expect(subs.size).to eq 2
        expect(subs.to_a.sum{ |s| s.submission_comments.size }).to eql 2
      end

      it "succeeds when commenting to the group from a student using PUT" do
        user_session(@u1)
        request.path = "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@u1.id}"
        post(
          :update,
          params: {
            course_id: @course.id,
            assignment_id: @assignment.id,
            id: @u1.id,
            submission: {
              assignment_id: @assignment.id,
              user_id: @u1.id,
              group_comment: '1',
              comment: "some comment"
            },
          },
          format: 'json')

        expect(response).to be_successful
      end
    end

    context "google doc" do
      before(:each) do
        course_with_student_logged_in(active_all: true)
        @assignment = @course.assignments.create!(title: 'some assignment', submission_types: 'online_upload')
      end

      it "should not save if domain restriction prevents it" do
        allow(@student).to receive(:gmail).and_return('student@does-not-match.com')
        account = Account.default
        flag    = FeatureFlag.new
        account.settings[:google_docs_domain] = 'example.com'
        account.save!
        flag.context = account
        flag.feature = 'google_docs_domain_restriction'
        flag.state = 'on'
        flag.save!
        mock_user_service = double()
        allow(@user).to receive(:user_services).and_return(mock_user_service)
        expect(mock_user_service).to receive(:where).with(service: "google_drive").
          and_return(double(first: double(token: "token", secret: "secret")))
        google_docs = double
        expect(GoogleDrive::Connection).to receive(:new).and_return(google_docs)

        expect(google_docs).to receive(:download).and_return([Net::HTTPOK.new(200, {}, ''), 'title', 'pdf'])
        post(:create, params: {course_id: @course.id, assignment_id: @assignment.id,
             submission: { submission_type: 'google_doc' },
             google_doc: { document_id: '12345' }})
        expect(response).to be_redirect
      end

      it "should use instfs to save google doc if instfs is enabled" do
        allow(InstFS).to receive(:enabled?).and_return(true)
        uuid = "1234-abcd"
        allow(InstFS).to receive(:direct_upload).and_return(uuid)

        attachment = @assignment.submissions.first.attachments.new
        SubmissionsController.new.store_google_doc_attachment(attachment, File.open("public/images/a.png"))
        expect(attachment.instfs_uuid).to eq uuid
      end
    end
  end

  describe "GET zip" do
    it "should zip and download" do
      local_storage!
      course_with_student_and_submitted_homework

      get 'index', params: {:course_id => @course.id, :assignment_id => @assignment.id, :zip => '1'}, format: 'json'
      expect(response).to be_successful

      a = Attachment.last
      expect(a.user).to eq @teacher
      expect(a.workflow_state).to eq 'to_be_zipped'
      a.update_attribute('workflow_state', 'zipped')
      allow(a).to receive('full_filename').and_return(File.expand_path(__FILE__)) # just need a valid file
      allow(a).to receive('content_type').and_return('test/file')
      allow(Attachment).to receive(:instantiate).and_return(a)

      request.headers['HTTP_ACCEPT'] = '*/*'
      get 'index', params: { :course_id => @course.id, :assignment_id => @assignment.id, :zip => '1' }
      expect(response).to be_successful
      expect(response.content_type).to eq 'test/file'
    end
  end

  describe "GET show" do
    before do
      course_with_student_and_submitted_homework
      @context = @course
      @submission.update!(score: 10)
    end

    let(:body) { JSON.parse(response.body)['submission'] }

    it "redirects to login when logged out" do
      remove_user_session
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      expect(response).to redirect_to(login_url)
    end

    it "renders show template" do
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      expect(response).to render_template(:show)
    end

    it "renders json with scores for teachers" do
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}, format: :json
      expect(body['id']).to eq @submission.id
      expect(body['score']).to eq 10
      expect(body['grade']).to eq '10'
      expect(body['published_grade']).to eq '10'
      expect(body['published_score']).to eq 10
    end

    it "renders json with scores for students" do
      user_session(@student)
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}, format: :json
      expect(body['id']).to eq @submission.id
      expect(body['score']).to eq 10
      expect(body['grade']).to eq '10'
      expect(body['published_grade']).to eq '10'
      expect(body['published_score']).to eq 10
    end

    it "mark read if reading one's own submission" do
      user_session(@student)
      request.accept = Mime[:json].to_s
      @submission.mark_unread(@student)
      @submission.save!
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}, format: :json
      expect(response).to be_successful
      submission = Submission.find(@submission.id)
      expect(submission.read?(@student)).to be_truthy
    end

    it "don't mark read if reading someone else's submission" do
      user_session(@teacher)
      request.accept = Mime[:json].to_s
      @submission.mark_unread(@student)
      @submission.mark_unread(@teacher)
      @submission.save!
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}, format: :json
      expect(response).to be_successful
      submission = Submission.find(@submission.id)
      expect(submission.read?(@student)).to be_falsey
      expect(submission.read?(@teacher)).to be_falsey
    end

    it "renders json with scores for teachers on muted assignments" do
      @assignment.update!(muted: true)
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}, format: :json
      expect(body['id']).to eq @submission.id
      expect(body['score']).to eq 10
      expect(body['grade']).to eq '10'
      expect(body['published_grade']).to eq '10'
      expect(body['published_score']).to eq 10
    end

    it "renders json without scores for students on muted assignments" do
      user_session(@student)
      @assignment.update!(muted: true)
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}, format: :json
      expect(body['id']).to eq @submission.id
      expect(body['score']).to be nil
      expect(body['grade']).to be nil
      expect(body['published_grade']).to be nil
      expect(body['published_score']).to be nil
    end

    it "renders the page for submitting student" do
      user_session(@student)
      @assignment.update!(anonymous_grading: true, muted: true)
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      assert_status(200)
    end

    it "renders unauthorized for non-submitting student" do
      new_student = User.create!
      @context.enroll_student(new_student, enrollment_state: 'active')
      user_session(new_student)
      @assignment.update!(anonymous_grading: true, muted: true)
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      assert_unauthorized
    end

    it "renders unauthorized for teacher" do
      user_session(@teacher)
      @assignment.update!(anonymous_grading: true, muted: true)
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      assert_unauthorized
    end

    it "renders unauthorized for admin" do
      user_session(account_admin_user)
      @assignment.update!(anonymous_grading: true, muted: true)
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      assert_unauthorized
    end

    it "renders the page for site admin" do
      user_session(site_admin_user)
      @assignment.update!(anonymous_grading: true, muted: true)
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      assert_status(200)
    end

    context "with user id not present in course" do
      before(:once) do
        course_with_student(active_all: true)
      end

      it "sets flash error" do
        get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
        expect(flash[:error]).not_to be_nil
      end

      it "should redirect to context assignment url" do
        get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
        expect(response).to redirect_to(course_assignment_url(@context, @assignment))
      end
    end

    it "should show rubric assessments to peer reviewers" do
      course_with_student(active_all: true)
      @assessor = @student
      outcome_with_rubric
      @association = @rubric.associate_with @assignment, @context, :purpose => 'grading'
      @assignment.peer_reviews = true
      @assignment.save!
      @assignment.assign_peer_review(@assessor, @submission.user)
      @assessment = @association.assess(:assessor => @assessor, :user => @submission.user, :artifact => @submission, :assessment => { :assessment_type => 'grading'})
      user_session(@assessor)

      get "show", params: {:id => @submission.user.id, :assignment_id => @assignment.id, :course_id => @context.id}

      expect(response).to be_successful

      expect(assigns[:visible_rubric_assessments]).to eq [@assessment]
    end
  end

 context 'originality report' do
  let(:test_course) do
    test_course = course_factory(active_course: true)
    test_course.enroll_teacher(test_teacher, enrollment_state: 'active')
    test_course.enroll_student(test_student, enrollment_state: 'active')
    test_course
  end

  let(:test_teacher) { User.create }
  let(:test_student) { User.create }
  let(:assignment) { Assignment.create!(title: 'test assignment', context: test_course) }
  let(:attachment) { attachment_model(filename: "submission.doc", context: test_student) }
  let(:submission) { assignment.submit_homework(test_student, attachments: [attachment]) }
  let!(:originality_report) do
    OriginalityReport.create!(attachment: attachment,
                              submission: submission,
                              originality_score: 0.5,
                              originality_report_url: 'http://www.instructure.com')
  end


  before :each do
    user_session(test_teacher)
  end


  describe 'GET originality_report' do
    it 'redirects to the originality report URL if it exists' do
      get 'originality_report', params: {course_id: assignment.context_id, assignment_id: assignment.id, submission_id: test_student.id, asset_string: attachment.asset_string}
      expect(response).to redirect_to originality_report.originality_report_url
    end

    it 'returns 400 if submission_id is not integer' do
      get 'originality_report', params: {:course_id => assignment.context_id, :assignment_id => assignment.id, :submission_id => '{ user_id }', :asset_string => attachment.asset_string}
      expect(response.response_code).to eq 400
    end

    it "returns unauthorized for users who can't read submission" do
      unauthorized_user = User.create
      user_session(unauthorized_user)
      get 'originality_report', params: {course_id: assignment.context_id, assignment_id: assignment.id, submission_id: test_student.id, asset_string: attachment.asset_string}
      expect(response.status).to eq 401
    end

    it 'gives error if no url is present for the OriginalityReport' do
      originality_report.update_attribute(:originality_report_url, nil)
      get 'originality_report', params: {course_id: assignment.context_id, assignment_id: assignment.id, submission_id: test_student.id, asset_string: attachment.asset_string}
      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST resubmit_to_turnitin' do
    it 'returns 400 if assignment_id is not integer' do
      assignment = assignment_model
      post 'resubmit_to_turnitin', params: {course_id: assignment.context_id, assignment_id: 'assignment-id', submission_id: test_student.id}
      expect(response.response_code).to eq 400
    end

    it "emits a 'plagiarism_resubmit' live event if originality report exists" do
      expect(Canvas::LiveEvents).to receive(:plagiarism_resubmit)
      post 'resubmit_to_turnitin', params: {course_id: assignment.context_id, assignment_id: assignment.id, submission_id: test_student.id}
    end

    it "emits a 'plagiarism_resubmit' live event if originality report does not exists" do
      originality_report.destroy
      expect(Canvas::LiveEvents).to receive(:plagiarism_resubmit)
      post 'resubmit_to_turnitin', params: {course_id: assignment.context_id, assignment_id: assignment.id, submission_id: test_student.id}
    end
  end

  it "redirects to speed grader when an anonymous submission id is used" do
    params = {
      course_id: assignment.context_id,
      assignment_id: assignment.id,
      submission_id: assignment.submission_for_student(test_student).anonymous_id,
      anonymous: true
    }
    post 'resubmit_to_turnitin', params: params
    expect(response).to be_redirect
  end

  describe 'POST resubmit_to_vericite' do
    it "emits a 'plagiarism_resubmit' live event" do
      expect(Canvas::LiveEvents).to receive(:plagiarism_resubmit)
      post 'resubmit_to_vericite', params: {course_id: assignment.context_id, assignment_id: assignment.id, submission_id: test_student.id}
    end
  end
 end

  describe 'GET turnitin_report' do
    it 'returns 400 if submission_id is not integer' do
      assignment = assignment_model
      get 'turnitin_report', params: {:course_id => assignment.context_id, :assignment_id => assignment.id, :submission_id => '{ user_id }', :asset_string => '123'}
      expect(response.response_code).to eq 400
    end
  end

  describe "copy_attachments_to_submissions_folder" do
    before(:once) do
      course_with_student
      attachment_model(context: @student)
    end

    it "copies a user attachment into the user's submissions folder" do
      atts = SubmissionsController.copy_attachments_to_submissions_folder(@course, [@attachment])
      expect(atts.length).to eq 1
      expect(atts[0]).not_to eq @attachment
      expect(atts[0].folder).to eq @student.submissions_folder(@course)
    end

    it "leaves files already in submissions folders alone" do
      @attachment.folder = @student.submissions_folder(@course)
      @attachment.save!
      atts = SubmissionsController.copy_attachments_to_submissions_folder(@course, [@attachment])
      expect(atts).to eq [@attachment]
    end

    it "copies a group attachment into the group submission folder" do
      group_model(context: @course)
      attachment_model(context: @group)
      atts = SubmissionsController.copy_attachments_to_submissions_folder(@course, [@attachment])
      expect(atts.length).to eq 1
      expect(atts[0]).not_to eq @attachment
      expect(atts[0].folder).to eq @group.submissions_folder
    end

    it "leaves files in non user/group context alone" do
      assignment_model(context: @course)
      weird_file = @assignment.attachments.create! display_name: 'blah', uploaded_data: default_uploaded_data
      atts = SubmissionsController.copy_attachments_to_submissions_folder(@course, [weird_file])
      expect(atts).to eq [weird_file]
    end
  end
end
