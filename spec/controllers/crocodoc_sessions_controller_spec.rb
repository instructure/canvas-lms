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
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CrocodocSessionsController do
  before :once do
    Setting.set 'crocodoc_counter', 0
    PluginSetting.create! :name => 'crocodoc',
                          :settings => { :api_key => "blahblahblahblahblah" }
    @student_pseudonym = @pseudonym
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
    attachment_model :content_type => 'application/pdf', :context => @student
    @blob = {attachment_id: @attachment.global_id,
             user_id: @student.global_id,
             type: "crocodoc"}.to_json
    @hmac = Canvas::Security.hmac_sha1(@blob)
  end

  before :each do
    Crocodoc::API.any_instance.stubs(:upload).returns 'uuid' => '1234567890'
    Crocodoc::API.any_instance.stubs(:session).returns 'session' => 'SESSION'
    user_session(@student)
  end

  context "without crocodoc" do
    before do
      @attachment.submit_to_crocodoc
    end

    it "works for the user in the blob" do
      get :show, blob: @blob, hmac: @hmac
      response.body.should include 'https://crocodoc.com/view/SESSION'
    end

    it "doesn't work for others" do
      user_session(@teacher)
      get :show, blob: @blob, hmac: @hmac
      assert_status(401)
    end
  end

  it "should 404 if a crocodoc document is unavailable" do
    get :show, blob: @blob, hmac: @hmac
    assert_status(404)
  end
end
