# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::FolderType do
  let_once(:course) do
    course_with_teacher(active_all: true)
    @course
  end
  let_once(:student) { student_in_course(course: @course) }
  let_once(:folder) { folder_model(context: course) }
  let(:folder_type) { GraphQLTypeTester.new(folder, current_user: @teacher) }

  it "works" do
    expect(folder_type.resolve("_id")).to eq folder.id.to_s
    expect(folder_type.resolve("name")).to eq folder.name
    expect(folder_type.resolve("fullName")).to eq folder.full_name
    expect(folder_type.resolve("contextId")).to eq folder.context_id.to_s
    expect(folder_type.resolve("contextType")).to eq folder.context_type
  end

  it "requires read permission" do
    other_course_student = student_in_course(course: course_factory).user
    resolver = GraphQLTypeTester.new(folder, current_user: other_course_student)
    expect(resolver.resolve("_id")).to be_nil
  end

  it "handles deleted folders" do
    context_value = course
    deleted_folder = folder_model(context: context_value)
    deleted_folder.destroy
    deleted_resolver = GraphQLTypeTester.new(deleted_folder, current_user: @teacher)
    expect(deleted_resolver.resolve("_id")).not_to be_nil
  end

  describe "nested folders and files" do
    before(:once) do
      @sub_folder = folder_model(parent_folder: folder, context: course, name: "sub folder")
      @file1 = attachment_model(context: course, folder:, display_name: "file1")
      @file2 = attachment_model(context: course, folder: @sub_folder, display_name: "file2")
    end

    it "returns sub folders" do
      expect(folder_type.resolve("subFolders { _id }")).to eq [@sub_folder.id.to_s]
      expect(folder_type.resolve("subFolders { name }")).to eq [@sub_folder.name]
    end

    it "returns files in the folder" do
      expect(folder_type.resolve("files { _id }")).to eq [@file1.id.to_s]
      expect(folder_type.resolve("files { displayName }")).to eq [@file1.display_name]
    end

    it "returns folders count" do
      expect(folder_type.resolve("foldersCount")).to eq 1
    end

    it "returns files count" do
      expect(folder_type.resolve("filesCount")).to eq 1
    end
  end

  describe "parent folder" do
    before(:once) do
      @parent_folder = folder_model(context: course, name: "parent folder")
      @child_folder = folder_model(parent_folder: @parent_folder, context: course, name: "child folder")
    end

    it "returns the parent folder" do
      child_resolver = GraphQLTypeTester.new(@child_folder, current_user: @teacher)
      expect(child_resolver.resolve("parentFolderId")).to eq @parent_folder.id.to_s
      expect(child_resolver.resolve("parentFolder { _id }")).to eq @parent_folder.id.to_s
      expect(child_resolver.resolve("parentFolder { name }")).to eq @parent_folder.name
    end

    it "returns null for root folders" do
      root_folder = Folder.root_folders(course).first
      root_resolver = GraphQLTypeTester.new(root_folder, current_user: @teacher)
      expect(root_resolver.resolve("parentFolder { _id }")).to be_nil
    end
  end

  describe "permissions" do
    it "has a canUpload field that checks manage_contents permission" do
      allow_any_instance_of(Folder).to receive(:grants_right?) do |_, _user, permission|
        if permission == :read
          true
        else
          permission == :manage_contents
        end
      end

      expect(folder_type.resolve("canUpload")).to be true

      allow_any_instance_of(Folder).to receive(:grants_right?) do |_, _user, permission|
        permission == :read
      end

      expect(folder_type.resolve("canUpload")).to be false
    end

    it "returns rootFolder status" do
      # Create a real root folder for testing
      root_folder = Folder.root_folders(course).first
      root_resolver = GraphQLTypeTester.new(root_folder, current_user: @teacher)
      expect(root_resolver.resolve("rootFolder")).to be true

      # Create a non-root folder
      child_folder = folder_model(parent_folder: root_folder, context: course)
      child_resolver = GraphQLTypeTester.new(child_folder, current_user: @teacher)
      expect(child_resolver.resolve("rootFolder")).to be false
    end

    it "returns currently_locked status" do
      # Create an unlocked folder
      unlocked_folder = folder_model(context: course)
      unlocked_resolver = GraphQLTypeTester.new(unlocked_folder, current_user: @teacher)
      expect(unlocked_resolver.resolve("currentlyLocked")).to be false

      # Create a locked folder
      locked_folder = folder_model(context: course, locked: true)
      locked_resolver = GraphQLTypeTester.new(locked_folder, current_user: @teacher)
      expect(locked_resolver.resolve("currentlyLocked")).to be true
    end
  end
end
