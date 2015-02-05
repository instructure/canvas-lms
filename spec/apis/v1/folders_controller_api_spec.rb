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
  before :once do
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
      expect(res).to eq %w{11folder aafolder folder1 folder2 zzfolder}
    end

    it "should list folders in saved order if flag set" do
      make_folders
      json = api_call(:get, @folders_path + "/#{@root.id}/folders?sort_by=position", @folders_path_options.merge(:action => "api_index", :sort_by => 'position'), {})

      res = json.map{|f|f['name']}
      expect(res).to eq %w{folder1 folder2 11folder zzfolder aafolder}
    end

    it "should allow getting locked folder if authed" do
      make_folders
      json = api_call(:get, @folders_path + "/#{@f4.id}/folders", @folders_path_options.merge(:action => "api_index", :id => @f4.id.to_param), {})

      expect(json).to eq []
    end

    it "should not list hidden folders if not authed" do
      make_folders
      course_with_student(:course => @course)
      json = api_call(:get, @folders_path + "/#{@root.id}/folders", @folders_path_options, {})

      expect(json.any?{|f|f[:id] == @f5.id}).to eq false
    end

    it "should not list locked folders if not authed" do
      make_folders
      course_with_student(:course => @course)
      raw_api_call(:get, @folders_path + "/#{@f4.id}/folders", @folders_path_options.merge(:action => "api_index", :id => @f4.id.to_param), {})

      expect(response.code).to eq "401"
    end

    it "should 404 for no folder found" do
      raw_api_call(:get, @folders_path + "/0/folders", @folders_path_options.merge(:action => "api_index", :id => "0"), {})

      expect(response.code).to eq "404"
    end

    it "should paginate" do
      7.times {|i| @root.sub_folders.create!(:name => "folder#{i}", :context => @course) }
      json = api_call(:get, @folders_path + "/#{@root.id}/folders?per_page=3", @folders_path_options.merge(:per_page => '3'), {})
      expect(json.length).to eq 3
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/folders\/#{@root.id}\/folders/ }).to be_truthy
      expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2&per_page=3>/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/

      json = api_call(:get, @folders_path + "/#{@root.id}/folders?per_page=3&page=3", @folders_path_options.merge(:per_page => '3', :page => '3'), {})
      expect(json.length).to eq 1
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/folders\/#{@root.id}\/folders/ }).to be_truthy
      expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2&per_page=3>/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/
    end
  end

  describe "#show" do
    it "should have the file and folder counts" do
      @root.sub_folders.create!(:name => "folder1", :context => @course)
      @root.sub_folders.create!(:name => "folder2", :context => @course)
      Attachment.create!(:filename => 'test.txt', :display_name => "testing.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course)
      json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(:action => "show"), {})
      expect(json['files_count']).to eq 1
      expect(json['folders_count']).to eq 2
    end

    it "should have url to list file and folder listings" do
      json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(:action => "show"), {})
      expect(json['files_url'].ends_with?("/api/v1/folders/#{@root.id}/files")).to eq true
      expect(json['folders_url'].ends_with?("/api/v1/folders/#{@root.id}/folders")).to eq true
    end

    it "should return unauthorized error" do
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course, :hidden => true)
      course_with_student(:course => @course)
      raw_api_call(:get, @folders_path + "/#{@f1.id}", @folders_path_options.merge(:action => "show", :id => @f1.id.to_param), {})
      expect(response.code).to eq "401"
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
      expect(json["locked_for_user"]).to eq false
      expect(json["locked"]).to eq false

      locked = @root.sub_folders.create!(:name => "locked", :context => @course, :position => 4, :locked => true)
      json = api_call(:get, @folders_path + "/#{locked.id}", @folders_path_options.merge(:action => "show", :id => locked.id.to_param), {})
      expect(json["locked"]).to eq true
      expect(json["locked_for_user"]).to eq false

      student_in_course(:course => @course, :active_all => true)
      json = api_call(:get, @folders_path + "/#{@root.id}/folders", @folders_path_options, {})
      expect(json).to be_empty
    end

    describe "folder in context" do
      it "should get the root folder for a course" do
        json = api_call(:get,  "/api/v1/courses/#{@course.id}/folders/root", @folders_path_options.merge(:action => "show", :course_id => @course.id.to_param, :id => 'root'), {})
        expect(json['id']).to eq @root.id
      end

      it "should get a folder in a context" do
        @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
        json = api_call(:get,  "/api/v1/courses/#{@course.id}/folders/#{@f1.id}", @folders_path_options.merge(:action => "show", :course_id => @course.id.to_param, :id => @f1.id.to_param), {})
        expect(json['id']).to eq @f1.id
      end

      it "should 404 for a folder in a different context" do
        group_model(:context => @course)
        group_root = Folder.root_folders(@group).first
        json = api_call(:get,  "/api/v1/courses/#{@course.id}/folders/#{group_root.id}", @folders_path_options.merge(:action => "show", :course_id => @course.id.to_param, :id => group_root.id.to_param), {}, {}, :expected_status => 404)
      end

      it "should get the root folder for a user" do
        @root = Folder.root_folders(@user).first
        json = api_call(:get,  "/api/v1/users/#{@user.id}/folders/root", @folders_path_options.merge(:action => "show", :user_id => @user.id.to_param, :id => 'root'), {})
        expect(json['id']).to eq @root.id
      end

      it "should get the root folder for a group" do
        group_model(:context => @course)
        @root = Folder.root_folders(@group).first
        json = api_call(:get,  "/api/v1/groups/#{@group.id}/folders/root", @folders_path_options.merge(:action => "show", :group_id => @group.id.to_param, :id => 'root'), {})
        expect(json['id']).to eq @root.id
      end
    end
  end

  describe "#destroy" do
    it "should delete an empty folder" do
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(:action => "api_destroy", :id => @f1.id.to_param), {})
      @f1.reload
      expect(@f1.workflow_state).to eq 'deleted'
    end

    it "should not allow deleting root folder of context" do
      json = api_call(:delete, @folders_path + "/#{@root.id}", @folders_path_options.merge(:action => "api_destroy", :id => @root.id.to_param), {}, {}, :expected_status => 400)
      expect(json['message']).to eq "Can't delete the root folder"
      @root.reload
      expect(@root.workflow_state).to eq 'visible'
    end

    it "should not allow deleting folders with contents without force flag" do
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      @f2 = @f1.sub_folders.create!(:name => "folder2", :context => @course)
      att = Attachment.create!(:filename => 'test.txt', :display_name => "testing.txt", :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course)
      json = api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(:action => "api_destroy", :id => @f1.id.to_param), {}, {}, :expected_status => 400)
      expect(json['message']).to eq "Can't delete a folder with content"
      @f1.reload
      expect(@f1.workflow_state).to eq 'visible'
      @f2.reload
      expect(@f2.workflow_state).to eq 'visible'
      att.reload
      expect(att.workflow_state).to eq 'processed'
    end

    it "should allow deleting folders with contents with force flag" do
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      @f2 = @f1.sub_folders.create!(:name => "folder2", :context => @course)
      api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(:action => "api_destroy", :id => @f1.id.to_param), {:force => true})
      @f1.reload
      expect(@f1.workflow_state).to eq 'deleted'
      @f2.reload
      expect(@f2.workflow_state).to eq 'deleted'
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      raw_api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(:action => "api_destroy", :id => @f1.id.to_param), {})
      expect(response.code).to eq '401'
      @f1.reload
      expect(@f1.workflow_state).to eq 'visible'
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
      expect(unfiled.sub_folders.count).to eq 1
      f1 = unfiled.sub_folders.first
      expect(f1.name).to eq 'f1'
      expect(f1.hidden).to eq true
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
      expect(sub1.name).to eq 'sub1'
      expect(sub1.locked).to eq true
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
      expect(sub1.name).to eq 'sub1'
      expect(sub1.locked).to eq true
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
      expect(json['message']).to eq "Can't set folder path and folder id"
    end

    it "should give error folder is used and id sent" do
      json = api_call(:post, "/api/v1/folders/#{@root.id}/folders",
               @folders_path_options.merge(:folder_id => @root.id.to_param),
               { :name => "sub1",  :locked => 'true', :parent_folder_id =>  @root.id.to_param},
               {},
               :expected_status => 400)
      expect(json['message']).to eq "Can't set folder path and folder id"
    end

    it "should create by folder path" do
      json = api_call(:post, "/api/v1/courses/#{@course.id}/folders",
               @folders_path_options.merge(:course_id => @course.id.to_param),
               { :name => "sub1", :parent_folder_path => "subfolder/path"}, {})

      @root.reload
      expect(@root.sub_folders.count).to eq 1
      subfolder = @root.sub_folders.first
      expect(subfolder.name).to eq 'subfolder'
      expect(subfolder.sub_folders.count).to eq 1
      path = subfolder.sub_folders.first
      expect(path.name).to eq 'path'
      expect(path.sub_folders.count).to eq 1
      sub1 = path.sub_folders.first
      expect(sub1.name).to eq 'sub1'
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
      expect(json['message']).to eq "Can't set folder path and folder id"
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      api_call(:post, "/api/v1/courses/#{@course.id}/folders",
               @folders_path_options.merge(:course_id => @course.id.to_param),
               { :name => "sub1"}, {}, :expected_status => 401)
    end
  end

  describe "#update" do
    before :once do
      @sub1 = @root.sub_folders.create!(:name => "sub1", :context => @course)
      @update_url = @folders_path + "/#{@sub1.id}"
      @folders_path_options = { :controller => "folders", :action => "update", :format => "json", :id => @sub1.id.to_param }
    end

    it "should update" do
      @sub2 = @root.sub_folders.create!(:name => "sub2", :context => @course)
      api_call(:put, @update_url, @folders_path_options, {:name => "new name", :parent_folder_id => @sub2.id.to_param}, {}, :expected_status => 200)
      @sub1.reload
      expect(@sub1.name).to eq "new name"
      expect(@sub1.parent_folder_id).to eq @sub2.id
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
      expect(attachment.folder_id).to eq @root_folder.id
    end
  end

  describe "#resolve_path" do
    before :once do
      @params_hash = { controller: 'folders', action: 'resolve_path', format: 'json' }
    end

    context "course" do
      before :once do
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
        expect(json.map { |folder| folder['id'] }).to eql [@root_folder.id]
      end

      describe "with full_path" do
        before :once do
          @folder = @course.folders.create! parent_folder: @root_folder, name: 'a folder'
          @sub_folder = @course.folders.create! parent_folder: @folder, name: 'locked subfolder', locked: true
          @path = [@folder.name, @sub_folder.name].join('/')
          @request_path += "/#{URI.encode(@path)}"
          @params_hash.merge!(full_path: @path)
        end

        it "should return a list of path components" do
          teacher_in_course
          json = api_call(:get, @request_path, @params_hash)
          expect(json.map { |folder| folder['id'] }).to eql [@root_folder.id, @folder.id, @sub_folder.id]
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
      before :once do
        group_with_user
        @root_folder = Folder.root_folders(@group).first
        @params_hash.merge!(group_id: @group.id)
      end

      it "should accept an empty path" do
        json = api_call(:get, "/api/v1/groups/#{@group.id}/folders/by_path/", @params_hash)
        expect(json.map { |folder| folder['id'] }).to eql [@root_folder.id]
      end

      it "should accept a non-empty path" do
        @folder = @group.folders.create! parent_folder: @root_folder, name: 'some folder'
        json = api_call(:get, "/api/v1/groups/#{@group.id}/folders/by_path/#{URI.encode(@folder.name)}", @params_hash.merge(full_path: @folder.name))
        expect(json.map { |folder| folder['id'] }).to eql [@root_folder.id, @folder.id]
      end
    end

    context "user" do
      before :once do
        user active_all: true
        @root_folder = Folder.root_folders(@user).first
        @params_hash.merge!(user_id: @user.id)
      end

      it "should accept an empty path" do
        json = api_call(:get, "/api/v1/users/#{@user.id}/folders/by_path/", @params_hash)
        expect(json.map { |folder| folder['id'] }).to eql [@root_folder.id]
      end

      it "should accept a non-empty path" do
        @folder = @user.folders.create! parent_folder: @root_folder, name: 'some folder'
        json = api_call(:get, "/api/v1/users/#{@user.id}/folders/by_path/#{URI.encode(@folder.name)}", @params_hash.merge(full_path: @folder.name))
        expect(json.map { |folder| folder['id'] }).to eql [@root_folder.id, @folder.id]
      end
    end
  end

  describe "copy_folder" do
    before :once do
      @source_context = course active_all: true
      @source_folder = @source_context.folders.create! name: 'teh folder'
      @file = attachment_model context: @source_context, folder: @source_folder, display_name: 'foo'
      @params_hash = { controller: 'folders', action: 'copy_folder', format: 'json' }

      @dest_context = course active_all: true
      @dest_folder = @dest_context.folders.create! name: 'put stuff here', parent_folder: Folder.root_folders(@dest_context).first

      user_model
    end

    it "should require :source_folder_id parameter" do
      json = api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_folder",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param),
               {}, {}, {expected_status: 400})
      expect(json['message']).to include 'source_folder_id'
    end

    it "should require :manage_files permission on the source context" do
      @source_context.enroll_student(@user, enrollment_state: 'active')
      @dest_context.enroll_teacher(@user, enrollment_state: 'active')
      api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_folder?source_folder_id=#{@source_folder.id}",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_folder_id: @source_folder.to_param),
               {}, {}, {expected_status: 401})
    end

    it "should require :create permission on the destination folder" do
      @source_context.enroll_teacher(@user, enrollment_state: 'active')
      @dest_context.enroll_student(@user, enrollment_state: 'active')
      api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_folder?source_folder_id=#{@source_folder.id}",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_folder_id: @source_folder.to_param),
               {}, {}, {expected_status: 401})
    end

    it "should copy a folder" do
      @source_context.enroll_teacher(@user, enrollment_state: 'active')
      @dest_context.enroll_teacher(@user, enrollment_state: 'active')
      json = api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_folder?source_folder_id=#{@source_folder.id}",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_folder_id: @source_folder.to_param))

      copy = Folder.find(json['id'])
      expect(copy.parent_folder).to eq(@dest_folder)
      contents = copy.active_file_attachments.all
      expect(contents.size).to eq 1
      expect(contents.first.root_attachment).to eq @file
    end

    context "within context" do
      before :once do
        @source_context.enroll_teacher(@user, enrollment_state: 'active')
      end

      it "should copy a folder within a context" do
        @new_folder = @source_context.folders.create! name: 'new folder'
        json = api_call(:post, "/api/v1/folders/#{@new_folder.id}/copy_folder?source_folder_id=#{@source_folder.id}",
              @params_hash.merge(dest_folder_id: @new_folder.to_param, source_folder_id: @source_folder.to_param))
        copy = Folder.find(json['id'])
        expect(copy.id).not_to eq @source_folder.id
        expect(copy.parent_folder).to eq @new_folder
        expect(copy.active_file_attachments.first.root_attachment).to eq @file
      end

      it "should rename if the folder already exists" do
        root_dir = @source_folder.parent_folder
        json = api_call(:post, "/api/v1/folders/#{root_dir.id}/copy_folder?source_folder_id=#{@source_folder.id}",
            @params_hash.merge(dest_folder_id: root_dir.to_param, source_folder_id: @source_folder.to_param))
        copy = Folder.find(json['id'])
        expect(copy.id).not_to eq @source_folder.id
        expect(copy.name).to start_with @source_folder.name
        expect(copy.name).not_to eq @source_folder.name
        expect(copy.active_file_attachments.first.root_attachment).to eq @file
      end

      it "should refuse to copy a folder into itself" do
        json = api_call(:post, "/api/v1/folders/#{@source_folder.id}/copy_folder?source_folder_id=#{@source_folder.id}",
                        @params_hash.merge(dest_folder_id: @source_folder.to_param, source_folder_id: @source_folder.to_param),
                        {}, {}, {expected_status: 400})
        expect(json['message']).to eq 'source folder may not contain destination folder'
      end

      it "should refuse to copy a folder into a descendant" do
        subsub = @source_context.folders.create! parent_folder: @source_folder, name: 'subsub'
        json = api_call(:post, "/api/v1/folders/#{subsub.id}/copy_folder?source_folder_id=#{@source_folder.id}",
                        @params_hash.merge(dest_folder_id: subsub.to_param, source_folder_id: @source_folder.to_param),
                        {}, {}, {expected_status: 400})
        expect(json['message']).to eq 'source folder may not contain destination folder'
      end
    end
  end

  describe "copy_file" do
    before :once do
      @params_hash = { controller: 'folders', action: 'copy_file', format: 'json' }
      @dest_context = course active_all: true
      @dest_folder = @dest_context.folders.create! name: 'put stuff here', parent_folder: Folder.root_folders(@dest_context).first

      user_model
      @source_file = attachment_model context: @user, display_name: 'baz'
    end

    it "should require :source_file_id parameter" do
      json = api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_file",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param),
               {}, {}, {expected_status: 400})
      expect(json['message']).to include 'source_file_id'
    end

    it "should require :download permission on the source file" do
      @user = @dest_context.teachers.first
      api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@source_file.id}",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @source_file.to_param),
               {}, {}, {expected_status: 401})
      expect(@dest_folder.active_file_attachments).not_to be_exists
    end

    it "should require :manage_files permission on the destination context" do
      api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@source_file.id}",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @source_file.to_param),
               {}, {}, {expected_status: 401})
      expect(@dest_folder.active_file_attachments).not_to be_exists
    end

    it "should copy a file" do
      @dest_context.enroll_teacher @user, enrollment_state: 'active'
      json = api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@source_file.id}",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @source_file.to_param))
      file = Attachment.find(json['id'])
      expect(file.folder).to eq(@dest_folder)
      expect(file.root_attachment).to eq(@source_file)
    end

    context "within context" do
      before :once do
        @dest_context.enroll_teacher @user, enrollment_state: 'active'
        @file = attachment_model context: @dest_context, folder: Folder.root_folders(@dest_context).first
      end

      it "should copy a file within a context" do
        json = api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@file.id}",
                        @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @file.to_param))
        file = Attachment.find(json['id'])
        expect(file).not_to eq(@file)
        expect(file.root_attachment).to eq(@file)
        expect(file.folder).to eq(@dest_folder)
      end

      it "should fail if the file already exists and on_duplicate was not given" do
        other_file = attachment_model context: @dest_context, folder: @dest_folder, display_name: @file.display_name
        json = api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@file.id}",
                        @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @file.to_param),
                        {}, {}, {expected_status: 409})
        expect(json['message']).to include "already exists"
        expect(@dest_context.attachments.active.count).to eq 2
      end

      it "should overwrite if asked" do
        other_file = attachment_model context: @dest_context, folder: @dest_folder, display_name: @file.display_name
        json = api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@file.id}&on_duplicate=overwrite",
                        @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @file.to_param, on_duplicate: 'overwrite'))
        file = Attachment.find(json['id'])
        expect(file).not_to eq(@file)
        expect(file.root_attachment).to eq(@file)
        expect(file.folder).to eq(@dest_folder)
        expect(file.display_name).to eq(json['display_name'])
        expect(file.display_name).to eq(@file.display_name)
        expect(other_file.reload).to be_deleted
        expect(other_file.replacement_attachment).to eq(file)
      end

      it "should rename if asked" do
        @file.update_attribute(:folder_id, @dest_folder.id)
        json = api_call(:post, "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@file.id}&on_duplicate=rename",
                        @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @file.to_param, on_duplicate: 'rename'))
        file = Attachment.find(json['id'])
        expect(file).not_to eq(@file)
        expect(file.root_attachment).to eq(@file)
        expect(file.folder).to eq(@dest_folder)
        expect(file.display_name).to eq(json['display_name'])
        expect(file.display_name).not_to eq(@file.display_name)
      end
    end
  end

  describe "#list_all_folders" do

    def make_folders_in_context(context)
      @root = Folder.root_folders(context).first
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => context , :position => 1)
      @f2 = @root.sub_folders.create!(:name => "folder2" , :context => context, :position => 2)
      @f3 = @f2.sub_folders.create!(:name => "folder2.1", :context => context, :position => 3)
      @f4 = @f3.sub_folders.create!(:name => "folder2.1.1", :context => context, :position => 4)
      @f5 = @f4.sub_folders.create!(:name => "folderlocked", :context => context, :position => 5, :locked => true)
      @f6 = @f5.sub_folders.create!(:name => "folderhidden", :context => context, :position => 6, :hidden => true)
    end

    context "course" do

      before :once do
         course_with_teacher(active_all: true)
         student_in_course(active_all: true)
         make_folders_in_context @course
       end

      it "should list all folders in a course including subfolders" do
        @user = @teacher
        json = api_call(:get, "/api/v1/courses/#{@course.id}/folders",
                        {:controller => "folders", :action => "list_all_folders", :format => "json", :course_id => @course.id.to_param})
        res = json.map{|f|f['name']}
        expect(res).to eq %w{course\ files folder1 folder2 folder2.1 folder2.1.1 folderhidden folderlocked}
      end

      it "should not show hidden and locked files to unauthorized users" do
        @user = @student
        json = api_call(:get, "/api/v1/courses/#{@course.id}/folders",
                        {:controller => "folders", :action => "list_all_folders", :format => "json", :course_id => @course.id.to_param})
        res = json.map{|f|f['name']}
        expect(res).to eq %w{course\ files folder1 folder2 folder2.1 folder2.1.1}
      end

      it "should return a 401 for unauthorized users" do
        @user = user(active_all: true)
        json = api_call(:get, "/api/v1/courses/#{@course.id}/folders",
                        {:controller => "folders", :action => "list_all_folders", :format => "json", :course_id => @course.id.to_param},
                        {}, {}, {:expected_status => 401})
      end

      it "should paginate the folder list" do
        @user = @teacher
        json = api_call(:get, "/api/v1/courses/#{@course.id}/folders",
                        {:controller => "folders", :action => "list_all_folders", :format => "json", :course_id => @course.id.to_param, :per_page => 3})

        expect(json.length).to eq 3
        links = response.headers['Link'].split(",")
        expect(links.all?{ |l| l =~ /api\/v1\/courses\/#{@course.id}\/folders/ }).to be_truthy
        expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2&per_page=3>/
        expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
        expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/

        json = api_call(:get, "/api/v1/courses/#{@course.id}/folders",
                        {:controller => "folders", :action => "list_all_folders", :format => "json", :course_id => @course.id.to_param, :per_page => 3, :page => 3})
        expect(json.length).to eq 1
        links = response.headers['Link'].split(",")
        expect(links.all?{ |l| l =~ /api\/v1\/courses\/#{@course.id}\/folders/ }).to be_truthy
        expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2&per_page=3>/
        expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
        expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/
      end
    end

    context "group" do
      it "should list all folders in a group including subfolders" do
        group_with_user(active_all: true)
        make_folders_in_context @group
        json = api_call(:get, "/api/v1/groups/#{@group.id}/folders",
                        {:controller => "folders", :action => "list_all_folders", :format => "json", :group_id => @group.id.to_param})
        res = json.map{|f|f['name']}
        expect(res).to eq %w{files folder1 folder2 folder2.1 folder2.1.1 folderhidden folderlocked}
      end
    end

    context "user" do
      it "should list all folders owned by a user including subfolders" do
        user(active_all: true)
        make_folders_in_context @user
        json = api_call(:get, "/api/v1/users/#{@user.id}/folders",
                        {:controller => "folders", :action => "list_all_folders", :format => "json", :user_id => @user.id.to_param})
        res = json.map{|f|f['name']}
        expect(res).to eq %w{folder1 folder2 folder2.1 folder2.1.1 folderhidden folderlocked my\ files}
      end
    end

  end
end
