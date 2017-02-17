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
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ContentParticipationCount do
  before :once do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)

    @assignment = @course.assignments.new(:title => "some assignment")
    @assignment.workflow_state = "published"
    @assignment.save
  end

  describe "create_or_update" do
    before :once do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
    end

    it "should count current unread objects correctly" do
      ["Submission"].each do |type|
        cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @teacher, :content_type => type)
        cpc.expects(:refresh_unread_count).never
        expect(cpc.unread_count).to eq 0

        cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @student, :content_type => type)
        cpc.expects(:refresh_unread_count).never
        expect(cpc.unread_count).to eq 1
      end
    end

    it "should update if the object already exists" do
      cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @student, :content_type => "Submission")
      ContentParticipationCount.create_or_update(:context => @course, :user => @student, :content_type => "Submission", :offset => -1)
      cpc.reload
      cpc.expects(:refresh_unread_count).never
      expect(cpc.unread_count).to eq 0
    end

    it "should not save if not changed" do
      time = Time.now.utc - 1.day
      cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @student, :content_type => "Submission")
      ContentParticipationCount.where(:id => cpc).update_all(:updated_at => time)
      ContentParticipationCount.create_or_update(:context => @course, :user => @student, :content_type => "Submission")
      expect(cpc.reload.updated_at.to_i).to eq time.to_i
    end
  end

  describe "unread_count_for" do
    before :once do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
    end

    it "should find the unread count for different types" do
      ["Submission"].each do |type|
        expect(ContentParticipationCount.unread_count_for(type, @course, @teacher)).to eq 0
        expect(ContentParticipationCount.unread_count_for(type, @course, @student)).to eq 1
      end
    end

    it "should handle invalid contexts" do
      ["Submission"].each do |type|
        expect(ContentParticipationCount.unread_count_for(type, Account.default, @student)).to eq 0
      end
    end

    it "should handle invalid types" do
      expect(ContentParticipationCount.unread_count_for("Assignment", @course, @student)).to eq 0
    end

    it "should handle missing contexts or users" do
      ["Submission"].each do |type|
        expect(ContentParticipationCount.unread_count_for(type, nil, @student)).to eq 0
        expect(ContentParticipationCount.unread_count_for(type, @course, nil)).to eq 0
      end
    end
  end

  describe "unread_count" do
    it "should not refresh if just created" do
      ["Submission"].each do |type|
        cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @teacher, :content_type => type)
        cpc.expects(:refresh_unread_count).never
        expect(cpc.unread_count).to eq 0
      end
    end

    it "should refresh if data could be stale" do
      ["Submission"].each do |type|
        cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @teacher, :content_type => type)
        cpc.expects(:refresh_unread_count).never
        expect(cpc.unread_count).to eq 0
        ContentParticipationCount.where(:id => cpc).update_all(:updated_at => Time.now.utc - 1.day)
        cpc.reload
        cpc.expects(:refresh_unread_count)
        expect(cpc.unread_count).to eq 0
      end
    end
  end

  describe "unread_submission_count_for" do
    it "should be read if a submission exists with no grade" do
      @submission = @assignment.submit_homework(@student)
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "should be unread after assignment is graded" do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 1
    end

    it "should not be unread if the assignment is unpublished after the submission is graded" do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @assignment.update_attribute(:workflow_state, 'unpublished')
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "should be read after viewing the graded assignment" do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @submission.change_read_state("read", @student)
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "should be unread after submission is graded" do
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 1
    end

    it "should be unread after submission is commented on by teacher" do
      @submission = @assignment.update_submission(@student, { :commenter => @teacher, :comment => "good!" }).first
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 1
    end

    it "should be read after viewing the submission comment" do
      @submission = @assignment.update_submission(@student, { :commenter => @teacher, :comment => "good!" }).first
      @submission.change_read_state("read", @student)
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "should be read after submission is commented on by self" do
      @submission = @assignment.submit_homework(@student)
      @comment = SubmissionComment.create!(:submission => @submission, :comment => "hi", :author => @student)
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "should be read if other submission fields change" do
      @submission = @assignment.submit_homework(@student)
      @submission.workflow_state = 'graded'
      @submission.graded_at = Time.now
      @submission.save!
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end
  end
end
