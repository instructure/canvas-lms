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

  before do
    course_with_student(:active_all => true)
    @student_pseudonym = @pseudonym
    course_with_teacher_logged_in(:active_all => true)

    attachment_model :content_type => 'application/pdf', :context => @student
    submission_model :course => @course, :user => @student
    @submission.update_attribute :attachment_ids, @attachment.id
  end

  context "with submission" do
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
  end

  context "without submission" do
    before do
      @attachment.submit_to_crocodoc
    end

    it "should create a session for the owner of the attachment" do
      user_session(@student)
      post :create, :attachment_id => @attachment.id
      response.body.should include 'https://crocodoc.com/view/SESSION'
    end

    it "should not create a session for others" do
      post :create, :attachment_id => @attachment.id
      response.status.should == '401 Unauthorized'
    end
  end

  it "should 404 if a crocodoc document is unavailable" do
    lambda {
      post :create,
           :submission_id => @submission.id,
           :attachment_id => @attachment.id
    }.should raise_error(ActiveRecord::RecordNotFound)
  end
end
