#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper.rb')

module Alerts
  describe Alerts::Interaction do
    before :once do
      course_with_teacher(:active_all => 1)
      @teacher = @user
      @user = nil
      student_in_course(:active_all => 1)
    end

    describe "#should_not_receive_message?" do
      context "when there are no messages" do
        context "when there is a start_at set on the course" do
          it "returns true for new courses" do
            interaction_alert = Alerts::Interaction.new(@course, [@student.id], [@teacher.id])
            interaction_alert.should_not_receive_message?(@student.id, 7).should == true
          end

          it "returns false for old courses" do
            @course.start_at = Time.now - 30.days

            interaction_alert = Alerts::Interaction.new(@course, [@student.id], [@teacher.id])
            interaction_alert.should_not_receive_message?(@student.id, 7).should == false
          end
        end

        context "when there is not a start_at set on the course" do
          it "returns true for new courses" do
            @course.created_at = Time.now
            @course.start_at = nil
            @course.save!

            interaction_alert = Alerts::Interaction.new(@course, [@student.id], [@teacher.id])
            interaction_alert.should_not_receive_message?(@student.id, 7).should == true
          end

          it "returns false for old courses" do
            @course.created_at = Time.now - 30.days
            @course.start_at = nil
            @course.save!

            interaction_alert = Alerts::Interaction.new(@course, [@student.id], [@teacher.id])
            interaction_alert.should_not_receive_message?(@student.id, 7).should == false
          end
        end
      end

      it "returns true for submission comments" do
        @assignment = @course.assignments.new(:title => "some assignment")
        @assignment.workflow_state = "published"
        @assignment.save
        @submission = @assignment.submit_homework(@student)
        SubmissionComment.create!(:submission => @submission, :comment => 'new comment', :author => @teacher, :recipient => @student)
        SubmissionComment.create!(:submission => @submission, :comment => 'old comment', :author => @teacher, :recipient => @student) do |submission_comment|
          submission_comment.created_at = Time.now - 30.days
        end
        @course.start_at = Time.now - 30.days

        interaction_alert = Alerts::Interaction.new(@course, [@student.id], [@teacher.id])
        interaction_alert.should_not_receive_message?(@student.id, 7).should == true
      end

      it "returns false for old submission comments" do
        @assignment = @course.assignments.new(:title => "some assignment")
        @assignment.workflow_state = "published"
        @assignment.save
        @submission = @assignment.submit_homework(@student)
        SubmissionComment.create!(:submission => @submission, :comment => 'some comment', :author => @teacher, :recipient => @student) do |sc|
          sc.created_at = Time.now - 30.days
        end
        @course.start_at = Time.now - 30.days

        interaction_alert = Alerts::Interaction.new(@course, [@student.id], [@teacher.id])
        interaction_alert.should_not_receive_message?(@student.id, 7).should == false
      end

      it "returns true for conversation messages" do
        @conversation = @teacher.initiate_conversation([@student])
        @conversation.add_message("hello")
        @course.start_at = Time.now - 30.days

        interaction_alert = Alerts::Interaction.new(@course, [@student.id], [@teacher.id])
        interaction_alert.should_not_receive_message?(@student.id, 7).should == true
      end

      it "returns false for old conversation messages" do
        @conversation = @teacher.initiate_conversation([@student, user])
        message = @conversation.add_message("hello")
        message.created_at = Time.now - 30.days
        message.save!
        @course.start_at = Time.now - 30.days
        @conversation.add_participants([user])
        @conversation.messages.length.should == 2

        interaction_alert = Alerts::Interaction.new(@course, [@student.id], [@teacher.id])
        interaction_alert.should_not_receive_message?(@student.id, 7).should == false
      end
    end
  end
end
