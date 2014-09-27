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

describe ConferencesController do
  before :once do
    # these specs need an enabled web conference plugin
    @plugin = PluginSetting.create!(name: 'wimba')
    @plugin.update_attribute(:settings, { :domain => 'wimba.test' })
    course_with_teacher(active_all: true, user: user_with_pseudonym(active_all: true))
    student_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
  end

  describe "GET 'index'" do
    it "should require authorization" do
      get 'index', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>12,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end
    
    it "should assign variables" do
      user_session(@student)
      get 'index', :course_id => @course.id
      response.should be_success
    end

    it "should not redirect from group context" do
      user_session(@student)
      @group = @course.groups.create!(:name => "some group")
      @group.add_user(@student)
      get 'index', :group_id => @group.id
      response.should be_success
    end
    
    it "should not include the student view student" do
      user_session(@teacher)
      @student_view_student = @course.student_view_student
      get 'index', :course_id => @course.id
      assigns[:users].include?(@student).should be_true
      assigns[:users].include?(@student_view_student).should be_false
    end

    it "should not allow the student view student to access collaborations" do
      course_with_teacher_logged_in(:active_user => true)
      @course.should_not be_available
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id
      
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should not list conferences that use a disabled plugin" do
      user_session(@teacher)
      plugin = PluginSetting.create!(name: 'adobe_connect')
      plugin.update_attribute(:settings, { :domain => 'adobe_connect.test' })

      @conference = @course.web_conferences.create!(:conference_type => 'AdobeConnect', :duration => 60, :user => @teacher)
      plugin.disabled = true
      plugin.save!
      get 'index', :course_id => @course.id
      assigns[:new_conferences].should be_empty
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', :course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'Wimba'}
      assert_unauthorized
    end
    
    it "should create a conference" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'Wimba'}, :format => 'json'
      response.should be_success
    end
  end

  describe "POST 'update'" do
    it "should require authorization" do
      post 'create', :course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'Wimba'}
      assert_unauthorized
    end
    
    it "should update a conference" do
      user_session(@teacher)
      @conference = @course.web_conferences.create!(:conference_type => 'Wimba', :user => @teacher)
      post 'update', :course_id => @course.id, :id => @conference, :web_conference => {:title => "Something else"}, :format => 'json'
      response.should be_success
    end
  end

  describe "POST 'join'" do
    it "should require authorization" do
      @conference = @course.web_conferences.create!(:conference_type => 'Wimba', :duration => 60, :user => @teacher)
      post 'join', :course_id => @course.id, :conference_id => @conference.id
      assert_unauthorized
    end

    it "should let admins join a conference" do
      WimbaConference.any_instance.stubs(:send_request).returns('')
      WimbaConference.any_instance.stubs(:get_auth_token).returns('abc123')
      user_session(@teacher)
      @conference = @course.web_conferences.create!(:conference_type => 'Wimba', :duration => 60, :user => @teacher)
      post 'join', :course_id => @course.id, :conference_id => @conference.id
      response.should be_redirect
      response['Location'].should =~ /wimba\.test/
    end

    it "should let students join an inactive long running conference" do
      WimbaConference.any_instance.stubs(:send_request).returns('')
      WimbaConference.any_instance.stubs(:get_auth_token).returns('abc123')
      user_session(@student)
      @conference = @course.web_conferences.create!(:conference_type => 'Wimba', :user => @teacher)
      @conference.update_attribute :start_at, 1.month.ago
      @conference.users << @student
      WimbaConference.any_instance.stubs(:conference_status).returns(:closed)
      post 'join', :course_id => @course.id, :conference_id => @conference.id
      response.should be_redirect
      response['Location'].should =~ /wimba\.test/
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
        WimbaConference.any_instance.expects(:active?).returns(false)
        post 'join', :course_id => @course.id, :conference_id => @conference.id
        response.should be_redirect
        response['Location'].should_not =~ /wimba\.test/
        flash[:notice].should match(/That conference is not currently active/)
      end

      describe 'when the conference is active' do
        before do
          Setting.set('enable_page_views', 'db')
          WimbaConference.any_instance.stubs(:send_request).returns('')
          WimbaConference.any_instance.stubs(:get_auth_token).returns('abc123')
          WimbaConference.any_instance.expects(:active?).returns(true)
          post 'join', :course_id => @course.id, :conference_id => @conference.id
        end

        after { Setting.set 'enable_page_views', 'false' }

        it "should let students join an active conference" do
          response.should be_redirect
          response['Location'].should =~ /wimba\.test/
        end

        it 'logs an asset access record for the discussion topic' do
          accessed_asset = assigns[:accessed_asset]
          accessed_asset[:code].should == @conference.asset_string
          accessed_asset[:category].should == 'conferences'
          accessed_asset[:level].should == 'participate'
        end

        it 'registers a page view' do
          page_view = assigns[:page_view]
          page_view.should_not be_nil
          page_view.http_method.should == 'post'
          page_view.url.should =~ %r{^http://test\.host/courses/\d+/conferences/\d+/join}
          page_view.participated.should be_true
        end

      end
    end

  end
end
