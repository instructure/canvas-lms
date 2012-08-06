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

describe FilesController do
  def course_folder
    @folder = @course.folders.create!(:name => "a folder", :workflow_state => "visible")
  end
  def io
    require 'action_controller'
    require 'action_controller/test_process.rb'
    ActionController::TestUploadedFile.new(File.expand_path(File.dirname(__FILE__) + '/../fixtures/scribd_docs/doc.doc'), 'application/msword', true)
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
    @module.evaluate_for(@user, true, true).state.should eql(:unlocked)
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
      get 'index', :course_id => @course.id, :folder_id => f2.id
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
      @module.evaluate_for(@user, true, true).state.should eql(:completed)
    end
    
    it "should not mark a file as viewed for module progressions if the file is locked" do
      file_in_a_module
      @file.locked = true
      @file.save!
      get 'show', :course_id => @course.id, :id => @file.id, :download => 1
      @module.reload
      @module.evaluate_for(@user, true, true).state.should eql(:unlocked)
    end
    
    it "should not mark a file as viewed for module progressions just because the files#show view is rendered" do
      file_in_a_module
      @file.locked = true
      @file.save!
      get 'show', :course_id => @course.id, :id => @file.id
      @module.reload
      @module.evaluate_for(@user, true, true).state.should eql(:unlocked)
    end
    
    it "should mark files as viewed for module progressions if the file is previewed inline" do
      file_in_a_module
      get 'show', :course_id => @course.id, :id => @file.id, :inline => 1
      json_parse.should == {'ok' => true}
      @module.reload
      @module.evaluate_for(@user, true, true).state.should eql(:completed)
    end
    
    it "should mark files as viewed for module progressions if the file data is requested and it includes the scribd_doc data" do
      file_in_a_module
      @file.scribd_doc = Scribd::Document.new
      @file.save!
      get 'show', :course_id => @course.id, :id => @file.id, :format => :json
      @module.reload
      @module.evaluate_for(@user, true, true).state.should eql(:completed)
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
      @module.evaluate_for(@user, true, true).state.should eql(:unlocked)
    end

    it "should redirect to an existing attachment with the same path as a deleted attachment" do
      course_with_student_logged_in(:active_all => true)
      old_file = course_file
      old_file.display_name = 'holla'
      old_file.save
      old_file.destroy

      get 'show', :course_id => @course.id, :id => old_file.id
      response.should be_redirect
      flash[:notice].should match(/has been deleted/)
      URI.parse(response['Location']).path.should == "/courses/#{@course.id}/files"

      new_file = course_file
      new_file.display_name = 'holla'
      new_file.save

      get 'show', :course_id => @course.id, :id => old_file.id
      response.should be_success
      assigns(:attachment).should == new_file
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
      proc { get "show_relative", :course_id => @course.id, :file_path => @file.full_display_path+"blah" }.should raise_error(ActiveRecord::RecordNotFound)
      proc { get "show_relative", :file_id => @file.id, :course_id => @course.id, :file_path => @file.full_display_path+"blah" }.should raise_error(ActiveRecord::RecordNotFound)
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
      json = json_parse
      json.should_not be_nil
      json['id'].should eql(assigns[:attachment].id)
      json['upload_url'].should_not be_nil
      json['upload_params'].should_not be_nil
      json['upload_params'].should_not be_empty
      json['remote_url'].should eql(false)
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
      json = json_parse
      json.should_not be_nil
      json['id'].should eql(assigns[:attachment].id)
      json['upload_url'].should_not be_nil
      json['upload_params'].should be_present
      json['upload_params']['AWSAccessKeyId'].should == 'stub_id'
      json['remote_url'].should eql(true)
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
      json['remote_url'].should eql(true)
    end

    it "should associate assignment submission for a group assignment with the group" do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      category = @course.group_categories.create
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
  end

  describe "POST 'api_create'" do
    before do
      # this endpoint does not need a logged-in user or api token auth, it's
      # based completely on the policy signature
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      @attachment = factory_with_protected_attributes(Attachment, :context => @course, :file_state => 'deleted', :workflow_state => 'unattached', :filename => 'test.txt', :content_type => 'text')
      @content = StringIO.new("test file")
      enable_forgery_protection true
      request.env['CONTENT_TYPE'] = 'multipart/form-data'
    end

    after do
      enable_forgery_protection false
    end

    it "should accept the upload data if the policy and attachment are acceptable" do
      params = @attachment.ajax_upload_params(@user.pseudonym, "", "")
      post "api_create", params[:upload_params].merge(:file => @content)
      response.should be_redirect
      @attachment.reload
      @attachment.workflow_state.should == 'processed'
      # the file is not available until the third api call is completed
      @attachment.file_state.should == 'deleted'
      @attachment.open.read.should == "test file"
    end

    it "should reject a blank policy" do
      post "api_create", { :file => @content }
      response.status.to_i.should == 400
    end

    it "should reject an expired policy" do
      params = @attachment.ajax_upload_params(@user.pseudonym, "", "", :expiration => -60)
      post "api_create", params[:upload_params].merge({ :file => @content })
      response.status.to_i.should == 400
    end

    it "should reject a modified policy" do
      params = @attachment.ajax_upload_params(@user.pseudonym, "", "")
      params[:upload_params]['Policy'] << 'a'
      post "api_create", params[:upload_params].merge({ :file => @content })
      response.status.to_i.should == 400
    end

    it "should reject a good policy if the attachment data is already uploaded" do
      params = @attachment.ajax_upload_params(@user.pseudonym, "", "")
      @attachment.uploaded_data = @content
      @attachment.save!
      post "api_create", params[:upload_params].merge(:file => @content)
      response.status.to_i.should == 400
    end
  end

  describe "GET 'public_feed.atom'" do
    before(:each) do
      course_with_student(:active_all => true)
      user_file
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code + 'x'
      assigns[:problem].should match /The verification code is invalid/
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.links.first.rel.should match(/self/)
      feed.links.first.href.should match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.should_not be_empty
      feed.entries.all?{|e| e.authors.present?}.should be_true
    end
  end
end
