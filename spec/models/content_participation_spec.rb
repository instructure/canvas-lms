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

describe ContentParticipation do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    assignment_model(course: @course)
    @content = @assignment.submit_homework(@student)
  end

  describe "create_or_update" do
    it "creates if it doesn't exist" do
      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "read",
                                              })
      end.to change(ContentParticipation, :count).by 1
    end

    it "updates existing if one already exists" do
      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "read",
                                              })
      end.to change(ContentParticipation, :count).by 1

      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "unread",
                                              })
      end.to change(ContentParticipation, :count).by 0

      cp = ContentParticipation.where(user_id: @student).first
      expect(cp.workflow_state).to eq "unread"
    end

    context "when feeback visibility ff is on" do
      before do
        Account.site_admin.enable_feature!(:visibility_feedback_student_grades_page)
      end

      it "creates 'grade' participation if content_item not given" do
        expect do
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread")
        end.to change(ContentParticipation, :count).by 1

        cp = ContentParticipation.where(user_id: @student).first
        expect(cp.content_item).to eq "grade"
      end

      it "create a participation item as read" do
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")

        cp = ContentParticipation.where(user_id: @student).first
        expect(cp.workflow_state).to eq "read"
      end

      it "creates all possible content items for a submission" do
        expect do
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread")
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread", content_item: "comment")
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread", content_item: "rubric")
        end.to change(ContentParticipation, :count).by 3
      end

      it "doesn't allow invalid content_item" do
        expect do
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread", content_item: "_ruby")
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "doesn't duplicate content_item if submission is the same" do
        expect do
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread")
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread")
        end.to change(ContentParticipation, :count).by 1
      end

      it "changes a content_item state from unread to read" do
        expect do
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread")
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
        end.to change(ContentParticipation, :count).by 1

        cp = ContentParticipation.where(user_id: @student).first
        expect(cp.workflow_state).to eq "read"
      end

      it "changes a content_item state from read to unread" do
        expect do
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread")
        end.to change(ContentParticipation, :count).by 1

        cp = ContentParticipation.where(user_id: @student).first
        expect(cp.workflow_state).to eq "unread"
      end

      context "when multiple submissions exist" do
        before do
          temp_assignment = @assignment
          @assignment2 = assignment_model(course: @course)
          @content2 = @assignment2.submit_homework(@student)
          @assignment = temp_assignment
        end

        it "create two participation if same item but different submissions" do
          expect do
            ContentParticipation.participate(content: @content, user: @student)
            ContentParticipation.participate(content: @content2, user: @student)
          end.to change(ContentParticipation, :count).by 2
        end
      end
    end
  end

  describe "submission_read?" do
    context "when feeback visibility ff is on" do
      before do
        Account.site_admin.enable_feature!(:visibility_feedback_student_grades_page)
      end

      it "is read if no participation exist" do
        expect(ContentParticipation.count).to eq 0
        expect(ContentParticipation.submission_read?(content: @content, user: @student)).to be_truthy
      end

      it "is not read if existing item is unread" do
        ContentParticipation.participate(content: @content, user: @student)
        expect(ContentParticipation.submission_read?(content: @content, user: @student)).to be_falsey
      end

      it "is read if one content_item is present and state changes to read" do
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread")
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
        expect(ContentParticipation.submission_read?(content: @content, user: @student)).to be_truthy
      end

      it "is read when all items are read" do
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
        ContentParticipation.participate(content: @content, user: @student, content_item: "comment", workflow_state: "read")
        ContentParticipation.participate(content: @content, user: @student, content_item: "rubric", workflow_state: "read")
        expect(ContentParticipation.submission_read?(content: @content, user: @student)).to be_truthy
      end

      it "is unread if at least one item is unread" do
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
        ContentParticipation.participate(content: @content, user: @student, content_item: "comment", workflow_state: "unread")
        ContentParticipation.participate(content: @content, user: @student, content_item: "rubric", workflow_state: "read")
        expect(ContentParticipation.submission_read?(content: @content, user: @student)).to be_falsey
      end
    end
  end

  describe "submission_item_read?" do
    context "when feeback visibility ff is on" do
      before do
        Account.site_admin.enable_feature!(:visibility_feedback_student_grades_page)
      end

      it "grade is unread if workflow_state is not given" do
        ContentParticipation.participate(content: @content, user: @student)

        expect(ContentParticipation.submission_item_read?(
                 content: @content,
                 user: @student,
                 content_item: "grade"
               )).to be_falsey
      end

      it "changes submisison grade from unread to read" do
        ContentParticipation.participate(content: @content, user: @student)
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")

        expect(ContentParticipation.submission_item_read?(
                 content: @content,
                 user: @student,
                 content_item: "grade"
               )).to be_truthy
      end
    end
  end

  describe "update_participation_count" do
    it "updates the participation count automatically when the workflow state changes" do
      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "read",
                                              })
      end.to change(ContentParticipationCount, :count).by 1

      ContentParticipation.create_or_update({
                                              content: @content,
                                              user: @student,
                                              workflow_state: "unread",
                                            })
      cpc = ContentParticipationCount.where(user_id: @student).first
      expect(cpc.unread_count).to eq 1
    end

    it "does not update participation count if workflow_state doesn't change" do
      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "read",
                                              })
      end.to change(ContentParticipationCount, :count).by 1

      ContentParticipation.create_or_update({
                                              content: @content,
                                              user: @student,
                                              workflow_state: "read",
                                            })
      cpc = ContentParticipationCount.where(user_id: @student).first
      expect(cpc.unread_count).to eq 0
    end

    it "unread count does not decrement if unread count is at 0 and workflow state changes from unread to read" do
      expect do
        ContentParticipation.create_or_update({
                                                content: @content,
                                                user: @student,
                                                workflow_state: "unread",
                                              })
      end.to change(ContentParticipationCount, :count).by 1

      ContentParticipation.create_or_update({
                                              content: @content,
                                              user: @student,
                                              workflow_state: "read",
                                            })
      cpc = ContentParticipationCount.where(user_id: @student).first
      expect(cpc.unread_count).to eq 0
    end

    context "when feeback visibility ff is on" do
      before do
        Account.site_admin.enable_feature!(:visibility_feedback_student_grades_page)
        @content.update_columns(posted_at: Time.now.utc, workflow_state: "graded", score: 10)
      end

      it "unread_count is 1 when at least one submission participation item is unread" do
        expect do
          ContentParticipation.participate(content: @content, user: @student)
          ContentParticipation.participate(content: @content, user: @student, content_item: "comment", workflow_state: "read")
          ContentParticipation.participate(content: @content, user: @student, content_item: "rubric", workflow_state: "read")
        end.to change(ContentParticipationCount, :count).by 1

        cpc = ContentParticipationCount.where(user_id: @student).first
        expect(cpc.unread_count).to eq 1
      end

      it "unread_count is 0 when all submission participation items are read" do
        expect do
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "read", content_item: "comment")
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "read", content_item: "rubric")
        end.to change(ContentParticipationCount, :count).by 1

        cpc = ContentParticipationCount.where(user_id: @student).first
        expect(cpc.unread_count).to eq 0
      end

      it "unread_count is 1 when all items are unread and one is set to read" do
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
        ContentParticipation.participate(content: @content, user: @student, content_item: "comment")
        ContentParticipation.participate(content: @content, user: @student, content_item: "rubric")

        expect do
          ContentParticipation.participate(content: @content, user: @student, content_item: "rubric", workflow_state: "read")
        end.to change(ContentParticipationCount, :count).by 0

        cpc = ContentParticipationCount.where(user_id: @student).first
        expect(cpc.unread_count).to eq 1
      end

      it "unread_count is 1 when all items are read and one is set to unread" do
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read", content_item: "comment")
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read", content_item: "rubric")

        expect(ContentParticipationCount.count).to eq 1

        ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread", content_item: "comment")

        cpc = ContentParticipationCount.where(user_id: @student).first
        expect(cpc.reload.unread_count).to eq 1
      end

      it "unread_count is 0 when the last unread item is set to read" do
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread", content_item: "comment")
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read", content_item: "rubric")

        cpc = ContentParticipationCount.where(user_id: @student).first
        expect(cpc.unread_count).to eq 1

        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read", content_item: "comment")
        expect(cpc.reload.unread_count).to eq 0
      end

      it "unread_count is 1 the only existing item is changed to unread" do
        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")

        cpc = ContentParticipationCount.where(user_id: @student).first
        expect(cpc.unread_count).to eq 0

        ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread")
        expect(cpc.reload.unread_count).to eq 1
      end

      it "unread_count is 0 the only existing item is changed to read" do
        ContentParticipation.participate(content: @content, user: @student)

        cpc = ContentParticipationCount.where(user_id: @student).first
        expect(cpc.unread_count).to eq 1

        ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
        expect(cpc.reload.unread_count).to eq 0
      end

      context "when multiple submissions exist" do
        before do
          temp_assignment = @assignment
          @assignment2 = assignment_model(course: @course)
          @content2 = @assignment2.submit_homework(@student)
          @assignment = temp_assignment
          @content2.update_columns(posted_at: Time.now.utc, workflow_state: "graded", score: 10)
        end

        it "unread_count is 2 when submissions are unread" do
          ContentParticipation.participate(content: @content, user: @student)
          ContentParticipation.participate(content: @content2, user: @student)

          cpc = ContentParticipationCount.where(user_id: @student).first
          expect(cpc.unread_count).to eq 2
        end

        it "unread_count is 0 when submissions are read" do
          ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
          ContentParticipation.participate(content: @content2, user: @student, workflow_state: "read")

          cpc = ContentParticipationCount.where(user_id: @student).first
          expect(cpc.unread_count).to eq 0
        end

        it "unread_count changes from 2 to 0 after submissions are read" do
          ContentParticipation.participate(content: @content, user: @student)
          ContentParticipation.participate(content: @content2, user: @student)

          cpc = ContentParticipationCount.where(user_id: @student).first
          expect(cpc.unread_count).to eq 2

          ContentParticipation.participate(content: @content, user: @student, workflow_state: "read")
          ContentParticipation.participate(content: @content2, user: @student, workflow_state: "read")

          expect(cpc.reload.unread_count).to eq 0
        end

        it "unread_count is 1 when one submission is read and another is unread" do
          ContentParticipation.participate(content: @content, user: @student)
          ContentParticipation.participate(content: @content2, user: @student, workflow_state: "read")

          cpc = ContentParticipationCount.where(user_id: @student).first
          expect(cpc.unread_count).to eq 1
        end
      end

      context "when multiple courses exist" do
        before do
          @course2 = Course.create!
          @course2_student = student_in_course(course: @course2, active_all: true).user
          @course2_assignment = assignment_model(course: @course2, due_at: 2.days, points_possible: 10)
          @course2_content = @course2_assignment.submit_homework(@course2_student)

          @course2_content.update_columns(posted_at: Time.now.utc, workflow_state: "graded", score: 10)
        end

        it "unread_count is 1 for each course" do
          expect do
            ContentParticipation.participate(content: @content, user: @student)
            ContentParticipation.participate(content: @course2_content, user: @course2_student)
          end.to change(ContentParticipationCount, :count).by 2

          cpc1 = @course.content_participation_counts.where(user_id: @student).first
          expect(cpc1.unread_count).to eq 1

          cpc2 = @course2.content_participation_counts.where(user_id: @course2_student).first
          expect(cpc2.unread_count).to eq 1
        end
      end
    end
  end

  describe "create" do
    it "sets the root_account_id from the submissions assignment" do
      participant = ContentParticipation.create_or_update({
                                                            content: @content,
                                                            user: @student,
                                                            workflow_state: "unread",
                                                          })
      expect(participant.root_account_id).to eq(@assignment.root_account_id)
    end
  end
end
