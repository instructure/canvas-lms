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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Folders API", type: :request do
  before do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    @root = Folder.root_folders(@course).first

    @folders_path = "/api/v1/folders"
    @folders_path_options = { :controller => "folders", :action => "api_index", :format => "json", :id => @root.id.to_param }
  end

  describe "#index" do
    def make_folders
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course , :position => 1)
      @f2 = @root.sub_folders.create!(:name => "folder2" , :context => @course, :position => 2)
      @f3 = @root.sub_folders.create!(:name => "11folder", :context => @course, :position => 3)
      @f4 = @root.sub_folders.create!(:name => "zzfolder", :context => @course, :position => 4, :locked => true)
      @f5 = @root.sub_folders.create!(:name => "aafolder", :context => @course, :position => 5, :hidden => true)
    end

    it "should list folders in alphabetical order" do
      make_folders
      json = api_call(:get, @folders_path + "/#{@root.id}/folders", @folders_path_options, {})
      res = json.map{|f|f['name']}
      res.should == %w{11folder aafolder folder1 folder2 zzfolder}
    end

    it "should list folders in saved order if flag set" do
      make_folders
      json = api_call(:get, @folders_path + "/#{@root.id}/folders?sort_by=position", @folders_path_options.merge(:action => "api_index", :sort_by => 'position'), {})

      res = json.map{|f|f['name']}
      res.should == %w{folder1 folder2 11folder zzfolder aafolder}
    end

    it "should allow getting locked folder if authed" do
      make_folders
      json = api_call(:get, @folders_path + "/#{@f4.id}/folders", @folders_path_options.merge(:action => "api_index", :id => @f4.id.to_param), {})

      json.should == []
    end

    it "should not list hidden folders if not authed" do
      make_folders
      course_with_student(:course => @course)
      json = api_call(:get, @folders_path + "/#{@root.id}/folders", @folders_path_options, {})

      json.any?{|f|f[:id] == @f5.id}.should == false
    end

    it "should not list locked folders if not authed" do
      make_folders
      course_with_student(:course => @course)
      raw_api_call(:get, @folders_path + "/#{@f4.id}/folders", @folders_path_options.merge(:action => "api_index", :id => @f4.id.to_param), {})

      response.code.should == "401"
    end

    it "should 404 for no folder found" do
      raw_api_call(:get, @folders_path + "/0/folders", @folders_path_options.merge(:action => "api_index", :id => "0"), {})

      response.code.should == "404"
    end

    it "should paginate" do
      7.times {|i| @root.sub_folders.create!(:name => "folder#{i}", :context => @course) }
      json = api_call(:get, @folders_path + "/#{@root.id}/folders?per_page=3", @folders_path_options.merge(:per_page => '3'), {})
      json.length.should == 3
      links = response.headers['Link'].split(",")
      links.all?{ |l| l =~ /api\/v1\/folders\/#{@root.id}\/folders/ }.should be_true
      links.find{ |l| l.match(/rel="next"/)}.should =~ /page=2&per_page=3>/
      links.find{ |l| l.match(/rel="first"/)}.should =~ /page=1&per_page=3>/
      links.find{ |l| l.match(/rel="last"/)}.should =~ /page=3&per_page=3>/

      json = api_call(:get, @folders_path + "/#{@root.id}/folders?per_page=3&page=3", @folders_path_options.merge(:per_page => '3', :page => '3'), {})
      json.length.should == 1
      links = response.headers['Link'].split(",")
      links.all?{ |l| l =~ /api\/v1\/folders\/#{@root.id}\/folders/ }.should be_true
      links.find{ |l| l.match(/rel="prev"/)}.should =~ /page=2&per_page=3>/
      links.find{ |l| l.match(/rel="first"/)}.should =~ /page=1&per_page=3>/
      links.find{ |l| l.match(/rel="last"/)}.should =~ /page=3&per_page=3>/
    end
  end

  describe "#show" do
    it "should have the file and folder counts" do
      @root.sub_folders.create!(:name => "folder1", :context => @course)
      @root.sub_folders.create!(:name => "folder2", :context => @course)
      Attachment.create!(:filename => 'test.txt', :display_name => "testing.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course)
      json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(:action => "show"), {})
      json['files_count'].should == 1
      json['folders_count'].should == 2
    end

    it "should have url to list file and folder listings" do
      json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(:action => "show"), {})
      json['files_url'].ends_with?("/api/v1/folders/#{@root.id}/files").should == true
      json['folders_url'].ends_with?("/api/v1/folders/#{@root.id}/folders").should == true
    end

    it "should return unauthorized error" do
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course, :hidden => true)
      course_with_student(:course => @course)
      raw_api_call(:get, @folders_path + "/#{@f1.id}", @folders_path_options.merge(:action => "show", :id => @f1.id.to_param), {})
      response.code.should == "401"
    end

    it "should 404 for no folder found" do
      raw_api_call(:get, @folders_path + "/0", @folders_path_options.merge(:action => "show", :id => "0"), {}, {}, :expected_status => 404)
    end

    it "should 404 for deleted folder" do
      f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      f1.destroy
      raw_api_call(:get, @folders_path + "/#{f1.id}", @folders_path_options.merge(:action => "show", :id => f1.id.to_param), {}, {}, :expected_status => 404)
    end

    it "should return correct locked values" do
      json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(:action => "show"), {})
      json["locked_for_user"].should == false
      json["locked"].should == false

      locked = @root.sub_folders.create!(:name => "locked", :context => @course, :position => 4, :locked => true)
      json = api_call(:get, @folders_path + "/#{locked.id}", @folders_path_options.merge(:action => "show", :id => locked.id.to_param), {})
      json["locked"].should == true
      json["locked_for_user"].should == false

      student_in_course(:course => @course, :active_all => true)
      json = api_call(:get, @folders_path + "/#{@root.id}/folders", @folders_path_options, {})
      json.should be_empty
    end

    describe "folder in context" do
      it "should get the root folder for a course" do
        json = api_call(:get,  "/api/v1/courses/#{@course.id}/folders/root", @folders_path_options.merge(:action => "show", :course_id => @course.id.to_param, :id => 'root'), {})
        json['id'].should == @root.id
      end
      
      it "should get a folder in a context" do
        @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
        json = api_call(:get,  "/api/v1/courses/#{@course.id}/folders/#{@f1.id}", @folders_path_options.merge(:action => "show", :course_id => @course.id.to_param, :id => @f1.id.to_param), {})
        json['id'].should == @f1.id
      end
      
      it "should 404 for a folder in a different context" do
        group_model(:context => @course)
        group_root = Folder.root_folders(@group).first
        json = api_call(:get,  "/api/v1/courses/#{@course.id}/folders/#{group_root.id}", @folders_path_options.merge(:action => "show", :course_id => @course.id.to_param, :id => group_root.id.to_param), {}, {}, :expected_status => 404)
      end

      it "should get the root folder for a user" do
        @root = Folder.root_folders(@user).first
        json = api_call(:get,  "/api/v1/users/#{@user.id}/folders/root", @folders_path_options.merge(:action => "show", :user_id => @user.id.to_param, :id => 'root'), {})
        json['id'].should == @root.id
      end

      it "should get the root folder for a group" do
        group_model(:context => @course)
        @root = Folder.root_folders(@group).first
        json = api_call(:get,  "/api/v1/groups/#{@group.id}/folders/root", @folders_path_options.merge(:action => "show", :group_id => @group.id.to_param, :id => 'root'), {})
        json['id'].should == @root.id
      end
    end
  end

  describe "#destroy" do
    it "should delete an empty folder" do
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(:action => "api_destroy", :id => @f1.id.to_param), {})
      @f1.reload
      @f1.workflow_state.should == 'deleted'
    end

    it "should not allow deleting root folder of context" do
      json = api_call(:delete, @folders_path + "/#{@root.id}", @folders_path_options.merge(:action => "api_destroy", :id => @root.id.to_param), {}, {}, :expected_status => 400)
      json['message'].should == "Can't delete the root folder"
      @root.reload
      @root.workflow_state.should == 'visible'
    end

    it "should not allow deleting folders with contents without force flag" do
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      @f2 = @f1.sub_folders.create!(:name => "folder2", :context => @course)
      att = Attachment.create!(:filename => 'test.txt', :display_name => "testing.txt", :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course)
      json = api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(:action => "api_destroy", :id => @f1.id.to_param), {}, {}, :expected_status => 400)
      json['message'].should == "Can't delete a folder with content"
      @f1.reload
      @f1.workflow_state.should == 'visible'
      @f2.reload
      @f2.workflow_state.should == 'visible'
      att.reload
      att.workflow_state.should == 'processed'
    end

    it "should allow deleting folders with contents with force flag" do
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      @f2 = @f1.sub_folders.create!(:name => "folder2", :context => @course)
      api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(:action => "api_destroy", :id => @f1.id.to_param), {:force => true})
      @f1.reload
      @f1.workflow_state.should == 'deleted'
      @f2.reload
      @f2.workflow_state.should == 'deleted'
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      raw_api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(:action => "api_destroy", :id => @f1.id.to_param), {})
      response.code.should == '401'
      @f1.reload
      @f1.workflow_state.should == 'visible'
    end
  end

  describe "#create" do
    append_before do
      @folders_path_options = { :controller => "folders", :action => "create", :format => "json" }
    end

    it "should create in unfiled folder" do
      json = api_call(:post, "/api/v1/users/#{@user.id}/folders",
               @folders_path_options.merge(:user_id => @user.id.to_param),
               { :name => "f1",  :hidden => 'true'}, {})

      unfiled = Folder.unfiled_folder(@user)
      unfiled.sub_folders.count.should == 1
      f1 = unfiled.sub_folders.first
      f1.name.should == 'f1'
      f1.hidden.should == true
    end

    it "should create by folder id" do
      group_model(:context => @course)
      @root = Folder.root_folders(@group).first
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @group)

      json = api_call(:post, "/api/v1/groups/#{@group.id}/folders",
               @folders_path_options.merge(:group_id => @group.id.to_param),
               { :name => "sub1",  :locked => 'true', :parent_folder_id => @f1.id.to_param}, {})
      @f1.reload
      sub1 = @f1.sub_folders.first
      sub1.name.should == 'sub1'
      sub1.locked.should == true
    end

    it "should create by folder id in the path" do
      group_model(:context => @course)
      @root = Folder.root_folders(@group).first
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @group)

      json = api_call(:post, "/api/v1/folders/#{@f1.id}/folders",
               @folders_path_options.merge(:folder_id => @f1.id.to_param),
               { :name => "sub1",  :locked => 'true' }, {})
      @f1.reload
      sub1 = @f1.sub_folders.first
      sub1.name.should == 'sub1'
      sub1.locked.should == true
    end

    it "should error with invalid folder id" do
      api_call(:post, "/api/v1/folders/0/folders",
               @folders_path_options.merge(:folder_id => "0"),
               {:name => "sub1",  :locked => 'true'},
               {},
               :expected_status => 404)
    end

    it "should give error folder is used and path sent" do
      json = api_call(:post, "/api/v1/folders/#{@root.id}/folders",
               @folders_path_options.merge(:folder_id => @root.id.to_param),
               { :name => "sub1",  :locked => 'true', :parent_folder_path => 'haha/fool'},
               {},
               :expected_status => 400)
      json['message'].should == "Can't set folder path and folder id"
    end

    it "should give error folder is used and id sent" do
      json = api_call(:post, "/api/v1/folders/#{@root.id}/folders",
               @folders_path_options.merge(:folder_id => @root.id.to_param),
               { :name => "sub1",  :locked => 'true', :parent_folder_id =>  @root.id.to_param},
               {},
               :expected_status => 400)
      json['message'].should == "Can't set folder path and folder id"
    end

    it "should create by folder path" do
      json = api_call(:post, "/api/v1/courses/#{@course.id}/folders",
               @folders_path_options.merge(:course_id => @course.id.to_param),
               { :name => "sub1", :parent_folder_path => "subfolder/path"}, {})

      @root.reload
      @root.sub_folders.count.should == 1
      subfolder = @root.sub_folders.first
      subfolder.name.should == 'subfolder'
      subfolder.sub_folders.count.should == 1
      path = subfolder.sub_folders.first
      path.name.should == 'path'
      path.sub_folders.count.should == 1
      sub1 = path.sub_folders.first
      sub1.name.should == 'sub1'
    end

    it "should error with invalid parent id" do
      api_call(:post, "/api/v1/courses/#{@course.id}/folders",
               @folders_path_options.merge(:course_id => @course.id.to_param),
               { :name => "sub1",  :locked => 'true', :parent_folder_id => "0"},
               {},
               :expected_status => 404)
    end

    it "should give error if path and id are passed" do
      json = api_call(:post, "/api/v1/courses/#{@course.id}/folders",
               @folders_path_options.merge(:course_id => @course.id.to_param),
               { :name => "sub1",  :locked => 'true', :parent_folder_id => "0", :parent_folder_path => 'haha/fool'},
               {},
               :expected_status => 400)
      json['message'].should == "Can't set folder path and folder id"
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      api_call(:post, "/api/v1/courses/#{@course.id}/folders",
               @folders_path_options.merge(:course_id => @course.id.to_param),
               { :name => "sub1"}, {}, :expected_status => 401)
    end
  end

  describe "#update" do
    append_before do
      @sub1 = @root.sub_folders.create!(:name => "sub1", :context => @course)
      @update_url = @folders_path + "/#{@sub1.id}"
      @folders_path_options = { :controller => "folders", :action => "update", :format => "json", :id => @sub1.id.to_param }
    end

    it "should update" do
      @sub2 = @root.sub_folders.create!(:name => "sub2", :context => @course)
      api_call(:put, @update_url, @folders_path_options, {:name => "new name", :parent_folder_id => @sub2.id.to_param}, {}, :expected_status => 200)
      @sub1.reload
      @sub1.name.should == "new name"
      @sub1.parent_folder_id.should == @sub2.id
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      api_call(:put, @update_url, @folders_path_options, {:name => "new name"}, {}, :expected_status => 401)
    end

    it "should 404 with invalid parent id" do
      api_call(:put, @update_url, @folders_path_options, {:name => "new name", :parent_folder_id => 0}, {}, :expected_status => 404)
    end

    it "should not allow moving to different context" do
      user_root = Folder.root_folders(@user).first
      api_call(:put, @update_url, @folders_path_options, {:name => "new name", :parent_folder_id => user_root.id.to_param}, {}, :expected_status => 404)
    end
  end

  describe "#create_file" do
    it "should create a file in the correct folder" do
      @context = course_with_teacher
      @user = @teacher
      @root_folder = Folder.root_folders(@course).first
      api_call(:post, "/api/v1/folders/#{@root_folder.id}/files",
        { :controller => "folders", :action => "create_file", :format => "json", :folder_id => @root_folder.id.to_param, },
        :name => "with_path.txt")
      attachment = Attachment.order(:id).last
      attachment.folder_id.should == @root_folder.id
    end
  end

  describe "#resolve_path" do
    before do
      @params_hash = { controller: 'folders', action: 'resolve_path', format: 'json' }
    end

    context "course" do
      before do
        course active_all: true
        @root_folder = Folder.root_folders(@course).first
        @request_path = "/api/v1/courses/#{@course.id}/folders/by_path"
        @params_hash.merge!(course_id: @course.to_param)
      end

      it "should check permissions" do
        user
        api_call(:get, @request_path, @params_hash, {}, {}, { expected_status: 401 })
      end

      it "should operate on an empty path" do
        student_in_course
        json = api_call(:get, @request_path, @params_hash)
        json.map { |folder| folder['id'] }.should eql [@root_folder.id]
      end

      describe "with full_path" do
        before do
          @folder = @course.folders.create! parent_folder: @root_folder, name: 'a folder'
          @sub_folder = @course.folders.create! parent_folder: @folder, name: 'locked subfolder', locked: true
          @path = [@folder.name, @sub_folder.name].join('/')
          @request_path += "/#{URI.encode(@path)}"
          @params_hash.merge!(full_path: @path)
        end

        it "should return a list of path components" do
          teacher_in_course
          json = api_call(:get, @request_path, @params_hash)
          json.map { |folder| folder['id'] }.should eql [@root_folder.id, @folder.id, @sub_folder.id]
        end

        it "should 404 on an invalid path" do
          teacher_in_course
          json = api_call(:get, @request_path + "/nonexistent", @params_hash.merge(full_path: @path + "/nonexistent"),
                          {}, {}, { expected_status: 404 })
        end

        it "should not traverse hidden or locked paths for students" do
          student_in_course
          api_call(:get, @request_path, @params_hash, {}, {}, { expected_status: 404 })
        end
      end
    end

    context "group" do
      before do
        group_with_user
        @root_folder = Folder.root_folders(@group).first
        @params_hash.merge!(group_id: @group.id)
      end

      it "should accept an empty path" do
        json = api_call(:get, "/api/v1/groups/#{@group.id}/folders/by_path/", @params_hash)
        json.map { |folder| folder['id'] }.should eql [@root_folder.id]
      end

      it "should accept a non-empty path" do
        @folder = @group.folders.create! parent_folder: @root_folder, name: 'some folder'
        json = api_call(:get, "/api/v1/groups/#{@group.id}/folders/by_path/#{URI.encode(@folder.name)}", @params_hash.merge(full_path: @folder.name))
        json.map { |folder| folder['id'] }.should eql [@root_folder.id, @folder.id]
      end
    end

    context "user" do
      before do
        user active_all: true
        @root_folder = Folder.root_folders(@user).first
        @params_hash.merge!(user_id: @user.id)
      end

      it "should accept an empty path" do
        json = api_call(:get, "/api/v1/users/#{@user.id}/folders/by_path/", @params_hash)
        json.map { |folder| folder['id'] }.should eql [@root_folder.id]
      end

      it "should accept a non-empty path" do
        @folder = @user.folders.create! parent_folder: @root_folder, name: 'some folder'
        json = api_call(:get, "/api/v1/users/#{@user.id}/folders/by_path/#{URI.encode(@folder.name)}", @params_hash.merge(full_path: @folder.name))
        json.map { |folder| folder['id'] }.should eql [@root_folder.id, @folder.id]
      end
    end
  end
end
