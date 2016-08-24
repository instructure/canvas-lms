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

RSpec.configure do |config|
  config.include ApplicationHelper
end

shared_examples_for "file uploads api" do
  def attachment_json(attachment, options = {})
    json = {
      'id' => attachment.id,
      'folder_id' => attachment.folder_id,
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
      'modified_at' => attachment.modified_at.as_json,
      'thumbnail_url' => attachment.thumbnail_url,
      'mime_class' => attachment.mime_class,
      'media_entry_id' => attachment.media_entry_id
    }

    if options[:include] && options[:include].include?("enhanced_preview_url") && (attachment.context.is_a?(Course) || attachment.context.is_a?(User))
      json.merge!({ 'preview_url' => context_url(attachment.context, :context_file_file_preview_url, attachment, annotate: 0) })
    end

    json
  end

  it "should upload (local files)" do
    filename = "my_essay.doc"
    content = "this is a test doc"

    local_storage!
    # step 1, preflight
    json = preflight({ :name => filename })
    attachment = Attachment.order(:id).last
    exemption_string = has_query_exemption? ? ("?quota_exemption=" + attachment.quota_exemption_key) : ""
    expect(json['upload_url']).to eq "http://www.example.com/files_api#{exemption_string}"

    # step 2, upload
    tmpfile = Tempfile.new(["test", File.extname(filename)])
    tmpfile.write(content)
    tmpfile.rewind
    post_params = json["upload_params"].merge({"file" => tmpfile})
    send_multipart(json["upload_url"], post_params)

    attachment = Attachment.order(:id).last
    expect(attachment).to be_deleted
    exemption_string = has_query_exemption? ? ("quota_exemption=" + attachment.quota_exemption_key + "&") : ""
    expect(response).to redirect_to("http://www.example.com/api/v1/files/#{attachment.id}/create_success?#{exemption_string}uuid=#{attachment.uuid}")

    # step 3, confirmation
    post response['Location'], {}, { 'Authorization' => "Bearer #{access_token_for_user @user}" }
    expect(response).to be_success
    attachment.reload
    json = json_parse(response.body)
    expected_json = {
        'id' => attachment.id,
        'folder_id' => attachment.folder_id,
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
        'thumbnail_url' => attachment.thumbnail_url,
        'modified_at' => attachment.modified_at.as_json,
        'mime_class' => attachment.mime_class,
        'media_entry_id' => attachment.media_entry_id
    }

    if attachment.context.is_a?(User) || attachment.context.is_a?(Course)
      expected_json.merge!({ 'preview_url' => context_url(attachment.context, :context_file_file_preview_url, attachment, annotate: 0) })
    end

    expect(json).to eq(expected_json)
    expect(attachment.file_state).to eq 'available'
    expect(attachment.content_type).to eq "application/msword"
    expect(attachment.open.read).to eq content
    expect(attachment.display_name).to eq filename
    expect(attachment.user.id).to eq @user.id
    attachment
  end

  it "should upload (s3 files)" do
    filename = "my_essay.doc"
    content = "this is a test doc"

    s3_storage!
    # step 1, preflight
    json = preflight({ :name => filename })
    expect(json['upload_url']).to eq "http://no-bucket.s3.amazonaws.com/"
    attachment = Attachment.order(:id).last
    redir = json['upload_params']['success_action_redirect']
    exemption_string = has_query_exemption? ? ("quota_exemption=" + attachment.quota_exemption_key + "&") : ""
    expect(redir).to eq "http://www.example.com/api/v1/files/#{attachment.id}/create_success?#{exemption_string}uuid=#{attachment.uuid}"
    expect(attachment).to be_deleted

    # step 2, upload
    # we skip the actual call and stub this out, since we can't hit s3 during specs
    AWS::S3::S3Object.any_instance.expects(:head).returns({
      :content_type => 'application/msword',
      :content_length => 1234,
    })

    # step 3, confirmation
    post redir, {}, { 'Authorization' => "Bearer #{access_token_for_user @user}" }
    expect(response).to be_success
    attachment.reload
    json = json_parse(response.body)
    expect(json).to eq attachment_json(attachment, { include: %w(enhanced_preview_url) })

    expect(attachment.file_state).to eq 'available'
    expect(attachment.content_type).to eq "application/msword"
    expect(attachment.display_name).to eq filename
    expect(attachment.user.id).to eq @user.id
    attachment
  end

  it "should allow uploading files from a url" do
    filename = "delete.png"

    local_storage!
    # step 1, preflight
    json = preflight({ :name => filename, :size => 20, :url => "http://www.example.com/images/delete.png" })
    attachment = Attachment.order(:id).last
    expect(attachment.file_state).to eq 'deleted'
    status_url = json['status_url']
    expect(status_url).to eq "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"

    # step 2, download
    json = api_call(:get, status_url, {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    expect(json['upload_status']).to eq 'pending'

    CanvasHttp.expects(:get).with("http://www.example.com/images/delete.png").yields(FakeHttpResponse.new(200, "asdf"))
    run_download_job

    json = api_call(:get, status_url, {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})

    expect(json).to eq({
      'upload_status' => 'ready',
      'attachment' => attachment_json(attachment.reload),
    })
    expect(attachment.file_state).to eq 'available'
    expect(attachment.size).to eq 4
    expect(attachment.user.id).to eq @user.id
  end

  it "should fail gracefully with a malformed url" do
    filename = "delete.png"

    local_storage!
    # step 1, preflight
    json = preflight({ :name => filename, :size => 20, :url => '#@$YA#Y#AGWREG' })
    attachment = Attachment.order(:id).last
    expect(json['status_url']).to eq "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"

    # step 2, download
    run_download_job
    json = api_call(:get, json['status_url'], {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    expect(json['upload_status']).to eq 'errored'
    expect(json['message']).to eq "Could not parse the URL: \#@$YA#Y#AGWREG"
    expect(attachment.reload.file_state).to eq 'errored'
  end

  it "should fail gracefully with a relative url" do
    filename = "delete.png"

    local_storage!
    # step 1, preflight
    json = preflight({ :name => filename, :size => 20, :url => '/images/delete.png' })
    attachment = Attachment.order(:id).last
    expect(json['status_url']).to eq "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"

    # step 2, download
    run_download_job
    json = api_call(:get, json['status_url'], {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    expect(json['upload_status']).to eq 'errored'
    expect(json['message']).to eq "No host provided for the URL: /images/delete.png"
    expect(attachment.reload.file_state).to eq 'errored'
  end

  it "should fail gracefully with a non-200 and non-300 status return" do
    filename = "delete.png"
    url = 'http://www.example.com/images/delete.png'

    local_storage!
    # step 1, preflight
    CanvasHttp.expects(:get).with(url).yields(FakeHttpResponse.new(404))
    json = preflight({ :name => filename, :size => 20, :url => url })
    attachment = Attachment.order(:id).last
    expect(json['status_url']).to eq "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"

    # step 2, download
    run_download_job
    json = api_call(:get, json['status_url'], {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    expect(json['upload_status']).to eq 'errored'
    expect(json['message']).to eq  "Invalid response code, expected 200 got 404"
    expect(attachment.reload.file_state).to eq 'errored'
  end

  it "should fail gracefully with a GET request timeout" do
    filename = "delete.png"
    url = 'http://www.example.com/images/delete.png'

    local_storage!
    # step 1, preflight
    CanvasHttp.expects(:get).with(url).raises(Timeout::Error)
    json = preflight({ :name => filename, :size => 20, :url => url })
    attachment = Attachment.order(:id).last
    expect(json['status_url']).to eq "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"

    # step 2, download
    run_download_job
    json = api_call(:get, json['status_url'], {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    expect(json['upload_status']).to eq 'errored'
    expect(json['message']).to eq "The request timed out: http://www.example.com/images/delete.png"
    expect(attachment.reload.file_state).to eq 'errored'
  end

  it "should fail gracefully with too many redirects" do
    filename = "delete.png"
    url = 'http://www.example.com/images/delete.png'

    local_storage!
    # step 1, preflight
    CanvasHttp.expects(:get).with(url).raises(CanvasHttp::TooManyRedirectsError)
    json = preflight({ :name => filename, :size => 20, :url => url })
    attachment = Attachment.order(:id).last
    expect(attachment.workflow_state).to eq 'unattached'
    expect(json['status_url']).to eq "http://www.example.com/api/v1/files/#{attachment.id}/#{attachment.uuid}/status"

    # step 2, download
    run_download_job
    json = api_call(:get, json['status_url'], {:id => attachment.id.to_s, :controller => 'files', :action => 'api_file_status', :format => 'json', :uuid => attachment.uuid})
    expect(json['upload_status']).to eq 'errored'
    expect(json['message']).to eq "Too many redirects"
    expect(attachment.reload.file_state).to eq 'errored'
  end

  def run_download_job
    expect(Delayed::Job.strand_size('file_download')).to be > 0
    run_jobs
  end

end

shared_examples_for "file uploads api with folders" do
  include_examples "file uploads api"

  it "should allow specifying a folder with deprecated argument name" do
    preflight({ :name => "with_path.txt", :folder => "files/a/b/c/mypath" })
    attachment = Attachment.order(:id).last
    expect(attachment.folder).to eq Folder.assert_path("/files/a/b/c/mypath", context)
  end

  it "should allow specifying a folder" do
    preflight({ :name => "with_path.txt", :parent_folder_path => "files/a/b/c/mypath" })
    attachment = Attachment.order(:id).last
    expect(attachment.folder).to eq Folder.assert_path("/files/a/b/c/mypath", context)
  end

  it "should allow specifying a parent folder by id" do
    root = Folder.root_folders(context).first
    sub = root.sub_folders.create!(:name => "folder1", :context => context)
    preflight({ :name => "with_path.txt", :parent_folder_id => sub.id.to_param })
    attachment = Attachment.order(:id).last
    expect(attachment.folder_id).to eq sub.id
  end

  it "should upload to an existing folder" do
    @folder = Folder.assert_path("/files/a/b/c/mypath", context)
    expect(@folder).to be_present
    expect(@folder).to be_visible
    preflight({ :name => "my_essay.doc", :folder => "files/a/b/c/mypath" })
    attachment = Attachment.order(:id).last
    expect(attachment.folder).to eq @folder
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
    expect(response).to be_success
    attachment = Attachment.order(:id).last
    expect(a1.reload).to be_deleted
    expect(attachment.reload).to be_available
    expect(attachment.display_name).to eq "test.txt"
    expect(attachment.folder).to eq @folder
    expect(attachment.open.read).to eq "second"
  end

  it "should overwrite duplicate files by default for URL uploads" do
    local_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(:folder => @folder, :context => context, :filename => "test.txt", :uploaded_data => StringIO.new("first"))
    json = preflight({ :name => "test.txt", :folder => "test", :url => "http://www.example.com/test" })
    attachment = Attachment.order(:id).last
    CanvasHttp.expects(:get).with("http://www.example.com/test").yields(FakeHttpResponse.new(200, "second"))
    run_jobs

    expect(a1.reload).to be_deleted
    expect(attachment.reload).to be_available
    expect(attachment.display_name).to eq "test.txt"
    expect(attachment.folder).to eq @folder
    expect(attachment.open.read).to eq "second"
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
    expect(response).to be_success
    attachment = Attachment.order(:id).last
    expect(a1.reload).to be_available
    expect(attachment.reload).to be_available
    expect(a1.display_name).to eq "test.txt"
    expect(attachment.display_name).to eq "test-1.txt"
    expect(attachment.folder).to eq @folder
  end

  it "should allow renaming instead of overwriting duplicate files for URL uploads" do
    local_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(:folder => @folder, :context => context, :filename => "test.txt", :uploaded_data => StringIO.new("first"))
    json = preflight({ :name => "test.txt", :folder => "test", :on_duplicate => 'rename', :url => "http://www.example.com/test" })
    attachment = Attachment.order(:id).last
    CanvasHttp.expects(:get).with("http://www.example.com/test").yields(FakeHttpResponse.new(200, "second"))
    run_jobs

    expect(a1.reload).to be_available
    expect(attachment.reload).to be_available
    expect(a1.display_name).to eq "test.txt"
    expect(attachment.display_name).to eq "test-1.txt"
    expect(attachment.folder).to eq @folder
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
    expect(response).to be_success
    expect(a1.reload).to be_available
    expect(attachment.reload).to be_available
    expect(attachment.display_name).to eq "test-1.txt"
  end

  it "should reject other duplicate file handling params" do
    expect { preflight({ :name => "test.txt", :folder => "test", :on_duplicate => 'killall' }) }.to raise_error
  end
end

shared_examples_for "file uploads api with quotas" do
  it "should return successful preflight for files within quota limits" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    json = preflight({ :name => "test.txt", :size => 3.megabytes })
    attachment = Attachment.order(:id).last
    expect(attachment.workflow_state).to eq 'unattached'
    expect(attachment.filename).to eq 'test.txt'
  end

  it "should return unsuccessful preflight for files exceeding quota limits" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    json = preflight({ :name => "test.txt", :size => 10.megabytes }, expected_status: 400)
    expect(json['message']).to eq "file size exceeds quota"
  end

  it "should return unsuccessful preflight for files exceeding quota limits (URL uploads)" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    json = preflight({ :name => "test.txt", :size => 10.megabytes, :url => "http://www.example.com/test" },
      expected_status: 400)
    expect(json['message']).to eq "file size exceeds quota"
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
    expect(json['id']).to eq attachment.id
    attachment.reload
    expect(attachment.file_state).to eq 'available'
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
    json = api_call(:get, "/api/v1/files/#{attachment.id}/create_success",
                    {:id => attachment.id.to_s, :controller => 'files', :action => 'api_create_success', :format => 'json'},
                    {:uuid => attachment.uuid},
                    {},
                    expected_status: 400)
    expect(json['message']).to eq 'file size exceeds quota limits'
    attachment.reload
    expect(attachment.file_state).to eq 'deleted'
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
    expect(json['upload_status']).to eq 'errored'
    expect(json['message']).to eq "file size exceeds quota limits: #{2.megabytes} bytes"
    expect(attachment.file_state).to eq 'deleted'
  end
end

shared_examples_for "file uploads api without quotas" do
  it "should ignore context-related quotas in preflight" do
    @context.write_attribute(:storage_quota, 0)
    @context.save!
    json = preflight({ :name => "test.txt", :size => 1.megabyte })
    attachment = Attachment.order(:id).last
    expect(json['upload_url']).to match(/#{attachment.quota_exemption_key}/)
  end
  it "should ignore context-related quotas in preflight" do
    s3_storage!
    @context.write_attribute(:storage_quota, 0)
    @context.save!
    json = preflight({ :name => "test.txt", :size => 1.megabyte })
    attachment = Attachment.order(:id).last
    expect(json['upload_params']['success_action_redirect']).to match(/#{attachment.quota_exemption_key}/)
  end
end
