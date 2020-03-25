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

require 'spec_helper'

describe SubmissionsController do
  it_behaves_like 'a submission update action', :submissions

  describe "POST create" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      @course.account.enable_service(:avatars)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
      assert_unauthorized
    end

    it "should allow submitting homework" do
      course_with_student_logged_in(:active_all => true)
      @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
    end

    it "should not double-send notifications to a teacher" do
      course_with_student_logged_in(:active_all => true)
      @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
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
        @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url")
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => ""}} # blank url not allowed
      expect(response).to be_redirect
      expect(flash[:error]).not_to be_nil
      expect(assigns[:submission]).to be_nil
    end

    it "should strip leading/trailing whitespace off url submissions" do
      course_with_student_logged_in(:active_all => true)
      @course.account.enable_service(:avatars)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url")
      post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => " http://www.google.com "}}
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].url).to eql("http://www.google.com")
    end

    it 'must accept a basic_lti_launch url when any online submission type is allowed' do
      course_with_student_logged_in(:active_all => true)
      @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
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
          @course.account.enable_service(:avatars)
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
        @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
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
        @course.account.enable_service(:avatars)
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
        @course.account.enable_service(:avatars)
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

    describe "confetti celebrations" do
      before(:each) do
        Account.default.enable_feature!(:confetti_for_assignments)
      end

      context "submission is made before due date" do
        before(:each) do
          course_with_student_logged_in(:active_all => true)
          @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload", :due_at => 5.days.from_now)
        end

        it "redirects with confetti" do
          post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
          expect(response).to be_redirect
          expect(response).to redirect_to(course_assignment_url(@course, @assignment, :confetti => true))
        end

        context "confetti_for_assignments flag is disabled" do
          before(:each) do
            Account.default.disable_feature!(:confetti_for_assignments)
          end

          it "redirects without confetti" do
            post 'create', params: {
              :course_id => @course.id,
              :assignment_id => @assignment.id,
              :submission => {:submission_type => "online_url", :url => "url"}
            }
            expect(response).to be_redirect
            expect(response).to_not redirect_to(course_assignment_url(@course, @assignment, :confetti => true))
          end
        end
      end

      context "submission is made after due date" do
        before(:each) do
          course_with_student_logged_in(:active_all => true)
          @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload", :due_at => 5.days.ago)
        end

        it "redirects without confetti" do
          post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
          expect(response).to be_redirect
          expect(response).to_not redirect_to(course_assignment_url(@course, @assignment, :confetti => true))
        end
      end

      context "submission is made with no due date" do
        before(:each) do
          course_with_student_logged_in(:active_all => true)
          @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
        end

        it "redirects with confetti" do
          post 'create', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}}
          expect(response).to be_redirect
          expect(response).to redirect_to(course_assignment_url(@course, @assignment, :confetti => true))
        end

        context "confetti_for_assignments flag is disabled" do
          before(:each) do
            Account.default.disable_feature!(:confetti_for_assignments)
          end

          it "redirects without confetti" do
            post 'create', params: {
              :course_id => @course.id,
              :assignment_id => @assignment.id,
              :submission => {:submission_type => "online_url", :url => "url"}
            }
            expect(response).to be_redirect
            expect(response).to_not redirect_to(course_assignment_url(@course, @assignment, :confetti => true))
          end
        end
      end
    end
  end

  describe "GET zip" do
    it "should zip and download" do
      local_storage!
      course_with_student_and_submitted_homework
      @course.account.enable_service(:avatars)

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
      @course.account.enable_service(:avatars)
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

    it "renders json with scores for teachers for unposted submissions" do
      @assignment.ensure_post_policy(post_manually: true)
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}, format: :json
      expect(body['id']).to eq @submission.id
      expect(body['score']).to eq 10
      expect(body['grade']).to eq '10'
      expect(body['published_grade']).to eq '10'
      expect(body['published_score']).to eq 10
    end

    it "renders json without scores for students for unposted submissions" do
      user_session(@student)
      @assignment.ensure_post_policy(post_manually: true)
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}, format: :json
      expect(body['id']).to eq @submission.id
      expect(body['score']).to be nil
      expect(body['grade']).to be nil
      expect(body['published_grade']).to be nil
      expect(body['published_score']).to be nil
    end

    it "renders json without scores for students with an unposted submission for a quiz" do
      quiz = @context.quizzes.create!
      quiz.workflow_state = "available"
      quiz.quiz_questions.create!({ question_data: test_quiz_data.first })
      quiz.save!
      quiz.assignment.ensure_post_policy(post_manually: true)

      quiz_submission = quiz.generate_submission(@student)
      Quizzes::SubmissionGrader.new(quiz_submission).grade_submission

      user_session(@student)
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: quiz.assignment.id, id: @student.id}, format: :json
      expect(body['id']).to eq quiz_submission.submission.id
      expect(body['body']).to be nil
    end

    it "renders the page for submitting student" do
      user_session(@student)
      @assignment.update!(anonymous_grading: true)
      @assignment.ensure_post_policy(post_manually: true)
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      assert_status(200)
    end

    describe "peer reviewers" do
      let(:course) { Course.create! }
      let(:assignment) { course.assignments.create!(peer_reviews: true) }
      let(:reviewer) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
      let(:reviewer_sub) { assignment.submissions.find_by!(user: reviewer) }
      let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
      let(:student_sub) { assignment.submissions.find_by!(user: student) }

      before(:each) do
        AssessmentRequest.create!(assessor: reviewer, assessor_asset: reviewer_sub, asset: student_sub, user: student)
        user_session(student)
      end

      it "renders okay for peer reviewer of student under view" do
        get :show, params: {course_id: course.id, assignment_id: assignment.id, id: student.id}
        expect(response).to have_http_status(:ok)
      end

      it "renders unauthorized for peer reviewer of a student not under view" do
        new_student = course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user
        get :show, params: {course_id: course.id, assignment_id: assignment.id, id: new_student.id}
        expect(response).to have_http_status(:unauthorized)
      end

      context "when anonymous grading is enabled for the assignment" do
        before(:each) do
          assignment.update!(anonymous_grading: true)
        end

        it "renders okay for peer reviewer of student under view" do
          get :show, params: {course_id: course.id, assignment_id: assignment.id, id: student.id}
          expect(response).to have_http_status(:ok)
        end

        it "renders unauthorized for peer reviewer of a student not under view" do
          new_student = course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user
          get :show, params: {course_id: course.id, assignment_id: assignment.id, id: new_student.id}
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when anonymous peer reviews are enabled for the assignment" do
        before(:each) do
          assignment.update!(anonymous_peer_reviews: true)
        end

        it "returns okay when a student attempts to view their own submission" do
          get :show, params: {course_id: course.id, assignment_id: assignment.id, id: student.id}
          expect(response).to have_http_status(:ok)
        end

        it "returns okay when a teacher attempts to view a student's submission" do
          teacher = course.enroll_teacher(User.create!, enrollment_state: "active").user
          user_session(teacher)
          get :show, params: {course_id: course.id, assignment_id: assignment.id, id: student.id}
          expect(response).to have_http_status(:ok)
        end

        it "renders unauthorized when a peer reviewer attempts to view the submission under review non-anonymously" do
          user_session(reviewer)
          get :show, params: {course_id: course.id, assignment_id: assignment.id, id: student.id}
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    it "renders unauthorized for non-submitting student" do
      new_student = User.create!
      @context.enroll_student(new_student, enrollment_state: 'active')
      user_session(new_student)
      @assignment.update!(anonymous_grading: true)
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      assert_unauthorized
    end

    it "renders unauthorized for teacher" do
      user_session(@teacher)
      @assignment.update!(anonymous_grading: true)
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      assert_unauthorized
    end

    it "renders unauthorized for admin" do
      user_session(account_admin_user)
      @assignment.update!(anonymous_grading: true)
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      assert_unauthorized
    end

    it "renders the page for site admin" do
      user_session(site_admin_user)
      @assignment.update!(anonymous_grading: true)
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id}
      assert_status(200)
    end

    context "with user id not present in course" do
      before(:once) do
        course_with_student(active_all: true)
        @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
      @assessor = @student
      outcome_with_rubric
      @association = @rubric.associate_with @assignment, @context, :purpose => 'grading'
      @assignment.peer_reviews = true
      @assignment.save!
      @assignment.unmute!
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
    test_course.account.enable_service(:avatars)
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

    context 'when there are multiple originality reports' do
      let(:submission2) { assignment.submit_homework(test_student, body: 'hello world') }
      let(:report_url2) { 'http://www.another-test-score.com/' }
      let(:originality_report2) {
        OriginalityReport.create!(attachment: nil,
                                  submission: submission2,
                                  originality_score: 0.4,
                                  originality_report_url: report_url2)
      }

      it 'can use attempt number to find the report url for text entry submissions' do
        originality_report2 # Create immediately
        originality_report.update!(attachment: nil)
        expect(submission2.id).to eq(submission.id) # submission2 is updated/reloaded with new version (last attempt number)
        expect(submission2.attempt).to be > submission.attempt
        get 'originality_report', params: {
          course_id: assignment.context_id, assignment_id: assignment.id, submission_id: test_student.id,
          asset_string: submission.asset_string, attempt: 1
        }
        expect(response).to redirect_to originality_report.originality_report_url
        get 'originality_report', params: {
          course_id: assignment.context_id, assignment_id: assignment.id, submission_id: test_student.id,
          asset_string: submission.asset_string, attempt: 2
        }
        expect(response).to redirect_to originality_report2.originality_report_url
      end
    end

    it 'returns bad_request if submission_id is not an integer' do
      get 'originality_report', params: {
        course_id: assignment.context_id,
        assignment_id: assignment.id,
        submission_id: '{ user_id }',
        asset_string: attachment.asset_string
      }
      expect(response).to have_http_status(:bad_request)
    end

    it "returns unauthorized for users who can't read submission" do
      unauthorized_user = User.create
      user_session(unauthorized_user)
      get 'originality_report', params: {course_id: assignment.context_id, assignment_id: assignment.id, submission_id: test_student.id, asset_string: attachment.asset_string}
      expect(response.status).to eq 401
    end

    it 'shows an error if no URL is present for the OriginalityReport' do
      originality_report.update_attribute(:originality_report_url, nil)
      get 'originality_report', params: {
        course_id: assignment.context_id,
        assignment_id: assignment.id,
        submission_id: test_student.id,
        asset_string: attachment.asset_string
      }
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST resubmit_to_turnitin' do
    it 'returns bad_request if assignment_id is not integer' do
      assignment = assignment_model
      post 'resubmit_to_turnitin', params: {course_id: assignment.context_id, assignment_id: 'assignment-id', submission_id: test_student.id}
      expect(response).to have_http_status(:bad_request)
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

  describe 'POST resubmit_to_vericite' do
    it "emits a 'plagiarism_resubmit' live event" do
      expect(Canvas::LiveEvents).to receive(:plagiarism_resubmit)
      post 'resubmit_to_vericite', params: {course_id: assignment.context_id, assignment_id: assignment.id, submission_id: test_student.id}
    end
  end
 end

  describe 'GET turnitin_report' do
    let(:course) { Course.create! }
    let(:student) { course.enroll_student(User.create!).user }
    let(:teacher) { course.enroll_teacher(User.create!).user }
    let(:assignment) { course.assignments.create!(submission_types: 'online_text_entry', title: 'hi') }
    let(:submission) { assignment.submit_homework(student, body: 'zzzzzzzzzz') }
    let(:asset_string) { submission.id.to_s }

    before { user_session(teacher) }

    it 'returns bad_request if submission_id is not an integer' do
      get 'turnitin_report', params: {
        course_id: assignment.context_id,
        assignment_id: assignment.id,
        submission_id: '{ user_id }',
        asset_string: asset_string
      }
      expect(response).to have_http_status(:bad_request)
    end

    context "when the submission's turnitin data contains a report URL" do
      before(:each) do
        submission.update!(turnitin_data: {asset_string => {report_url: 'MY_GREAT_REPORT'}})
      end

      it "redirects to the course tool retrieval URL" do
        get 'turnitin_report', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          submission_id: student.id,
          asset_string: asset_string
        }
        expect(response).to redirect_to(/#{retrieve_course_external_tools_url(course.id)}/)
      end

      it "includes the report URL in the redirect" do
        get 'turnitin_report', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          submission_id: student.id,
          asset_string: asset_string
        }
        expect(response).to redirect_to(/MY_GREAT_REPORT/)
      end
    end

    it "redirects the user to the submission details page if no turnitin URL exists" do
      get 'turnitin_report', params: {
        course_id: assignment.context_id,
        assignment_id: assignment.id,
        submission_id: student.id,
        asset_string: asset_string
      }
      expect(response).to redirect_to course_assignment_submission_url(assignment.context_id, assignment.id, student.id)
    end

    it "displays a flash error if no turnitin URL exists" do
      get 'turnitin_report', params: {
        course_id: assignment.context_id,
        assignment_id: assignment.id,
        submission_id: student.id,
        asset_string: asset_string
      }

      expect(flash[:error]).to be_present
    end
  end

  describe "GET audit_events" do
    let(:first_student) { course_with_user("StudentEnrollment", course: @course, name: "First", active_all: true).user }

    before(:each) do
      @course = Course.create!
      @course.account.enable_service(:avatars)
      second_student = course_with_user("StudentEnrollment", course: @course, name: "Second", active_all: true).user
      @teacher = course_with_user("TeacherEnrollment", course: @course, name: "Teacher", active_all: true).user
      @assignment = @course.assignments.create!(name: "anonymous", anonymous_grading: true, updating_user: @teacher)
      @submission = @assignment.submissions.find_by!(user: first_student)
      @submission.submission_comments.create!(author: first_student, comment: "Student comment")
      @submission.submission_comments.create!(author: @teacher, comment: "Teacher comment")
      @unrelated_submission = @assignment.submissions.find_by!(user: second_student)
      @teacher.account.role_overrides.create!(permission: :view_audit_trail, role: teacher_role, enabled: true)
    end

    before(:each) do
      user_session(@teacher)
    end

    let(:params) do
      {
        assignment_id: @assignment.id,
        course_id: @course.id,
        submission_id: @submission.id
      }
    end

    it "renders unauthorized if user does not have view_audit_trail permission" do
      @teacher.account.role_overrides.where(permission: :view_audit_trail).destroy_all
      get :audit_events, params: params, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "renders ok if user does have view_audit_trail permission" do
      get :audit_events, params: params, format: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns only related audit events" do
      @unrelated_submission.submission_comments.create!(author: @teacher, comment: "unrelated Teacher comment")
      @course.assignments.create!(name: "unrelated", anonymous_grading: true, updating_user: @teacher)
      get :audit_events, params: params, format: :json
      audit_events = json_parse(response.body).fetch("audit_events")
      expect(audit_events.count).to be 3
    end

    it "returns the assignment audit events" do
      get :audit_events, params: params, format: :json
      assignment_audit_events = json_parse(response.body).fetch("audit_events").select do |event|
        event.fetch("event_type").include?("assignment_")
      end
      expect(assignment_audit_events.count).to be 1
    end

    it "returns the submission audit events" do
      get :audit_events, params: params, format: :json
      submission_audit_events = json_parse(response.body).fetch("audit_events").select do |event|
        event.fetch("event_type").include?("submission_")
      end
      expect(submission_audit_events.count).to be 2
    end

    it "returns the audit events in order of created at" do
      get :audit_events, params: params, format: :json
      audit_event_ids = json_parse(response.body).fetch("audit_events").map do |event|
        event.fetch("id")
      end
      expect(audit_event_ids).to eql audit_event_ids.sort
    end

    describe "user names and roles" do
      let(:admin) { site_admin_user }
      let(:final_grader) { @teacher }
      let(:other_grader) { User.create!(name: "Nobody") }

      let(:returned_users) { json_parse(response.body).fetch("users") }

      before(:each) do
        @course.enroll_teacher(other_grader, enrollment_state: "active")
        @assignment.update!(moderated_grading: true, grader_count: 2, final_grader: final_grader)

        @submission.submission_comments.create!(author: admin, comment: "I am an administrator :)")
        @submission.submission_comments.create!(
          author: other_grader,
          comment: "I am nobody. Who are you? Are you nobody too?"
        )
      end

      it "returns all users who have generated events for a submission" do
        extraneous_grader = User.create!
        @assignment.create_moderation_grader(extraneous_grader, occupy_slot: true)

        get :audit_events, params: params, format: :json
        user_ids = returned_users.pluck("id")
        expect(user_ids).to match_array([first_student.id, admin.id, other_grader.id, final_grader.id])
      end

      it "returns the name associated with a user" do
        get :audit_events, params: params, format: :json
        expect(returned_users).to include(hash_including({"id" => other_grader.id, "name" => "Nobody" }))
      end

      it "returns a role of 'final_grader' if a user is the final grader" do
        get :audit_events, params: params, format: :json
        expect(returned_users).to include(hash_including({"id" => final_grader.id, "role" => "final_grader" }))
      end

      it "returns a role of 'admin' if a user is an administrator" do
        get :audit_events, params: params, format: :json
        expect(returned_users).to include(hash_including({"id" => admin.id, "role" => "admin" }))
      end

      it "returns a role of 'grader' if a user is a grader" do
        get :audit_events, params: params, format: :json
        expect(returned_users).to include(hash_including({"id" => other_grader.id, "role" => "grader" }))
      end

      it "returns a role of 'student' if a user is a student" do
        get :audit_events, params: params, format: :json
        expect(returned_users).to include(hash_including({"id" => first_student.id, "role" => "student" }))
      end
    end

    describe "external tool events" do
      let(:external_tool) do
        Account.default.context_external_tools.create!(
          name: "Undertow",
          url: "http://www.example.com",
          consumer_key: '12345',
          shared_secret: 'secret'
        )
      end
      let(:returned_tools) { json_parse(response.body).fetch("tools") }
      let(:external_tool_events) do
        json_parse(response.body).fetch("audit_events").select do |event|
          event.fetch("event_type").include?("submission_") && event.fetch("context_external_tool_id").present?
        end
      end

      before(:each) { @assignment.grade_student(first_student, grader_id: -external_tool.id, score: 80) }

      it "returns an event for external tool" do
        get :audit_events, params: params, format: :json
        expect(external_tool_events.count).to be 1
      end

      it "returns the name associated with an external tool" do
        get :audit_events, params: params, format: :json
        expect(returned_tools).to include(hash_including({ "id" => external_tool.id, "name" => "Undertow" }))
      end

      it "returns the role of grader for an external tool" do
        get :audit_events, params: params, format: :json
        expect(returned_tools).to include(hash_including({ "id" => external_tool.id, "role" => "grader" }))
      end
    end

    describe "quiz events" do
      let(:quiz) do
        quiz = @course.quizzes.create!
        quiz.workflow_state = "available"
        quiz.quiz_questions.create!({ question_data: test_quiz_data.first })
        quiz.save!
        quiz.assignment.updating_user = @teacher
        quiz.assignment.update_attribute(:anonymous_grading, true)

        qsub = Quizzes::SubmissionManager.new(quiz).find_or_create_submission(first_student)
        qsub.quiz_data = test_quiz_data
        qsub.started_at = 1.minute.ago
        qsub.attempt = 1
        qsub.submission_data = [{:points=>0, :text=>"7051", :question_id=>128, :correct=>false, :answer_id=>7051}]
        qsub.score = 0
        qsub.save!
        qsub.finished_at = Time.now.utc
        qsub.workflow_state = 'complete'
        qsub.submission = quiz.assignment.find_or_create_submission(first_student)
        qsub.submission.audit_grade_changes = true
        qsub.with_versioning(true) { qsub.save! }

        quiz
      end
      let(:quiz_assignment) { quiz.assignment }
      let(:quiz_audit_params) do
        {
          assignment_id: quiz_assignment.id,
          course_id: @course.id,
          submission_id: quiz_assignment.submissions.find_by!(user: first_student).id
        }
      end
      let(:returned_quizzes) { json_parse(response.body).fetch("quizzes") }
      let(:quiz_events) do
        json_parse(response.body).fetch("audit_events").select do |event|
          event.fetch("event_type").include?("submission_") && event.fetch("quiz_id").present?
        end
      end

      it "returns an event for a quiz" do
        get :audit_events, params: quiz_audit_params, format: :json
        expect(quiz_events.count).to be 1
      end

      it "returns the name associated with the quiz" do
        get :audit_events, params: quiz_audit_params, format: :json
        expect(returned_quizzes).to include(hash_including({ "id" => quiz.id, "name" => "Unnamed Quiz" }))
      end

      it "returns the role of grader for a quiz" do
        get :audit_events, params: quiz_audit_params, format: :json
        expect(returned_quizzes).to include(hash_including({ "id" => quiz.id, "role" => "grader" }))
      end
    end
  end

  describe "copy_attachments_to_submissions_folder" do
    before(:once) do
      course_with_student
      @course.account.enable_service(:avatars)
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
