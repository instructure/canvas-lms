# frozen_string_literal: true

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

require_relative "../api_spec_helper"

describe "Folders API", type: :request do
  before :once do
    course_with_teacher(active_all: true, user: user_with_pseudonym)
    @root = Folder.root_folders(@course).first

    @folders_path = "/api/v1/folders"
    @folders_path_options = { controller: "folders", action: "api_index", format: "json", id: @root.id.to_param }
  end

  describe "#index" do
    context "with folders" do
      before(:once) do
        @f1 = @root.sub_folders.create!(name: "folder1", context: @course, position: 1)
        @f2 = @root.sub_folders.create!(name: "folder2", context: @course, position: 2)
        @f3 = @root.sub_folders.create!(name: "11folder", context: @course, position: 3)
        @f4 = @root.sub_folders.create!(name: "zzfolder", context: @course, position: 4, locked: true)
        @f5 = @root.sub_folders.create!(name: "aafolder", context: @course, position: 5, hidden: true)
      end

      it "lists folders in alphabetical order" do
        json = api_call(:get, @folders_path + "/#{@root.id}/folders", @folders_path_options, {})
        res = json.pluck("name")
        expect(res).to eq %w[11folder aafolder folder1 folder2 zzfolder]
      end

      it "lists folders in saved order if flag set" do
        json = api_call(:get, @folders_path + "/#{@root.id}/folders?sort_by=position", @folders_path_options.merge(action: "api_index", sort_by: "position"), {})

        res = json.pluck("name")
        expect(res).to eq %w[folder1 folder2 11folder zzfolder aafolder]
      end

      it "allows getting locked folder if authed" do
        json = api_call(:get, @folders_path + "/#{@f4.id}/folders", @folders_path_options.merge(action: "api_index", id: @f4.id.to_param), {})

        expect(json).to eq []
      end

      it "does not list hidden folders if not authed" do
        course_with_student(course: @course)
        json = api_call(:get, @folders_path + "/#{@root.id}/folders", @folders_path_options, {})

        expect(json.any? { |f| f[:id] == @f5.id }).to be false
      end

      it "does not list locked folders if not authed" do
        course_with_student(course: @course)
        raw_api_call(:get, @folders_path + "/#{@f4.id}/folders", @folders_path_options.merge(action: "api_index", id: @f4.id.to_param), {})

        expect(response).to have_http_status :unauthorized
      end
    end

    it "404s for no folder found" do
      raw_api_call(:get, @folders_path + "/0/folders", @folders_path_options.merge(action: "api_index", id: "0"), {})

      expect(response).to have_http_status :not_found
    end

    it "paginates" do
      7.times { |i| @root.sub_folders.create!(name: "folder#{i}", context: @course) }
      json = api_call(:get, @folders_path + "/#{@root.id}/folders?per_page=3", @folders_path_options.merge(per_page: "3"), {})
      expect(json.length).to eq 3
      links = response.headers["Link"].split(",")
      expect(links.all? { |l| l =~ %r{api/v1/folders/#{@root.id}/folders} }).to be_truthy
      expect(links.find { |l| l.include?('rel="next"') }).to match(/page=2&per_page=3>/)
      expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
      expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3&per_page=3>/)

      json = api_call(:get, @folders_path + "/#{@root.id}/folders?per_page=3&page=3", @folders_path_options.merge(per_page: "3", page: "3"), {})
      expect(json.length).to eq 1
      links = response.headers["Link"].split(",")
      expect(links.all? { |l| l =~ %r{api/v1/folders/#{@root.id}/folders} }).to be_truthy
      expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=2&per_page=3>/)
      expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
      expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3&per_page=3>/)
    end

    context "student" do
      before(:once) do
        student_in_course
        @root = Folder.root_folders(@student).first
        @normal_folder = @student.folders.create! name: "Normal folder", parent_folder_id: @root
        @student.submissions_folder
      end

      it "indicates submissions folders" do
        json = api_call(:get, @folders_path + "/#{@root.id}/folders", @folders_path_options.merge(id: @root.to_param))
        expect(json.detect { |f| f["id"] == @normal_folder.id }["for_submissions"]).to be false
        expect(json.detect { |f| f["id"] == @student.submissions_folder.id }["for_submissions"]).to be true
        expect(json.detect { |f| f["id"] == @student.submissions_folder.id }["can_upload"]).to be false
      end
    end
  end

  describe "#show" do
    describe "file and folder counts" do
      before(:once) do
        @root.sub_folders.create!(name: "folder1", context: @course)
        @root.sub_folders.create!(name: "folder2", context: @course, workflow_state: "hidden")
        Attachment.create!(filename: "test1.txt", display_name: "test1.txt", uploaded_data: StringIO.new("file"), folder: @root, context: @course)
        Attachment.create!(filename: "test2.txt", display_name: "test2.txt", uploaded_data: StringIO.new("file"), folder: @root, context: @course).update_attribute(:file_state, "hidden")
      end

      it "counts hidden items for teachers" do
        json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(action: "show"), {})
        expect(json["files_count"]).to eq 2
        expect(json["folders_count"]).to eq 2
      end

      it "does not count hidden items for students" do
        student_in_course active_all: true
        json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(action: "show"), {})
        expect(json["files_count"]).to eq 1
        expect(json["folders_count"]).to eq 1
      end
    end

    it "has url to list file and folder listings" do
      json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(action: "show"), {})
      expect(json["files_url"].ends_with?("/api/v1/folders/#{@root.id}/files")).to be true
      expect(json["folders_url"].ends_with?("/api/v1/folders/#{@root.id}/folders")).to be true
    end

    it "returns unauthorized error if requestor is not permitted to view folder" do
      @f1 = @root.sub_folders.create!(name: "folder1", context: @course, hidden: true)
      course_with_student(course: @course)
      raw_api_call(:get, @folders_path + "/#{@f1.id}", @folders_path_options.merge(action: "show", id: @f1.id.to_param), {})
      expect(response).to have_http_status :unauthorized
    end

    it "404s for no folder found" do
      raw_api_call(:get, @folders_path + "/0", @folders_path_options.merge(action: "show", id: "0"))
      assert_status(404)
    end

    it "404s for deleted folder" do
      f1 = @root.sub_folders.create!(name: "folder1", context: @course)
      f1.destroy
      raw_api_call(:get, @folders_path + "/#{f1.id}", @folders_path_options.merge(action: "show", id: f1.id.to_param))
      assert_status(404)
    end

    it "returns correct locked values" do
      json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(action: "show"), {})
      expect(json["locked_for_user"]).to be false
      expect(json["locked"]).to be false

      locked = @root.sub_folders.create!(name: "locked", context: @course, position: 4, locked: true)
      json = api_call(:get, @folders_path + "/#{locked.id}", @folders_path_options.merge(action: "show", id: locked.id.to_param), {})
      expect(json["locked"]).to be true
      expect(json["locked_for_user"]).to be false

      student_in_course(course: @course, active_all: true)
      json = api_call(:get, @folders_path + "/#{@root.id}/folders", @folders_path_options, {})
      expect(json).to be_empty
    end

    it "shows if the user can upload files to the folder" do
      json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(action: "show"), {})
      expect(json["can_upload"]).to be true
      student_in_course(course: @course)
      json = api_call(:get, @folders_path + "/#{@root.id}", @folders_path_options.merge(action: "show"), {})
      expect(json["can_upload"]).to be false
    end

    describe "folder in context" do
      it "gets the root folder for a course" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/folders/root",
                        @folders_path_options
                                  .merge(action: "show", course_id: @course.id.to_param, id: "root"),
                        {})
        expect(json["id"]).to eq @root.id
      end

      it "gets a folder in a context" do
        @f1 = @root.sub_folders.create!(name: "folder1", context: @course)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/folders/#{@f1.id}",
                        @folders_path_options
                                  .merge(action: "show", course_id: @course.id.to_param, id: @f1.id.to_param),
                        {})
        expect(json["id"]).to eq @f1.id
      end

      it "404s for a folder in a different context" do
        group_model(context: @course)
        group_root = Folder.root_folders(@group).first
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/folders/#{group_root.id}",
                 @folders_path_options
                           .merge(action: "show", course_id: @course.id.to_param, id: group_root.id.to_param),
                 {},
                 {},
                 expected_status: 404)
      end

      it "gets the root folder for a user" do
        @root = Folder.root_folders(@user).first
        json = api_call(:get,
                        "/api/v1/users/#{@user.id}/folders/root",
                        @folders_path_options
                                  .merge(action: "show", user_id: @user.id.to_param, id: "root"),
                        {})
        expect(json["id"]).to eq @root.id
      end

      it "gets the root folder for a group" do
        group_model(context: @course)
        @root = Folder.root_folders(@group).first
        json = api_call(:get,
                        "/api/v1/groups/#{@group.id}/folders/root",
                        @folders_path_options
                                  .merge(action: "show", group_id: @group.id.to_param, id: "root"),
                        {})
        expect(json["id"]).to eq @root.id
      end
    end
  end

  describe "#icon_maker_folder" do
    it "creates an icon maker folder for the course" do
      expect do
        api_call(
          :get,
          "/api/v1/courses/#{@course.id}/folders/icon_maker",
          @folders_path_options.merge(action: "icon_maker_folder", course_id: @course.id.to_param).except(:id),
          {}
        )
      end.to change {
        @course.folders.where(unique_type: Folder::ICON_MAKER_UNIQUE_TYPE).count
      }.from(0).to(1)
    end

    it "returns the existing icon maker folder for the course" do
      existing_folder = Folder.icon_maker_folder(@course)

      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/folders/icon_maker",
        @folders_path_options.merge(action: "icon_maker_folder", course_id: @course.id.to_param).except(:id),
        {}
      )

      aggregate_failures do
        expect(json["id"]).to eq existing_folder.id
        expect(@course.folders.where(unique_type: Folder::ICON_MAKER_UNIQUE_TYPE).count).to be 1
      end
    end
  end

  describe "#media_folder" do
    it "creates a media folder for a course" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/folders/media",
                      @folders_path_options
                              .merge(action: "media_folder", course_id: @course.id.to_param).except(:id),
                      {})
      folder = @course.folders.where(name: "Uploaded Media").first
      expect(folder.unique_type).to eq Folder::MEDIA_TYPE
      expect(json["id"]).to eq folder.id
      expect(json["hidden"]).to be_truthy

      # get the same one twice
      json2 = api_call(:get,
                       "/api/v1/courses/#{@course.id}/folders/media",
                       @folders_path_options
                               .merge(action: "media_folder", course_id: @course.id.to_param).except(:id),
                       {})
      expect(json2["id"]).to eq folder.id
    end

    it "creates a folder in the user's root if user doesn't have upload rights" do
      course_with_student(course: @course, active_all: true)
      @me = @student
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/folders/media",
                      @folders_path_options
                              .merge(action: "media_folder", course_id: @course.id.to_param).except(:id),
                      {})
      expect(@course.folders.where(name: "Uploaded Media").first).to be_nil
      folder = @user.folders.where(name: "Uploaded Media").first
      expect(json["id"]).to eq folder.id
      expect(json["can_upload"]).to be true
    end

    it "creates a media folder for a group" do
      group_model(context: @course)
      json = api_call(:get,
                      "/api/v1/groups/#{@group.id}/folders/media",
                      @folders_path_options
                              .merge(action: "media_folder", group_id: @group.id.to_param).except(:id),
                      {})
      folder = @group.folders.where(name: "Uploaded Media").first
      expect(json["id"]).to eq folder.id
    end
  end

  describe "#destroy" do
    it "deletes an empty folder" do
      @f1 = @root.sub_folders.create!(name: "folder1", context: @course)
      api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(action: "api_destroy", id: @f1.id.to_param), {})
      @f1.reload
      expect(@f1.workflow_state).to eq "deleted"
    end

    it "does not allow deleting root folder of context" do
      json = api_call(:delete,
                      @folders_path + "/#{@root.id}",
                      @folders_path_options
                              .merge(action: "api_destroy", id: @root.id.to_param),
                      {},
                      {},
                      expected_status: 400)
      expect(json["message"]).to eq "Can't delete the root folder"
      @root.reload
      expect(@root.workflow_state).to eq "visible"
    end

    it "does not allow deleting folders with contents without force flag" do
      @f1 = @root.sub_folders.create!(name: "folder1", context: @course)
      @f2 = @f1.sub_folders.create!(name: "folder2", context: @course)
      att = Attachment.create!(filename: "test.txt",
                               display_name: "testing.txt",
                               uploaded_data: StringIO.new("file"),
                               folder: @f1,
                               context: @course)
      json = api_call(:delete,
                      @folders_path + "/#{@f1.id}",
                      @folders_path_options
                              .merge(action: "api_destroy", id: @f1.id.to_param),
                      {},
                      {},
                      expected_status: 400)
      expect(json["message"]).to eq "Can't delete a folder with content"
      @f1.reload
      expect(@f1.workflow_state).to eq "visible"
      @f2.reload
      expect(@f2.workflow_state).to eq "visible"
      att.reload
      expect(att.workflow_state).to eq "processed"
    end

    it "allows deleting folders with contents with force flag" do
      @f1 = @root.sub_folders.create!(name: "folder1", context: @course)
      @f2 = @f1.sub_folders.create!(name: "folder2", context: @course)
      api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(action: "api_destroy", id: @f1.id.to_param), { force: true })
      @f1.reload
      expect(@f1.workflow_state).to eq "deleted"
      @f2.reload
      expect(@f2.workflow_state).to eq "deleted"
    end

    it "will not delete a submissions folder" do
      user_model
      api_call_as_user(@user,
                       :delete,
                       @folders_path + "/#{@user.submissions_folder.id}",
                       @folders_path_options.merge(action: "api_destroy", id: @user.submissions_folder.to_param),
                       { force: true },
                       {},
                       { expected_status: 401 })
    end

    it "returns unauthorized error" do
      course_with_student(course: @course)
      @f1 = @root.sub_folders.create!(name: "folder1", context: @course)
      raw_api_call(:delete, @folders_path + "/#{@f1.id}", @folders_path_options.merge(action: "api_destroy", id: @f1.id.to_param), {})
      expect(response).to have_http_status :unauthorized
      @f1.reload
      expect(@f1.workflow_state).to eq "visible"
    end

    context "as teacher without manage_files_delete permission" do
      before do
        teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: @course.root_account.id)
        RoleOverride.create!(
          permission: "manage_files_delete",
          enabled: false,
          role: teacher_role,
          account: @course.root_account
        )
      end

      it "disallows deleting an empty folder" do
        @f1 = @root.sub_folders.create!(name: "folder1", context: @course)
        api_call(:delete,
                 @folders_path + "/#{@f1.id}",
                 @folders_path_options.merge(action: "api_destroy", id: @f1.id.to_param),
                 {},
                 { expected_status: 401 })
      end

      it "disallows deleting folders with contents with force flag" do
        @f1 = @root.sub_folders.create!(name: "folder1", context: @course)
        @f2 = @f1.sub_folders.create!(name: "folder2", context: @course)
        api_call(:delete,
                 @folders_path + "/#{@f1.id}",
                 @folders_path_options.merge(action: "api_destroy", id: @f1.id.to_param),
                 { force: true },
                 { expected_status: 401 })
      end
    end
  end

  describe "#create" do
    append_before do
      @folders_path_options = { controller: "folders", action: "create", format: "json" }
    end

    it "creates in unfiled folder" do
      api_call(:post,
               "/api/v1/users/#{@user.id}/folders",
               @folders_path_options.merge(user_id: @user.id.to_param),
               { name: "f1", hidden: "true" },
               {})

      unfiled = Folder.unfiled_folder(@user)
      expect(unfiled.sub_folders.count).to eq 1
      f1 = unfiled.sub_folders.first
      expect(f1.name).to eq "f1"
      expect(f1.hidden).to be true
    end

    it "creates by folder id" do
      group_model(context: @course)
      @root = Folder.root_folders(@group).first
      @f1 = @root.sub_folders.create!(name: "folder1", context: @group)

      api_call(:post,
               "/api/v1/groups/#{@group.id}/folders",
               @folders_path_options.merge(group_id: @group.id.to_param),
               { name: "sub1", locked: "true", parent_folder_id: @f1.id.to_param },
               {})
      @f1.reload
      sub1 = @f1.sub_folders.first
      expect(sub1.name).to eq "sub1"
      expect(sub1.locked).to be true
    end

    it "creates by folder id in the path" do
      group_model(context: @course)
      @root = Folder.root_folders(@group).first
      @f1 = @root.sub_folders.create!(name: "folder1", context: @group)

      api_call(:post,
               "/api/v1/folders/#{@f1.id}/folders",
               @folders_path_options.merge(folder_id: @f1.id.to_param),
               { name: "sub1", locked: "true" },
               {})
      @f1.reload
      sub1 = @f1.sub_folders.first
      expect(sub1.name).to eq "sub1"
      expect(sub1.locked).to be true
    end

    it "errors with invalid folder id" do
      api_call(:post,
               "/api/v1/folders/0/folders",
               @folders_path_options.merge(folder_id: "0"),
               { name: "sub1", locked: "true" },
               {},
               expected_status: 404)
    end

    it "gives error folder is used and path sent" do
      json = api_call(:post,
                      "/api/v1/folders/#{@root.id}/folders",
                      @folders_path_options.merge(folder_id: @root.id.to_param),
                      { name: "sub1", locked: "true", parent_folder_path: "haha/fool" },
                      {},
                      expected_status: 400)
      expect(json["message"]).to eq "Can't set folder path and folder id"
    end

    it "gives error folder is used and id sent" do
      json = api_call(:post,
                      "/api/v1/folders/#{@root.id}/folders",
                      @folders_path_options.merge(folder_id: @root.id.to_param),
                      { name: "sub1", locked: "true", parent_folder_id: @root.id.to_param },
                      {},
                      expected_status: 400)
      expect(json["message"]).to eq "Can't set folder path and folder id"
    end

    it "creates by folder path" do
      api_call(:post,
               "/api/v1/courses/#{@course.id}/folders",
               @folders_path_options.merge(course_id: @course.id.to_param),
               { name: "sub1", parent_folder_path: "subfolder/path" },
               {})

      @root.reload
      expect(@root.sub_folders.count).to eq 1
      subfolder = @root.sub_folders.first
      expect(subfolder.name).to eq "subfolder"
      expect(subfolder.sub_folders.count).to eq 1
      path = subfolder.sub_folders.first
      expect(path.name).to eq "path"
      expect(path.sub_folders.count).to eq 1
      sub1 = path.sub_folders.first
      expect(sub1.name).to eq "sub1"
    end

    it "errors with invalid parent id" do
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/folders",
                      @folders_path_options.merge(course_id: @course.id.to_param),
                      { name: "sub1", locked: "true", parent_folder_id: "0" },
                      {},
                      expected_status: 404)
      message = json["errors"][0]["message"]
      expect(message).to eq "The specified resource does not exist."
    end

    it "errors with deleted folder id" do
      root = Folder.root_folders(@course).first
      sub = root.sub_folders.create!(name: "folder1", context: @course, workflow_state: "deleted")
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/folders",
                      @folders_path_options.merge(course_id: @course.id.to_param),
                      { name: "test", parent_folder_id: sub.id },
                      {},
                      expected_status: 404)
      message = json["errors"][0]["message"]
      expect(message).to eq "The specified resource does not exist."
    end

    it "gives error if path and id are passed" do
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/folders",
                      @folders_path_options.merge(course_id: @course.id.to_param),
                      { name: "sub1", locked: "true", parent_folder_id: "0", parent_folder_path: "haha/fool" },
                      {},
                      expected_status: 400)
      expect(json["message"]).to eq "Can't set folder path and folder id"
    end

    it "returns unauthorized error" do
      course_with_student(course: @course)
      api_call(:post,
               "/api/v1/courses/#{@course.id}/folders",
               @folders_path_options.merge(course_id: @course.id.to_param),
               { name: "sub1" },
               {},
               expected_status: 401)
    end

    it "errors if the name is too long" do
      api_call(:post,
               "/api/v1/courses/#{@course.id}/folders",
               @folders_path_options.merge(course_id: @course.id.to_param),
               { name: "X" * 256 },
               {},
               expected_status: 400)
    end

    it "fails to create in a submissions folder (user context)" do
      sub_folder = @user.submissions_folder
      api_call(:post,
               "/api/v1/users/#{@user.id}/folders",
               @folders_path_options.merge(user_id: @user.to_param),
               { name: "booga", parent_folder_id: sub_folder.to_param },
               {},
               expected_status: 401)
    end

    it "fails to create in a submissions folder (folder context)" do
      sub_folder = @user.submissions_folder
      api_call(:post,
               "/api/v1/folders/#{sub_folder.id}/folders",
               @folders_path_options.merge(folder_id: sub_folder.to_param),
               { name: "booga" },
               {},
               expected_status: 401)
    end

    context "as teacher without manage_files_add permission" do
      before do
        teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: @course.root_account.id)
        RoleOverride.create!(
          permission: "manage_files_add",
          enabled: false,
          role: teacher_role,
          account: @course.root_account
        )
      end

      it "disallows creating by folder path in course context" do
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/folders",
                 @folders_path_options.merge(course_id: @course.id.to_param),
                 { name: "sub1", parent_folder_path: "subfolder/path" },
                 {},
                 expected_status: 401)
      end
    end
  end

  describe "#update" do
    before :once do
      @sub1 = @root.sub_folders.create!(name: "sub1", context: @course)
      @update_url = @folders_path + "/#{@sub1.id}"
      @folders_path_options = { controller: "folders", action: "update", format: "json", id: @sub1.id.to_param }
    end

    it "updates" do
      @sub2 = @root.sub_folders.create!(name: "sub2", context: @course)
      api_call(:put, @update_url, @folders_path_options, { name: "new name", parent_folder_id: @sub2.id.to_param }, {}, expected_status: 200)
      @sub1.reload
      expect(@sub1.name).to eq "new name"
      expect(@sub1.parent_folder_id).to eq @sub2.id
    end

    it "returns unauthorized error" do
      course_with_student(course: @course)
      api_call(:put, @update_url, @folders_path_options, { name: "new name" }, {}, expected_status: 401)
    end

    it "404s with invalid parent id" do
      api_call(:put, @update_url, @folders_path_options, { name: "new name", parent_folder_id: 0 }, {}, expected_status: 404)
    end

    it "does not allow moving to different context" do
      user_root = Folder.root_folders(@user).first
      api_call(:put, @update_url, @folders_path_options, { name: "new name", parent_folder_id: user_root.id.to_param }, {}, expected_status: 404)
    end

    it "does not move a folder into a submissions folder" do
      sub_folder = @user.submissions_folder
      source_folder = @user.folders.create! name: "hello"
      api_call(:put,
               "/api/v1/folders/#{source_folder.id}",
               @folders_path_options.merge(id: source_folder.to_param),
               { parent_folder_id: sub_folder.to_param },
               {},
               { expected_status: 401 })
    end

    context "as teacher without manage_files_edit permission" do
      before do
        teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: @course.root_account.id)
        RoleOverride.create!(
          permission: "manage_files_edit",
          enabled: false,
          role: teacher_role,
          account: @course.root_account
        )
      end

      it "disallows modifying a folder" do
        @sub2 = @root.sub_folders.create!(name: "sub2", context: @course)
        api_call(:put,
                 @update_url,
                 @folders_path_options,
                 { name: "new name", parent_folder_id: @sub2.id.to_param },
                 {},
                 expected_status: 401)
      end
    end
  end

  describe "#create_file" do
    it "creates a file in the correct folder" do
      @context = course_with_teacher
      @user = @teacher
      @root_folder = Folder.root_folders(@course).first
      api_call(:post,
               "/api/v1/folders/#{@root_folder.id}/files",
               { controller: "folders", action: "create_file", format: "json", folder_id: @root_folder.id.to_param },
               name: "with_path.txt")
      attachment = Attachment.order(:id).last
      expect(attachment.folder_id).to eq @root_folder.id
    end

    it "does not create a file in a submissions folder" do
      user_model
      sub_folder = @user.submissions_folder
      api_call(:post,
               "/api/v1/folders/#{sub_folder.id}/files",
               { controller: "folders", action: "create_file", format: "json", folder_id: sub_folder.to_param },
               { name: "with_path.txt" },
               {},
               { expected_status: 401 })
    end

    context "as teacher without manage_files_add permission" do
      before do
        teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: @course.root_account.id)
        RoleOverride.create!(
          permission: "manage_files_add",
          enabled: false,
          role: teacher_role,
          account: @course.root_account
        )
      end

      it "disallows creating a file in the correct folder" do
        api_call(:post,
                 "/api/v1/folders/#{@root.id}/files",
                 { controller: "folders", action: "create_file", format: "json", folder_id: @root.id.to_param },
                 { name: "with_path.txt" },
                 {},
                 { expected_status: 401 })
      end
    end
  end

  describe "#resolve_path" do
    before :once do
      @params_hash = { controller: "folders", action: "resolve_path", format: "json" }
    end

    context "course" do
      before :once do
        course_factory active_all: true
        @root_folder = Folder.root_folders(@course).first
        @request_path = "/api/v1/courses/#{@course.id}/folders/by_path"
        @params_hash[:course_id] = @course.to_param
      end

      it "checks permissions" do
        user_factory
        api_call(:get, @request_path, @params_hash, {}, {}, { expected_status: 401 })
      end

      it "operates on an empty path" do
        student_in_course
        json = api_call(:get, @request_path, @params_hash)
        expect(json.pluck("id")).to eql [@root_folder.id]
      end

      describe "with full_path" do
        before :once do
          @folder = @course.folders.create! parent_folder: @root_folder, name: "a folder"
          @sub_folder = @course.folders.create! parent_folder: @folder, name: "locked subfolder", locked: true
          @path = [@folder.name, @sub_folder.name].join("/")
          @request_path += "/#{URI::DEFAULT_PARSER.escape(@path)}"
          @params_hash.merge!(full_path: @path)
        end

        it "returns a list of path components" do
          teacher_in_course
          json = api_call(:get, @request_path, @params_hash)
          expect(json.pluck("id")).to eql [@root_folder.id, @folder.id, @sub_folder.id]
        end

        it "404s on an invalid path" do
          teacher_in_course
          api_call(:get,
                   @request_path + "/nonexistent",
                   @params_hash.dup.merge(full_path: @path + "/nonexistent"),
                   {},
                   {},
                   { expected_status: 404 })
        end

        it "does not traverse hidden or locked paths for students" do
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

      it "accepts an empty path" do
        json = api_call(:get, "/api/v1/groups/#{@group.id}/folders/by_path/", @params_hash)
        expect(json.pluck("id")).to eql [@root_folder.id]
      end

      it "accepts a non-empty path" do
        @folder = @group.folders.create! parent_folder: @root_folder, name: "some folder"
        json = api_call(:get, "/api/v1/groups/#{@group.id}/folders/by_path/#{URI::DEFAULT_PARSER.escape(@folder.name)}", @params_hash.merge(full_path: @folder.name))
        expect(json.pluck("id")).to eql [@root_folder.id, @folder.id]
      end
    end

    context "user" do
      before :once do
        user_factory active_all: true
        @root_folder = Folder.root_folders(@user).first
        @params_hash.merge!(user_id: @user.id)
      end

      it "accepts an empty path" do
        json = api_call(:get, "/api/v1/users/#{@user.id}/folders/by_path/", @params_hash)
        expect(json.pluck("id")).to eql [@root_folder.id]
      end

      it "accepts a non-empty path" do
        @folder = @user.folders.create! parent_folder: @root_folder, name: "some folder"
        json = api_call(:get, "/api/v1/users/#{@user.id}/folders/by_path/#{URI::DEFAULT_PARSER.escape(@folder.name)}", @params_hash.merge(full_path: @folder.name))
        expect(json.pluck("id")).to eql [@root_folder.id, @folder.id]
      end
    end
  end

  describe "copy_folder" do
    before :once do
      @source_context = course_factory active_all: true
      @source_folder = @source_context.folders.create! name: "teh folder"
      @file = attachment_model context: @source_context, folder: @source_folder, display_name: "foo"
      @params_hash = { controller: "folders", action: "copy_folder", format: "json" }
      @dest_context = course_factory active_all: true
      @dest_folder = @dest_context.folders.create! name: "put stuff here", parent_folder: Folder.root_folders(@dest_context).first

      user_model
    end

    it "requires :source_folder_id parameter" do
      json = api_call(:post,
                      "/api/v1/folders/#{@dest_folder.id}/copy_folder",
                      @params_hash.merge(dest_folder_id: @dest_folder.to_param),
                      {},
                      {},
                      { expected_status: 400 })
      expect(json["message"]).to include "source_folder_id"
    end

    it "requires any manage_files permissions on the source context" do
      @source_context.enroll_student(@user, enrollment_state: "active")
      @dest_context.enroll_teacher(@user, enrollment_state: "active")
      api_call(:post,
               "/api/v1/folders/#{@dest_folder.id}/copy_folder?source_folder_id=#{@source_folder.id}",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_folder_id: @source_folder.to_param),
               {},
               {},
               { expected_status: 401 })
    end

    it "requires :create permission on the destination folder" do
      @source_context.enroll_teacher(@user, enrollment_state: "active")
      @dest_context.enroll_student(@user, enrollment_state: "active")
      api_call(:post,
               "/api/v1/folders/#{@dest_folder.id}/copy_folder?source_folder_id=#{@source_folder.id}",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_folder_id: @source_folder.to_param),
               {},
               {},
               { expected_status: 401 })
    end

    it "copies a folder" do
      @source_context.enroll_teacher(@user, enrollment_state: "active")
      @dest_context.enroll_teacher(@user, enrollment_state: "active")
      json = api_call(:post,
                      "/api/v1/folders/#{@dest_folder.id}/copy_folder?source_folder_id=#{@source_folder.id}",
                      @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_folder_id: @source_folder.to_param))

      copy = Folder.find(json["id"])
      expect(copy.parent_folder).to eq(@dest_folder)
      contents = copy.active_file_attachments.to_a
      expect(contents.size).to eq 1
      expect(contents.first.root_attachment).to eq @file
    end

    context "within context" do
      before :once do
        @source_context.enroll_teacher(@user, enrollment_state: "active")
      end

      it "copies a folder within a context" do
        @new_folder = @source_context.folders.create! name: "new folder"
        json = api_call(:post,
                        "/api/v1/folders/#{@new_folder.id}/copy_folder?source_folder_id=#{@source_folder.id}",
                        @params_hash.merge(dest_folder_id: @new_folder.to_param, source_folder_id: @source_folder.to_param))
        copy = Folder.find(json["id"])
        expect(copy.id).not_to eq @source_folder.id
        expect(copy.parent_folder).to eq @new_folder
        expect(copy.active_file_attachments.first.root_attachment).to eq @file
      end

      it "renames if the folder already exists" do
        root_dir = @source_folder.parent_folder
        json = api_call(:post,
                        "/api/v1/folders/#{root_dir.id}/copy_folder?source_folder_id=#{@source_folder.id}",
                        @params_hash.merge(dest_folder_id: root_dir.to_param, source_folder_id: @source_folder.to_param))
        copy = Folder.find(json["id"])
        expect(copy.id).not_to eq @source_folder.id
        expect(copy.name).to start_with @source_folder.name
        expect(copy.name).not_to eq @source_folder.name
        expect(copy.active_file_attachments.first.root_attachment).to eq @file
      end

      it "refuses to copy a folder into itself" do
        json = api_call(:post,
                        "/api/v1/folders/#{@source_folder.id}/copy_folder?source_folder_id=#{@source_folder.id}",
                        @params_hash.merge(dest_folder_id: @source_folder.to_param, source_folder_id: @source_folder.to_param),
                        {},
                        {},
                        { expected_status: 400 })
        expect(json["message"]).to eq "source folder may not contain destination folder"
      end

      it "refuses to copy a folder into a descendant" do
        subsub = @source_context.folders.create! parent_folder: @source_folder, name: "subsub"
        json = api_call(:post,
                        "/api/v1/folders/#{subsub.id}/copy_folder?source_folder_id=#{@source_folder.id}",
                        @params_hash.merge(dest_folder_id: subsub.to_param, source_folder_id: @source_folder.to_param),
                        {},
                        {},
                        { expected_status: 400 })
        expect(json["message"]).to eq "source folder may not contain destination folder"
      end

      it "refuses to copy a folder into a submissions folder" do
        sub_folder = @user.submissions_folder
        source_folder = @user.folders.create! name: "source"
        api_call(:post,
                 "/api/v1/folders/#{sub_folder.id}/copy_folder?source_folder_id=#{source_folder.id}",
                 @params_hash.merge(dest_folder_id: sub_folder.to_param, source_folder_id: source_folder.to_param),
                 {},
                 {},
                 { expected_status: 401 })
      end
    end
  end

  describe "copy_file" do
    before :once do
      @params_hash = { controller: "folders", action: "copy_file", format: "json" }
      @dest_context = course_factory active_all: true
      @dest_folder = @dest_context.folders.create! name: "put stuff here", parent_folder: Folder.root_folders(@dest_context).first

      user_model
      @source_file = attachment_model context: @user, display_name: "baz"
    end

    it "requires :source_file_id parameter" do
      json = api_call(:post,
                      "/api/v1/folders/#{@dest_folder.id}/copy_file",
                      @params_hash.merge(dest_folder_id: @dest_folder.to_param),
                      {},
                      {},
                      { expected_status: 400 })
      expect(json["message"]).to include "source_file_id"
    end

    it "requires :download permission on the source file" do
      @user = @dest_context.teachers.first
      api_call(:post,
               "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@source_file.id}",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @source_file.to_param),
               {},
               {},
               { expected_status: 401 })
      expect(@dest_folder.active_file_attachments).not_to be_exists
    end

    it "requires :manage_files permission on the destination context" do
      api_call(:post,
               "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@source_file.id}",
               @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @source_file.to_param),
               {},
               {},
               { expected_status: 401 })
      expect(@dest_folder.active_file_attachments).not_to be_exists
    end

    it "copies a file" do
      @dest_context.enroll_teacher @user, enrollment_state: "active"
      json = api_call(:post,
                      "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@source_file.id}",
                      @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @source_file.to_param))
      file = Attachment.find(json["id"])
      expect(file.folder).to eq(@dest_folder)
      expect(file.root_attachment).to eq(@source_file)
      expect(json["url"]).to include "verifier="
    end

    it "omits verifier in-app" do
      allow_any_instance_of(FoldersController).to receive(:in_app?).and_return(true)
      allow_any_instance_of(FoldersController).to receive(:verified_request?).and_return(true)

      @dest_context.enroll_teacher @user, enrollment_state: "active"
      json = api_call(:post,
                      "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@source_file.id}",
                      @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @source_file.to_param))
      expect(json["url"]).not_to include "verifier="
    end

    context "within context" do
      before :once do
        @dest_context.enroll_teacher @user, enrollment_state: "active"
        @file = attachment_model context: @dest_context, folder: Folder.root_folders(@dest_context).first
      end

      it "copies a file within a context" do
        json = api_call(:post,
                        "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@file.id}",
                        @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @file.to_param))
        file = Attachment.find(json["id"])
        expect(file).not_to eq(@file)
        expect(file.root_attachment).to eq(@file)
        expect(file.folder).to eq(@dest_folder)
      end

      it "fails if the file already exists and on_duplicate was not given" do
        attachment_model context: @dest_context, folder: @dest_folder, display_name: @file.display_name
        json = api_call(:post,
                        "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@file.id}",
                        @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @file.to_param),
                        {},
                        {},
                        { expected_status: 409 })
        expect(json["message"]).to include "already exists"
        expect(@dest_context.attachments.active.count).to eq 2
      end

      it "overwrites if asked" do
        other_file = attachment_model context: @dest_context, folder: @dest_folder, display_name: @file.display_name
        json = api_call(:post,
                        "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@file.id}&on_duplicate=overwrite",
                        @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @file.to_param, on_duplicate: "overwrite"))
        file = Attachment.find(json["id"])
        expect(file).not_to eq(@file)
        expect(file.root_attachment).to eq(@file)
        expect(file.folder).to eq(@dest_folder)
        expect(file.display_name).to eq(json["display_name"])
        expect(file.display_name).to eq(@file.display_name)
        expect(other_file.reload).to be_deleted
        expect(other_file.replacement_attachment).to eq(file)
      end

      it "renames if asked" do
        @file.update_attribute(:folder_id, @dest_folder.id)
        json = api_call(:post,
                        "/api/v1/folders/#{@dest_folder.id}/copy_file?source_file_id=#{@file.id}&on_duplicate=rename",
                        @params_hash.merge(dest_folder_id: @dest_folder.to_param, source_file_id: @file.to_param, on_duplicate: "rename"))
        file = Attachment.find(json["id"])
        expect(file).not_to eq(@file)
        expect(file.root_attachment).to eq(@file)
        expect(file.folder).to eq(@dest_folder)
        expect(file.display_name).to eq(json["display_name"])
        expect(file.display_name).not_to eq(@file.display_name)
      end
    end

    it "refuses to copy a file into a submissions folder" do
      sub_folder = @user.submissions_folder
      api_call(:post,
               "/api/v1/folders/#{sub_folder.id}/copy_file?source_file_id=#{@source_file.id}",
               @params_hash.merge(dest_folder_id: sub_folder.to_param, source_file_id: @source_file.to_param),
               {},
               {},
               { expected_status: 401 })
    end
  end

  describe "#list_all_folders" do
    def make_folders_in_context(context, duplicatenames: false)
      @root = Folder.root_folders(context).first
      @f1 = @root.sub_folders.create!(name: "folder1", context:, position: 1)
      @f2 = @root.sub_folders.create!(name: "folder2", context:, position: 2)
      @f3 = @f2.sub_folders.create!(name: "folder2.1", context:, position: 3)
      @f4 = @f3.sub_folders.create!(name: "folder2.1.1", context:, position: 4)
      @f5 = @f4.sub_folders.create!(name: "folderlocked", context:, position: 5, locked: true)
      @f6 = @f5.sub_folders.create!(name: "folderhidden", context:, position: 6, hidden: true)
      if duplicatenames
        @f7 = @f2.sub_folders.create!(name: "folder1", context:, position: 7)
        @f8 = @f3.sub_folders.create!(name: "folder1", context:, position: 8)
        @f9 = @f4.sub_folders.create!(name: "folder1", context:, position: 9)
      end
    end

    context "course" do
      before :once do
        course_with_teacher(active_all: true)
        student_in_course(active_all: true)
        make_folders_in_context(@course, duplicatenames: true)
      end

      it "lists all folders in a course including subfolders" do
        @user = @teacher
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/folders",
                        { controller: "folders", action: "list_all_folders", format: "json", course_id: @course.id.to_param })
        res = json.pluck("name")
        expect(res).to eq ["course files", "folder1", "folder1", "folder1", "folder1", "folder2", "folder2.1", "folder2.1.1", "folderhidden", "folderlocked"]
      end

      it "does not show hidden and locked files to unauthorized users" do
        @user = @student
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/folders",
                        { controller: "folders", action: "list_all_folders", format: "json", course_id: @course.id.to_param })
        res = json.pluck("name")
        expect(res).to eq ["course files", "folder1", "folder1", "folder1", "folder1", "folder2", "folder2.1", "folder2.1.1"]
      end

      it "returns a 401 for unauthorized users" do
        @user = user_factory(active_all: true)
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/folders",
                 { controller: "folders", action: "list_all_folders", format: "json", course_id: @course.id.to_param },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "paginates the folder list" do
        @user = @teacher
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/folders",
                        { controller: "folders", action: "list_all_folders", format: "json", course_id: @course.id.to_param, per_page: 3 })

        expect(json.length).to eq 3
        links = response.headers["Link"].split(",")
        expect(links.all? { |l| l =~ %r{api/v1/courses/#{@course.id}/folders} }).to be_truthy
        expect(links.find { |l| l.include?('rel="next"') }).to match(/page=2&per_page=3>/)
        expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
        expect(links.find { |l| l.include?('rel="last"') }).to match(/page=4&per_page=3>/)

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/folders",
                        { controller: "folders", action: "list_all_folders", format: "json", course_id: @course.id.to_param, per_page: 3, page: 4 })
        expect(json.length).to eq 1
        links = response.headers["Link"].split(",")
        expect(links.all? { |l| l =~ %r{api/v1/courses/#{@course.id}/folders} }).to be_truthy
        expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=3&per_page=3>/)
        expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
        expect(links.find { |l| l.include?('rel="last"') }).to match(/page=4&per_page=3>/)
      end

      it "doesnt drop items in pagination" do
        @user = @teacher
        folders = []
        4.times do |i|
          folders.push(*api_call(:get,
                                 "/api/v1/courses/#{@course.id}/folders",
                                 { controller: "folders", action: "list_all_folders", format: "json", course_id: @course.id.to_param, per_page: 3, page: i + 1 }))
        end
        res = folders.pluck("full_name")
        expect(res.size).to eq res.uniq.size
      end
    end

    context "group" do
      it "lists all folders in a group including subfolders" do
        group_with_user(active_all: true)
        make_folders_in_context @group
        json = api_call(:get,
                        "/api/v1/groups/#{@group.id}/folders",
                        { controller: "folders", action: "list_all_folders", format: "json", group_id: @group.id.to_param })
        res = json.pluck("name")
        expect(res).to eq %w[files folder1 folder2 folder2.1 folder2.1.1 folderhidden folderlocked]
      end
    end

    context "user" do
      it "lists all folders owned by a user including subfolders" do
        user_factory(active_all: true)
        make_folders_in_context @user
        json = api_call(:get,
                        "/api/v1/users/#{@user.id}/folders",
                        { controller: "folders", action: "list_all_folders", format: "json", user_id: @user.id.to_param })
        res = json.pluck("name")
        expect(res).to eq ["folder1", "folder2", "folder2.1", "folder2.1.1", "folderhidden", "folderlocked", "my files"]
      end
    end
  end
end
