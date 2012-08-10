#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/api_spec_helper')

shared_examples_for "file uploads api" do
  it "should upload (local files)" do
    filename = "my_essay.doc"
    content = "this is a test doc"

    local_storage!
    # step 1, preflight
    json = preflight({ :name => filename })
    attachment = Attachment.last(:order => :id)
    exemption_string = has_query_exemption? ? ("?quota_exemption=" + attachment.quota_exemption_key) : ""
    json['upload_url'].should == "http://www.example.com/files_api#{exemption_string}"

    # step 2, upload
    tmpfile = Tempfile.new(["test", File.extname(filename)])
    tmpfile.write(content)
    tmpfile.rewind
    post_params = json["upload_params"].merge({"file" => tmpfile})
    send_multipart(json["upload_url"], post_params)

    attachment = Attachment.last(:order => :id)
    attachment.should be_deleted
    exemption_string = has_query_exemption? ? ("quota_exemption=" + attachment.quota_exemption_key + "&") : ""
    response.should redirect_to("http://www.example.com/api/v1/files/#{attachment.id}/create_success?#{exemption_string}uuid=#{attachment.uuid}")

    # step 3, confirmation
    post response['Location'], {}, { 'Authorization' => "Bearer #{@user.access_tokens.first.token}" }
    response.should be_success
    attachment.reload
    json = json_parse(response.body)
    json.should == {
      'id' => attachment.id,
      'url' => file_download_url(attachment, :verifier => attachment.uuid, :download => '1', :download_frd => '1'),
      'content-type' => attachment.content_type,
      'display_name' => attachment.display_name,
      'filename' => attachment.filename,
      'size' => tmpfile.size,
    }

    attachment.file_state.should == 'available'
    attachment.content_type.should == "application/msword"
    attachment.open.read.should == content
    attachment.display_name.should == filename
    attachment
  end

  it "should upload (s3 files)" do
    filename = "my_essay.doc"
    content = "this is a test doc"

    s3_storage!
    # step 1, preflight
    json = preflight({ :name => filename })
    json['upload_url'].should == "http://no-bucket.s3.amazonaws.com/"
    attachment = Attachment.last(:order => :id)
    redir = json['upload_params']['success_action_redirect']
    exemption_string = has_query_exemption? ? ("quota_exemption=" + attachment.quota_exemption_key + "&") : ""
    redir.should == "http://www.example.com/api/v1/files/#{attachment.id}/create_success?#{exemption_string}uuid=#{attachment.uuid}"
    attachment.should be_deleted

    # step 2, upload
    # we skip the actual call and stub this out, since we can't hit s3 during specs
    AWS::S3::S3Object.expects(:about).with(attachment.full_filename, attachment.bucket_name).returns({
      'content-type' => 'application/msword',
      'content-length' => 1234,
    })

    # step 3, confirmation
    post redir, {}, { 'Authorization' => "Bearer #{@user.access_tokens.first.token}" }
    response.should be_success
    attachment.reload
    json = json_parse(response.body)
    json.should == {
      'id' => attachment.id,
      'url' => file_download_url(attachment, :verifier => attachment.uuid, :download => '1', :download_frd => '1'),
      'content-type' => attachment.content_type,
      'display_name' => attachment.display_name,
      'filename' => attachment.filename,
      'size' => 1234,
    }

    attachment.file_state.should == 'available'
    attachment.content_type.should == "application/msword"
    attachment.display_name.should == filename
    attachment
  end
end

shared_examples_for "file uploads api with folders" do
  it_should_behave_like "file uploads api"

  it "should allow specifying a folder with deprecated argument name" do
    preflight({ :name => "with_path.txt", :folder => "files/a/b/c/mypath" })
    attachment = Attachment.last(:order => :id)
    attachment.folder.should == Folder.assert_path("/files/a/b/c/mypath", context)
  end

  it "should allow specifying a folder" do
    preflight({ :name => "with_path.txt", :parent_folder_path => "files/a/b/c/mypath" })
    attachment = Attachment.last(:order => :id)
    attachment.folder.should == Folder.assert_path("/files/a/b/c/mypath", context)
  end

  it "should allow specifying a parent folder by id" do
    root = Folder.root_folders(context).first
    sub = root.sub_folders.create!(:name => "folder1", :context => context)
    preflight({ :name => "with_path.txt", :parent_folder_id => sub.id.to_param })
    attachment = Attachment.last(:order => :id)
    attachment.folder_id.should == sub.id
  end

  it "should upload to an existing folder" do
    @folder = Folder.assert_path("/files/a/b/c/mypath", context)
    @folder.should be_present
    @folder.should be_visible
    preflight({ :name => "my_essay.doc", :folder => "files/a/b/c/mypath" })
    attachment = Attachment.last(:order => :id)
    attachment.folder.should == @folder
  end

  it "should overwrite duplicate files by default" do
    local_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(:folder => @folder, :context => context, :filename => "test.txt", :uploaded_data => StringIO.new("first"))
    json = preflight({ :name => "test.txt", :folder => "test" })

    tmpfile = Tempfile.new(["test", ".txt"])
    tmpfile.write("second")
    tmpfile.rewind
    post_params = json["upload_params"].merge({"file" => tmpfile})
    send_multipart(json["upload_url"], post_params)
    post response['Location'], {}, { 'Authorization' => "Bearer #{@user.access_tokens.first.token}" }
    response.should be_success
    attachment = Attachment.last(:order => :id)
    a1.reload.should be_deleted
    attachment.reload.should be_available
  end

  it "should allow renaming instead of overwriting duplicate files (local storage)" do
    local_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(:folder => @folder, :context => context, :filename => "test.txt", :uploaded_data => StringIO.new("first"))
    json = preflight({ :name => "test.txt", :folder => "test", :on_duplicate => 'rename' })

    tmpfile = Tempfile.new(["test", ".txt"])
    tmpfile.write("second")
    tmpfile.rewind
    post_params = json["upload_params"].merge({"file" => tmpfile})
    send_multipart(json["upload_url"], post_params)
    post response['Location'], {}, { 'Authorization' => "Bearer #{@user.access_tokens.first.token}" }
    response.should be_success
    attachment = Attachment.last(:order => :id)
    a1.reload.should be_available
    attachment.reload.should be_available
    attachment.display_name.should == "test-1.txt"
  end

  it "should allow renaming instead of overwriting duplicate files (s3 storage)" do
    s3_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(:folder => @folder, :context => context, :filename => "test.txt", :uploaded_data => StringIO.new("first"))
    json = preflight({ :name => "test.txt", :folder => "test", :on_duplicate => 'rename' })

    redir = json['upload_params']['success_action_redirect']
    attachment = Attachment.last(:order => :id)
    AWS::S3::S3Object.expects(:about).with(attachment.full_filename, attachment.bucket_name).returns({
      'content-type' => 'application/msword',
      'content-length' => 1234,
    })

    post redir, {}, { 'Authorization' => "Bearer #{@user.access_tokens.first.token}" }
    response.should be_success
    a1.reload.should be_available
    attachment.reload.should be_available
    attachment.display_name.should == "test-1.txt"
  end

  it "should reject other duplicate file handling params" do
    proc { preflight({ :name => "test.txt", :folder => "test", :on_duplicate => 'killall' }) }.should raise_error
  end
end

shared_examples_for "file uploads api with quotas" do
  it "should return successful preflight for files within quota limits" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    json = preflight({ :name => "test.txt", :size => 3.megabytes })
    attachment = Attachment.last(:order => :id)
    attachment.workflow_state.should == 'unattached'
    attachment.filename.should == 'test.txt'
  end
  
  it "should return unsuccessful preflight for files exceeding quota limits" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    json = {}
    begin
      preflight({ :name => "test.txt", :size => 10.megabytes })
    rescue => e
      json = JSON.parse(e.message)
    end
    json['message'].should == "file size exceeds quota"
  end
  
  it "should return successful create_success for files within quota" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    attachment = @context.attachments.new
    attachment.filename = "smaller_file.txt"
    attachment.file_state = 'deleted'
    attachment.workflow_state = 'unattached'
    attachment.content_type = 'text/plain'
    attachment.size = 4.megabytes
    attachment.save!
    json = api_call(:get, "/api/v1/files/#{attachment.id}/create_success", {:id => attachment.id.to_s, :controller => 'files', :action => 'api_create_success', :format => 'json'}, {:uuid => attachment.uuid})
    json['id'].should == attachment.id
    attachment.reload
    attachment.file_state.should == 'available'
  end
  
  it "should return unsuccessful create_success for files exceeding quota limits" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    attachment = @context.attachments.new
    attachment.filename = "bigger_file.txt"
    attachment.file_state = 'deleted'
    attachment.workflow_state = 'unattached'
    attachment.content_type = 'text/plain'
    attachment.size = 6.megabytes
    attachment.save!
    json = {}
    begin
      api_call(:get, "/api/v1/files/#{attachment.id}/create_success", {:id => attachment.id.to_s, :controller => 'files', :action => 'api_create_success', :format => 'json'}, {:uuid => attachment.uuid})
    rescue => e
      json = JSON.parse(e.message)
    end
    json['message'].should == 'file size exceeds quota limits'
    attachment.reload
    attachment.file_state.should == 'deleted'
  end
  
end

shared_examples_for "file uploads api without quotas" do
  it "should ignore context-related quotas in preflight" do
    @context.write_attribute(:storage_quota, 0)
    @context.save!
    json = preflight({ :name => "test.txt", :size => 1.megabyte })
    attachment = Attachment.last(:order => :id)
    json['upload_url'].should match(/#{attachment.quota_exemption_key}/)
  end
  it "should ignore context-related quotas in preflight" do
    s3_storage!
    @context.write_attribute(:storage_quota, 0)
    @context.save!
    json = preflight({ :name => "test.txt", :size => 1.megabyte })
    attachment = Attachment.last(:order => :id)
    json['upload_params']['success_action_redirect'].should match(/#{attachment.quota_exemption_key}/)
  end
end



