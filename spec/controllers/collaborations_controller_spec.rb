#
# Copyright (C) 2011-2012 Instructure, Inc.
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

describe CollaborationsController do
  before :once do
    plugin_setting = PluginSetting.new(:name => "etherpad", :settings => {})
    plugin_setting.save!
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  describe "GET 'index'" do
    it "should require authorization" do
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>16,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end

    it "should assign variables" do
      user_session(@student)
      mock_user_service = mock()
      @user.expects(:user_services).returns(mock_user_service)
      mock_user_service.expects(:where).with(service: "google_docs").returns(stub(first: mock(token: "token", secret: "secret")))
      GoogleDocs::Connection.any_instance.expects(:verify_access_token).returns(true)

      get 'index', :course_id => @course.id

      response.should be_success
      assigns(:google_docs_authorized).should == true
    end

    it "should handle users without google authorized" do
      user_session(@student)
      mock_user_service = mock()
      @user.expects(:user_services).returns(mock_user_service)
      mock_user_service.expects(:where).with(service: "google_docs").returns(stub(first: mock(token: nil, secret: nil)))

      get 'index', :course_id => @course.id

      response.should be_success
      assigns(:google_docs_authorized).should == false
    end

    it "should assign variables when verify raises" do
      user_session(@student)
      mock_user_service = mock()
      @user.expects(:user_services).returns(mock_user_service)
      mock_user_service.expects(:where).with(service: "google_docs").returns(stub(first: mock(token: "token", secret: "secret")))
      GoogleDocs::Connection.any_instance.expects(:verify_access_token).raises("Error")

      get 'index', :course_id => @course.id

      response.should be_success
      assigns(:google_docs_authorized).should == false
    end

    it "should not allow the student view student to access collaborations" do
      course_with_teacher_logged_in(:active_user => true)
      @course.should_not be_available
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should work with groups" do
      user_session(@student)
      gc = group_category
      group = gc.groups.create!(:context => @course)
      group.add_user(@student, 'accepted')

      mock_user_service = mock()
      @user.expects(:user_services).returns(mock_user_service)
      mock_user_service.expects(:where).with(service: "google_docs").returns(stub(first: mock(token: "token", secret: "secret")))

      get 'index', :group_id => group.id
      response.should be_success
    end
  end

  describe "GET 'show'" do
    let(:collab_course) { course_with_teacher_logged_in(:active_all => true); @course }
    let(:collaboration) { collab_course.collaborations.create!(title: "my collab", user: @teacher).tap{ |c| c.update_attribute :url, 'http://www.example.com' } }

    before :once do
      Setting.set('enable_page_views', 'db')
      course_with_teacher(:active_all => true)
    end

    before :each do
      user_session(@teacher)
      get 'show', :course_id=>collab_course.id, :id => collaboration.id
    end

    it 'loads the correct collaboration' do
      assigns(:collaboration).should == collaboration
    end

    it 'logs an asset access record for the discussion topic' do
      accessed_asset = assigns[:accessed_asset]
      accessed_asset[:code].should == collaboration.asset_string
      accessed_asset[:category].should == 'collaborations'
      accessed_asset[:level].should == 'participate'
    end

    it 'registers a page view' do
      page_view = assigns[:page_view]
      page_view.should_not be_nil
      page_view.http_method.should == 'get'
      page_view.url.should =~ %r{^http://test\.host/courses/\d+/collaborations}
      page_view.participated.should be_true
    end

  end

  describe "POST 'create'" do
    before(:once) { course_with_teacher(active_all: true) }

    it "should require authorization" do
      post 'create', :course_id => @course.id, :collaboration => {}
      assert_unauthorized
    end

    it "should fail with invalid collaboration type" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :collaboration => {:title => "My Collab"}
      assert_status(500)
    end

    it "should create collaboration" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :collaboration => {:collaboration_type => 'EtherPad', :title => "My Collab"}
      response.should be_redirect
      assigns[:collaboration].should_not be_nil
      assigns[:collaboration].class.should eql(EtherpadCollaboration)
      assigns[:collaboration].collaboration_type.should eql('EtherPad')
      Collaboration.find(assigns[:collaboration].id).should be_is_a(EtherpadCollaboration)
    end
  end
end
