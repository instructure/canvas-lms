#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe AssignmentsController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    course_assignment
  end

  def course_assignment(course = nil)
    course ||= @course
    @group = course.assignment_groups.create(:name => "some group")
    @assignment = course.assignments.create(:title => "some assignment", :assignment_group => @group)
    expect(@assignment.assignment_group).to eql(@group)
    expect(@group.assignments).to be_include(@assignment)
    @assignment
  end

  describe "GET 'index'" do
    it "should throw 404 error without a valid context id" do
      #controller.use_rails_error_handling!
      get 'index'
      assert_status(404)
    end

    it "should return unauthorized without a valid session" do
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>3,'hidden'=>true}])
      get 'index', :course_id => @course.id
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    context "draft state" do
      it "should create a default group if none exist" do
        user_session(@student)

        get 'index', :course_id => @course.id

        expect(@course.reload.assignment_groups.count).to eq 1
      end

      it "should separate manage_assignments and manage_grades permissions" do
        user_session(@teacher)
        @course.account.role_overrides.create! role: teacher_role, permission: 'manage_assignments', enabled: false
        get 'index', course_id: @course.id
        expect(assigns[:js_env][:PERMISSIONS][:manage_grades]).to be_truthy
        expect(assigns[:js_env][:PERMISSIONS][:manage_assignments]).to be_falsey
        expect(assigns[:js_env][:PERMISSIONS][:manage]).to be_falsey
        expect(assigns[:js_env][:PERMISSIONS][:manage_course]).to be_truthy
      end
    end
  end

  describe "GET 'show_moderate'" do

    it "should set the js_env for URLS" do
      user_session(@teacher)
      assignment = @course.assignments.create(:title => "some assignment")
      assignment.workflow_state = 'published'
      assignment.moderated_grading = true
      assignment.save!

      get 'show_moderate', :course_id => @course.id, :assignment_id => assignment.id
      expect(assigns[:js_env][:URLS][:student_submissions_url]).to eq "http://test.host/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions?include[]=user_summary&include[]=provisional_grades"
      expect(assigns[:js_env][:URLS][:provisional_grades_base_url]).to eq "http://test.host/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/provisional_grades"
    end

    it "should set the js_env for ASSIGNMENT_TITLE" do
      user_session(@teacher)
      assignment = @course.assignments.create(:title => "some assignment")
      assignment.workflow_state = 'published'
      assignment.moderated_grading = true
      assignment.save!

      get 'show_moderate', :course_id => @course.id, :assignment_id => assignment.id
      expect(assigns[:js_env][:ASSIGNMENT_TITLE]).to eq "some assignment"
    end
  end

  describe "GET 'show'" do
    it "should return 404 on non-existant assignment" do
      #controller.use_rails_error_handling!
      user_session(@student)

      get 'show', :course_id => @course.id, :id => 5
      assert_status(404)
    end

    it "should return unauthorized if not enrolled" do
      get 'show', :course_id => @course.id, :id => @assignment.id
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@student)
      a = @course.assignments.create(:title => "some assignment")

      get 'show', :course_id => @course.id, :id => a.id
      expect(@course.reload.assignment_groups).not_to be_empty
      expect(assigns[:unlocked]).not_to be_nil
    end

    it "should assign submission variable if current user and submitted" do
      user_session(@student)
      @assignment.submit_homework(@student, :submission_type => 'online_url', :url => 'http://www.google.com')
      get 'show', :course_id => @course.id, :id => @assignment.id
      expect(response).to be_success
      expect(assigns[:current_user_submission]).not_to be_nil
    end

    it "should redirect to wiki page if assignment is linked to wiki page" do
      @course.enable_feature!(:conditional_release)
      user_session(@student)
      @assignment.reload.submission_types = 'wiki_page'
      @assignment.save!

      get 'show', :course_id => @course.id, :id => @assignment.id
      expect(response).to be_redirect
    end

    it "should not redirect to wiki page" do
      @course.disable_feature!(:conditional_release)
      user_session(@student)
      @assignment.submission_types = 'wiki_page'
      @assignment.save!

      get 'show', :course_id => @course.id, :id => @assignment.id
      expect(response).not_to be_redirect
    end

    it "should redirect to discussion if assignment is linked to discussion" do
      user_session(@student)
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!

      get 'show', :course_id => @course.id, :id => @assignment.id
      expect(response).to be_redirect
    end

    it "should not redirect to discussion for observer if assignment is linked to discussion but read_forum is false" do
      course_with_observer(:active_all => true, :course => @course)
      user_session(@observer)
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!

      RoleOverride.create!(:context => @course.account, :permission => 'read_forum',
                           :role => observer_role, :enabled => false)

      get 'show', :course_id => @course.id, :id => @assignment.id
      expect(response).not_to be_redirect
      expect(response).to be_success
    end

    it "should not show locked external tool assignments" do
      user_session(@student)

      @assignment.lock_at = Time.now - 1.week
      @assignment.unlock_at = Time.now + 1.week
      @assignment.submission_types = 'external_tool'
      @assignment.save
      # This is usually a ContentExternalTool, but it only needs to
      # be true here because we aren't redirecting to it.
      Assignment.any_instance.stubs(:external_tool_tag).returns(true)

      get 'show', :course_id => @course.id, :id => @assignment.id

      expect(assigns[:locked]).to be_truthy
      # make sure that the show.html.erb template is rendered, because
      # in normal cases we redirect to the assignment's external_tool_tag.
      expect(response).to render_template('assignments/show')
    end

    it "should require login for external tools in a public course" do
      @course.update_attribute(:is_public, true)
      @course.context_external_tools.create!(
        :shared_secret => 'test_secret',
        :consumer_key => 'test_key',
        :name => 'test tool',
        :domain => 'example.com'
      )
      @assignment.submission_types = 'external_tool'
      @assignment.build_external_tool_tag(:url => "http://example.com/test")
      @assignment.save!

      get 'show', :course_id => @course.id, :id => @assignment.id
      assert_require_login
    end

    it 'should set user_has_google_drive' do
      user_session(@student)
      a = @course.assignments.create(:title => "some assignment")
      plugin = Canvas::Plugin.find(:google_drive)
      plugin_setting = PluginSetting.find_by_name(plugin.id) || PluginSetting.new(:name => plugin.id, :settings => plugin.default_settings)
      plugin_setting.posted_settings = {}
      plugin_setting.save!
      google_drive_mock = mock('google_drive')
      google_drive_mock.stubs(:authorized?).returns(true)
      controller.stubs(:google_drive_connection).returns(google_drive_mock)
      get 'show', :course_id => @course.id, :id => a.id

      expect(response).to be_success
      expect(assigns(:user_has_google_drive)).to be true
    end

    context "page views enabled" do
      before do
        Setting.set('enable_page_views', 'db')
        @old_thread_context = Thread.current[:context]
        Thread.current[:context] = { request_id: SecureRandom.uuid }
      end

      after do
        Thread.current[:context] = @old_thread_context
      end

      it "should log an AUA as an assignment view for an external tool assignment" do
        user_session(@student)
        @course.context_external_tools.create!(
          :shared_secret => 'test_secret',
          :consumer_key => 'test_key',
          :name => 'test tool',
          :domain => 'example.com'
        )
        @assignment.submission_types = 'external_tool'
        @assignment.build_external_tool_tag(:url => "http://example.com/test")
        @assignment.save!

        get 'show', :course_id => @course.id, :id => @assignment.id
        expect(response).to be_success
        aua = AssetUserAccess.where(user_id: @student, context_type: 'Course', context_id: @course).first
        expect(aua.asset_category).to eq 'assignments'
        expect(aua.asset_code).to eq @assignment.asset_string
      end
    end

  end

  describe "GET 'syllabus'" do
    it "should require authorization" do
      #controller.use_rails_error_handling!
      get 'syllabus', :course_id => @course.id
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>1,'hidden'=>true}])
      get 'syllabus', :course_id => @course.id
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "should assign variables" do
      @course.update_attribute(:syllabus_body, "<p>Here is your syllabus.</p>")
      user_session(@student)
      get 'syllabus', :course_id => @course.id
      expect(assigns[:syllabus_body]).not_to be_nil
    end
  end

  describe "GET 'new'" do
    it "should require authorization" do
      #controller.use_rails_error_handling!
      get 'new', :course_id => @course.id
      assert_unauthorized
    end

    it "should default to unpublished for draft state" do
      @course.require_assignment_group

      get 'new', :course_id => @course.id

      expect(assigns[:assignment].workflow_state).to eq 'unpublished'
    end
  end

  describe "POST 'create'" do
    it "sets the lti_context_id if provided" do
      user_session(@student)
      lti_context_id = SecureRandom.uuid
      jwt = Canvas::Security.create_jwt(lti_context_id: lti_context_id)
      post 'create', course_id: @course.id, assignment: {title: "some assignment",secure_params: jwt}
      expect(assigns[:assignment].lti_context_id).to eq lti_context_id
    end

    it "should require authorization" do
      #controller.use_rails_error_handling!
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment"}
      assert_unauthorized
    end

    it "should create assignment" do
      user_session(@student)
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment"}
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment].title).to eql("some assignment")
      expect(assigns[:assignment].context_id).to eql(@course.id)
    end

    it "should create assignment when no groups exist yet" do
      user_session(@student)
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment", :assignment_group_id => ''}
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment].title).to eql("some assignment")
      expect(assigns[:assignment].context_id).to eql(@course.id)
    end

    it "should set updating_user on created assignment" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment", :submission_types => "discussion_topic"}
      a = assigns[:assignment]
      expect(a).not_to be_nil
      expect(a.discussion_topic).not_to be_nil
      expect(a.discussion_topic.user_id).to eql(@teacher.id)
    end

    it "should default to unpublished if draft state is enabled" do
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment"}
      expect(assigns[:assignment]).to be_unpublished
    end

    it "should assign to a group" do
      user_session(@student)
      group2 = @course.assignment_groups.create!(name: 'group2')
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment", :assignment_group_id => group2.to_param}
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment].title).to eql("some assignment")
      expect(assigns[:assignment].context_id).to eql(@course.id)
      expect(assigns[:assignment].assignment_group).to eq group2
    end

    it "should not assign to a group from a different course" do
      user_session(@student)
      course2 = Account.default.courses.create!
      group2 = course2.assignment_groups.create!(name: 'group2')
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment", :assignment_group_id => group2.to_param}
      expect(response).to be_not_found
    end
  end

  describe "GET 'edit'" do
    include_context "multiple grading periods within controller" do
      let(:course) { @course }
      let(:teacher) { @teacher }
      let(:request_params) { [:edit, course_id: course, id: @assignment] }
    end

    it "should require authorization" do
      #controller.use_rails_error_handling!
      get 'edit', :course_id => @course.id, :id => @assignment.id
      assert_unauthorized
    end

    it "should find assignment" do
      user_session(@student)
      get 'edit', :course_id => @course.id, :id => @assignment.id
      expect(assigns[:assignment]).to eql(@assignment)
    end

    it "bootstraps the correct assignment info to js_env" do
      user_session(@teacher)
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: '12345', shared_secret: 'secret')
      @assignment.tool_settings_tools = [tool]

      get 'edit', :course_id => @course.id, :id => @assignment.id
      expect(assigns[:js_env][:ASSIGNMENT]['id']).to eq @assignment.id
      expect(assigns[:js_env][:ASSIGNMENT_OVERRIDES]).to eq []
      expect(assigns[:js_env][:COURSE_ID]).to eq @course.id
      expect(assigns[:js_env][:SELECTED_CONFIG_TOOL_ID]).to eq tool.id
    end

    context "redirects" do
      before do
        user_session(@teacher)
      end

      it "to quiz" do
        assignment_quiz [], course: @course
        get 'edit', :course_id => @course.id, :id => @quiz.assignment.id
        expect(response).to redirect_to controller.edit_course_quiz_path(@course, @quiz)
      end

      it "to discussion topic" do
        group_assignment_discussion course: @course
        get 'edit', :course_id => @course.id, :id => @root_topic.assignment.id
        expect(response).to redirect_to controller.edit_course_discussion_topic_path(@course, @root_topic)
      end

      it "to wiki page" do
        Course.any_instance.stubs(:feature_enabled?).with(:conditional_release).returns(true)
        wiki_page_assignment_model course: @course
        get 'edit', :course_id => @course.id, :id => @page.assignment.id
        expect(response).to redirect_to controller.edit_course_wiki_page_path(@course, @page)
      end

      it "includes return_to" do
        assignment_quiz [], course: @course
        get 'edit', :course_id => @course.id, :id => @quiz.assignment.id, :return_to => 'flibberty'
        expect(response.redirect_url).to match(/\?return_to=flibberty/)
      end
    end

    context "conditional release" do
      before do
        ConditionalRelease::Service.stubs(:env_for).returns({ dummy: 'cr-assignment' })
      end

      it "should define env when enabled" do
        ConditionalRelease::Service.stubs(:enabled_in_context?).returns(true)
        user_session(@teacher)
        get 'edit', :course_id => @course.id, :id => @assignment.id
        expect(assigns[:js_env][:dummy]).to eq 'cr-assignment'
      end

      it "should not define env when not enabled" do
        ConditionalRelease::Service.stubs(:enabled_in_context?).returns(false)
        user_session(@teacher)
        get 'edit', :course_id => @course.id, :id => @assignment.id
        expect(assigns[:js_env][:dummy]).to be nil
      end
    end
  end

  describe "PUT 'update'" do
    it "should require authorization" do
      #controller.use_rails_error_handling!
      put 'update', :course_id => @course.id, :id => @assignment.id
      assert_unauthorized
    end

    it "should update attributes" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @assignment.id,
        :assignment_type => "attendance", :assignment => { :title => "test title" }
      expect(assigns[:assignment]).to eql(@assignment)
      expect(assigns[:assignment].title).to eql("test title")
      expect(assigns[:assignment].submission_types).to eql("attendance")
    end
  end

  describe "DELETE 'destroy'" do
    it "should require authorization" do
      delete 'destroy', :course_id => @course.id, :id => @assignment.id
      assert_unauthorized
    end

    it "should delete assignments if authorized" do
      user_session(@teacher)
      delete 'destroy', :course_id => @course.id, :id => @assignment.id
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment]).not_to be_frozen
      expect(assigns[:assignment]).to be_deleted
    end
  end

  describe "GET list_google_docs" do
    it "passes errors through to Canvas::Errors" do
      user_session(@teacher)
      connection = stub()
      connection.stubs(:list_with_extension_filter).raises(ArgumentError)
      controller.stubs(:google_drive_connection).returns(connection)
      Assignment.any_instance.stubs(:allow_google_docs_submission?).returns(true)
      Canvas::Errors.expects(:capture_exception)
      params = {course_id: @course.id, id: @assignment.id, format: 'json' }
      get 'list_google_docs', params
      expect(response.code).to eq("200")
    end
  end

end
