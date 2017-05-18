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

  context "with crocodoc" do
    before do
      @attachment.submit_to_crocodoc
    end

    it "works for the user in the blob" do
      get :show, blob: @blob, hmac: @hmac
      expect(response.body).to include 'https://crocodoc.com/view/SESSION'
    end

    it "doesn't work for others" do
      user_session(@teacher)
      get :show, blob: @blob, hmac: @hmac
      assert_status(401)
    end

    it "fails gracefulishly when crocodoc times out" do
      Crocodoc::API.any_instance.stubs(:session).raises(Timeout::Error)
      get :show, blob: @blob, hmac: @hmac
      assert_status(503)
    end

    it "updates attachment.viewed_at if the owner (user that is the context of the attachment) views" do
      last_viewed_at = @attachment.viewed_at

      get :show, blob: @blob, hmac: @hmac

      @attachment.reload
      expect(@attachment.viewed_at).not_to eq(last_viewed_at)
    end


    it "updates attachment.viewed_at if the owner (person in the user attribute of the attachment) views" do
      assignment = @course.assignments.create!(assignment_valid_attributes)
      attachment = attachment_model content_type: 'application/pdf', context: assignment, user: @student
      attachment.submit_to_crocodoc
      blob = {attachment_id: attachment.global_id,
             user_id: @student.global_id,
             type: "crocodoc"}.to_json
      hmac = Canvas::Security.hmac_sha1(blob)
      last_viewed_at = attachment.viewed_at

      get :show, blob: blob, hmac: hmac

      attachment.reload
      expect(attachment.viewed_at).not_to eq(last_viewed_at)
    end

    it "doesn't update attachment.viewed_at for non-owner views" do
      last_viewed_at = @attachment.viewed_at

      teacher_blob = {attachment_id: @attachment.global_id,
                      user_id: @teacher.global_id,
                      type: "crocodoc"}.to_json
      teacher_hmac = Canvas::Security.hmac_sha1(teacher_blob)
      user_session(@teacher)

      get :show, blob: teacher_blob, hmac: teacher_hmac

      @attachment.reload
      expect(@attachment.viewed_at).to eq(last_viewed_at)
    end
  end

  it "should 404 if a crocodoc document is unavailable" do
    get :show, blob: @blob, hmac: @hmac
    assert_status(404)
  end

  context "Migrate to Canvadocs" do
    before do
      @attachment.submit_to_crocodoc
      Account.default.enable_feature!(:new_annotations)
      Canvadocs.stubs(:enabled?).returns true
      Canvadocs.stubs(:annotations_supported?).returns true
      Canvadocs.stubs(:hijack_crocodoc_sessions?).returns false

      Canvadocs::API.any_instance.stubs(:session).returns 'id' => 'SESSION'
      PluginSetting.create! :name => 'canvadocs',
                            :settings => { "base_url" => "https://canvadocs.instructure.docker" }
    end

    it "should redirect to a canvadocs session instead of crocodoc when enabled" do
      Canvadocs.stubs(:hijack_crocodoc_sessions?).returns true
      get :show, blob: @blob, hmac: @hmac
      expect(response.body).to include 'https://canvadocs.instructure.docker/sessions/SESSION/view'
    end

    it "should not redirect to a canvadocs session instead of crocodoc when disabled" do
      get :show, blob: @blob, hmac: @hmac
      expect(response.body).to_not include 'https://canvadocs.instructure.docker/sessions/SESSION/view'
    end
  end
end
