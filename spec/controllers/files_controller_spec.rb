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
    course_with_student_logged_in(:active_all => true)
    @file = factory_with_protected_attributes(@course.attachments, :uploaded_data => io)
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({:type => 'attachment', :id => @file.id}) 
    @module.reload
    hash = {}
    hash[@tag.id.to_s] = {:type => 'must_view'}
    @module.completion_requirements = hash
    @module.save!
    @module.evaluate_for(@user, true).state.should eql(:unlocked)
  end

  def file_with_path(path)
    components = path.split('/')
    folder = nil
    while components.size > 1
      component = components.shift
      folder = @course.folders.find_by_name(component)
      folder ||= @course.folders.create!(:name => component, :workflow_state => "visible", :parent_folder => folder)
    end
    filename = components.shift
    @file = folder.active_file_attachments.build(:filename => filename, :uploaded_data => io)
    @file.context = @course
    @file.save!
    @file
  end

  describe "GET 'quota'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'quota', :course_id => @course.id
      assert_unauthorized
    end

    it "should assign variables for course quota" do
      course_with_teacher_logged_in(:active_all => true)
      get 'quota', :course_id => @course.id
      assigns[:quota].should_not be_nil
      response.should be_success
    end

    it "should assign variables for user quota" do
      user(:active_all => true)
      user_session(@user)
      get 'quota', :user_id => @user.id
      assigns[:quota].should_not be_nil
      response.should be_success
    end

    it "should assign variables for group quota" do
      course_with_teacher_logged_in(:active_all => true)
      group_model(:context => @course)
      get 'quota', :group_id => @group.id
      assigns[:quota].should_not be_nil
      response.should be_success
    end

    it "should allow changing group quota" do
      course_with_teacher_logged_in(:active_all => true)
      group_model(:context => @course, :storage_quota => 500.megabytes)
      get 'quota', :group_id => @group.id
      assigns[:quota].should == 500.megabytes
      response.should be_success
    end
  end

  describe "GET 'index'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:tab_configuration, [{'id'=>11,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end

    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      get 'index', :course_id => @course.id
      response.should be_success
      assigns[:contexts].should_not be_nil
      assigns[:contexts][0].should eql(@course)
    end

    it "should return data for sub_folder if specified" do
      course_with_teacher_logged_in(:active_all => true)
      f1 = course_folder
      a1 = folder_file
      get 'index', :course_id => @course.id, :format => 'json'
      response.should be_success
      data = json_parse
      data.should_not be_nil
      data['contexts'].length.should eql(1)
      data['contexts'][0]['course']['id'].should eql(@course.id)

      f2 = course_folder
      a2 = folder_file
      get 'index', :course_id => @course.id, :folder_id => f2.id, :format => 'json'
      response.should be_success
      assigns[:current_folder].should eql(f2)
      assigns[:current_attachments].should_not be_nil
      assigns[:current_attachments].should_not be_empty
      assigns[:current_attachments][0].should eql(a2)
    end

    it "should work for a user context, too" do
      user(:active_all => true)
      user_session(@user)
      get 'index', :user_id => @user.id
      response.should be_success
    end

    it "should work for a group context, too" do
      group_with_user_logged_in(:group_context => Account.default)
      get 'index', :group_id => @group.id
      response.should be_success
    end

    describe 'across shards' do
      specs_require_sharding

      before do
        @shard2.activate do
          user(:active_all => true)
        end
        user_session(@user)
      end

      it "authorizes users on a remote shard" do
        get 'index', :user_id => @user.global_id
        response.should be_success
      end

      it "authorizes users on a remote shard for JSON data" do
        get 'index', :user_id => @user.global_id, :format => :json
        response.should be_success
      end
    end
  end

  describe "GET 'show'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_file
      get 'show', :course_id => @course.id, :id => @file.id
    end

    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      course_file
      get 'show', :course_id => @course.id, :id => @file.id
      response.should be_success
      assigns[:attachment].should_not be_nil
      assigns[:attachment].should eql(@file)
    end

    it "should redirect for download" do
      course_with_teacher_logged_in(:active_all => true)
      course_file
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1
      response.should be_redirect
    end

    it "should force download when download_frd is set" do
      course_with_teacher_logged_in(:active_all => true)
      course_file
      # this call should happen inside of FilesController#send_attachment
      FilesController.any_instance.expects(:send_stored_file).with(@file, false, true)
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1, :verifier => @file.uuid, :download_frd => 1
    end

    it "should set cache headers for non text files" do
      course_with_teacher(:active_all => true)
      course_file
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1, :verifier => @file.uuid, :download_frd => 1
      response.header["Cache-Control"].should include "private, max-age"
      response.header["Cache-Control"].should_not include "no-cache"
      response.header["Cache-Control"].should_not include "no-store"
      response.header["Cache-Control"].should_not include "max-age=0"
      response.header["Cache-Control"].should_not include "must-revalidate"
      response.header.should include("Expires")
      response.header.should_not include("Pragma")
    end

    it "should not set cache headers for text files" do
      course_with_teacher(:active_all => true)
      course_file
      @file.content_type = "text/html"
      @file.save
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1, :verifier => @file.uuid, :download_frd => 1
      response.header["Cache-Control"].should_not include "private, max-age"
      response.header["Cache-Control"].should include "no-cache"
      response.header["Cache-Control"].should include "no-store"
      response.header["Cache-Control"].should include "max-age=0"
      response.header["Cache-Control"].should include "must-revalidate"
      response.header.should_not include("Expires")
      response.header.should include("Pragma")
    end

    it "should allow concluded teachers to read and download files" do
      course_with_teacher_logged_in(:active_all => true)
      course_file
      @enrollment.conclude
      get 'show', :course_id => @course.id, :id => @file.id
      response.should be_success
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1
      response.should be_redirect
    end

    it "should allow concluded students to read and download files" do
      course_with_student_logged_in(:active_all => true)
      course_file
      @enrollment.conclude
      get 'show', :course_id => @course.id, :id => @file.id
      response.should be_success
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1
      response.should be_redirect
    end

    it "should mark files as viewed for module progressions if the file is downloaded" do
      file_in_a_module
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1
      @module.reload
      @module.evaluate_for(@user, true).state.should eql(:completed)
      @file.reload.last_inline_view.should be_nil
    end

    it "should not mark a file as viewed for module progressions if the file is locked" do
      file_in_a_module
      @file.locked = true
      @file.save!
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1
      @module.reload
      @module.evaluate_for(@user, true).state.should eql(:unlocked)
      @file.reload.last_inline_view.should be_nil
    end

    it "should not mark a file as viewed for module progressions just because the files#show view is rendered" do
      file_in_a_module
      @file.locked = true
      @file.save!
      get 'show', :course_id => @course.id, :id => @file.id
      @module.reload
      @module.evaluate_for(@user, true).state.should eql(:unlocked)
      @file.reload.last_inline_view.should be_nil
    end

    it "should mark files as viewed for module progressions if the file is previewed inline" do
      file_in_a_module
      get 'show', :course_id => @course.id, :id => @file.id, :inline => 1
      json_parse.should == {'ok' => true}
      @module.reload
      @module.evaluate_for(@user, true).state.should eql(:completed)
      @file.reload.last_inline_view.should > 1.minute.ago
    end

    it "should record the inline view when a teacher previews a student's submission" do
      course_with_student :active_all => true
      @assignment = @course.assignments.create!(:title => 'upload_assignment', :submission_types => 'online_upload')
      attachment_model :context => @student
      @assignment.submit_homework @student, :attachments => [@attachment]

      teacher_in_course :active_all => true
      user_session @teacher
      get 'show', :user_id => @student.id, :id => @attachment.id, :inline => 1
      response.should be_success
      @attachment.reload.last_inline_view.should > 1.minute.ago
    end

    it "should mark files as viewed for module progressions if the file data is requested and it includes the scribd_doc data" do
      file_in_a_module
      @file.scribd_doc = Scribd::Document.new
      @file.save!
      get 'show', :course_id => @course.id, :id => @file.id, :format => :json
      @module.reload
      @module.evaluate_for(@user, true).state.should eql(:completed)
      @file.reload.last_inline_view.should > 1.minute.ago
    end

    it "should not mark files as viewed for module progressions if the file data is requested and it doesn't include the scribd_doc data (meaning it got viewed in scribd inline) and google docs preview is disabled" do
      file_in_a_module
      @file.scribd_doc = nil
      @file.save!

      # turn off google docs previews for this acccount so we can isolate testing just scribd.
      account = Account.default
      account.disable_service(:google_docs_previews)
      account.save!

      get 'show', :course_id => @course.id, :id => @file.id, :format => :json
      @module.reload
      @module.evaluate_for(@user, true).state.should eql(:unlocked)
      @file.reload.last_inline_view.should be_nil
    end

    it "should redirect to the user's files URL when browsing to an attachment with the same path as a deleted attachment" do
      course_with_student_logged_in(:active_all => true)
      unowned_file = course_file
      unowned_file.display_name = 'holla'
      unowned_file.save
      unowned_file.destroy

      get 'show', :course_id => @course.id, :id => unowned_file.id
      assert_unauthorized

      owned_file = course_file
      owned_file.display_name = 'holla'
      owned_file.user_id = @user.id
      owned_file.save
      owned_file.destroy

      get 'show', :course_id => @course.id, :id => owned_file.id
      response.should be_redirect
      flash[:notice].should match(/has been deleted/)
      URI.parse(response['Location']).path.should == "/courses/#{@course.id}/files"

      new_file = course_file
      new_file.display_name = 'holla'
      new_file.save

      get 'show', :course_id => @course.id, :id => new_file.id
      response.should be_success
      assigns(:attachment).should == new_file
    end

    it "should work for quiz_statistics" do
      course_with_teacher_logged_in(:active_all => true)
      quiz_model
      file = @quiz.statistics_csv('student_analysis').csv_attachment
      get 'show', :quiz_statistics_id => file.reload.context.id,
        :file_id => file.id, :download => '1', :verifier => file.uuid
      response.should be_redirect
    end

    describe "scribd_doc" do
      before do
        course_with_student_logged_in(:active_all => true)
        @file = attachment_model(:scribd_doc => Scribd::Document.new, :uploaded_data => stub_png_data)
      end

      it "should be included if :download is allowed" do
        get 'show', :course_id => @course.id, :id => @file.id, :format => 'json'
        json_parse['attachment']['scribd_doc'].should be_present
      end

      it "should not be included if locked" do
        @file.lock_at = 1.month.ago
        @file.save!
        get 'show', :course_id => @course.id, :id => @file.id, :format => 'json'
        json_parse['attachment']['scribd_doc'].should be_blank
      end

      it "should not be included for locked attachments with a root_attachment" do
        @file.lock_at = 1.month.ago
        @file.save!
        course2 = course(:active_all => true)
        course2.enroll_student(@student).accept!
        file2 = @file.clone_for(course2)
        file2.save!
        file2.scribd_doc.should be_present
        file2.locked_for?(@student).should be_true

        get 'show', :course_id => course2.id, :id => file2.id, :format => 'json'
        json_parse['attachment']['scribd_doc'].should be_blank
      end
    end

  end

  describe "GET 'show_relative'" do
    it "should find files by relative path" do
      course_with_teacher_logged_in(:active_all => true)

      file_in_a_module
      get "show_relative", :course_id => @course.id, :file_path => @file.full_display_path
      response.should be_redirect
      get "show_relative", :course_id => @course.id, :file_path => @file.full_path
      response.should be_redirect

      def test_path(path)
        file_with_path(path)
        get "show_relative", :course_id => @course.id, :file_path => @file.full_display_path
        response.should be_redirect
        get "show_relative", :course_id => @course.id, :file_path => @file.full_path
        response.should be_redirect
      end

      test_path("course files/unfiled/test1.txt")
      test_path("course files/blah")
      test_path("course files/a/b/c%20dude/d/e/f.gif")
    end

    it "should fail if the file path doesn't match" do
      course_with_teacher_logged_in(:active_all => true)
      file_in_a_module
      assert_page_not_found do
        get "show_relative", :course_id => @course.id, :file_path => @file.full_display_path+"blah"
      end

      assert_page_not_found do
        get "show_relative", :file_id => @file.id, :course_id => @course.id, :file_path => @file.full_display_path+"blah"
      end
    end

    it "should ignore bad file_ids" do
      course_with_teacher_logged_in(:active_all => true)
      file_in_a_module
      get "show_relative", :file_id => @file.id + 1, :course_id => @course.id, :file_path => @file.full_display_path
      response.should be_redirect
      get "show_relative", :file_id => "blah", :course_id => @course.id, :file_path => @file.full_display_path
      response.should be_redirect
    end
  end

  describe "GET 'new'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'new', :course_id => @course.id
      assert_unauthorized
    end

    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      get 'new', :course_id => @course.id
      assigns[:attachment].should_not be_nil
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'create', :course_id => @course.id, :attachment => {:display_name => "bob"}
      assert_unauthorized
    end

    it "should create file" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :attachment => {:display_name => "bob", :uploaded_data => io}
      response.should be_redirect
      assigns[:attachment].should_not be_nil
      assigns[:attachment].display_name.should eql("bob")
    end
  end

  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_file
      put 'update', :course_id => @course.id, :id => @file.id
      assert_unauthorized
    end

    it "should update file" do
      course_with_teacher_logged_in(:active_all => true)
      course_file
      put 'update', :course_id => @course.id, :id => @file.id, :attachment => {:display_name => "new name", :uploaded_data => nil}
      response.should be_redirect
      assigns[:attachment].should eql(@file)
      assigns[:attachment].display_name.should eql("new name")
    end

    it "should move file into a folder" do
      course_with_teacher_logged_in(:active_all => true)
      course_file
      course_folder

      put 'update', :course_id => @course.id, :id => @file.id, :attachment => { :folder_id => @folder.id }, :format => 'json'
      response.should be_success

      @file.reload
      @file.folder.should eql(@folder)
    end
  end

  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_file
      delete 'destroy', :course_id => @course.id, :id => @file.id
    end

    it "should delete file" do
      course_with_teacher_logged_in(:active_all => true)
      course_file
      delete 'destroy', :course_id => @course.id, :id => @file.id
      response.should be_redirect
      assigns[:attachment].should eql(@file)
      assigns[:attachment].file_state.should == 'deleted'
    end
  end

  describe "POST 'create_pending'" do
    it "should require authorization" do
      course(:active_course => true)
      user(:acitve_user => true)
      user_session(user)
      post 'create_pending', {:attachment => {:context_code => @course.asset_string}}
      assert_unauthorized
    end

    it "should require a pseudonym" do
      course_with_teacher(:active_all => true)
      post 'create_pending', {:attachment => {:context_code => @course.asset_string}}
      response.should redirect_to login_url
    end

    it "should create file placeholder (in local mode)" do
      local_storage!
      course_with_teacher_logged_in(:active_all => true)
      post 'create_pending', {:attachment => {
        :context_code => @course.asset_string,
        :filename => "bob.txt"
      }}
      response.should be_success
      assigns[:attachment].should_not be_nil
      assigns[:attachment].id.should_not be_nil
      assigns[:attachment][:user_id].should_not be_nil
      json = json_parse
      json.should_not be_nil
      json['id'].should eql(assigns[:attachment].id)
      json['upload_url'].should_not be_nil
      json['upload_params'].should_not be_nil
      json['upload_params'].should_not be_empty
    end

    it "should create file placeholder (in s3 mode)" do
      s3_storage!
      course_with_teacher_logged_in(:active_all => true)
      post 'create_pending', {:attachment => {
        :context_code => @course.asset_string,
        :filename => "bob.txt"
      }}
      response.should be_success
      assigns[:attachment].should_not be_nil
      assigns[:attachment].id.should_not be_nil
      assigns[:attachment][:user_id].should_not be_nil
      json = json_parse
      json.should_not be_nil
      json['id'].should eql(assigns[:attachment].id)
      json['upload_url'].should_not be_nil
      json['upload_params'].should be_present
      json['upload_params']['AWSAccessKeyId'].should == 'stub_id'
    end

    it "should not allow going over quota for file uploads" do
      s3_storage!
      course_with_student_logged_in(:active_all => true)
      Setting.set('user_default_quota', -1)
      post 'create_pending', {:attachment => {
        :context_code => @user.asset_string,
        :filename => "bob.txt"
      }}
      response.should be_redirect
      assigns[:quota_used].should > assigns[:quota]
    end

    it "should allow going over quota for homework submissions" do
      s3_storage!
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => 'upload_assignment', :submission_types => 'online_upload')
      Setting.set('user_default_quota', -1)
      post 'create_pending', {:attachment => {
        :context_code => @assignment.context_code,
        :asset_string => @assignment.asset_string,
        :intent => 'submit',
        :filename => "bob.txt"
      }, :format => :json}
      response.should be_success
      assigns[:attachment].should_not be_nil
      assigns[:attachment].id.should_not be_nil
      json = json_parse
      json.should_not be_nil
      json['id'].should eql(assigns[:attachment].id)
      json['upload_url'].should_not be_nil
      json['upload_params'].should be_present
      json['upload_params']['AWSAccessKeyId'].should == 'stub_id'
    end

    it "should associate assignment submission for a group assignment with the group" do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      category = group_category
      assignment = @course.assignments.create(:group_category => category, :submission_types => 'online_upload')
      group = category.groups.create(:context => @course)
      group.add_user(@student)
      user_session(@student)

      #assignment.grants_right?(@student, nil, :submit).should be_true
      #assignment.grants_right?(@student, nil, :nothing).should be_true

      s3_storage!
      post 'create_pending', {:attachment => {
        :context_code => @course.asset_string,
        :asset_string => assignment.asset_string,
        :intent => 'submit',
        :filename => "bob.txt"
      }}
      response.should be_success

      assigns[:attachment].should_not be_nil
      assigns[:attachment].context.should == group
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
        response.should be_success
        assigns[:attachment].should_not be_nil
        assigns[:attachment].id.should_not be_nil
        assigns[:attachment].shard.should == @shard1
        json = json_parse
        json.should_not be_nil
        json['id'].should eql(assigns[:attachment].id)
        json['upload_url'].should_not be_nil
        json['upload_params'].should_not be_nil
        json['upload_params'].should_not be_empty
      end
    end
  end

  describe "POST 'api_create'" do
    before do
      # this endpoint does not need a logged-in user or api token auth, it's
      # based completely on the policy signature
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      @attachment = factory_with_protected_attributes(Attachment, :context => @course, :file_state => 'deleted', :workflow_state => 'unattached', :filename => 'test.txt', :content_type => 'text')
      @content = Rack::Test::UploadedFile.new(File.join(ActionController::TestCase.fixture_path, 'courses.yml'), '')
      request.env['CONTENT_TYPE'] = 'multipart/form-data'
      enable_forgery_protection
    end

    it "should accept the upload data if the policy and attachment are acceptable" do
      params = @attachment.ajax_upload_params(@user.pseudonym, "", "")
      post "api_create", params[:upload_params].merge(:file => @content)
      response.should be_redirect
      @attachment.reload
      # the file is not available until the third api call is completed
      @attachment.file_state.should == 'deleted'
      @attachment.open.read.should == File.read(File.join(ActionController::TestCase.fixture_path, 'courses.yml'))
    end

    it "should reject a blank policy" do
      post "api_create", { :file => @content }
      assert_status(400)
    end

    it "should reject an expired policy" do
      params = @attachment.ajax_upload_params(@user.pseudonym, "", "", :expiration => -60)
      post "api_create", params[:upload_params].merge({ :file => @content })
      assert_status(400)
    end

    it "should reject a modified policy" do
      params = @attachment.ajax_upload_params(@user.pseudonym, "", "")
      params[:upload_params]['Policy'] << 'a'
      post "api_create", params[:upload_params].merge({ :file => @content })
      assert_status(400)
    end

    it "should reject a good policy if the attachment data is already uploaded" do
      params = @attachment.ajax_upload_params(@user.pseudonym, "", "")
      @attachment.uploaded_data = @content
      @attachment.save!
      post "api_create", params[:upload_params].merge(:file => @content)
      assert_status(400)
    end
  end

  describe "public_url" do
    before do
      course_with_student :active_all => true
      assignment_model :course => @course, :submission_types => %w(online_upload)
      attachment_model :context => @student
      @submission = @assignment.submit_homework @student, :attachments => [@attachment]
    end

    context "with direct rights" do
      before do
        user_session @student
      end

      it "should give a download url" do
        get "public_url", :id => @attachment.id
        response.should be_success
        data = json_parse
        data.should == { "public_url" => @attachment.authenticated_s3_url }
      end
    end

    context "without direct rights" do
      before do
        teacher_in_course :active_all => true
        user_session @teacher
      end

      it "should fail if no submission_id is given" do
        get "public_url", :id => @attachment.id
        assert_unauthorized
      end

      it "should allow a teacher to download a student's submission" do
        get "public_url", :id => @attachment.id, :submission_id => @submission.id
        response.should be_success
        data = json_parse
        data.should == { "public_url" => @attachment.authenticated_s3_url }
      end

      it "should verify that the requested file belongs to the submission" do
        otherfile = attachment_model
        get "public_url", :id => otherfile, :submission_id => @submission.id
        assert_unauthorized
      end
    end
  end
end
