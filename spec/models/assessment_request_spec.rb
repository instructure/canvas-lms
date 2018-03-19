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
  before :once do
    course_with_teacher(active_all: true)
    @submission_student = student_in_course(active_all: true, course: @course).user
    @review_student = student_in_course(active_all: true, course: @course).user
    @assignment = @course.assignments.create!
    submission = @assignment.find_or_create_submission(@user)
    @request = AssessmentRequest.create!(user: @submission_student, asset: submission, assessor_asset: @review_student, assessor: @review_student)
  end

  describe "workflow" do
    it "defaults to assigned" do
      expect(@request).to be_assigned
    end

    it "can be completed" do
      @request.complete!
      expect(@request).to be_completed
    end
  end

  describe "notifications" do

    let(:notification_name) { 'Rubric Assessment Submission Reminder' }
    let(:notification)      { Notification.create!(:name => notification_name, :category => 'Invitation') }

    it "should send submission reminders" do
      @student.communication_channels.create!(:path => 'test@example.com').confirm!
      NotificationPolicy.create!(:notification => notification,
        :communication_channel => @student.communication_channel, :frequency => 'immediately')

      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
      @assignment.update_attribute(:title, 'new assmt title')

      @request.rubric_association = @association
      @request.save!
      @request.send_reminder!

      expect(@request.messages_sent.keys).to include(notification_name)
      message = @request.messages_sent[notification_name].first
      expect(message.body).to include(@assignment.title)
    end
  end

  describe 'policies' do

    before :once do
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
      @assignment.update_attribute(:anonymous_peer_reviews, true)
      @reviewed = @student
      @reviewer = student_in_course(active_all: true, course: @course).user
      @assessment_request = @assignment.assign_peer_review(@reviewer, @reviewed)
      @assessment_request.rubric_association = @association
      @assessment_request.save!
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

  describe '#delete_ignores' do
    before :once do
      @ignore = Ignore.create!(asset: @request, user: @student, purpose: 'reviewing')
    end

    it 'should delete ignores if the request is completed' do
      @request.complete!
      expect {@ignore.reload}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should delete ignores if the request is deleted' do
      @request.destroy!
      expect {@ignore.reload}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should not delete ignores if the request is updated, but not completed or deleted' do
      @request.assessor = @teacher
      @request.save!
      expect(@ignore.reload).to eq @ignore
    end
  end
end
