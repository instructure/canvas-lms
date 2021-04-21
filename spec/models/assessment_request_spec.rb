# frozen_string_literal: true

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
    assessor_submission = @assignment.find_or_create_submission(@review_student)
    @request = AssessmentRequest.create!(user: @submission_student, asset: submission, assessor_asset: assessor_submission, assessor: @review_student)
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

  describe 'peer review invitations' do
    before :once do
      communication_channel(@student, {username: 'test@example.com', active_cc: true})
      @notification_name = "Peer Review Invitation"
      notification = Notification.create!(:name => @notification_name, :category => 'Invitation')
      NotificationPolicy.create!(:notification => notification, :communication_channel => @student.communication_channel, :frequency => 'immediately')
    end

    it 'should send a notification if the course and assignment are published' do
      @request.send_reminder!
      expect(@request.messages_sent.keys).to include(@notification_name)
    end

    it 'should not send a notification if the course is unpublished' do
      submission = @assignment.find_or_create_submission(@user)
      assessor_submission = @assignment.find_or_create_submission(@review_student)
      @course.update!(workflow_state: 'created')
      peer_review_request = AssessmentRequest.create!(user: @submission_student, asset: submission, assessor_asset: assessor_submission, assessor: @review_student)
      peer_review_request.send_reminder!

      expect(peer_review_request.messages_sent.keys).to be_empty
    end

    it 'should not send a notification if the assignment is unpublished' do
      @assignment.update!(workflow_state: 'unpublished')
      submission = @assignment.find_or_create_submission(@user)
      assessor_submission = @assignment.find_or_create_submission(@review_student)
      peer_review_request = AssessmentRequest.create!(user: @submission_student, asset: submission, assessor_asset: assessor_submission, assessor: @review_student)
      peer_review_request.send_reminder!

      expect(peer_review_request.messages_sent.keys).to be_empty
    end
  end

  describe "notifications" do

    let(:notification_name) { 'Rubric Assessment Submission Reminder' }
    let(:notification)      { Notification.create!(:name => notification_name, :category => 'Invitation') }

    it "should send submission reminders" do
      communication_channel(@student, {username: 'test@example.com', active_cc: true})
      NotificationPolicy.create!(:notification => notification,
        :communication_channel => @student.communication_channel, :frequency => 'immediately')

      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
      @assignment.update_attribute(:title, 'new assmt title')

      @request.rubric_association = @association
      @request.save!
      @request.send_reminder!

      expect(@request.messages_sent.keys).to include(notification_name)
      expect(@request.messages_sent[notification_name].count).to eq 1
      message = @request.messages_sent[notification_name].first
      expect(message.body).to include(@assignment.title)
    end

    it "should send to the correct url if anonymous" do
      communication_channel(@student, {username: 'test@example.com', active_cc: true})
      NotificationPolicy.create!(:notification => notification,
        :communication_channel => @student.communication_channel, :frequency => 'immediately')

      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
      @assignment.update(:anonymous_peer_reviews => true)

      @request.rubric_association = @association
      @request.save!
      @request.send_reminder!

      expect(@request.messages_sent.keys).to include(notification_name)
      message = @request.messages_sent[notification_name].first
      expect(message.body).to include("/courses/#{@course.id}/assignments/#{@assignment.id}/anonymous_submissions/#{@request.asset.anonymous_id}")
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

  describe "#active_rubric_association?" do
    before(:once) do
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, purpose: 'grading', use_for_grading: true)
      @request.rubric_association = @association
      @request.save!
    end

    it "returns false if there is no rubric association" do
      @request.update!(rubric_association: nil)
      expect(@request).not_to be_active_rubric_association
    end

    it "returns false if the rubric association is soft-deleted" do
      @association.destroy
      expect(@request).not_to be_active_rubric_association
    end

    it "returns true if the rubric association exists and is active" do
      expect(@request).to be_active_rubric_association
    end
  end
end
