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
end
