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
  
  def folder_file
    @file = @folder.active_file_attachments.build(:uploaded_data => io)
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
    
    it "should select a default folder" do
      course_with_teacher_logged_in(:active_all => true)
      get 'index', :course_id => @course.id, :format => 'json'
      response.should be_success
      assigns[:current_folder].should_not be_nil
      assigns[:current_folder].name.should eql("course files")
    end
    
    it "should return data for sub_folder if specified" do
      course_with_teacher_logged_in(:active_all => true)
      f1 = course_folder
      a1 = folder_file
      get 'index', :course_id => @course.id, :format => 'json'
      response.should be_success
      data = JSON.parse(response.body) rescue nil
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
      group_with_user
      @group.add_user(@user)
      user_session(@user)
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
      begin
        get 'show', :course_id => @course.id, :id => @file.id, :download => 1
      rescue => e
        e.to_s.should eql("Not Found")
      end
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
      # TODO: attachment_fu is not playing nice with this test.
      # TODO: attachment_fu gets mad if there's no actual file
      # put 'update', :course_id => @course.id, :id => @file.id, :attachment => {:display_name => "new name", :uploaded_data => nil}
      # response.should be_redirect
      # assigns[:attachment].should eql(@file)
      # assigns[:attachment].display_name.should eql("new name")
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
      # TODO: attachment_fu is not playing nice with this test
      # delete 'destroy', :course_id => @course.id, :id => @file.id
      # response.should be_redirect
      # assigns[:attachment].should eql(@file)
      # assigns[:attachment].should be_frozen
    end
  end
  
  describe "POST 'create_pending'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'create_pending', {:attachment => {:context_code => @course.asset_string}}
      assert_unauthorized
    end
    
    it "should create file placeholder (in local mode)" do
      class Attachment
        class <<self
          alias :old_s3_storage? :s3_storage?
          alias :old_local_storage? :local_storage?
        end
        def self.s3_storage?; false; end
        def self.local_storage?; true; end
      end
      begin
        Attachment.local_storage?.should eql(true)
        Attachment.s3_storage?.should eql(false)
        course_with_teacher_logged_in(:active_all => true)
        post 'create_pending', {:attachment => {
          :context_code => @course.asset_string,
          :filename => "bob.txt"
        }}
        response.should be_success
        assigns[:attachment].should_not be_nil
        assigns[:attachment].id.should_not be_nil
        json = JSON.parse(response.body) rescue nil
        json.should_not be_nil
        json['id'].should eql(assigns[:attachment].id)
        json['upload_url'].should_not be_nil
        json['upload_params'].should_not be_nil
        json['upload_params'].should_not be_empty
        json['remote_url'].should eql(false)
      ensure
        class Attachment
          class <<self
            alias :s3_storage? :old_s3_storage?
            alias :local_storage? :old_local_storage?
          end
        end
      end
    end
    
    it "should create file placeholder (in s3 mode)" do
      class Attachment
        class <<self
          alias :old_s3_storage? :s3_storage?
          alias :old_local_storage? :local_storage?
        end
        def self.s3_storage?; true; end
        def self.local_storage?; false; end
      end
      begin
        Attachment.s3_storage?.should eql(true)
        Attachment.local_storage?.should eql(false)
        course_with_teacher_logged_in(:active_all => true)
        post 'create_pending', {:attachment => {
          :context_code => @course.asset_string,
          :filename => "bob.txt"
        }}
        response.should be_success
        assigns[:attachment].should_not be_nil
        assigns[:attachment].id.should_not be_nil
        json = JSON.parse(response.body) rescue nil
        json.should_not be_nil
        json['id'].should eql(assigns[:attachment].id)
        json['upload_url'].should_not be_nil
        json['upload_params'].should_not be_nil
        json['upload_params'].should_not be_empty
        json['remote_url'].should eql(true)
      ensure
        class Attachment
          class <<self
            alias :s3_storage? :old_s3_storage?
            alias :local_storage? :old_local_storage?
          end
        end
      end
    end
  end
  
  describe "POST 's3_success'" do
  end
  
end
