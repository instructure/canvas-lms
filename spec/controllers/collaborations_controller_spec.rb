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
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "should assign variables" do
      user_session(@student)
      controller.stubs(:google_docs_connection).returns(mock(verify_access_token:true))

      get 'index', :course_id => @course.id

      expect(response).to be_success
      expect(assigns(:google_docs_authorized)).to eq true
    end

    it "should handle users without google authorized" do
      user_session(@student)
      controller.stubs(:google_docs_connection).returns(mock(verify_access_token:false))

      get 'index', :course_id => @course.id

      expect(response).to be_success
      expect(assigns(:google_docs_authorized)).to eq false
    end

    it "should assign variables when verify raises" do
      user_session(@student)
      google_docs_connection_mock = mock()
      google_docs_connection_mock.expects(:verify_access_token).raises("Error")
      controller.stubs(:google_docs_connection).returns(google_docs_connection_mock)

      get 'index', :course_id => @course.id

      expect(response).to be_success
      expect(assigns(:google_docs_authorized)).to eq false
    end

    it 'handles users that need to upgrade to google_drive' do
      user_session(@student)
      plugin = Canvas::Plugin.find(:google_drive)
      plugin_setting = PluginSetting.find_by_name(plugin.id) || PluginSetting.new(:name => plugin.id, :settings => plugin.default_settings)
      plugin_setting.posted_settings = {}
      plugin_setting.save!
      get 'index', :course_id => @course.id

      expect(response).to be_success
      expect(assigns(:google_docs_authorized)).to be_falsey
      expect(assigns(:google_drive_upgrade)).to be_truthy
    end

    it "should not allow the student view student to access collaborations" do
      course_with_teacher_logged_in(:active_user => true)
      expect(@course).not_to be_available
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

      #controller.stubs(:google_docs_connection).returns(mock(verify_access_token:false))

      get 'index', :group_id => group.id
      expect(response).to be_success
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
      expect(assigns(:collaboration)).to eq collaboration
    end

    it 'logs an asset access record for the discussion topic' do
      accessed_asset = assigns[:accessed_asset]
      expect(accessed_asset[:code]).to eq collaboration.asset_string
      expect(accessed_asset[:category]).to eq 'collaborations'
      expect(accessed_asset[:level]).to eq 'participate'
    end

    it 'registers a page view' do
      page_view = assigns[:page_view]
      expect(page_view).not_to be_nil
      expect(page_view.http_method).to eq 'get'
      expect(page_view.url).to match %r{^http://test\.host/courses/\d+/collaborations}
      expect(page_view.participated).to be_truthy
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
      expect(response).to be_redirect
      expect(assigns[:collaboration]).not_to be_nil
      expect(assigns[:collaboration].class).to eql(EtherpadCollaboration)
      expect(assigns[:collaboration].collaboration_type).to eql('EtherPad')
      expect(Collaboration.find(assigns[:collaboration].id)).to be_is_a(EtherpadCollaboration)
    end
  end
end
