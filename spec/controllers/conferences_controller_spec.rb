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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ConferencesController do
  before :once do
    # these specs need an enabled web conference plugin
    @plugin = PluginSetting.create!(name: 'wimba')
    @plugin.update_attribute(:settings, { :domain => 'wimba.test' })
    course_with_teacher(active_all: true, user: user_with_pseudonym(active_all: true))
    @inactive_student = course_with_user('StudentEnrollment', course: @course, enrollment_state: 'invited').user
    student_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
  end

  before :each do
    allow_any_instance_of(WimbaConference).to receive(:send_request).and_return('')
    allow_any_instance_of(WimbaConference).to receive(:get_auth_token).and_return('abc123')
  end

  describe "GET 'index'" do
    it "should require authorization" do
      get 'index', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>12,'hidden'=>true}])
      get 'index', params: {:course_id => @course.id}
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "should assign variables" do
      user_session(@student)
      get 'index', params: {:course_id => @course.id}
      expect(response).to be_successful
    end

    it "should not redirect from group context" do
      user_session(@student)
      @group = @course.groups.create!(:name => "some group")
      @group.add_user(@student)
      get 'index', params: {:group_id => @group.id}
      expect(response).to be_successful
    end

    it "should not include the student view student" do
      user_session(@teacher)
      @student_view_student = @course.student_view_student
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:users].include?(@student)).to be_truthy
      expect(assigns[:users].include?(@student_view_student)).to be_falsey
    end

    it "doesn't include inactive users" do
      user_session(@teacher)
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:users].include?(@student)).to be_truthy
      expect(assigns[:users].include?(@inactive_student)).to be_falsey
    end

    it "should not allow the student view student to access collaborations" do
      course_with_teacher_logged_in(:active_user => true)
      expect(@course).not_to be_available
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      get 'index', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should not list conferences that use a disabled plugin" do
      user_session(@teacher)
      plugin = PluginSetting.create!(name: 'adobe_connect')
      plugin.update_attribute(:settings, { :domain => 'adobe_connect.test' })

      @conference = @course.web_conferences.create!(:conference_type => 'AdobeConnect', :duration => 60, :user => @teacher)
      plugin.disabled = true
      plugin.save!
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:new_conferences]).to be_empty
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', params: {:course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'Wimba'}}
      assert_unauthorized
    end

    it "should create a conference" do
      user_session(@teacher)
      post 'create', params: {:course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'Wimba'}}, :format => 'json'
      expect(response).to be_successful
    end

    it "should create a conference with observers removed" do
      user_session(@teacher)
      enrollment = observer_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
      post 'create', params: {:observers => { :remove => "1" }, :course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'Wimba'}}, :format => 'json'
      expect(response).to be_successful
      conference = WebConference.last
      expect(conference.invitees).not_to include(enrollment.user)
    end

    context 'with concluded students in context' do
      context "with a course context" do
        it 'should not invite students with a concluded enrollment' do
          user_session(@teacher)
          enrollment = student_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
          enrollment.conclude
          post 'create', params: {:course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'Wimba'}}, :format => 'json'
          conference = WebConference.last
          expect(conference.invitees).not_to include(enrollment.user)
        end
      end

      context 'with a group context' do
        it 'should not invite students with a concluded enrollment' do
          user_session(@teacher)
          concluded_enrollment = student_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
          concluded_enrollment.conclude

          enrollment = student_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
          group_category = @course.group_categories.create(:name => "category 1")
          group = @course.groups.create(:name => "some group", :group_category => group_category)
          group.add_user enrollment.user, 'accepted'
          group.add_user concluded_enrollment.user, 'accepted'

          post 'create', params: {:group_id => group.id, :web_conference => {:title => "My Conference", :conference_type => 'Wimba'}}, :format => 'json'
          conference = WebConference.last
          expect(conference.invitees).not_to include(concluded_enrollment.user)
          expect(conference.invitees).to include(enrollment.user)
        end
      end
    end
  end

  describe "POST 'update'" do
    it "should require authorization" do
      post 'create', params: {:course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'Wimba'}}
      assert_unauthorized
    end

    it "should update a conference" do
      user_session(@teacher)
      @conference = @course.web_conferences.create!(:conference_type => 'Wimba', :user => @teacher)
      post 'update', params: {:course_id => @course.id, :id => @conference, :web_conference => {:title => "Something else"}}, :format => 'json'
      expect(response).to be_successful
    end
  end

  describe "POST 'join'" do
    it "should require authorization" do
      @conference = @course.web_conferences.create!(:conference_type => 'Wimba', :duration => 60, :user => @teacher)
      post 'join', params: {:course_id => @course.id, :conference_id => @conference.id}
      assert_unauthorized
    end

    it "should let admins join a conference" do
      user_session(@teacher)
      @conference = @course.web_conferences.create!(:conference_type => 'Wimba', :duration => 60, :user => @teacher)
      post 'join', params: {:course_id => @course.id, :conference_id => @conference.id}
      expect(response).to be_redirect
      expect(response['Location']).to match /wimba\.test/
    end

    it "should let students join an inactive long running conference" do
      user_session(@student)
      @conference = @course.web_conferences.create!(:conference_type => 'Wimba', :user => @teacher)
      @conference.update_attribute :start_at, 1.month.ago
      @conference.users << @student
      allow_any_instance_of(WimbaConference).to receive(:conference_status).and_return(:closed)
      post 'join', params: {:course_id => @course.id, :conference_id => @conference.id}
      expect(response).to be_redirect
      expect(response['Location']).to match /wimba\.test/
    end

    describe 'when student is part of the conference' do

      before :once do
        @conference = @course.web_conferences.create!(:conference_type => 'Wimba', :duration => 60, :user => @teacher)
        @conference.users << @student
      end

      before :each do
        user_session(@student)
      end

      it "should not let students join an inactive conference" do
        expect_any_instance_of(WimbaConference).to receive(:active?).and_return(false)
        post 'join', params: {:course_id => @course.id, :conference_id => @conference.id}
        expect(response).to be_redirect
        expect(response['Location']).not_to match /wimba\.test/
        expect(flash[:notice]).to match(/That conference is not currently active/)
      end

      describe 'when the conference is active' do
        before do
          Setting.set('enable_page_views', 'db')
          expect_any_instance_of(WimbaConference).to receive(:active?).and_return(true)
          post 'join', params: {:course_id => @course.id, :conference_id => @conference.id}
        end

        it "should let students join an active conference" do
          expect(response).to be_redirect
          expect(response['Location']).to match /wimba\.test/
        end

        it 'logs an asset access record for the discussion topic' do
          accessed_asset = assigns[:accessed_asset]
          expect(accessed_asset[:code]).to eq @conference.asset_string
          expect(accessed_asset[:category]).to eq 'conferences'
          expect(accessed_asset[:level]).to eq 'participate'
        end

        it 'registers a page view' do
          page_view = assigns[:page_view]
          expect(page_view).not_to be_nil
          expect(page_view.http_method).to eq 'post'
          expect(page_view.url).to match %r{^http://test\.host/courses/\d+/conferences/\d+/join}
          expect(page_view.participated).to be_truthy
        end
      end
    end
  end
end
