#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe AssessmentRequest do
  describe "workflow" do
    let_once(:request) do
      user_factory
      course_factory
      assignment = @course.assignments.create!
      submission = assignment.find_or_create_submission(@user)

      AssessmentRequest.create!(user: @user, asset: submission, assessor_asset: @user, assessor: @user)
    end

    it "defaults to assigned" do
      expect(request).to be_assigned
    end

    it "can be completed" do
      request.complete!
      expect(request).to be_completed
    end
  end

  describe "notifications" do

    let(:notification_name) { 'Rubric Assessment Submission Reminder' }
    let(:notification)      { Notification.create!(:name => notification_name, :category => 'Invitation') }

    it "should send submission reminders" do
      course_with_student(:active_all => true)
      @student.communication_channels.create!(:path => 'test@example.com').confirm!
      NotificationPolicy.create!(:notification => notification,
        :communication_channel => @user.communication_channel, :frequency => 'immediately')

      assignment = @course.assignments.create!
      submission = assignment.find_or_create_submission(@student)
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
      assignment.update_attribute(:title, 'new assmt title')

      request = AssessmentRequest.new(:user => @user, :asset => submission, :assessor_asset => @student, :assessor => @user, :rubric_association => @association)
      request.send_reminder!

      expect(request.messages_sent.keys).to include(notification_name)
      message = request.messages_sent[notification_name].first
      expect(message.body).to include(assignment.title)
    end
  end

  describe 'policies' do

    before :once do
      assignment_model
      @teacher = user_factory(active_all: true)
      @course.enroll_teacher(@teacher).accept
      @student = user_factory(active_all: true)
      @course.enroll_student(@student).accept
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
      @assignment.update_attribute(:anonymous_peer_reviews, true)
      @reviewed = @student
      @reviewer = student_in_course(:active_all => true).user
      @assessment_request = @assignment.assign_peer_review(@reviewer, @reviewed)
    end
    it "should prevent reviewer from seeing reviewed name" do
      expect(@assessment_request.grants_right?(@reviewer, :read_assessment_user)).to be_falsey
    end

    it "should allow reviewed to see own name" do
      expect(@assessment_request.grants_right?(@reviewed, :read_assessment_user)).to be_truthy
    end

    it "should allow teacher to see reviewed users name" do
      expect(@assessment_request.grants_right?(@teacher, :read_assessment_user)).to be_truthy
    end
  end

end
