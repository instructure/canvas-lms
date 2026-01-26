# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe OverrideTooltipPresenter do
  describe "#selector" do
    it "returns a unique selector for the assignment" do
      assignment = Assignment.new
      assignment.context = course_factory
      assignment.save

      presenter = OverrideTooltipPresenter.new(assignment)

      expect(presenter.selector).to eq "assignment_#{assignment.id}"
    end

    it "returns a unique selector for the quiz" do
      quiz = Quizzes::Quiz.new(title: "some quiz")
      quiz.context = course_factory
      quiz.save

      presenter = OverrideTooltipPresenter.new(quiz)

      expect(presenter.selector).to eq "quiz_#{quiz.id}"
    end

    it "returns a downcase selector for peer review sub-assignments" do
      course = course_factory
      course.root_account.enable_feature!(:peer_review_allocation_and_grading)
      assignment = course.assignments.create!(title: "Test Assignment", peer_reviews: true)

      PeerReview::PeerReviewCreatorService.call(
        parent_assignment: assignment,
        points_possible: 5
      )

      peer_review_sub = assignment.reload.peer_review_sub_assignment
      presenter = OverrideTooltipPresenter.new(peer_review_sub)

      expect(presenter.selector).to eq "peerreviewsubassignment_#{peer_review_sub.id}"
    end
  end

  describe "#due_date_summary" do
    let(:course) { course_factory }
    let(:student) { user_factory }
    let(:section1) { course.course_sections.create!(name: "Section A") }
    let(:section2) { course.course_sections.create!(name: "Section B") }

    context "with peer review sub-assignments" do
      it "includes unlock_at and lock_at in the summary" do
        course.root_account.enable_feature!(:peer_review_allocation_and_grading)
        assignment = course.assignments.create!(title: "Test Assignment", peer_reviews: true)

        PeerReview::PeerReviewCreatorService.call(
          parent_assignment: assignment,
          points_possible: 5,
          due_at: 2.days.from_now
        )

        peer_review_sub = assignment.reload.peer_review_sub_assignment

        parent_override1 = assignment.assignment_overrides.create!(
          set_type: "CourseSection",
          set_id: section1.id
        )

        parent_override2 = assignment.assignment_overrides.create!(
          set_type: "CourseSection",
          set_id: section2.id
        )

        peer_review_sub.assignment_overrides.create!(
          set_type: "CourseSection",
          set_id: section1.id,
          parent_override_id: parent_override1.id,
          due_at: 2.days.from_now,
          unlock_at: 1.day.from_now,
          lock_at: 3.days.from_now
        )

        peer_review_sub.assignment_overrides.create!(
          set_type: "CourseSection",
          set_id: section2.id,
          parent_override_id: parent_override2.id,
          due_at: 3.days.from_now,
          unlock_at: 2.days.from_now,
          lock_at: 4.days.from_now
        )

        presenter = OverrideTooltipPresenter.new(peer_review_sub, student)
        summary = presenter.due_date_summary

        expect(summary).to be_an(Array)
        expect(summary.first).to have_key(:unlock_at)
        expect(summary.first).to have_key(:lock_at)
        expect(summary.first).to have_key(:due_for)
        expect(summary.first).to have_key(:due_at)
      end
    end

    context "with assignments that have peer reviews enabled" do
      it "includes unlock_at and lock_at in the summary" do
        assignment = course.assignments.create!(
          title: "Test Assignment",
          peer_reviews: true,
          due_at: 2.days.from_now
        )

        assignment.assignment_overrides.create!(
          set_type: "CourseSection",
          set_id: section1.id,
          due_at: 2.days.from_now,
          unlock_at: 1.day.from_now,
          lock_at: 3.days.from_now
        )

        assignment.assignment_overrides.create!(
          set_type: "CourseSection",
          set_id: section2.id,
          due_at: 3.days.from_now,
          unlock_at: 2.days.from_now,
          lock_at: 4.days.from_now
        )

        presenter = OverrideTooltipPresenter.new(assignment, student)
        summary = presenter.due_date_summary

        expect(summary).to be_an(Array)
        expect(summary.first).to have_key(:unlock_at)
        expect(summary.first).to have_key(:lock_at)
      end
    end

    context "with assignments that do not have peer reviews enabled" do
      it "does not include unlock_at and lock_at in the summary" do
        assignment = course.assignments.create!(
          title: "Test Assignment",
          peer_reviews: false,
          due_at: 2.days.from_now
        )

        assignment.assignment_overrides.create!(
          set_type: "CourseSection",
          set_id: section1.id,
          due_at: 2.days.from_now,
          unlock_at: 1.day.from_now,
          lock_at: 3.days.from_now
        )

        assignment.assignment_overrides.create!(
          set_type: "CourseSection",
          set_id: section2.id,
          due_at: 3.days.from_now,
          unlock_at: 2.days.from_now,
          lock_at: 4.days.from_now
        )

        presenter = OverrideTooltipPresenter.new(assignment, student)
        summary = presenter.due_date_summary

        expect(summary).to be_an(Array)
        expect(summary.first).not_to have_key(:unlock_at)
        expect(summary.first).not_to have_key(:lock_at)
        expect(summary.first).to have_key(:due_for)
        expect(summary.first).to have_key(:due_at)
      end
    end
  end
end
