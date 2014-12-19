#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
# more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CanvadocSessionsController do
  before :once do
    course_with_teacher(:active_all => true)

    @attachment1 = attachment_model :content_type => 'application/pdf',
      :context => @course
  end

  before :each do
    PluginSetting.create! :name => 'canvadocs',
                          :settings => {"base_url" => "https://example.com"}
    Canvadocs::API.any_instance.stubs(:upload).returns "id" => 1234
    Canvadocs::API.any_instance.stubs(:session).returns 'id' => 'SESSION'
    user_session(@teacher)
  end

  describe '#show' do
    before do
      @blob = {
        attachment_id: @attachment1.global_id,
        user_id: @teacher.global_id,
        type: "canvadoc",
      }
    end

    it "works" do
      get :show, blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)
      expect(response).to redirect_to("https://example.com/sessions/SESSION/view?theme=dark")
    end

    it "doesn't upload documents that are already uploaded" do
      @attachment1.submit_to_canvadocs
      Attachment.any_instance.expects(:submit_to_canvadocs).never
      get :show, blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)
      expect(response).to redirect_to("https://example.com/sessions/SESSION/view?theme=dark")
    end

    it "needs a valid signed blob" do
      hmac = Canvas::Security.hmac_sha1(@blob.to_json)

      attachment2 = attachment_model :content_type => 'application/pdf',
        :context => @course
      @blob[:attachment_id] = attachment2.id

      get :show, blob: @blob.to_json, hmac: hmac
      assert_status(401)
    end

    it "needs to be run by the blob user" do
      student_in_course
      @blob[:user_id] = @student.global_id
      blob = @blob.to_json
      get :show, blob: blob, hmac: Canvas::Security.hmac_sha1(blob)
      assert_status(401)
    end

    it "doesn't let you use a crocodoc blob" do
      @blob[:type] = "crocodoc"
      get :show, blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)
      assert_status(401)
    end

    it "allows nil users" do
      remove_user_session
      @blob[:user_id] = nil
      blob = @blob.to_json
      get :show, blob: blob, hmac: Canvas::Security.hmac_sha1(blob)
      expect(response).to redirect_to("https://example.com/sessions/SESSION/view?theme=dark")
    end

    it "fails gracefulishly when canvadocs times out" do
      Canvadocs::API.any_instance.stubs(:session).raises(Timeout::Error)
      get :show, blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)
      assert_status(503)
    end
  end
end
