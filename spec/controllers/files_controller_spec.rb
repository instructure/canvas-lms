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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def new_valid_tool(course)
  tool = course.context_external_tools.new(
      name: "bob",
      consumer_key: "bob",
      shared_secret: "bob",
      tool_id: 'some_tool',
      privacy_level: 'public'
  )
  tool.url = "http://www.example.com/basic_lti"
  tool.resource_selection = {
      :url => "http://#{HostUrl.default_host}/selection_test",
      :selection_width => 400,
      :selection_height => 400}
  tool.save!
  tool
end

describe FilesController do
  def course_folder
    @folder = @course.folders.create!(:name => "a folder", :workflow_state => "visible")
  end

  def io
    fixture_file_upload('scribd_docs/doc.doc', 'application/msword', true)
  end

  def course_file
    @file = factory_with_protected_attributes(@course.attachments, :uploaded_data => io)
  end

  def user_file
    @file = factory_with_protected_attributes(@user.attachments, :uploaded_data => io)
  end

  def folder_file
    @file = @folder.active_file_attachments.build(:uploaded_data => io)
    @file.context = @course
    @file.save!
    @file
  end

  def file_in_a_module
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({:type => 'attachment', :id => @file.id})
    @module.reload
    hash = {}
    hash[@tag.id.to_s] = {:type => 'must_view'}
    @module.completion_requirements = hash
    @module.save!
  end

  def file_with_path(path)
    components = path.split('/')
    folder = nil
    while components.size > 1
      component = components.shift
      folder = @course.folders.where(name: component).first
      folder ||= @course.folders.create!(:name => component, :workflow_state => "visible", :parent_folder => folder)
    end
    filename = components.shift
    @file = folder.active_file_attachments.build(:filename => filename, :uploaded_data => io)
    @file.context = @course
    @file.save!
    @file
  end

  before :once do
    @other_user = user_factory(active_all: true)
    course_with_teacher active_all: true
    student_in_course active_all: true
  end

  describe "GET 'quota'" do
    it "should require authorization" do
      get 'quota', :course_id => @course.id
      assert_unauthorized
    end

    it "should assign variables for course quota" do
      user_session(@teacher)
      get 'quota', :course_id => @course.id
      expect(assigns[:quota]).not_to be_nil
      expect(response).to be_success
    end

    it "should assign variables for user quota" do
      user_session(@student)
      get 'quota', :user_id => @student.id
      expect(assigns[:quota]).not_to be_nil
      expect(response).to be_success
    end

    it "should assign variables for group quota" do
      user_session(@teacher)
      group_model(:context => @course)
      get 'quota', :group_id => @group.id
      expect(assigns[:quota]).not_to be_nil
      expect(response).to be_success
    end

    it "should allow changing group quota" do
      user_session(@teacher)
      group_model(:context => @course, :storage_quota => 500.megabytes)
      get 'quota', :group_id => @group.id
      expect(assigns[:quota]).to eq 500.megabytes
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    it "should require authorization" do
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>11,'hidden'=>true}])
      get 'index', :course_id => @course.id
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "should assign variables" do
      user_session(@teacher)
      get 'index', :course_id => @course.id
      expect(response).to be_success
      expect(assigns[:contexts]).not_to be_nil
      expect(assigns[:contexts][0]).to eql(@course)
    end

    it "should return a json format for wiki sidebar" do
      user_session(@teacher)
      r1 = Folder.root_folders(@course).first
      f1 = course_folder
      a1 = folder_file
      get 'index', :course_id => @course.id, :format => 'json'
      expect(response).to be_success
      data = json_parse
      expect(data).not_to be_nil
      # order expected
      expect(data["folders"].map{|x| x["folder"]["id"]}).to eql([r1.id, f1.id])
    end

    it "should work for a user context, too" do
      user_session(@student)
      get 'index', :user_id => @student.id
      expect(response).to be_success
    end

    it "should work for a group context, too" do
      group_with_user_logged_in(:group_context => Account.default)
      get 'index', :group_id => @group.id
      expect(response).to be_success
    end

    it "should not show external tools in a group context" do
      group_with_user_logged_in(:group_context => Account.default)
      new_valid_tool(@course)
      user_file
      @file.context = @group
      get 'index', :group_id => @group.id
      expect(assigns[:js_env][:FILES_CONTEXTS][0][:file_menu_tools]).to eq []
    end

    context "file menu tool visibility" do
      before do
        course_factory(active_all: true)
        @tool = @course.context_external_tools.create!(:name => "a", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
        @tool.file_menu = {
          :visibility => "admins"
        }
        @tool.save!
        Account.default.enable_feature!(:lor_for_account)
      end

      before :each do
        user_factory(active_all: true)
        user_session(@user)
      end

      it "should show restricted external tools to teachers" do
        @course.enroll_teacher(@user).accept!

        get 'index', :course_id => @course.id
        expect(assigns[:js_env][:FILES_CONTEXTS][0][:file_menu_tools].count).to eq 1
      end

      it "should not show restricted external tools to students" do
        @course.enroll_student(@user).accept!

        get 'index', :course_id => @course.id
        expect(assigns[:js_env][:FILES_CONTEXTS][0][:file_menu_tools]).to eq []
      end
    end

    describe 'across shards' do
      specs_require_sharding

      before :once do
        @shard2.activate do
          user_factory(active_all: true)
        end
      end

      before :each do
        user_session(@user)
      end

      it "authorizes users on a remote shard" do
        get 'index', :user_id => @user.global_id
        expect(response).to be_success
      end

      it "authorizes users on a remote shard for JSON data" do
        get 'index', :user_id => @user.global_id, :format => :json
        expect(response).to be_success
      end
    end
  end

  describe "GET 'show'" do
    before :once do
      course_file
    end

    it "should require authorization" do
      get 'show', :course_id => @course.id, :id => @file.id
      assert_unauthorized
    end

    describe "with verifiers" do
      it "should allow public access with legacy verifier" do
        Attachment.any_instance.stubs(:canvadoc_url).returns "stubby"
        get 'show', :course_id => @course.id, :id => @file.id, :verifier => @file.uuid, :format => 'json'
        expect(response).to be_success
        expect(json_parse['attachment']).to_not be_nil
        expect(json_parse['attachment']['canvadoc_session_url']).to eq "stubby"
        expect(json_parse['attachment']['md5']).to be_nil
      end

      it "should allow public access with new verifier" do
        verifier = Attachments::Verification.new(@file).verifier_for_user(nil)
        get 'show', :course_id => @course.id, :id => @file.id, :verifier => verifier, :format => 'json'
        expect(response).to be_success
        expect(json_parse['attachment']).to_not be_nil
        expect(json_parse['attachment']['md5']).to be_nil
      end

      it "should not redirect to terms-acceptance page" do
        user_session(@teacher)
        session[:require_terms] = true
        verifier = Attachments::Verification.new(@file).verifier_for_user(@teacher)
        get 'show', :course_id => @course.id, :id => @file.id, :verifier => verifier, :format => 'json'
        expect(response).to be_success
      end
    end

    it "should assign variables" do
      user_session(@teacher)
      get 'show', :course_id => @course.id, :id => @file.id
      expect(response).to be_success
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment]).to eql(@file)
    end

    it "should redirect for download" do
      user_session(@teacher)
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1
      expect(response).to be_redirect
    end

    it "should force download when download_frd is set" do
      user_session(@teacher)
      # this call should happen inside of FilesController#send_attachment
      FilesController.any_instance.expects(:send_stored_file).with(@file, false, true)
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1, :verifier => @file.uuid, :download_frd => 1
    end

    it "should remember most recent sf_verifier in session" do
      user1 = user_factory(active_all: true)
      file1 = user_file
      ts1, sf_verifier1 = user1.access_verifier

      user2 = user_factory(active_all: true)
      file2 = user_file
      ts2, sf_verifier2 = user2.access_verifier

      # first verifier
      user_session(user1)
      get 'show', :user_id => user1.id, :id => file1.id, :ts => ts1, :sf_verifier => sf_verifier1
      expect(response).to be_success

      expect(session[:file_access_user_id]).to eq user1.id
      expect(session[:file_access_expiration]).not_to be_nil
      expect(session[:permissions_key]).not_to be_nil
      permissions_key = session[:permissions_key]

      # second verifier, should update session
      get 'show', :user_id => user2.id, :id => @file.id, :ts => ts2, :sf_verifier => sf_verifier2
      expect(response).to be_success

      expect(session[:file_access_user_id]).to eq user2.id
      expect(session[:file_access_expiration]).not_to be_nil
      expect(session[:permissions_key]).not_to eq permissions_key
      permissions_key = session[:permissions_key]

      # repeat access, even without verifier, should extend expiration (though
      # we can't assert that, because milliseconds) and thus change
      # permissions_key
      get 'show', :user_id => user2.id, :id => @file.id
      expect(response).to be_success

      expect(session[:permissions_key]).not_to eq permissions_key
    end

    it "should set cache headers for non text files" do
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1, :verifier => @file.uuid, :download_frd => 1
      expect(response.header["Cache-Control"]).to include "private, max-age"
      expect(response.header["Cache-Control"]).not_to include "no-cache"
      expect(response.header["Cache-Control"]).not_to include "no-store"
      expect(response.header["Cache-Control"]).not_to include "max-age=0"
      expect(response.header["Cache-Control"]).not_to include "must-revalidate"
      expect(response.header).to include("Expires")
      expect(response.header).not_to include("Pragma")
    end

    it "should not set cache headers for text files" do
      @file.content_type = "text/html"
      @file.save
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1, :verifier => @file.uuid, :download_frd => 1
      expect(response.header["Cache-Control"]).not_to include "private, max-age"
      expect(response.header["Cache-Control"]).to include "no-cache"
      expect(response.header["Cache-Control"]).to include "no-store"
      expect(response.header["Cache-Control"]).to include "max-age=0"
      expect(response.header["Cache-Control"]).to include "must-revalidate"
      expect(response.header).not_to include("Expires")
      expect(response.header).to include("Pragma")
    end

    it "should allow concluded teachers to read and download files" do
      user_session(@teacher)
      @enrollment.conclude
      get 'show', :course_id => @course.id, :id => @file.id
      expect(response).to be_success
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1
      expect(response).to be_redirect
    end

    it "should find overwritten files" do
      @old_file = @course.attachments.build(display_name: 'old file')
      @old_file.file_state = 'deleted'
      @old_file.replacement_attachment = @file
      @old_file.save!

      user_session(@teacher)
      get 'show', course_id: @course.id, id: @old_file.id, preview: 1
      expect(response).to be_redirect
      expect(response.location).to match /\/courses\/#{@course.id}\/files\/#{@file.id}/
    end

    describe "as a student" do
      before do
        user_session(@student)
      end

      it "should allow concluded students to read and download files" do
        @enrollment.conclude
        get 'show', :course_id => @course.id, :id => @file.id
        expect(response).to be_success
        get 'show', :course_id => @course.id, :id => @file.id, :download => 1
        expect(response).to be_redirect
      end

      it "should mark files as viewed for module progressions if the file is previewed inline" do
        file_in_a_module
        get 'show', :course_id => @course.id, :id => @file.id, :inline => 1
        expect(json_parse).to eq({'ok' => true})
        @module.reload
        expect(@module.evaluate_for(@student).state).to eql(:completed)
      end

      it "should mark files as viewed for module progressions if the file is downloaded" do
        file_in_a_module
        get 'show', :course_id => @course.id, :id => @file.id, :download => 1
        @module.reload
        expect(@module.evaluate_for(@student).state).to eql(:completed)
      end

      it "should mark files as viewed for module progressions if the file data is requested and is canvadocable" do
        file_in_a_module
        Attachment.any_instance.stubs(:canvadocable?).returns true
        get 'show', :course_id => @course.id, :id => @file.id, :format => :json
        @module.reload
        expect(@module.evaluate_for(@student).state).to eql(:completed)
      end

      it "should mark media files viewed when rendering html with file_preview" do
        @file = attachment_model(:context => @course, :uploaded_data => stub_file_data('test.m4v', 'asdf', 'video/mp4'))
        file_in_a_module
        get 'show', :course_id => @course.id, :id => @file.id, :format => :html
        @module.reload
        expect(@module.evaluate_for(@student).state).to eql(:completed)
      end

      it "should redirect to the user's files URL when browsing to an attachment with the same path as a deleted attachment" do
        owned_file = course_file
        owned_file.display_name = 'holla'
        owned_file.user_id = @student.id
        owned_file.save
        owned_file.destroy
        get 'show', :course_id => @course.id, :id => owned_file.id
        expect(response).to be_redirect
        expect(flash[:notice]).to match(/has been deleted/)
        expect(URI.parse(response['Location']).path).to eq "/courses/#{@course.id}/files"
      end

      it 'displays a new file without incident' do
        new_file = course_file
        new_file.display_name = 'holla'
        new_file.save

        get 'show', :course_id => @course.id, :id => new_file.id
        expect(response).to be_success
        expect(assigns(:attachment)).to eq new_file
      end

      it "does not leak the name of unowned deleted files" do
        unowned_file = @file
        unowned_file.display_name = 'holla'
        unowned_file.save
        unowned_file.destroy

        get 'show', :course_id => @course.id, :id => unowned_file.id
        expect(response.status).to eq(404)
        expect(assigns(:not_found_message)).to eq("This file has been deleted")
      end

      it "does not blow up for logged out users" do
        unowned_file = @file
        unowned_file.display_name = 'holla'
        unowned_file.save
        unowned_file.destroy

        remove_user_session
        get 'show', :course_id => @course.id, :id => unowned_file.id
        expect(response.status).to eq(404)
        expect(assigns(:not_found_message)).to eq("This file has been deleted")
      end

      it "should view file when student's submission was deleted" do
        @assignment = @course.assignments.create!(title: 'upload_assignment', submission_types: 'online_upload')
        attachment_model context: @student
        @assignment.submit_homework @student, attachments: [@attachment]
        # create an orphaned attachment_association
        @assignment.submissions.delete_all
        get 'show', user_id: @student.id, id: @attachment.id, download_frd: 1
        expect(response).to be_success
      end
    end

    describe "as a teacher" do
      before do
        user_session @teacher
      end

      it "should work for quiz_statistics" do
        quiz_model
        file = @quiz.statistics_csv('student_analysis').csv_attachment
        get 'show', :quiz_statistics_id => file.reload.context.id,
          :file_id => file.id, :download => '1', :verifier => file.uuid
        expect(response).to be_redirect
      end

      it "should record the inline view when a teacher previews a student's submission" do
        @assignment = @course.assignments.create!(:title => 'upload_assignment', :submission_types => 'online_upload')
        attachment_model :context => @student
        @assignment.submit_homework @student, :attachments => [@attachment]
        get 'show', :user_id => @student.id, :id => @attachment.id, :inline => 1
        expect(response).to be_success
      end
    end

    describe "canvadoc_session_url" do
      before do
        user_session(@student)
        Canvadocs.stubs(:enabled?).returns true
        @file = canvadocable_attachment_model
      end

      it "is included if :download is allowed" do
        get 'show', :course_id => @course.id, :id => @file.id, :format => 'json'
        expect(json_parse['attachment']['canvadoc_session_url']).to be_present
      end

      it "is not included if locked" do
        @file.lock_at = 1.month.ago
        @file.save!
        get 'show', :course_id => @course.id, :id => @file.id, :format => 'json'
        expect(json_parse['attachment']['canvadoc_session_url']).to be_nil
      end

      it "is included in newly uploaded files" do
        user_session(@teacher)
        post 'create', :format => 'json', :course_id => @course.id, :attachment => {:display_name => "bob", :uploaded_data => io}
        expect(json_parse['attachment']['canvadoc_session_url']).to be_present
      end
    end
  end

  describe "GET 'show_relative'" do
    before(:once) do
      course_file
      file_in_a_module
    end

    context "as student" do
      before(:each) do
        user_session(@student)
      end

      it "should find files by relative path" do
        get "show_relative", :course_id => @course.id, :file_path => @file.full_display_path
        expect(response).to be_redirect
        get "show_relative", :course_id => @course.id, :file_path => @file.full_path
        expect(response).to be_redirect

        def test_path(path)
          file_with_path(path)
          get "show_relative", :course_id => @course.id, :file_path => @file.full_display_path
          expect(response).to be_redirect
          get "show_relative", :course_id => @course.id, :file_path => @file.full_path
          expect(response).to be_redirect
        end

        test_path("course files/unfiled/test1.txt")
        test_path("course files/blah")
        test_path("course files/a/b/c%20dude/d/e/f.gif")
      end

      it "should render unauthorized access page if the file path doesn't match" do
        get "show_relative", :course_id => @course.id, :file_path => @file.full_display_path+"blah"
        expect(response).to render_template("shared/errors/file_not_found")
        get "show_relative", :file_id => @file.id, :course_id => @course.id, :file_path => @file.full_display_path+"blah"
        expect(response).to render_template("shared/errors/file_not_found")
      end

      it "should render file_not_found even if the format is non-html" do
        get "show_relative", :file_id => @file.id, :course_id => @course.id, :file_path => @file.full_display_path+".css", :format => 'css'
        expect(response).to render_template("shared/errors/file_not_found")
      end

      it "should ignore bad file_ids" do
        get "show_relative", :file_id => @file.id + 1, :course_id => @course.id, :file_path => @file.full_display_path
        expect(response).to be_redirect
        get "show_relative", :file_id => "blah", :course_id => @course.id, :file_path => @file.full_display_path
        expect(response).to be_redirect
      end
    end

    context "unauthenticated user" do
      it "renders unauthorized if the file exists" do
        get "show_relative", :course_id => @course.id, :file_path => @file.full_display_path
        assert_unauthorized
      end

      it "renders unauthorized if the file doesn't exist" do
        get "show_relative", :course_id => @course.id, :file_path => "course files/nope"
        assert_unauthorized
      end
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', :course_id => @course.id, :attachment => {:display_name => "bob"}
      assert_unauthorized
    end

    it "should create file" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :attachment => {:display_name => "bob", :uploaded_data => io}
      expect(response).to be_redirect
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].display_name).to eql("bob")
    end

    it "should create unpublished files if usage rights required" do
      @course.account.allow_feature! :usage_rights_required
      @course.enable_feature! :usage_rights_required
      user_session(@teacher)
      post 'create', :course_id => @course.id, :attachment => {:display_name => "wat", :uploaded_data => io}
      expect(assigns[:attachment]).to be_locked
    end

    it "should reject an upload that would exceed quota" do
      user_session(@teacher)
      Setting.set('user_default_quota', 7) # seven... seven bytes.
      post 'create', :user_id => @teacher.id, :format => :json, :attachment => {:display_name => "bob", :uploaded_data => io}
      expect(response.status).to eq 400
      expect(response.body).to include 'quota exceeded'
    end

    it "does not check quota for local-storage submission uploads" do
      local_storage!
      user_session(@student)
      Setting.set('user_default_quota', 7)
      file = @student.attachments.build
      file.file_state = 'deleted'
      file.workflow_state = 'unattached'
      file.save!
      post 'create', :user_id => @student.id,
           :format => 'json',
           :check_quota_after => '0',
           :filename => 'submission.doc',
           :attachment => {
             :unattached_attachment_id => file.id,
             :uploaded_data => io
           }
      expect(response).to be_success
      expect(file.reload).to be_available
    end

    it "refuses to create a file in a submissions folder" do
      user_session(@student)
      post 'create', :user_id => @student.id, :format => :json, :attachment => {:display_name => 'blah', :uploaded_data => io, :folder_id => @student.submissions_folder.id}
      expect(response.status).to eq 401
    end

    context "sharding" do
      specs_require_sharding

      it "should create when an unattached file is on another shard" do
        root_attachment = factory_with_protected_attributes(Attachment, :context => @course, :file_state => 'deleted', :workflow_state => 'unattached', :filename => 'test.txt', :content_type => 'text')
        root_attachment.uploaded_data = io
        root_attachment.save!

        @shard1.activate do
          @student = user_factory(active_user: true)
          @attachment = factory_with_protected_attributes(Attachment, :context => @student, :file_state => 'deleted', :workflow_state => 'unattached', :filename => 'test.txt', :content_type => 'text')
        end

        @course.enroll_user(@student, "StudentEnrollment").accept!
        @assignment = @course.assignments.create!(:title => 'upload_assignment', :submission_types => 'online_upload')

        user_session(@student)
        post 'create', :attachment => {:display_name => "bob", :uploaded_data => io, :unattached_attachment_id => @attachment.id}
        expect(response).to be_redirect
        expect(assigns[:attachment]).not_to be_nil
        expect(assigns[:attachment].display_name).to eql("bob")
        expect(assigns[:attachment].shard).to eql @shard1
      end
    end
  end

  describe "PUT 'update'" do
    before :once do
      course_file
    end

    it "should require authorization" do
      put 'update', :course_id => @course.id, :id => @file.id
      assert_unauthorized
    end

    it "should update file" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @file.id, :attachment => {:display_name => "new name", :uploaded_data => nil}
      expect(response).to be_redirect
      expect(assigns[:attachment]).to eql(@file)
      expect(assigns[:attachment].display_name).to eql("new name")
      expect(assigns[:attachment].user_id).to be_nil
    end

    it "should move file into a folder" do
      user_session(@teacher)
      course_folder

      put 'update', :course_id => @course.id, :id => @file.id, :attachment => { :folder_id => @folder.id }, :format => 'json'
      expect(response).to be_success

      @file.reload
      expect(@file.folder).to eql(@folder)
    end

    context "submissions folder" do
      before(:once) do
        @student = user_model
        @root_folder = Folder.root_folders(@student).first
        @file = attachment_model(:context => @user, :uploaded_data => default_uploaded_data, :folder => @root_folder)
        @sub_folder = @student.submissions_folder
        @sub_file = attachment_model(:context => @user, :uploaded_data => default_uploaded_data, :folder => @sub_folder)
      end

      it "should not move a file into a submissions folder" do
        user_session(@student)
        put 'update', :user_id => @student.id, :id => @file.id, :attachment => { :folder_id => @sub_folder.id }, :format => 'json'
        expect(response.status).to eq 401
      end

      it "should not move a file out of a submissions folder" do
        user_session(@student)
        put 'update', :user_id => @student.id, :id => @sub_file.id, :attachment => { :folder_id => @root_folder.id }, :format => 'json'
        expect(response.status).to eq 401
      end
    end

    it "should replace content and update user_id" do
      course_with_teacher_logged_in(:active_all => true)
      course_file
      new_content = default_uploaded_data
      put 'update', :course_id => @course.id, :id => @file.id, :attachment => {:uploaded_data => new_content}
      expect(response).to be_redirect
      expect(assigns[:attachment]).to eql(@file)
      @file.reload
      expect(@file.size).to eql new_content.size
      expect(@file.user).to eql @teacher
    end

    context "usage_rights_required" do
      before do
        @course.enable_feature! :usage_rights_required
        user_session(@teacher)
        @file.update_attribute(:locked, true)
      end

      it "should not publish if usage_rights unset" do
        put 'update', :course_id => @course.id, :id => @file.id, :attachment => {:locked => "false"}
        expect(@file.reload).to be_locked
      end

      it "should publish if usage_rights set" do
        @file.usage_rights = @course.usage_rights.create! use_justification: 'public_domain'
        @file.save!
        put 'update', :course_id => @course.id, :id => @file.id, :attachment => {:locked => "false"}
        expect(@file.reload).not_to be_locked
      end
    end
  end

  describe "DELETE 'destroy'" do
    context "authorization" do
      before :once do
        course_file
      end

      it "should require authorization" do
        delete 'destroy', :course_id => @course.id, :id => @file.id
        expect(response.body).to eql("{\"message\":\"Unauthorized to delete this file\"}")
        expect(assigns[:attachment].file_state).to eq 'available'
      end

      it "should delete file" do
        user_session(@teacher)
        delete 'destroy', :course_id => @course.id, :id => @file.id
        expect(response).to be_redirect
        expect(assigns[:attachment]).to eql(@file)
        expect(assigns[:attachment].file_state).to eq 'deleted'
      end
    end

    it "refuses to delete a file in a submissions folder" do
      file = @student.attachments.create! :display_name => 'blah', :uploaded_data => default_uploaded_data, :folder => @student.submissions_folder
      delete 'destroy', :user_id => @student.id, :id => file.id
      expect(response.status).to eq 401
    end

    context "file that has been submitted" do
      def submit_file
        assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_upload")
        @file = attachment_model(:context => @user, :uploaded_data => stub_file_data('test.txt', 'asdf', 'text/plain'))
        assignment.submit_homework(@student, :attachments => [@file])
      end

      before :once do
        submit_file
      end

      before :each do
        user_session(@student)
      end

      it "should not delete" do
        delete 'destroy', :id => @file.id
        expect(response.body).to eql("{\"message\":\"Cannot delete a file that has been submitted as part of an assignment\"}")
        expect(assigns[:attachment].file_state).to eq 'available'
      end
    end
  end

  describe "POST 'create_pending'" do
    it "should require authorization" do
      user_session(@other_user)
      post 'create_pending', {:attachment => {:context_code => @course.asset_string}}
      assert_unauthorized
    end

    it "should require a pseudonym" do
      post 'create_pending', {:attachment => {:context_code => @course.asset_string}}
      expect(response).to redirect_to login_url
    end

    it "should create file placeholder (in local mode)" do
      local_storage!
      user_session(@teacher)
      post 'create_pending', {:attachment => {
        :context_code => @course.asset_string,
        :filename => "bob.txt"
      }}
      expect(response).to be_success
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].id).not_to be_nil
      expect(assigns[:attachment][:user_id]).not_to be_nil
      json = json_parse
      expect(json).not_to be_nil
      expect(json['id']).to eql(assigns[:attachment].id)
      expect(json['upload_url']).not_to be_nil
      expect(json['upload_params']).not_to be_nil
      expect(json['upload_params']).not_to be_empty
    end

    it "should create file placeholder (in s3 mode)" do
      s3_storage!
      user_session(@teacher)
      post 'create_pending', {:attachment => {
        :context_code => @course.asset_string,
        :filename => "bob.txt"
      }}
      expect(response).to be_success
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].id).not_to be_nil
      expect(assigns[:attachment][:user_id]).not_to be_nil
      json = json_parse
      expect(json).not_to be_nil
      expect(json['id']).to eql(assigns[:attachment].id)
      expect(json['upload_url']).not_to be_nil
      expect(json['upload_params']).to be_present
      expect(json['upload_params']['x-amz-credential']).to start_with('stub_id')
    end

    it "should not allow going over quota for file uploads" do
      s3_storage!
      user_session(@student)
      Setting.set('user_default_quota', -1)
      post 'create_pending', {:attachment => {
        :context_code => @student.asset_string,
        :filename => "bob.txt"
      }}
      expect(response).to be_redirect
      expect(assigns[:quota_used]).to be > assigns[:quota]
    end

    it "should allow going over quota for homework submissions" do
      s3_storage!
      user_session(@student)
      @assignment = @course.assignments.create!(:title => 'upload_assignment', :submission_types => 'online_upload')
      Setting.set('user_default_quota', -1)
      post 'create_pending', {:attachment => {
        :context_code => @assignment.context_code,
        :asset_string => @assignment.asset_string,
        :intent => 'submit',
        :filename => "bob.txt"
      }, :format => :json}
      expect(response).to be_success
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].id).not_to be_nil
      json = json_parse
      expect(json).not_to be_nil
      expect(json['id']).to eql(assigns[:attachment].id)
      expect(json['upload_url']).not_to be_nil
      expect(json['upload_params']).to be_present
      expect(json['upload_params']['x-amz-credential']).to start_with('stub_id')
    end

    it "should associate assignment submission for a group assignment with the group" do
      user_session(@student)
      category = group_category
      assignment = @course.assignments.create(:group_category => category, :submission_types => 'online_upload')
      group = category.groups.create(:context => @course)
      group.add_user(@student)
      user_session(@student)

      #assignment.grants_right?(@student, :submit).should be_true
      #assignment.grants_right?(@student, :nothing).should be_true

      s3_storage!
      post 'create_pending', {:attachment => {
        :context_code => @course.asset_string,
        :asset_string => assignment.asset_string,
        :intent => 'submit',
        :filename => "bob.txt"
      }}
      expect(response).to be_success

      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].context).to eq group
    end

    it "should create the file in unlocked state if :usage_rights_required is disabled" do
      @course.disable_feature! :usage_rights_required
      user_session(@teacher)
      post 'create_pending', {:attachment => {
          :context_code => @course.asset_string,
          :filename => "bob.txt"
      }}
      expect(response).to be_success
      expect(assigns[:attachment].locked).to be_falsy
    end

    it "should create the file in locked state if :usage_rights_required is enabled" do
      @course.enable_feature! :usage_rights_required
      user_session(@teacher)
      post 'create_pending', {:attachment => {
          :context_code => @course.asset_string,
          :filename => "bob.txt"
      }}
      expect(response).to be_success
      expect(assigns[:attachment].locked).to be_truthy
    end

    it "refuses to create a file in a submissions folder" do
      user_session(@student)
      post 'create_pending', {:attachment => {
        :context_code => @student.asset_string,
        :filename => 'test.txt',
        :folder_id => @student.submissions_folder.id
      }}
      expect(response.status).to eq 401
    end

    it "creates a file in the submissions folder if intent=='submit' and the feature is enabled" do
      @course.root_account.enable_feature! :submissions_folder
      user_session(@student)
      assignment = @course.assignments.create!(:submission_types => 'online_upload')
      post 'create_pending', {:attachment => {
        :context_code => assignment.context_code,
        :asset_string => assignment.asset_string,
        :filename => 'test.txt',
        :intent => 'submit'
      }}
      f = assigns[:attachment].folder
      expect(f.submission_context_code).to eq @course.asset_string
    end

    it "uses a submissions folder for group assignments when the feature is enabled" do
      @course.root_account.enable_feature! :submissions_folder
      user_session(@student)
      category = group_category
      assignment = @course.assignments.create(:group_category => category, :submission_types => 'online_upload')
      group = category.groups.create(:context => @course)
      group.add_user(@student)
      user_session(@student)
      post 'create_pending', {:attachment => {
        :context_code => @course.asset_string,
        :asset_string => assignment.asset_string,
        :intent => 'submit',
        :filename => "bob.txt"
      }}
      expect(response).to be_success
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].context).to eq group
      expect(assigns[:attachment].folder).to be_for_submissions
    end

    it "does not require usage rights for group submissions to be visible to students" do
      @course.root_account.enable_feature! :submissions_folder
      @course.root_account.enable_feature! :usage_rights_required
      user_session(@student)
      category = group_category
      assignment = @course.assignments.create(:group_category => category, :submission_types => 'online_upload')
      group = category.groups.create(:context => @course)
      group.add_user(@student)
      user_session(@student)
      post 'create_pending', {:attachment => {
        :context_code => @course.asset_string,
        :asset_string => assignment.asset_string,
        :intent => 'submit',
        :filename => "bob.txt"
      }}
      expect(response).to be_success
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment]).not_to be_locked
    end

    context "sharding" do
      specs_require_sharding

      it "should create the attachment on the context's shard" do
        local_storage!
        @shard1.activate do
          account = Account.create!
          course_with_teacher_logged_in(:active_all => true, :account => account)
        end
        post 'create_pending', {:attachment => {
                                 :context_code => @course.asset_string,
                                 :filename => "bob.txt"
                             }}
        expect(response).to be_success
        expect(assigns[:attachment]).not_to be_nil
        expect(assigns[:attachment].id).not_to be_nil
        expect(assigns[:attachment].shard).to eq @shard1
        json = json_parse
        expect(json).not_to be_nil
        expect(json['id']).to eql(assigns[:attachment].id)
        expect(json['upload_url']).not_to be_nil
        expect(json['upload_params']).not_to be_nil
        expect(json['upload_params']).not_to be_empty
      end

      it "should create the attachment on the user's shard when submitting" do
        local_storage!
        account = Account.create!
        @shard1.activate do
          @student = user_factory(active_user: true)
        end
        course_factory(active_all: true, :account => account)
        @course.enroll_user(@student, "StudentEnrollment").accept!
        @assignment = @course.assignments.create!(:title => 'upload_assignment', :submission_types => 'online_upload')

        user_session(@student)
        post 'create_pending', {:attachment => {
                                 :context_code => @course.asset_string,
                                 :asset_string => @assignment.asset_string,
                                 :intent => 'submit',
                                 :filename => "bob.txt"
                             }}
        expect(response).to be_success
        expect(assigns[:attachment]).not_to be_nil
        expect(assigns[:attachment].id).not_to be_nil
        expect(assigns[:attachment].shard).to eq @shard1
        json = json_parse
        expect(json).not_to be_nil
        expect(json['id']).to eql(assigns[:attachment].id)
        expect(json['upload_url']).not_to be_nil
        expect(json['upload_params']).not_to be_nil
        expect(json['upload_params']).not_to be_empty
      end
    end
  end

  describe "POST 'api_create'" do
    before :once do
      # this endpoint does not need a logged-in user or api token auth, it's
      # based completely on the policy signature
      pseudonym(@teacher)
      @attachment = factory_with_protected_attributes(Attachment, :context => @course, :file_state => 'deleted', :workflow_state => 'unattached', :filename => 'test.txt', :content_type => 'text')
    end

    before :each do
      @content = Rack::Test::UploadedFile.new(File.join(ActionController::TestCase.fixture_path, 'courses.yml'), '')
      request.env['CONTENT_TYPE'] = 'multipart/form-data'
      enable_forgery_protection
    end

    it "should accept the upload data if the policy and attachment are acceptable" do
      params = @attachment.ajax_upload_params(@teacher.pseudonym, "", "")
      post "api_create", params[:upload_params].merge(:file => @content)
      expect(response).to be_redirect
      @attachment.reload
      # the file is not available until the third api call is completed
      expect(@attachment.file_state).to eq 'deleted'
      expect(@attachment.open.read).to eq File.read(File.join(ActionController::TestCase.fixture_path, 'courses.yml'))
    end

    it "opens up cors headers" do
      params = @attachment.ajax_upload_params(@teacher.pseudonym, "", "")
      post "api_create", params[:upload_params].merge(:file => @content)
      expect(response.header["Access-Control-Allow-Origin"]).to eq "*"
    end

    it "has a preflight point for options requests (mostly safari)" do
      process :api_create_success_cors, 'OPTIONS', id: ""
      expect(response.header['Access-Control-Allow-Headers']).to eq('Origin, X-Requested-With, Content-Type, Accept, Authorization, Accept-Encoding')
    end

    it "should reject a blank policy" do
      post "api_create", { :file => @content }
      assert_status(400)
    end

    it "should reject an expired policy" do
      params = @attachment.ajax_upload_params(@teacher.pseudonym, "", "", :expiration => -60.seconds)
      post "api_create", params[:upload_params].merge({ :file => @content })
      assert_status(400)
    end

    it "should reject a modified policy" do
      params = @attachment.ajax_upload_params(@teacher.pseudonym, "", "")
      params[:upload_params]['Policy'] << 'a'
      post "api_create", params[:upload_params].merge({ :file => @content })
      assert_status(400)
    end

    it "should reject a good policy if the attachment data is already uploaded" do
      params = @attachment.ajax_upload_params(@teacher.pseudonym, "", "")
      @attachment.uploaded_data = @content
      @attachment.save!
      post "api_create", params[:upload_params].merge(:file => @content)
      assert_status(400)
    end
  end

  describe "public_url" do
    before :once do
      assignment_model :course => @course, :submission_types => %w(online_upload)
      attachment_model :context => @student
      @submission = @assignment.submit_homework @student, :attachments => [@attachment]
    end

    context "with direct rights" do
      before :each do
        user_session @student
      end

      it "should give a download url" do
        get "public_url", :id => @attachment.id
        expect(response).to be_success
        data = json_parse
        expect(data).to eq({ "public_url" => @attachment.authenticated_s3_url })
      end
    end

    context "without direct rights" do
      before :each do
        user_session @teacher
      end

      it "should fail if no submission_id is given" do
        get "public_url", :id => @attachment.id
        assert_unauthorized
      end

      it "should allow a teacher to download a student's submission" do
        get "public_url", :id => @attachment.id, :submission_id => @submission.id
        expect(response).to be_success
        data = json_parse
        expect(data).to eq({ "public_url" => @attachment.authenticated_s3_url })
      end

      it "should verify that the requested file belongs to the submission" do
        otherfile = attachment_model
        get "public_url", :id => otherfile, :submission_id => @submission.id
        assert_unauthorized
      end

      it "allows downloading an attachment to a previous version" do
        old_file = @attachment
        new_file = attachment_model(:context => @student)
        @assignment.submit_homework @student, :attachments => [new_file]
        get "public_url", :id => old_file.id, :submission_id => @submission.id
        expect(response).to be_success
        data = json_parse
        expect(data).to eq({ "public_url" => old_file.authenticated_s3_url })
      end
    end
  end
end
