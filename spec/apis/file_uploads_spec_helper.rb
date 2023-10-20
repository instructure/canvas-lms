# frozen_string_literal: true

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

require_relative "api_spec_helper"

shared_examples_for "file uploads api" do
  include ApplicationHelper

  # send a multipart post request in an integration spec post_params is
  # an array of [k,v] params so that the order of the params can be
  # defined
  def send_multipart(url, post_params = {}, http_headers = {}, method = :post)
    query, headers = LegacyMultipart::Post.prepare_query(post_params)

    # A bug in the testing adapter in Rails 3-2-stable doesn't corretly handle
    # translating this header to the Rack/CGI compatible version:
    # (https://github.com/rails/rails/blob/3-2-stable/actionpack/lib/action_dispatch/testing/integration.rb#L289)
    #
    # This issue is fixed in Rails 4-0 stable, by using a newer version of
    # ActionDispatch Http::Headers which correctly handles the merge
    headers = headers.dup.tap { |h| h["CONTENT_TYPE"] ||= h.delete("Content-type") }

    send(method, url, params: query, headers: headers.merge(http_headers))
  end

  def attachment_json(attachment, options = {})
    json = {
      "id" => attachment.id,
      "uuid" => attachment.uuid,
      "folder_id" => attachment.folder_id,
      "url" => file_download_url(attachment, verifier: attachment.uuid, download: "1", download_frd: "1"),
      "content-type" => attachment.content_type,
      "display_name" => attachment.display_name,
      "filename" => attachment.filename,
      "upload_status" => "success",
      "size" => attachment.size,
      "unlock_at" => attachment.unlock_at&.as_json,
      "locked" => !!attachment.locked,
      "hidden" => !!attachment.hidden,
      "lock_at" => attachment.lock_at&.as_json,
      "locked_for_user" => false,
      "hidden_for_user" => false,
      "created_at" => attachment.created_at.as_json,
      "updated_at" => attachment.updated_at.as_json,
      "modified_at" => attachment.modified_at.as_json,
      "thumbnail_url" => attachment.has_thumbnail? ? thumbnail_image_url(attachment, attachment.uuid, host: "www.example.com") : nil,
      "mime_class" => attachment.mime_class,
      "media_entry_id" => attachment.media_entry_id,
      "category" => "uncategorized"
    }

    if options[:include]&.include?("enhanced_preview_url") && (attachment.context.is_a?(Course) || attachment.context.is_a?(User) || attachment.context.is_a?(Group))
      json["preview_url"] = context_url(attachment.context, :context_file_file_preview_url, attachment, annotate: 0)
    end

    if attachment.supports_visibility?
      json["visibility_level"] = attachment.visibility_level
    end

    unless options[:no_doc_preview]
      json["canvadoc_session_url"] = nil
      json["crocodoc_session_url"] = nil
    end

    json
  end

  it "uploads (local files)" do
    filename = "my_essay.doc"
    content = "this is a test doc"

    local_storage!
    # step 1, preflight
    json = preflight({ name: filename })
    attachment = Attachment.order(:id).last
    exemption_string = has_query_exemption? ? ("?quota_exemption=" + attachment.quota_exemption_key) : ""
    expect(json["upload_url"]).to eq "http://www.example.com/files_api#{exemption_string}"

    # step 2, upload
    tmpfile = Tempfile.new(["test", File.extname(filename)])
    tmpfile.write(content)
    tmpfile.rewind
    post_params = json["upload_params"].merge({ "file" => tmpfile })
    send_multipart(json["upload_url"], post_params)

    attachment = Attachment.order(:id).last
    expect(attachment).to be_deleted
    exemption_string = has_query_exemption? ? ("quota_exemption=" + attachment.quota_exemption_key + "&") : ""
    expect(response).to redirect_to("http://www.example.com/api/v1/files/#{attachment.id}/create_success?#{exemption_string}uuid=#{attachment.uuid}")

    # step 3, confirmation
    post response["Location"], headers: { "Authorization" => "Bearer #{access_token_for_user @user}" }
    expect(response).to be_successful
    attachment.reload
    json = json_parse(response.body)
    expected_json = {
      "id" => attachment.id,
      "uuid" => attachment.uuid,
      "folder_id" => attachment.folder_id,
      "url" => file_download_url(attachment, verifier: attachment.uuid, download: "1", download_frd: "1"),
      "content-type" => attachment.content_type,
      "display_name" => attachment.display_name,
      "filename" => attachment.filename,
      "size" => tmpfile.size,
      "unlock_at" => nil,
      "locked" => false,
      "hidden" => false,
      "lock_at" => nil,
      "locked_for_user" => false,
      "hidden_for_user" => false,
      "created_at" => attachment.created_at.as_json,
      "updated_at" => attachment.updated_at.as_json,
      "upload_status" => "success",
      "thumbnail_url" => attachment.has_thumbnail? ? thumbnail_image_url(attachment, attachment.uuid, host: "www.example.com") : nil,
      "modified_at" => attachment.modified_at.as_json,
      "mime_class" => attachment.mime_class,
      "media_entry_id" => attachment.media_entry_id,
      "canvadoc_session_url" => nil,
      "crocodoc_session_url" => nil,
      "category" => "uncategorized"
    }

    if attachment.context.is_a?(User) || attachment.context.is_a?(Course) || attachment.context.is_a?(Group)
      expected_json["preview_url"] = context_url(attachment.context, :context_file_file_preview_url, attachment, annotate: 0)
    end

    if attachment.supports_visibility?
      expected_json["visibility_level"] = attachment.visibility_level
    end

    expect(json).to eq(expected_json)
    expect(attachment.file_state).to eq "available"
    expect(attachment.content_type).to eq "application/msword"
    expect(attachment.open.read).to eq content
    expect(attachment.display_name).to eq filename
    expect(attachment.user.id).to eq @user.id
    attachment
  end

  it "uploads (s3 files)" do
    filename = "my_essay.doc"

    s3_storage!
    # step 1, preflight
    json = preflight({ name: filename })
    expect(json["upload_url"]).to eq "https://no-bucket.s3.amazonaws.com"
    attachment = Attachment.order(:id).last
    redir = json["upload_params"]["success_action_redirect"]
    exemption_string = has_query_exemption? ? ("quota_exemption=" + attachment.quota_exemption_key + "&") : ""
    expect(redir).to eq "http://www.example.com/api/v1/files/#{attachment.id}/create_success?#{exemption_string}uuid=#{attachment.uuid}"
    expect(attachment).to be_deleted

    # step 2, upload
    # we skip the actual call and double this out, since we can't hit s3 during specs
    expect_any_instance_of(Aws::S3::Object).to receive(:data).and_return({
                                                                           content_type: "application/msword",
                                                                           content_length: 1234,
                                                                         })

    # step 3, confirmation
    post redir, headers: { "Authorization" => "Bearer #{access_token_for_user @user}" }
    expect(response).to be_successful
    attachment.reload
    json = json_parse(response.body)
    expect(json).to eq attachment_json(attachment, { include: %w[enhanced_preview_url] })

    expect(attachment.file_state).to eq "available"
    expect(attachment.content_type).to eq "application/msword"
    expect(attachment.display_name).to eq filename
    expect(attachment.user.id).to eq @user.id
    attachment
  end

  it "allows uploading files from a url" do
    filename = "delete.png"

    local_storage!
    # step 1, preflight
    json = preflight({ name: filename, size: 20, url: "http://www.example.com/images/delete.png" })
    progress_url = json["progress"]["url"]
    progress_id = json["progress"]["id"]
    attachment = Attachment.order(:id).last
    expect(attachment.file_state).to eq "deleted"
    expect(progress_url).to be_present

    # step 2, download
    json = api_call(:get, progress_url, { id: progress_id, controller: "progress", action: "show", format: "json" })
    expect(json["workflow_state"]).to eq "queued"

    expect(CanvasHttp).to receive(:get).with("http://www.example.com/images/delete.png").and_yield(FakeHttpResponse.new(200, "asdf"))
    run_download_job

    json = api_call(:get, progress_url, { id: progress_id, controller: "progress", action: "show", format: "json" })

    expect(json["workflow_state"]).to eq("completed")
    expect(json["results"]).to be_present
    expect(json["results"]["id"]).to eq(attachment.id)

    attachment.reload
    expect(attachment.file_state).to eq "available"
    expect(attachment.size).to eq 4
    expect(attachment.user.id).to eq @user.id
  end

  it "fails gracefully with a malformed url" do
    filename = "delete.png"

    local_storage!
    # step 1, preflight
    json = preflight({ name: filename, size: 20, url: '#@$YA#Y#AGWREG' })
    progress_url = json["progress"]["url"]
    progress_id = json["progress"]["id"]
    attachment = Attachment.order(:id).last
    expect(progress_url).to be_present

    # step 2, download
    run_download_job
    json = api_call(:get, progress_url, { id: progress_id, controller: "progress", action: "show", format: "json" })
    expect(json["workflow_state"]).to eq "failed"
    expect(json["message"]).to eq "Could not parse the URL: \#@$YA#Y#AGWREG"
    expect(attachment.reload.file_state).to eq "errored"
  end

  it "fails gracefully with a relative url" do
    filename = "delete.png"

    local_storage!
    # step 1, preflight
    json = preflight({ name: filename, size: 20, url: "/images/delete.png" })
    progress_url = json["progress"]["url"]
    progress_id = json["progress"]["id"]
    attachment = Attachment.order(:id).last
    expect(progress_url).to be_present

    # step 2, download
    run_download_job
    json = api_call(:get, progress_url, { id: progress_id, controller: "progress", action: "show", format: "json" })
    expect(json["workflow_state"]).to eq "failed"
    expect(json["message"]).to eq "No host provided for the URL: /images/delete.png"
    expect(attachment.reload.file_state).to eq "errored"
  end

  it "fails gracefully with a non-200 and non-300 status return" do
    filename = "delete.png"
    url = "http://www.example.com/images/delete.png"

    local_storage!
    # step 1, preflight
    expect(CanvasHttp).to receive(:get).with(url).and_yield(FakeHttpResponse.new(404))
    json = preflight({ name: filename, size: 20, url: })
    progress_url = json["progress"]["url"]
    progress_id = json["progress"]["id"]
    attachment = Attachment.order(:id).last
    expect(progress_url).to be_present

    # step 2, download
    run_download_job
    json = api_call(:get, progress_url, { id: progress_id, controller: "progress", action: "show", format: "json" })
    expect(json["workflow_state"]).to eq "failed"
    expect(json["message"]).to include "Invalid response code, expected 200 got 404"
    expect(attachment.reload.file_state).to eq "errored"
  end

  it "fails gracefully with a GET request timeout" do
    filename = "delete.png"
    url = "http://www.example.com/images/delete.png"

    local_storage!
    # step 1, preflight
    expect(CanvasHttp).to receive(:get).with(url).and_raise(Timeout::Error)
    json = preflight({ name: filename, size: 20, url: })
    progress_url = json["progress"]["url"]
    progress_id = json["progress"]["id"]
    attachment = Attachment.order(:id).last
    expect(progress_url).to be_present

    # step 2, download
    run_download_job
    json = api_call(:get, progress_url, { id: progress_id, controller: "progress", action: "show", format: "json" })
    expect(json["workflow_state"]).to eq "failed"
    expect(json["message"]).to eq "The request timed out: http://www.example.com/images/delete.png"
    expect(attachment.reload.file_state).to eq "errored"
  end

  it "fails gracefully with too many redirects" do
    filename = "delete.png"
    url = "http://www.example.com/images/delete.png"

    local_storage!
    # step 1, preflight
    expect(CanvasHttp).to receive(:get).with(url).and_raise(CanvasHttp::TooManyRedirectsError)
    json = preflight({ name: filename, size: 20, url: })
    progress_url = json["progress"]["url"]
    progress_id = json["progress"]["id"]
    attachment = Attachment.order(:id).last
    expect(attachment.workflow_state).to eq "unattached"
    expect(progress_url).to be_present

    # step 2, download
    run_download_job
    json = api_call(:get, progress_url, { id: progress_id, controller: "progress", action: "show", format: "json" })
    expect(json["workflow_state"]).to eq "failed"
    expect(json["message"]).to include "Too many redirects"
    expect(attachment.reload.file_state).to eq "errored"
  end

  def run_download_job
    expect(Delayed::Job.where("tag like '#{Services::SubmitHomeworkService}::%'").count).to be > 0
    run_jobs
  end
end

shared_examples_for "file uploads api with folders" do
  include_examples "file uploads api"

  it "allows specifying a folder with deprecated argument name" do
    preflight({ name: "with_path.txt", folder: "files/a/b/c/mypath" })
    attachment = Attachment.order(:id).last
    expect(attachment.folder).to eq Folder.assert_path("/files/a/b/c/mypath", context)
  end

  it "allows specifying a folder" do
    preflight({ name: "with_path.txt", parent_folder_path: "files/a/b/c/mypath" })
    attachment = Attachment.order(:id).last
    expect(attachment.folder).to eq Folder.assert_path("/files/a/b/c/mypath", context)
  end

  it "allows specifying a parent folder by id" do
    root = Folder.root_folders(context).first
    sub = root.sub_folders.create!(name: "folder1", context:)
    preflight({ name: "with_path.txt", parent_folder_id: sub.id.to_param })
    attachment = Attachment.order(:id).last
    expect(attachment.folder_id).to eq sub.id
  end

  it "rejects for deleted parent folder id" do
    root = Folder.root_folders(context).first
    sub = root.sub_folders.create!(name: "folder1", context:, workflow_state: "deleted")
    json = preflight({ name: "test1.txt", parent_folder_id: sub.id.to_param }, expected_status: 404)
    expect(json["message"]).to eq "The specified resource does not exist."
  end

  it "rejects for nonexistent parent folder id" do
    json = preflight({ name: "test2.txt", parent_folder_id: 12_345_678_910_111_213.to_param }, expected_status: 404)
    expect(json["message"]).to eq "The specified resource does not exist."
  end

  it "uploads to an existing folder" do
    @folder = Folder.assert_path("/files/a/b/c/mypath", context)
    expect(@folder).to be_present
    expect(@folder).to be_visible
    preflight({ name: "my_essay.doc", folder: "files/a/b/c/mypath" })
    attachment = Attachment.order(:id).last
    expect(attachment.folder).to eq @folder
  end

  it "overwrites duplicate files by default" do
    local_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(folder: @folder, context:, filename: "test.txt", uploaded_data: StringIO.new("first"))
    json = preflight({ name: "test.txt", folder: "test" })

    tmpfile = Tempfile.new(["test", ".txt"])
    tmpfile.write("second")
    tmpfile.rewind
    post_params = json["upload_params"].merge({ "file" => tmpfile })
    send_multipart(json["upload_url"], post_params)
    post response["Location"], headers: { "Authorization" => "Bearer #{access_token_for_user @user}" }
    expect(response).to be_successful
    attachment = Attachment.order(:id).last
    expect(a1.reload).to be_deleted
    expect(attachment.reload).to be_available
    expect(attachment.display_name).to eq "test.txt"
    expect(attachment.folder).to eq @folder
    expect(attachment.open.read).to eq "second"
  end

  it "overwrites duplicate files by default for URL uploads" do
    local_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(folder: @folder, context:, filename: "test.txt", uploaded_data: StringIO.new("first"))
    preflight({ name: "test.txt", folder: "test", url: "http://www.example.com/test" })
    attachment = Attachment.order(:id).last
    expect(CanvasHttp).to receive(:get).with("http://www.example.com/test").and_yield(FakeHttpResponse.new(200, "second"))
    run_jobs

    expect(a1.reload).to be_deleted
    expect(attachment.reload).to be_available
    expect(attachment.display_name).to eq "test.txt"
    expect(attachment.folder).to eq @folder
    expect(attachment.open.read).to eq "second"
  end

  it "allows renaming instead of overwriting duplicate files (local storage)" do
    local_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(folder: @folder, context:, filename: "test.txt", uploaded_data: StringIO.new("first"))
    json = preflight({ name: "test.txt", folder: "test", on_duplicate: "rename" })

    tmpfile = Tempfile.new(["test", ".txt"])
    tmpfile.write("second")
    tmpfile.rewind
    post_params = json["upload_params"].merge({ "file" => tmpfile })
    send_multipart(json["upload_url"], post_params)
    post response["Location"], headers: { "Authorization" => "Bearer #{access_token_for_user @user}" }
    expect(response).to be_successful
    attachment = Attachment.order(:id).last
    expect(a1.reload).to be_available
    expect(attachment.reload).to be_available
    expect(a1.display_name).to eq "test.txt"
    expect(attachment.display_name).to eq "test-1.txt"
    expect(attachment.folder).to eq @folder
  end

  it "allows renaming instead of overwriting duplicate files for URL uploads" do
    local_storage!
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(folder: @folder, context:, filename: "test.txt", uploaded_data: StringIO.new("first"))
    preflight({ name: "test.txt", folder: "test", on_duplicate: "rename", url: "http://www.example.com/test" })
    attachment = Attachment.order(:id).last
    expect(CanvasHttp).to receive(:get).with("http://www.example.com/test").and_yield(FakeHttpResponse.new(200, "second"))
    run_jobs

    expect(a1.reload).to be_available
    expect(attachment.reload).to be_available
    expect(a1.display_name).to eq "test.txt"
    expect(attachment.display_name).to eq "test-1.txt"
    expect(attachment.folder).to eq @folder
  end

  it "allows renaming instead of overwriting duplicate files (s3 storage)" do
    @folder = Folder.assert_path("test", context)
    a1 = Attachment.create!(folder: @folder, context:, filename: "test.txt", uploaded_data: StringIO.new("first"))
    s3_storage!
    json = preflight({ name: "test.txt", folder: "test", on_duplicate: "rename" })

    redir = json["upload_params"]["success_action_redirect"]
    attachment = Attachment.order(:id).last
    expect_any_instance_of(Aws::S3::Object).to receive(:data).and_return({
                                                                           content_type: "application/msword",
                                                                           content_length: 1234,
                                                                         })

    post redir, headers: { "Authorization" => "Bearer #{access_token_for_user @user}" }
    expect(response).to be_successful
    expect(a1.reload).to be_available
    expect(attachment.reload).to be_available
    expect(attachment.display_name).to eq "test-1.txt"
  end

  it "rejects other duplicate file handling params" do
    json = preflight({ name: "test.txt", folder: "test", on_duplicate: "killall" }, { expected_status: 400 })
    expect(json["message"]).to eq "invalid on_duplicate option"
  end
end

shared_examples_for "file uploads api with quotas" do
  before do
    local_storage!
  end

  it "returns successful preflight for files within quota limits" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    preflight({ name: "test.txt", size: 3.megabytes })
    attachment = Attachment.order(:id).last
    expect(attachment.workflow_state).to eq "unattached"
    expect(attachment.filename).to eq "test.txt"
  end

  it "returns unsuccessful preflight for files exceeding quota limits" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    json = preflight({ name: "test.txt", size: 10.megabytes }, expected_status: 400)
    expect(json["message"]).to eq "file size exceeds quota"
  end

  it "returns unsuccessful preflight for files exceeding quota limits (URL uploads)" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    json = preflight({ name: "test.txt", size: 10.megabytes, url: "http://www.example.com/test" },
                     expected_status: 400)
    expect(json["message"]).to eq "file size exceeds quota"
  end

  it "returns successful create_success for files within quota" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    attachment = @context.attachments.new
    attachment.filename = "smaller_file.txt"
    attachment.file_state = "deleted"
    attachment.workflow_state = "unattached"
    attachment.content_type = "text/plain"
    attachment.size = 4.megabytes
    attachment.save!
    json = api_call(:get, "/api/v1/files/#{attachment.id}/create_success", { id: attachment.id.to_s, controller: "files", action: "api_create_success", format: "json" }, { uuid: attachment.uuid })
    expect(json["id"]).to eq attachment.id
    attachment.reload
    expect(attachment.file_state).to eq "available"
  end

  it "returns unsuccessful create_success for files exceeding quota limits" do
    @context.write_attribute(:storage_quota, 5.megabytes)
    @context.save!
    attachment = @context.attachments.new
    attachment.filename = "bigger_file.txt"
    attachment.file_state = "deleted"
    attachment.workflow_state = "unattached"
    attachment.content_type = "text/plain"
    attachment.size = 6.megabytes
    attachment.save!
    json = api_call(:get,
                    "/api/v1/files/#{attachment.id}/create_success",
                    { id: attachment.id.to_s, controller: "files", action: "api_create_success", format: "json" },
                    { uuid: attachment.uuid },
                    {},
                    expected_status: 400)
    expect(json["message"]).to eq "file size exceeds quota limits"
    attachment.reload
    expect(attachment.file_state).to eq "deleted"
  end

  it "fails URL uploads for files exceeding quota limits" do
    @context.write_attribute(:storage_quota, 1.megabyte)
    @context.save!
    json = preflight({ name: "test.txt", url: "http://www.example.com/test" })
    progress_url = json["progress"]["url"]
    progress_id = json["progress"]["id"]
    attachment = Attachment.order(:id).last
    expect(CanvasHttp).to receive(:get).with("http://www.example.com/test").and_yield(FakeHttpResponse.new(200, (" " * 2.megabytes)))
    run_jobs

    json = api_call(:get, progress_url, { id: progress_id, controller: "progress", action: "show", format: "json" })
    expect(json["workflow_state"]).to eq "failed"
    expect(json["message"]).to eq "file size exceeds quota limits: #{ActiveSupport::NumberHelper.number_to_delimited(2.megabytes)} bytes"
    expect(attachment.file_state).to eq "deleted"
  end
end

shared_examples_for "file uploads api without quotas" do
  it "ignores context-related quotas in preflight" do
    local_storage!

    @context.write_attribute(:storage_quota, 0)
    @context.save!
    json = preflight({ name: "test.txt", size: 1.megabyte })
    attachment = Attachment.order(:id).last
    expect(json["upload_url"]).to match(/#{attachment.quota_exemption_key}/)
  end

  it "ignores context-related quotas in preflight" do
    s3_storage!
    @context.write_attribute(:storage_quota, 0)
    @context.save!
    json = preflight({ name: "test.txt", size: 1.megabyte })
    attachment = Attachment.order(:id).last
    expect(json["upload_params"]["success_action_redirect"]).to match(/#{attachment.quota_exemption_key}/)
  end
end
