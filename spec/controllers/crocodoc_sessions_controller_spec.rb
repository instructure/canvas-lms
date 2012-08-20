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
  before do
    Setting.set 'crocodoc_counter', 0
    PluginSetting.create! :name => 'crocodoc',
                          :settings => { :api_key => "blahblahblahblahblah" }
    Crocodoc::API.any_instance.stubs(:upload).returns 'uuid' => '1234567890'
    Crocodoc::API.any_instance.stubs(:session).returns 'session' => 'SESSION'
  end

  context "POST 'create'" do
    before do
      course_with_teacher_logged_in(:active_all => true)

      attachment_model :content_type => 'application/pdf'
      submission_model :course => @course
      @submission.update_attribute :attachment_ids, @attachment.id
    end

    it "should create a session" do
      @attachment.submit_to_crocodoc
      post :create,
           :submission_id => @submission.id,
           :attachment_id => @attachment.id
      assert_response :success
      response.body.should include 'https://crocodoc.com/view/SESSION'
    end

    it "should ensure the attachment is tied to the submission" do
      @submission.update_attribute :attachment_ids, nil
      lambda {
        post :create,
             :submission_id => @submission.id,
             :attachment_id => @attachment.id
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should 404 if a crocodoc document is unavailable" do
      lambda {
        post :create,
             :submission_id => @submission.id,
             :attachment_id => @attachment.id
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
