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

describe "Files API", :type => :integration do
  before do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
  end

  describe "api_create_success" do
    before do
      @attachment = Attachment.new
      @attachment.context = @course
      @attachment.filename = "test.txt"
      @attachment.file_state = 'deleted'
      @attachment.workflow_state = 'unattached'
      @attachment.content_type = "text/plain"
      @attachment.save!
    end

    def upload_data
      @attachment.workflow_state = nil
      @content = Tempfile.new(["test", ".txt"])
      def @content.content_type
        "text/plain"
      end
      @content.write("test file")
      @content.rewind
      @attachment.uploaded_data = @content
      @attachment.save!
    end

    it "should set the attachment to available (local storage)" do
      local_storage!
      upload_data
      json = api_call(:post, "/api/v1/files/#{@attachment.id}/create_success?uuid=#{@attachment.uuid}",
                   { :controller => "files", :action => "api_create_success", :format => "json", :id => @attachment.to_param, :uuid => @attachment.uuid })
      json.should == {
        'id' => @attachment.id,
        'url' => file_download_url(@attachment, :verifier => @attachment.uuid, :download => '1', :download_frd => '1'),
        'content-type' => 'text/plain',
        'display_name' => 'test.txt',
        'filename' => @attachment.filename,
        'size' => @attachment.size,
      }
      @attachment.reload.file_state.should == 'available'
    end

    it "should set the attachment to available (s3 storage)" do
      s3_storage!
      AWS::S3::S3Object.expects(:about).with(@attachment.full_filename, @attachment.bucket_name).returns({
        'content-type' => 'text/plain',
        'content-length' => 1234,
      })
      json = api_call(:post, "/api/v1/files/#{@attachment.id}/create_success?uuid=#{@attachment.uuid}",
                   { :controller => "files", :action => "api_create_success", :format => "json", :id => @attachment.to_param, :uuid => @attachment.uuid })
      @attachment.reload
      json.should == {
        'id' => @attachment.id,
        'url' => file_download_url(@attachment, :verifier => @attachment.uuid, :download => '1', :download_frd => '1'),
        'content-type' => 'text/plain',
        'display_name' => 'test.txt',
        'filename' => @attachment.filename,
        'size' => @attachment.size,
      }
      @attachment.reload.file_state.should == 'available'
    end

    it "should fail for an incorrect uuid" do
      upload_data
      raw_api_call(:post, "/api/v1/files/#{@attachment.id}/create_success?uuid=abcde",
                   { :controller => "files", :action => "api_create_success", :format => "json", :id => @attachment.to_param, :uuid => "abcde" })
      response.status.to_i.should == 400
    end

    it "should fail if the attachment is already available" do
      upload_data
      @attachment.update_attribute(:file_state, 'available')
      raw_api_call(:post, "/api/v1/files/#{@attachment.id}/create_success?uuid=#{@attachment.uuid}",
                   { :controller => "files", :action => "api_create_success", :format => "json", :id => @attachment.to_param, :uuid => @attachment.uuid })
      response.status.to_i.should == 400
    end
  end

  describe "#index" do
    append_before do
      @root = Folder.root_folders(@course).first
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      @a1 = Attachment.create!(:filename => 'ztest.txt', :display_name => "ztest.txt", :position => 1, :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course)
      @a3 = Attachment.create(:filename => 'atest3.txt', :display_name => "atest3.txt", :position => 2, :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course)
      @a3.hidden = true
      @a3.save!
      @a2 = Attachment.create!(:filename => 'mtest2.txt', :display_name => "mtest2.txt", :position => 3, :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course, :locked => true)

      @files_path = "/api/v1/folders/#{@f1.id}/files"
      @files_path_options = { :controller => "files", :action => "api_index", :format => "json", :id => @f1.id.to_param }
    end

    it "should list files in alphabetical order" do
      json = api_call(:get, @files_path, @files_path_options, {})
      res = json.map{|f|f['display_name']}
      res.should == %w{atest3.txt mtest2.txt ztest.txt}
    end

    it "should list files in saved order if flag set" do
      json = api_call(:get, @files_path + "?sort_by=position", @files_path_options.merge(:sort_by => 'position'), {})
      res = json.map{|f|f['display_name']}
      res.should == %w{ztest.txt atest3.txt mtest2.txt}
    end

    it "should not list locked file if not authed" do
      course_with_student(:course => @course)
      json = api_call(:get, @files_path, @files_path_options, {})
      json.any?{|f|f[:id] == @a2.id}.should == false
    end

    it "should not list hidden files if not authed" do
      course_with_student(:course => @course)
      json = api_call(:get, @files_path, @files_path_options, {})

      json.any?{|f|f[:id] == @a3.id}.should == false
    end

    it "should not list locked folder if not authed" do
      @f1.locked = true
      @f1.save!
      course_with_student(:course => @course)
      raw_api_call(:get, @files_path, @files_path_options, {}, {}, :expected_status => 401)
    end

    it "should 404 for no folder found" do
      raw_api_call(:get, "/api/v1/folders/0/files", @files_path_options.merge(:id => "0"), {}, {}, :expected_status => 404)
    end

    it "should paginate" do
      7.times {|i| Attachment.create!(:filename => "test#{i}.txt", :display_name => "test#{i}.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course) }
      json = api_call(:get, "/api/v1/folders/#{@root.id}/files?per_page=3", @files_path_options.merge(:id => @root.id.to_param, :per_page => '3'), {})
      json.length.should == 3
      response.headers['Link'].should == [
        %{<http://www.example.com/api/v1/folders/#{@root.id}/files?page=2&per_page=3>; rel="next"},
        %{<http://www.example.com/api/v1/folders/#{@root.id}/files?page=1&per_page=3>; rel="first"},
        %{<http://www.example.com/api/v1/folders/#{@root.id}/files?page=3&per_page=3>; rel="last"}
      ].join(',')

      json = api_call(:get, "/api/v1/folders/#{@root.id}/files?per_page=3&page=3", @files_path_options.merge(:id => @root.id.to_param, :per_page => '3', :page => '3'), {})
      json.length.should == 1
      response.headers['Link'].should == [
        %{<http://www.example.com/api/v1/folders/#{@root.id}/files?page=2&per_page=3>; rel="prev"},
        %{<http://www.example.com/api/v1/folders/#{@root.id}/files?page=1&per_page=3>; rel="first"},
        %{<http://www.example.com/api/v1/folders/#{@root.id}/files?page=3&per_page=3>; rel="last"}
      ].join(',')
    end
  end

  describe "#show" do
    append_before do
      @root = Folder.root_folders(@course).first
      @att = Attachment.create!(:filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course)
      @file_path = "/api/v1/files/#{@att.id}"
      @file_path_options = { :controller => "files", :action => "api_show", :format => "json", :id => @att.id.to_param }
    end

    it "should return expected json" do
      json = api_call(:get, @file_path, @file_path_options, {})
      json.should == {
              'id' => @att.id,
              'url' => file_download_url(@att, :verifier => @att.uuid, :download => '1', :download_frd => '1'),
              'content-type' => "unknown/unknown",
              'display_name' => 'test.txt',
              'filename' => @att.filename,
              'size' => @att.size,
      }
    end

    it "should return not found error" do
      api_call(:get, "/api/v1/files/0", @file_path_options.merge(:id => '0'), {}, {}, :expected_status => 404)
    end

    it "should return not found for deleted attachment" do
      @att.destroy
      api_call(:get, @file_path, @file_path_options, {}, {}, :expected_status => 404)
    end

    it "should return no permissions error for no context enrollment" do
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      api_call(:get, @file_path, @file_path_options, {}, {}, :expected_status => 401)
    end

    it "should return a hidden file" do
      course_with_student(:course => @course)
      @att.hidden = true
      @att.save!
      api_call(:get, @file_path, @file_path_options, {}, {}, :expected_status => 200)
    end
  end

  describe "#destroy" do
    append_before do
      @root = Folder.root_folders(@course).first
      @att = Attachment.create!(:filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course)
      @file_path = "/api/v1/files/#{@att.id}"
      @file_path_options = { :controller => "files", :action => "destroy", :format => "json", :id => @att.id.to_param }
    end

    it "should delete a file" do
      api_call(:delete, @file_path, @file_path_options)
      @att.reload
      @att.file_state.should == 'deleted'
    end

    it "should return 404" do
      api_call(:delete, "/api/v1/files/0", @file_path_options.merge(:id => '0'), {}, {}, :expected_status => 404)
    end

    it "should return unauthorized error if not authorized to delete" do
      course_with_student(:course => @course)
      api_call(:delete, @file_path, @file_path_options, {}, {}, :expected_status => 401)
    end
  end

  describe "#update" do
    append_before do
      @root = Folder.root_folders(@course).first
      @att = Attachment.create!(:filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course)
      @file_path = "/api/v1/files/#{@att.id}"
      @file_path_options = { :controller => "files", :action => "api_update", :format => "json", :id => @att.id.to_param }
    end

    it "should update" do
      api_call(:put, @file_path, @file_path_options, {:name => "newname.txt", :locked => 'true'}, {}, :expected_status => 200)
      @att.reload
      @att.display_name.should == "newname.txt"
      @att.locked.should == true
    end

    it "should move to another folder" do
      @sub = @root.sub_folders.create!(:name => "sub", :context => @course)
      api_call(:put, @file_path, @file_path_options, {:parent_folder_id => @sub.id.to_param}, {}, :expected_status => 200)
      @att.reload
      @att.folder_id.should == @sub.id
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      api_call(:put, @file_path, @file_path_options, {:name => "new name"}, {}, :expected_status => 401)
    end

    it "should 404 with invalid parent id" do
      api_call(:put, @file_path, @file_path_options, {:parent_folder_id => 0}, {}, :expected_status => 404)
    end

    it "should not allow moving to different context" do
      user_root = Folder.root_folders(@user).first
      api_call(:put, @file_path, @file_path_options, {:parent_folder_id => user_root.id.to_param}, {}, :expected_status => 404)
    end
  end
end
