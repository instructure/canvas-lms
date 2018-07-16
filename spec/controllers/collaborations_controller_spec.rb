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

describe CollaborationsController do
  before :once do
    plugin_setting = PluginSetting.new(:name => "etherpad", :settings => {})
    plugin_setting.save!
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)

    group_model(:context => @course)
  end

  describe "GET 'index'" do
    it "should require authorization" do
      get 'index', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>16,'hidden'=>true}])
      get 'index', params: {:course_id => @course.id}
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "should assign variables" do
      user_session(@student)
      allow(controller).to receive(:google_drive_connection).and_return(double(authorized?:true))

      get 'index', params: {:course_id => @course.id}

      expect(response).to be_successful
      expect(assigns(:user_has_google_drive)).to eq true
    end

    it "should handle users without google authorized" do
      user_session(@student)
      allow(controller).to receive(:google_drive_connection).and_return(double(authorized?:false))

      get 'index', params: {:course_id => @course.id}

      expect(response).to be_successful
      expect(assigns(:user_has_google_drive)).to eq false
    end

    it 'handles users that need to upgrade to google_drive' do
      user_session(@student)
      plugin = Canvas::Plugin.find(:google_drive)
      plugin_setting = PluginSetting.find_by_name(plugin.id) || PluginSetting.new(:name => plugin.id, :settings => plugin.default_settings)
      plugin_setting.posted_settings = {}
      plugin_setting.save!
      get 'index', params: {:course_id => @course.id}

      expect(response).to be_successful
      expect(assigns(:user_has_google_drive)).to be false
    end

    it "should not allow the student view student to access collaborations" do
      course_with_teacher_logged_in(:active_user => true)
      expect(@course).not_to be_available
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      get 'index', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should work with groups" do
      user_session(@student)
      gc = group_category
      group = gc.groups.create!(:context => @course)
      group.add_user(@student, 'accepted')

      #allow(controller).to receive(:google_docs_connection).and_return(double(authorized?:false))

      get 'index', params: {:group_id => group.id}
      expect(response).to be_successful
    end

    it "only returns collaborations that the user has access to read" do
      user_session(@student)
      collab1 = @course.collaborations.create!(
        title: "inaccessible",
        user: @teacher
      ).tap{ |c| c.update_attribute :url, 'http://www.example.com' }

      collab2 = @course.collaborations.create!(
        title: "accessible",
        user: @student
      ).tap{ |c| c.update_attribute :url, 'http://www.example.com' }


      get 'index', params: {course_id: @course.id}

      expect(assigns[:collaborations]).to eq [collab2]
    end

  end

  describe "GET 'members'" do
    before(:each) do
      @collab = @course.collaborations.create!(
        title: "accessible",
        user: @student,
        url: 'http://www.example.com'
      )
      @collab.reload
    end

    it "should require authorization" do
      get 'members', params: {id: @collab.id}
      assert_unauthorized
    end

    context "with user access token" do
      before(:each) do
        pseudonym(@student)
        @student.save!
        token = @student.access_tokens.create!(purpose: 'test').full_token
        @request.headers['Authorization'] = "Bearer #{token}"
      end

      it "should return back collaboration members" do
        get 'members', params: {id: @collab.id}
        hash = JSON.parse(@response.body).first

        expect(hash['id']).to eq @collab.collaborators.first.id
        expect(hash['type']).to eq 'user'
        expect(hash['name']).to eq @student.sortable_name
        expect(hash['collaborator_id']).to eq @student.id
      end

      it "should include collaborator_lti_id" do
        get 'members', params: {id: @collab.id, include: ['collaborator_lti_id']}
        @student.reload
        hash = JSON.parse(@response.body).first

        expect(hash['collaborator_lti_id']).to eq @student.lti_context_id
      end

      it "should include avatar_image_url" do
        @student.avatar_image_url = 'https://www.example.com/awesome-avatar.png'
        @student.save!
        get 'members', params: {id: @collab.id, include: ['avatar_image_url']}
        hash = JSON.parse(@response.body).first

        expect(hash['avatar_image_url']).to eq @student.avatar_image_url
      end
    end
  end

  describe "GET 'lti_index'" do
    it "should require authorization for the course" do
      get 'lti_index', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should require authorization for the group" do
      get 'lti_index', params: {:group_id => @group.id}
      assert_unauthorized
    end
  end


  describe "GET 'show'" do
    let(:collaboration) do
      @course.collaborations.create!(
        title: "my collab",
        user: @teacher
      ).tap{ |c| c.update_attribute :url, 'http://www.example.com' }
    end

    it 'redirects to the lti launch url for ExternalToolCollaborations' do
      course_with_teacher(:active_all => true)
      user_session(@teacher)
      collab = ExternalToolCollaboration.new(
        title: "my collab",
        user: @teacher,
        url: 'http://www.example.com'
      )
      collab.context = @course
      collab.save!
      get 'show', params: {:course_id=>@course.id, :id => collab.id}
      url = CGI::escape(collab[:url])
      expect(response).to redirect_to "/courses/#{@course.id}/external_tools/retrieve?display=borderless&url=#{url}"
    end

    context "logged in user" do
      before :once do
        Setting.set('enable_page_views', 'db')
        course_with_teacher(:active_all => true)
      end

      before :each do
        user_session(@teacher)
        get 'show', params: {:course_id=>@course.id, :id => collaboration.id}
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

    context "logged out user" do
      it 'rejects access properly' do
        get 'show', params: {course_id: @course.id, id: collaboration.id}

        expect(response.status).to eq 302
        expect(response.headers['Location']).to match(/login/)
      end
    end
  end

  describe "POST 'create'" do
    before(:once) { course_with_teacher(active_all: true) }

    it "should require authorization" do
      post 'create', params: {:course_id => @course.id, :collaboration => {}}
      assert_unauthorized
    end

    it "should fail with invalid collaboration type" do
      user_session(@teacher)
      post 'create', params: {:course_id => @course.id, :collaboration => {:title => "My Collab"}}
      assert_status(500)
    end

    it "should create collaboration" do
      user_session(@teacher)
      post 'create', params: {:course_id => @course.id, :collaboration => {:collaboration_type => 'EtherPad', :title => "My Collab"}}
      expect(response).to be_redirect
      expect(assigns[:collaboration]).not_to be_nil
      expect(assigns[:collaboration].class).to eql(EtherpadCollaboration)
      expect(assigns[:collaboration].collaboration_type).to eql('EtherPad')
      expect(Collaboration.find(assigns[:collaboration].id)).to be_is_a(EtherpadCollaboration)
    end

    context "content_items" do

      let(:content_items) do
        [
          {
            title: 'my collab',
            text: 'collab description',
            url: 'http://example.invalid/test',
            confirmUrl: 'http://example.com/confirm/343'
          }
        ]
      end

      it "should create a collaboration using content-item" do
        user_session(@teacher)

        post 'create', params: {:course_id => @course.id, :contentItems => content_items.to_json}
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(assigns[:collaboration]).not_to be_nil
        expect(assigns[:collaboration].class).to eql(ExternalToolCollaboration)
        expect(collaboration).to be_is_a(ExternalToolCollaboration)
        expect(collaboration.title).to eq content_items.first[:title]
        expect(collaboration.description).to eq content_items.first[:text]
        expect(collaboration.url).to eq content_items[0][:url]
      end

      it "callback url should not be nil if provided" do
        user_session(@teacher)
        post 'create', params: {:course_id => @course.id, :contentItems => content_items.to_json}
        collaboration = ExternalToolCollaboration.last
        expect(collaboration.data["confirmUrl"]).to eq 'http://example.com/confirm/343'
      end

      it "should callback on success" do
        user_session(@teacher)
        content_item_util_stub = double('ContentItemUtil')
        expect(content_item_util_stub).to receive(:success_callback)
        allow(Lti::ContentItemUtil).to receive(:new).and_return(content_item_util_stub)
        post 'create', params: {:course_id => @course.id, :contentItems => content_items.to_json}
      end

      it "should callback on failure" do
        user_session(@teacher)
        expect_any_instance_of(Collaboration).to receive(:save).and_return(false)
        content_item_util_stub = double('ContentItemUtil')
        expect(content_item_util_stub).to receive(:failure_callback)
        allow(Lti::ContentItemUtil).to receive(:new).and_return(content_item_util_stub)
        post 'create', params: {:course_id => @course.id, :contentItems => content_items.to_json}
      end

      it "adds users if sent" do
        user_session(@teacher)
        users = 2.times.map { |_| student_in_course(course: @course, active_all: true).user}
        lti_user_ids = users.map {|student| Lti::Asset.opaque_identifier_for(student)}
        content_items.first['ext_canvas_visibility'] = {users: lti_user_ids}
        post 'create', params: {:course_id => @course.id, :contentItems => content_items.to_json}
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(collaboration.collaborators.map(&:user_id)).to match_array([*users, @teacher].map(&:id))
      end

      it "adds groups if sent" do
        user_session(@teacher)
        group = group_model(:context => @course)
        group.add_user(@teacher, 'active')
        content_items.first['ext_canvas_visibility'] = {groups: [Lti::Asset.opaque_identifier_for(group)]}
        post 'create', params: {:course_id => @course.id, :contentItems => content_items.to_json}
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(collaboration.collaborators.map(&:group_id).compact).to match_array([group.id])
      end

    end

  end

  describe "PUT #update" do
    context "content_items" do
      let(:collaboration) do
        collab = @course.collaborations.create!(
          title: "a collab",
          user: @teacher
        )
        collab.update_attribute :url, 'http://www.example.com'
        collab.update_attribute :type, "ExternalToolCollaboration"
        collab
      end

      let(:content_items) do
        [
          {
            title: 'my collab',
            text: 'collab description',
            url: 'http://example.invalid/test',
            confirmUrl: 'http://example.com/confirm/343'
          }
        ]
      end

      it "should update a collaboration using content-item" do
        user_session(@teacher)
        put 'update', params: {id: collaboration.id, :course_id => @course.id, :contentItems => content_items.to_json}
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(assigns[:collaboration]).not_to be_nil
        expect(assigns[:collaboration].class).to eql(ExternalToolCollaboration)
        expect(collaboration).to be_is_a(ExternalToolCollaboration)
        expect(collaboration.title).to eq content_items.first[:title]
        expect(collaboration.description).to eq content_items.first[:text]
        expect(collaboration.url).to eq content_items[0][:url]
      end

      it "callback url should not be nil if provided" do
        user_session(@teacher)
        put 'update', params: {id: collaboration.id, :course_id => @course.id, :contentItems => content_items.to_json}
        c = ExternalToolCollaboration.find(collaboration.id)
        expect(c.data["confirmUrl"]).to eq 'http://example.com/confirm/343'
      end

      it "should callback on success" do
        user_session(@teacher)
        content_item_util_stub = double('ContentItemUtil')
        expect(content_item_util_stub).to receive(:success_callback)
        allow(Lti::ContentItemUtil).to receive(:new).and_return(content_item_util_stub)
        put 'update', params: {id: collaboration.id, :course_id => @course.id, :contentItems => content_items.to_json}
      end

      it "should callback on failure" do
        user_session(@teacher)
        allow_any_instance_of(Collaboration).to receive(:save).and_return(false)
        content_item_util_stub = double('ContentItemUtil')
        expect(content_item_util_stub).to receive(:failure_callback)
        allow(Lti::ContentItemUtil).to receive(:new).and_return(content_item_util_stub)
        put 'update', params: {id: collaboration.id, :course_id => @course.id, :contentItems => content_items.to_json}
      end

      it "adds users if sent" do
        user_session(@teacher)
        users = 2.times.map { |_| student_in_course(course: @course, active_all: true).user}
        lti_user_ids = users.map {|student| Lti::Asset.opaque_identifier_for(student)}
        content_items.first['ext_canvas_visibility'] = {users: lti_user_ids}
        put 'update', params: {id: collaboration.id, :course_id => @course.id, :contentItems => content_items.to_json}
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(collaboration.collaborators.map(&:user_id)).to match_array([*users, @teacher].map(&:id))
      end

      it "adds groups if sent" do
        user_session(@teacher)
        group = group_model(:context => @course)
        group.add_user(@teacher, 'active')
        content_items.first['ext_canvas_visibility'] = {groups: [Lti::Asset.opaque_identifier_for(group)]}
        put 'update', params: {id: collaboration.id, :course_id => @course.id, :contentItems => content_items.to_json}
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(collaboration.collaborators.map(&:group_id).compact).to match_array([group.id])
      end

      it "adds each group only once on multiple requests" do
        user_session(@teacher)
        group = group_model(:context => @course)
        group.add_user(@teacher, 'active')
        content_items.first['ext_canvas_visibility'] = {
          groups: [Lti::Asset.opaque_identifier_for(group)],
          users: [Lti::Asset.opaque_identifier_for(@teacher)]
        }
        2.times {
          put 'update', params: {id: collaboration.id, :course_id => @course.id, :contentItems => content_items.to_json}
        }
        collaboration = Collaboration.find(assigns[:collaboration].id)

        expect(collaboration.collaborators.map(&:group_id).compact).to match_array([group.id])
      end
    end
  end

end
