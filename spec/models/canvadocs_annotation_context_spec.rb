# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"

describe CanvadocsAnnotationContext do
  before(:once) do
    @course = course_model
    student = student_in_course(course: @course, active_all: true).user
    @assignment = assignment_model(course: @course)
    @sub = @assignment.submissions.find_by(user: student)
    @att = attachment_model(context: student)
  end

  it "requires an attachment" do
    expect do
      CanvadocsAnnotationContext.create!(submission: @sub, attachment: nil, submission_attempt: 1)
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "requires a submission" do
    expect do
      CanvadocsAnnotationContext.create!(submission: nil, attachment: @att, submission_attempt: 1)
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "sets a root_account_id automatically" do
    annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
    expect(annotation_context.root_account_id).to eq @course.root_account_id
  end

  it "does not allow setting the root_account_id to nil" do
    annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
    expect { annotation_context.update!(root_account_id: nil) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "sets a launch_id automatically" do
    annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
    expect(annotation_context.launch_id).not_to be_nil
  end

  it "does not allow setting the launch_id to nil" do
    annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
    expect { annotation_context.update!(launch_id: nil) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "is unique for a combination of attachment_id, submission_attempt, and submission_id" do
    CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)

    expect do
      CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  describe "permissions" do
    describe "read" do
      context "draft submissions" do
        let(:annotation_context) do
          @sub.canvadocs_annotation_contexts.create!(attachment: @att, submission_attempt: nil)
        end

        it "grants read to the owning user" do
          expect(annotation_context.grants_right?(@sub.user, :read)).to be true
        end

        it "does not grant read to students that do not own the submission" do
          other_student = student_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(other_student, :read)).to be false
        end

        it "does not grant read to peers assigned for review" do
          peer_reviewer = student_in_course(course: @course, active_all: true).user
          @assignment.update!(peer_reviews: true)
          @assignment.assign_peer_review(peer_reviewer, @sub.user)
          expect(annotation_context.grants_right?(peer_reviewer, :read)).to be false
        end

        it "does not grant read to teachers" do
          teacher = teacher_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(teacher, :read)).to be false
        end

        it "does not grant read to provisional graders" do
          @assignment.update!(moderated_grading: true, grader_count: 1)
          teacher = teacher_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(teacher, :read)).to be false
        end
      end

      context "non-draft submissions" do
        let(:annotation_context) do
          @sub.canvadocs_annotation_contexts.create!(attachment: @att, submission_attempt: 1)
        end

        it "grants read to the owning user" do
          expect(annotation_context.grants_right?(@sub.user, :read)).to be true
        end

        it "does not grant read to students that do not own the submission" do
          other_student = student_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(other_student, :read)).to be false
        end

        it "grants read to peers assigned for review" do
          peer_reviewer = student_in_course(course: @course, active_all: true).user
          @assignment.update!(peer_reviews: true)
          @assignment.assign_peer_review(peer_reviewer, @sub.user)
          expect(annotation_context.grants_right?(peer_reviewer, :read)).to be true
        end

        it "grants read to teachers" do
          teacher = teacher_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(teacher, :read)).to be true
        end

        it "does not grant read to teachers without manage grades permissions" do
          @course.root_account.role_overrides.create!(permission: "manage_grades", role: teacher_role, enabled: false)
          teacher = teacher_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(teacher, :read)).to be false
        end

        it "grants read to provisional graders" do
          @assignment.update!(moderated_grading: true, grader_count: 1)
          teacher = teacher_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(teacher, :read)).to be true
        end
      end
    end

    describe "annotate" do
      context "draft submissions" do
        let(:annotation_context) do
          @sub.canvadocs_annotation_contexts.create!(attachment: @att, submission_attempt: nil)
        end

        it "grants annotate to the owning user" do
          expect(annotation_context.grants_right?(@sub.user, :annotate)).to be true
        end

        it "does not grant annotate to students that do not own the submission" do
          other_student = student_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(other_student, :annotate)).to be false
        end

        it "does not grant annotate to peers assigned for review" do
          peer_reviewer = student_in_course(course: @course, active_all: true).user
          @assignment.update!(peer_reviews: true)
          @assignment.assign_peer_review(peer_reviewer, @sub.user)
          expect(annotation_context.grants_right?(peer_reviewer, :annotate)).to be false
        end

        it "does not grant annotate to teachers" do
          teacher = teacher_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(teacher, :annotate)).to be false
        end

        it "does not grant annotate to provisional graders" do
          @assignment.update!(moderated_grading: true, grader_count: 1)
          teacher = teacher_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(teacher, :annotate)).to be false
        end
      end

      context "non-draft submissions" do
        let(:annotation_context) do
          @sub.canvadocs_annotation_contexts.create!(attachment: @att, submission_attempt: 1)
        end

        it "does not grant annotate to the owning user" do
          expect(annotation_context.grants_right?(@sub.user, :annotate)).to be false
        end

        it "does not grant annotate to students that do not own the submission" do
          other_student = student_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(other_student, :annotate)).to be false
        end

        it "does not grant annotate to peers assigned for review" do
          peer_reviewer = student_in_course(course: @course, active_all: true).user
          @assignment.update!(peer_reviews: true)
          @assignment.assign_peer_review(peer_reviewer, @sub.user)
          expect(annotation_context.grants_right?(peer_reviewer, :annotate)).to be false
        end

        it "grants annotate to teachers" do
          teacher = teacher_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(teacher, :annotate)).to be true
        end

        it "does not grant annotate to teachers without manage grades permissions" do
          @course.root_account.role_overrides.create!(permission: "manage_grades", role: teacher_role, enabled: false)
          teacher = teacher_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(teacher, :annotate)).to be false
        end

        it "grants annotate to provisional graders" do
          @assignment.update!(moderated_grading: true, grader_count: 1)
          teacher = teacher_in_course(course: @course, active_all: true).user
          expect(annotation_context.grants_right?(teacher, :annotate)).to be true
        end
      end
    end

    context "when assignment is moderated" do
      before(:once) do
        @final_grader = @course.enroll_teacher(User.create!, enrollment_state: :active).user
        @provisional_grader_1 = @course.enroll_teacher(User.create!).user
        @provisional_grader_2 = @course.enroll_teacher(User.create!).user
        @provisional_grader_3 = @course.enroll_teacher(User.create!).user
        @assignment.update!(final_grader: @final_grader, grader_count: 2, moderated_grading: true)
      end

      it "grants annotate if grader slots are still available" do
        annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
        expect(annotation_context.grants_right?(@provisional_grader_1, :annotate)).to be true
      end

      it "grants annotate if grader is final grader and slots are full" do
        @assignment.grade_student(@sub.user, grader: @provisional_grader_1, provisional: true, score: 1)
        @assignment.grade_student(@sub.user, grader: @provisional_grader_2, provisional: true, score: 1)
        annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
        expect(annotation_context.grants_right?(@final_grader, :annotate)).to be true
      end

      it "grants annotate if grader is not final grader, slots are full, but user has graded before" do
        @assignment.grade_student(@sub.user, grader: @provisional_grader_1, provisional: true, score: 1)
        @assignment.grade_student(@sub.user, grader: @provisional_grader_2, provisional: true, score: 1)
        annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
        expect(annotation_context.grants_right?(@provisional_grader_1, :annotate)).to be true
      end

      it "does not grant annotate if grader is not final grader, slots are full, and user has not graded before" do
        @assignment.grade_student(@sub.user, grader: @provisional_grader_1, provisional: true, score: 1)
        @assignment.grade_student(@sub.user, grader: @provisional_grader_2, provisional: true, score: 1)
        annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
        expect(annotation_context.grants_right?(@provisional_grader_3, :annotate)).to be false
      end
    end
  end

  describe "#draft?" do
    it "is a draft when it isn't associated with any submission attempt" do
      annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att)
      expect(annotation_context).to be_draft
    end

    it "is not a draft when it is associated with any submission attempt" do
      annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
      expect(annotation_context).not_to be_draft
    end
  end
end
