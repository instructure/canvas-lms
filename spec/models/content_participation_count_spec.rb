# frozen_string_literal: true

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

describe ContentParticipationCount do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)

    @course.default_post_policy.update!(post_manually: false)

    @assignment = @course.assignments.new(title: "some assignment")
    @assignment.workflow_state = "published"
    @assignment.save
  end

  describe "create_or_update" do
    before :once do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
    end

    it "counts current unread objects correctly" do
      ["Submission"].each do |type|
        cpc = ContentParticipationCount.create_or_update(context: @course, user: @teacher, content_type: type)
        expect(cpc).not_to receive(:refresh_unread_count)
        expect(cpc.unread_count).to eq 0

        cpc = ContentParticipationCount.create_or_update(context: @course, user: @student, content_type: type)
        expect(cpc).not_to receive(:refresh_unread_count)
        expect(cpc.unread_count).to eq 1
      end
    end

    it "updates if the object already exists" do
      cpc = ContentParticipationCount.create_or_update(context: @course, user: @student, content_type: "Submission")
      ContentParticipationCount.create_or_update(context: @course, user: @student, content_type: "Submission", offset: -1)
      cpc.reload
      expect(cpc).not_to receive(:refresh_unread_count)
      expect(cpc.unread_count).to eq 0
    end

    it "does not save if not changed" do
      time = Time.now.utc - 1.day
      cpc = ContentParticipationCount.create_or_update(context: @course, user: @student, content_type: "Submission")
      ContentParticipationCount.where(id: cpc).update_all(updated_at: time)
      ContentParticipationCount.create_or_update(context: @course, user: @student, content_type: "Submission")
      expect(cpc.reload.updated_at.to_i).to eq time.to_i
    end

    it "sets root_account_id from course correctly" do
      cpc = ContentParticipationCount.create_or_update(context: @course, user: @student, content_type: "Submission")
      expect(cpc.root_account_id).to eq(@course.root_account_id)
    end
  end

  describe "unread_count_for" do
    before :once do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
    end

    it "finds the unread count for different types" do
      ["Submission"].each do |type|
        expect(ContentParticipationCount.unread_count_for(type, @course, @teacher)).to eq 0
        expect(ContentParticipationCount.unread_count_for(type, @course, @student)).to eq 1
      end
    end

    it "handles invalid contexts" do
      ["Submission"].each do |type|
        expect(ContentParticipationCount.unread_count_for(type, Account.default, @student)).to eq 0
      end
    end

    it "handles invalid types" do
      expect(ContentParticipationCount.unread_count_for("Assignment", @course, @student)).to eq 0
    end

    it "handles missing contexts or users" do
      ["Submission"].each do |type|
        expect(ContentParticipationCount.unread_count_for(type, nil, @student)).to eq 0
        expect(ContentParticipationCount.unread_count_for(type, @course, nil)).to eq 0
      end
    end
  end

  describe "unread_count" do
    it "does not refresh if just created" do
      ["Submission"].each do |type|
        cpc = ContentParticipationCount.create_or_update(context: @course, user: @teacher, content_type: type)
        expect(cpc).not_to receive(:refresh_unread_count)
        expect(cpc.unread_count).to eq 0
      end
    end

    it "refreshes if data could be stale" do
      ["Submission"].each do |type|
        cpc = ContentParticipationCount.create_or_update(context: @course, user: @teacher, content_type: type)
        allowed = false
        expect(cpc).to receive(:refresh_unread_count).and_wrap_original do |original|
          raise "not allowed" unless allowed

          original.call
        end
        expect(cpc.unread_count).to eq 0
        ContentParticipationCount.where(id: cpc).update_all(updated_at: Time.now.utc - 1.day)
        cpc.reload
        allowed = true
        expect(cpc.unread_count).to eq 0
      end
    end
  end

  describe "unread_submission_count_for" do
    it "is read if a submission exists with no grade" do
      @submission = @assignment.submit_homework(@student)
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "is unread after assignment is graded" do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 1
    end

    it "is not unread if the assignment is unpublished after the submission is graded" do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @assignment.update_attribute(:workflow_state, "unpublished")
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "is read after viewing the graded assignment" do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @submission.change_read_state("read", @student)
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "is read if a graded assignment is set to ungraded for some reason" do
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @assignment.update_attribute(:submission_types, "not_graded")
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "is unread after submission is graded" do
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 1
    end

    it "is unread after submission is commented on by teacher" do
      @submission = @assignment.update_submission(@student, { commenter: @teacher, comment: "good!" }).first
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 1
    end

    it "ignores draft comments" do
      @submission = @assignment.update_submission(
        @student,
        {
          commenter: @teacher,
          comment: "good!",
          draft_comment: true
        }
      ).first
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "ignores hidden comments" do
      @assignment.ensure_post_policy(post_manually: true)
      @submission = @assignment.update_submission(
        @student,
        {
          commenter: @teacher,
          comment: "good!",
          hidden: true
        }
      ).first
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "is read after viewing the submission comment" do
      @submission = @assignment.update_submission(@student, { commenter: @teacher, comment: "good!" }).first
      @submission.mark_item_read("comment")
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "is read after submission is commented on by self" do
      @submission = @assignment.submit_homework(@student)
      @comment = SubmissionComment.create!(submission: @submission, comment: "hi", author: @student)
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "is read if other submission fields change" do
      @submission = @assignment.submit_homework(@student)
      @submission.workflow_state = "graded"
      @submission.graded_at = Time.now
      @submission.save!
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 0
    end

    it "counts unread for automatically posted submissions that have no posted_at" do
      student2 = User.create!
      @submission = @assignment.update_submission(@student, { commenter: student2, comment: "good!" }).first
      expect(@submission.reload.posted_at).to be_nil
      expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 1
    end

    context "muted assignments" do
      it "does not ignore muted assignments" do
        @assignment.grade_student(@student, grade: 3, grader: @teacher)
        @assignment.muted = true
        @assignment.save
        expect(ContentParticipationCount.unread_submission_count_for(@course, @student)).to eq 1
      end
    end
  end
end
