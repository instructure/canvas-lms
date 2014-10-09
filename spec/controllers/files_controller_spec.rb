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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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
    @other_user = user(active_all: true)
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

    it "should return data for sub_folder if specified" do
      user_session(@teacher)
      f1 = course_folder
      a1 = folder_file
      get 'index', :course_id => @course.id, :format => 'json'
      expect(response).to be_success
      data = json_parse
      expect(data).not_to be_nil
      expect(data['contexts'].length).to eql(1)
      expect(data['contexts'][0]['course']['id']).to eql(@course.id)

      f2 = course_folder
      a2 = folder_file
      get 'index', :course_id => @course.id, :folder_id => f2.id, :format => 'json'
      expect(response).to be_success
      expect(assigns[:current_folder]).to eql(f2)
      expect(assigns[:current_attachments]).not_to be_nil
      expect(assigns[:current_attachments]).not_to be_empty
      expect(assigns[:current_attachments][0]).to eql(a2)
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

    describe 'across shards' do
      specs_require_sharding

      before :once do
        @shard2.activate do
          user(:active_all => true)
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
      user1 = user(:active_all => true)
      file1 = user_file
      ts1, sf_verifier1 = user1.access_verifier

      user2 = user(:active_all => true)
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
        expect(@file.reload.last_inline_view).to be > 1.minute.ago
      end

      it "should mark files as viewed for module progressions if the file is downloaded" do
        file_in_a_module
        get 'show', :course_id => @course.id, :id => @file.id, :download => 1
        @module.reload
        expect(@module.evaluate_for(@student).state).to eql(:completed)
        expect(@file.reload.last_inline_view).to be_nil
      end

      it "should mark files as viewed for module progressions if the file is previewed inline" do
        file_in_a_module
        get 'show', :course_id => @course.id, :id => @file.id, :inline => 1
        expect(json_parse).to eq({'ok' => true})
        @module.reload
        expect(@module.evaluate_for(@student).state).to eql(:completed)
        expect(@file.reload.last_inline_view).to be > 1.minute.ago
      end

      it "should mark files as viewed for module progressions if the file data is requested and is canvadocable" do
        file_in_a_module
        Attachment.any_instance.stubs(:canvadocable?).returns true
        get 'show', :course_id => @course.id, :id => @file.id, :format => :json
        @module.reload
        expect(@module.evaluate_for(@student).state).to eql(:completed)
        expect(@file.reload.last_inline_view).to be > 1.minute.ago
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

      it "doesnt leak the name of unowned deleted files" do
        unowned_file = @file
        unowned_file.display_name = 'holla'
        unowned_file.save
        unowned_file.destroy

        get 'show', :course_id => @course.id, :id => unowned_file.id
        expect(response.status).to eq(404)
        expect(assigns(:not_found_message)).to eq("This file has been deleted")
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
        expect(@attachment.reload.last_inline_view).to be > 1.minute.ago
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
    end
  end

  describe "GET 'show_relative'" do
    before(:once) do
      course_file
      file_in_a_module
    end

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

    it "should ignore bad file_ids" do
      get "show_relative", :file_id => @file.id + 1, :course_id => @course.id, :file_path => @file.full_display_path
      expect(response).to be_redirect
      get "show_relative", :file_id => "blah", :course_id => @course.id, :file_path => @file.full_display_path
      expect(response).to be_redirect
    end
  end

  describe "GET 'new'" do
    it "should require authorization" do
      get 'new', :course_id => @course.id
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@teacher)
      get 'new', :course_id => @course.id
      expect(assigns[:attachment]).not_to be_nil
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
  end

  describe "DELETE 'destroy'" do
    before :once do
      course_file
    end

    it "should require authorization" do
      delete 'destroy', :course_id => @course.id, :id => @file.id
    end

    it "should delete file" do
      user_session(@teacher)
      delete 'destroy', :course_id => @course.id, :id => @file.id
      expect(response).to be_redirect
      expect(assigns[:attachment]).to eql(@file)
      expect(assigns[:attachment].file_state).to eq 'deleted'
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
      expect(json['upload_params']['AWSAccessKeyId']).to eq 'stub_id'
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
      expect(json['upload_params']['AWSAccessKeyId']).to eq 'stub_id'
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

    it "should reject a blank policy" do
      post "api_create", { :file => @content }
      assert_status(400)
    end

    it "should reject an expired policy" do
      params = @attachment.ajax_upload_params(@teacher.pseudonym, "", "", :expiration => -60)
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
    end
  end
end
