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
  def attachment_json(attachment)
    {
      'id' => attachment.id,
      'url' => file_download_url(attachment, :verifier => attachment.uuid, :download => '1', :download_frd => '1'),
      'content-type' => attachment.content_type,
      'display_name' => attachment.display_name,
      'filename' => attachment.filename,
      'size' => attachment.size,
      'unlock_at' => attachment.unlock_at ? attachment.unlock_at.as_json : nil,
      'locked' => !!attachment.locked,
      'hidden' => !!attachment.hidden,
      'lock_at' => attachment.lock_at ? attachment.lock_at.as_json : nil,
      'locked_for_user' => false,
      'hidden_for_user' => false,
      'created_at' => attachment.created_at.as_json,
      'updated_at' => attachment.updated_at.as_json,
      'thumbnail_url' => attachment.thumbnail_url
    }
  end

  it "should upload (local files)" do
    filename = "my_essay.doc"
    content = "this is a test doc"

    local_storage!
    # step 1, preflight
    json = preflight({ :name => filename })
    attachment = Attachment.order(:id).last
    exemption_string = has_query_exemption? ? ("?quota_exemption=" + attachment.quota_exemption_key) : ""
    json['upload_url'].should == "http://www.example.com/files_api#{exemption_string}"

    # step 2, upload
    tmpfile = Tempfile.new(["test", File.extname(filename)])
    tmpfile.write(content)
    tmpfile.rewind
    post_params = json["upload_params"].merge({"file" => tmpfile})
    send_multipart(json["upload_url"], post_params)

    attachment = Attachment.order(:id).last
    attachment.should be_deleted
    exemption_string = has_query_exemption? ? ("quota_exemption=" + attachment.quota_exemption_key + "&") : ""
    response.should redirect_to("http://www.example.com/api/v1/files/#{attachment.id}/create_success?#{exemption_string}uuid=#{attachment.uuid}")

    # step 3, confirmation
    post response['Location'], {}, { 'Authorization' => "Bearer #{access_token_for_user @user}" }
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
      'unlock_at' => nil,
      'locked' => false,
      'hidden' => false,
      'lock_at' => nil,
      'locked_for_user' => false,
      'hidden_for_user' => false,
      'created_at' => attachment.created_at.as_json,
      'updated_at' => attachment.updated_at.as_json,
      'thumbnail_url' => attachment.thumbnail_url
    }

    attachment.file_state.should == 'available'
    attachment.content_type.should == "application/msword"
    attachment.open.read.should == content
    attachment.display_name.should == filename
    attachment.user.id.should == @user.id
    attachment
  end

  it "should upload (s3 files)" do
    filename = "my_essay.doc"
    content = "this is a test doc"

    s3_storage!
    # step 1, preflight
    json = preflight({ :name => filename })
    json['upload_url'].should == "http://no-bucket.s3.amazonaws.com/"
    attachment = Attachment.order(:id).last
    redir = json['upload_params']['success_action_redirect']
    exemption_string = has_query_exemption? ? ("quota_exemption=" + attachment.quota_exemption_key + "&") : ""
    redir.should == "http://www.example.com/api/v1/files/#{attachment.id}/create_success?#{exemption_string}uuid=#{attachment.uuid}"
    attachment.should be_deleted

    # step 2, upload
    # we skip the actual call and stub this out, since we can't hit s3 during specs
    AWS::S3::S3Object.any_instance.expects(:head).returns({
      :content_type => 'application/msword',
      :content_length => 1234,
    })

    # step 3, confirmation
    post redir, {}, { 'Authorization' => "Bearer #{access_token_for_user @user}" }
    response.should be_success
    attachment.reload
    json = json_parse(response.body)
    json.should == attachment_json(attachment)

    attachment.file_state.should == 'available'
    attachment.content_type.should == "application/msword"
    attachment.display_name.should == filename
    attachment.user.id.should == @user.id
    attachment
  end

  it "should allow uploading files from a url" do
    filename = "delete.png"

    local_storage!
    # step 1, preflight
    json = preflight({ :name => filename, :size => 20, :url => "http://www.example.com/images/delete.png" })
    attachment = Attachment.order(:id).last
    attachment.file_state.should == 'deleted'
    status_url = json['status_url']
    status_url.should == "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"
    
    # step 2, download
    json = api_call(:get, status_url, {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    json['upload_status'].should == 'pending'
    
    CanvasHttp.expects(:get).with("http://www.example.com/images/delete.png").yields(FakeHttpResponse.new(200, "asdf"))
    run_download_job

    json = api_call(:get, status_url, {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})

    json.should == {
      'upload_status' => 'ready',
      'attachment' => attachment_json(attachment.reload),
    }
    attachment.file_state.should == 'available'
    attachment.size.should == 4
    attachment.user.id.should == @user.id
  end
  
  it "should fail gracefully with a malformed url" do
    filename = "delete.png"

    local_storage!
    # step 1, preflight
    json = preflight({ :name => filename, :size => 20, :url => '#@$YA#Y#AGWREG' })
    attachment = Attachment.order(:id).last
    json['status_url'].should == "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"
    
    # step 2, download
    run_download_job
    json = api_call(:get, json['status_url'], {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    json['upload_status'].should == 'errored'
    json['message'].should == "Could not parse the URL: \#@$YA#Y#AGWREG"
    attachment.reload.file_state.should == 'errored'
  end
  
  it "should fail gracefully with a relative url" do
    filename = "delete.png"

    local_storage!
    # step 1, preflight
    json = preflight({ :name => filename, :size => 20, :url => '/images/delete.png' })
    attachment = Attachment.order(:id).last
    json['status_url'].should == "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"
    
    # step 2, download
    run_download_job
    json = api_call(:get, json['status_url'], {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    json['upload_status'].should == 'errored'
    json['message'].should == "No host provided for the URL: /images/delete.png"
    attachment.reload.file_state.should == 'errored'
  end
  
  it "should fail gracefully with a non-200 and non-300 status return" do
    filename = "delete.png"
    url = 'http://www.example.com/images/delete.png'

    local_storage!
    # step 1, preflight
    CanvasHttp.expects(:get).with(url).yields(FakeHttpResponse.new(404))
    json = preflight({ :name => filename, :size => 20, :url => url })
    attachment = Attachment.order(:id).last
    json['status_url'].should == "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"
    
    # step 2, download
    run_download_job
    json = api_call(:get, json['status_url'], {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    json['upload_status'].should == 'errored'
    json['message'].should ==  "Invalid response code, expected 200 got 404"
    attachment.reload.file_state.should == 'errored'
  end
  
  it "should fail gracefully with a GET request timeout" do
    filename = "delete.png"
    url = 'http://www.example.com/images/delete.png'

    local_storage!
    # step 1, preflight
    CanvasHttp.expects(:get).with(url).raises(Timeout::Error)
    json = preflight({ :name => filename, :size => 20, :url => url })
    attachment = Attachment.order(:id).last
    json['status_url'].should == "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"
    
    # step 2, download
    run_download_job
    json = api_call(:get, json['status_url'], {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    json['upload_status'].should == 'errored'
    json['message'].should == "The request timed out: http://www.example.com/images/delete.png"
    attachment.reload.file_state.should == 'errored'
  end
  
  it "should fail gracefully with too many redirects" do
    filename = "delete.png"
    url = 'http://www.example.com/images/delete.png'

    local_storage!
    # step 1, preflight
    CanvasHttp.expects(:get).with(url).raises(CanvasHttp::TooManyRedirectsError)
    json = preflight({ :name => filename, :size => 20, :url => url })
    attachment = Attachment.order(:id).last
    attachment.workflow_state.should == 'unattached'
    json['status_url'].should == "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"
    
    # step 2, download
    run_download_job
    json = api_call(:get, json['status_url'], {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    json['upload_status'].should == 'errored'
    json['message'].should == "Too many redirects"
    attachment.reload.file_state.should == 'errored'
  end
  
  def run_download_job
    Delayed::Job.strand_size('file_download').should > 0
    run_jobs
  end

end

shared_examples_for "file uploads api with folders" do
  include_examples "file uploads api"

  it "should allow specifying a folder with deprecated argument name" do
    preflight({ :name => "with_path.txt", :folder => "files/a/b/c/mypath" })
    attachment = Attachment.order(:id).last
    attachment.folder.should == Folder.assert_path("/files/a/b/c/mypath", context)
  end

  it "should allow specifying a folder" do
    preflight({ :name => "with_path.txt", :parent_folder_path => "files/a/b/c/mypath" })
    attachment = Attachment.order(:id).last
    attachment.folder.should == Folder.assert_path("/files/a/b/c/mypath", context)
  end

  it "should allow specifying a parent folder by id" do
    root = Folder.root_folders(context).first
    sub = root.sub_folders.create!(:name => "folder1", :context => context)
    preflight({ :name => "with_path.txt", :parent_folder_id => sub.id.to_param })
    attachment = Attachment.order(:id).last
    attachment.folder_id.should == sub.id
  end

  it "should upload to an existing folder" do
    @folder = Folder.assert_path("/files/a/b/c/mypath", context)
    @folder.should be_present
    @folder.should be_visible
    preflight({ :name => "my_essay.doc", :folder => "files/a/b/c/mypath" })
    attachment = Attachment.order(:id).last
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
    post response['Location'], {}, { 'Authorization' => "Bearer #{access_token_for_user @user}" }
    response.should be_success
    attachment = Attachment.order(:id).last
    a1.reload.should be_deleted
    attachment.reload.should be_available
    attachment.display_name.should == "test.txt"
    attachment.folder.should == @folder
    attachment.open.read.should == "second"
  end

  it "should overwrite duplicate files by default for URL uploads" do
    local_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(:folder => @folder, :context => context, :filename => "test.txt", :uploaded_data => StringIO.new("first"))
    json = preflight({ :name => "test.txt", :folder => "test", :url => "http://www.example.com/test" })
    attachment = Attachment.order(:id).last
    CanvasHttp.expects(:get).with("http://www.example.com/test").yields(FakeHttpResponse.new(200, "second"))
    run_jobs

    a1.reload.should be_deleted
    attachment.reload.should be_available
    attachment.display_name.should == "test.txt"
    attachment.folder.should == @folder
    attachment.open.read.should == "second"
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
    post response['Location'], {}, { 'Authorization' => "Bearer #{access_token_for_user @user}" }
    response.should be_success
    attachment = Attachment.order(:id).last
    a1.reload.should be_available
    attachment.reload.should be_available
    a1.display_name.should == "test.txt"
    attachment.display_name.should == "test-1.txt"
    attachment.folder.should == @folder
  end

  it "should allow renaming instead of overwriting duplicate files for URL uploads" do
    local_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(:folder => @folder, :context => context, :filename => "test.txt", :uploaded_data => StringIO.new("first"))
    json = preflight({ :name => "test.txt", :folder => "test", :on_duplicate => 'rename', :url => "http://www.example.com/test" })
    attachment = Attachment.order(:id).last
    CanvasHttp.expects(:get).with("http://www.example.com/test").yields(FakeHttpResponse.new(200, "second"))
    run_jobs

    a1.reload.should be_available
    attachment.reload.should be_available
    a1.display_name.should == "test.txt"
    attachment.display_name.should == "test-1.txt"
    attachment.folder.should == @folder
  end

  it "should allow renaming instead of overwriting duplicate files (s3 storage)" do
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(:folder => @folder, :context => context, :filename => "test.txt", :uploaded_data => StringIO.new("first"))
    s3_storage!
    json = preflight({ :name => "test.txt", :folder => "test", :on_duplicate => 'rename' })

    redir = json['upload_params']['success_action_redirect']
    attachment = Attachment.order(:id).last
    AWS::S3::S3Object.any_instance.expects(:head).returns({
                                      :content_type => 'application/msword',
                                      :content_length => 1234,
                                    })

    post redir, {}, { 'Authorization' => "Bearer #{access_token_for_user @user}" }
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
    attachment = Attachment.order(:id).last
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

  it "should return unsuccessful preflight for files exceeding quota limits (URL uploads)" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    json = {}
    begin
      preflight({ :name => "test.txt", :size => 10.megabytes, :url => "http://www.example.com/test" })
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

  it "should fail URL uploads for files exceeding quota limits" do
    @context.write_attribute(:storage_quota, 1.megabyte)
    @context.save!
    json = preflight({ :name => "test.txt", :url => "http://www.example.com/test" })
    status_url = json['status_url']
    attachment = Attachment.order(:id).last
    CanvasHttp.expects(:get).with("http://www.example.com/test").yields(FakeHttpResponse.new(200, (" " * 2.megabytes)))
    run_jobs

    json = api_call(:get, status_url, {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    json['upload_status'].should == 'errored'
    json['message'].should == "file size exceeds quota limits: #{2.megabytes} bytes"
    attachment.file_state.should == 'deleted'
  end
end

shared_examples_for "file uploads api without quotas" do
  it "should ignore context-related quotas in preflight" do
    @context.write_attribute(:storage_quota, 0)
    @context.save!
    json = preflight({ :name => "test.txt", :size => 1.megabyte })
    attachment = Attachment.order(:id).last
    json['upload_url'].should match(/#{attachment.quota_exemption_key}/)
  end
  it "should ignore context-related quotas in preflight" do
    s3_storage!
    @context.write_attribute(:storage_quota, 0)
    @context.save!
    json = preflight({ :name => "test.txt", :size => 1.megabyte })
    attachment = Attachment.order(:id).last
    json['upload_params']['success_action_redirect'].should match(/#{attachment.quota_exemption_key}/)
  end
end
