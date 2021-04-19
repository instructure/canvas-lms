# frozen_string_literal: true

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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# We have the funky indenting here because we will remove this once the granular
# permission stuff is released, and I don't want to complicate the git history
RSpec.shared_examples "course_files" do
describe FoldersController do
  def io
    fixture_file_upload('docs/doc.doc', 'application/msword', true)
  end

  def root_folder
    @root = Folder.root_folders(@course).first
  end

  def course_folder
    @folder = @root.sub_folders.create!(:name => "some folder", :context => @course)
  end

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    root_folder
    set_granular_permission
  end

  describe "GET 'show'" do
    it "should not return hidden files for students" do
      user_session(@student)
      course_folder
      file = @folder.active_file_attachments.build(:filename => 'long_unique_filename', :uploaded_data => io)
      file.context = @course
      file.save!

      get 'show', params: {:course_id => @course.id, :id => @folder.id}, :format => 'json'
      json = json_parse
      expect(json['files'].count).to eql(1)

      file.hidden = true
      file.save!
      get 'show', params: {:course_id => @course.id, :id => @folder.id}, :format => 'json'
      json = json_parse
      expect(json['files'].count).to eql(0)
    end
  end

  describe "PUT 'update'" do
    before(:once) { course_folder }

    it "should require authorization" do
      put 'update', params: {:course_id => @course.id, :id => @folder.id, :folder => {:name => "hi"}}
      assert_unauthorized
    end

    it "should update folder" do
      user_session(@teacher)
      put 'update', params: {:course_id => @course.id, :id => @folder.id, :folder => {:name => "new name"}}
      expect(response).to be_redirect
      expect(assigns[:folder]).not_to be_nil
      expect(assigns[:folder]).to eql(@folder)
      expect(assigns[:folder].name).to eql("new name")
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', params: {:course_id => @course.id, :folder => {:name => "folder"}}
      assert_unauthorized
    end

    it "should create folder" do
      user_session(@teacher)
      post 'create', params: {:course_id => @course.id, :folder => {:name => "new name"}}
      expect(response).to be_redirect
      expect(assigns[:folder]).not_to be_nil
      expect(assigns[:folder].name).to eql("new name")
    end

    it "should force new folders to be sub_folders" do
      user_session(@teacher)
      post 'create', params: {:course_id => @course.id, :folder => {:name => "new name"}}
      expect(response).to be_redirect
      expect(assigns[:folder]).not_to be_nil
      expect(assigns[:folder].name).to eql("new name")
      expect(assigns[:folder].parent_folder_id).not_to be_nil
      # assigns[:folder].parent_folder.name.should eql("unfiled")
    end

    it "should create sub_folder" do
      user_session(@teacher)
      course_folder
      post 'create', params: {:course_id => @course.id, :folder => {:name => "new folder", :parent_folder_id => @folder.id}}
      expect(response).to be_redirect
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) { course_folder }

    it "should require authorization" do
      delete 'destroy', params: {:course_id => @course.id, :id => @folder.id}
      assert_unauthorized
    end

    def delete_folder
      user_session(@teacher)
      yield if block_given?
      delete 'destroy', params: {:course_id => @course.id, :id => @folder.id}
      expect(response).to be_redirect
      expect(assigns[:folder]).not_to be_frozen
      expect(assigns[:folder]).to be_deleted
      @course.reload
      expect(@course.folders).to be_include(@folder)
      expect(@course.folders.active).not_to be_include(@folder)
    end

    it "should delete folder" do
      delete_folder
    end

    it "should delete folder with contents" do
      delete_folder do
        @folder.sub_folders.create!(:name => "folder2", :context => @course)
      end
    end
  end
end
end # End shared_example block

RSpec.describe 'With granular permission on' do
  it_behaves_like "course_files" do
    let(:set_granular_permission) { @course.root_account.enable_feature!(:granular_permissions_course_files) }
  end
end

RSpec.describe 'With granular permission off' do
  it_behaves_like "course_files" do
    let(:set_granular_permission) { @course.root_account.disable_feature!(:granular_permissions_course_files) }
  end
end