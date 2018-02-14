#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../selenium/common')
require_relative '../../selenium/helpers/files_common'
require_relative '../../apis/api_spec_helper'
require_relative '../../selenium/helpers/eportfolios_common'
require_relative '../../../gems/canvas_http/lib/canvas_http'

describe "instfs file uploads" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include Helpers
  # include EportfoliosCommon
  include CanvasHttp
  let(:admin_guy) {account_admin_user(account: Account.site_admin)}
  let(:folder) { Folder.root_folders(admin_guy).first }
  let(:token) {Canvas::Security.create_jwt({}, nil, InstFS.jwt_secret)}

  def get_instfs_url(context_var, user, folder_location, filename, file_type)
    instfs_stuff = InstFS.upload_preflight_json(
      context: context_var,
      user: user,
      folder: folder_location,
      filename: filename,
      content_type: file_type,
      on_duplicate: "overwrite",
      quota_exempt: true,
      capture_url: "http://#{HostUrl.default_host}/api/v1/files/capture"
    )
    URI(instfs_stuff[:upload_url])
  end

  def get_request(url, filename, file_path, file_type)
    request = Net::HTTP::Post.new(url)
    boundary = "socool"
    post_body = []
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"#{filename}\"; filename=\"#{file_path}\"\r\n"
    post_body << "Content-Type: #{file_type}\r\n\r\n"
    post_body << File.read(file_path)
    post_body << "\r\n--#{boundary}--\r\n"
    request.body = post_body.join
    request["content-type"] = "multipart/form-data; boundary=#{boundary}"
    request
  end

  def upload_file_to_instfs(file_path, context_var, user, folder_location)
    filename = File.basename(file_path)
    file_type = Attachment.mimetype(filename)
    url = get_instfs_url(context_var, user, folder_location, filename, file_type)
    request = get_request(url, filename, file_path, file_type)
    http = Net::HTTP.new(url.host, url.port)
    http.request(request)
  end

  context 'when uploading to instfs as an admin' do
    before do
      user_session(admin_guy)
      course_with_teacher(account: @root_account, active_all: true, password: 'lolwut12')
      setting = PluginSetting.find_by(name: 'inst_fs') || PluginSetting.new(name: 'inst_fs')
      setting.disabled = false
      setting.settings = {}
      setting.save
      allow(InstFS).to receive(:enabled?).and_return true
    end

    it "should upload a file to instfs on the files page", priority: "1", test_id: 3399288 do
      filename = "test_image.jpg"
      # filename = "files/instructure.png"
      file_path = File.join(ActionController::TestCase.fixture_path, filename)
      upload_file_to_instfs(file_path, admin_guy, admin_guy, folder)
      get "/files"
      wait_for_ajaximations
      file_element = f(".ef-name-col__link")
      # if a file is less than 10K, "open" will return a StringIO, not a file object.
      # need to stream to a temp file just in case
      downloaded_data = open(file_element.attribute("href"))
      temp_file = Tempfile.new("cool")
      IO.copy_stream(downloaded_data, temp_file.path)
      temp_md5 = Digest::MD5.hexdigest File.read(temp_file)
      original_md5 = Digest::MD5.hexdigest File.read(file_path)
      expect(temp_file.size).to be > 0
      expect(temp_md5).to eq original_md5
    end
  end
end
