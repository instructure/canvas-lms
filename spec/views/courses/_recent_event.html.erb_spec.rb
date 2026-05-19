# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../views_helper"

describe "courses/_recent_event" do
  it "renders" do
    course_with_student
    assignment = @course.assignments.create!(title: "my assignment")
    view_context
    render partial: "courses/recent_event", object: assignment, locals: { is_hidden: false }
    expect(response).not_to be_nil
    expect(response.body).to match %r{<b class="event-details__title">my assignment</b>}
  end

  it "renders without a user" do
    course_factory
    assignment = @course.assignments.create!(title: "my assignment")
    view_context
    render partial: "courses/recent_event", object: assignment, locals: { is_hidden: false }
    expect(response).not_to be_nil
    expect(response.body).to match %r{<b class="event-details__title">my assignment</b>}
  end

  it "shows the context when asked to" do
    course_with_student
    event = @course.calendar_events.create(title: "some assignment", start_at: Time.zone.now)

    render partial: "courses/recent_event", object: event, locals: { is_hidden: false, show_context: true }

    expect(response.body).to include(@course.short_name)
  end

  it "doesn't show the context when not asked to" do
    course_with_student
    event = @course.calendar_events.create(title: "some assignment", start_at: Time.zone.now)

    render partial: "courses/recent_event", object: event, locals: { is_hidden: false }

    expect(response.body).not_to include(@course.name)
  end

  it "updates the course code when it changes" do
    enable_cache do
      course_with_student
      @course.update!(course_code: "MATH-101")
      event = @course.calendar_events.create(title: "some assignment", start_at: Time.zone.now)

      render partial: "courses/recent_event", object: event, locals: { is_hidden: false, show_context: true }
      expect(response.body).to include("MATH-101")

      @course.update!(course_code: "MATH-102")

      render partial: "courses/recent_event", object: event, locals: { is_hidden: false, show_context: true }
      expect(response.body).to include("MATH-102")
    end
  end

  it "renders calendar events with CourseSection context" do
    course_with_student
    section = @course.course_sections.create!(name: "Section A")
    event = section.calendar_events.create(title: "Section Event", start_at: Time.zone.now)

    render partial: "courses/recent_event", object: event, locals: { is_hidden: false }

    expect(response).not_to be_nil
    expect(response.body).to include("Section Event")
  end

  it "renders calendar events with CourseSection context showing the course code" do
    course_with_student
    @course.update!(course_code: "MATH-101")
    section = @course.course_sections.create!(name: "Section A")
    event = section.calendar_events.create(title: "Section Event", start_at: Time.zone.now)

    render partial: "courses/recent_event", object: event, locals: { is_hidden: false, show_context: true }

    expect(response.body).to include("MATH-101")
    expect(response.body).to include("Section Event")
  end

  context "assignments" do
    before do
      course_with_student(active_all: true)
      submission_model
      assign(:current_user, @user)
    end

    it "shows points possible for an ungraded assignment" do
      render partial: "courses/recent_event", object: @assignment, locals: { is_hidden: false }

      expect(response.body).to include("#{@assignment.points_possible} points")
    end

    it "shows the grade for a graded assignment" do
      @assignment.grade_student(@user, grade: 7, grader: @teacher)

      render partial: "courses/recent_event", object: @assignment, locals: { is_hidden: false }

      expect(response.body).to include("7 out of #{@assignment.points_possible}")
    end

    it "shows the due date" do
      render partial: "courses/recent_event", object: @assignment, locals: { is_hidden: false }

      expect(response.body).to include(view.datetime_string(@assignment.due_at))
    end

    it "shows overridden due date" do
      different_due_at = 2.days.from_now
      create_adhoc_override_for_assignment(@assignment, @user, due_at: different_due_at)

      render partial: "courses/recent_event", object: @assignment, locals: { is_hidden: false }

      expect(response.body).to include(view.datetime_string(different_due_at))
    end
  end

  context "peer review sub assignments" do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.account.enable_feature!(:peer_review_allocation_and_grading)
      @peer_review = peer_review_model(course: @course, due_at: 2.days.from_now, points_possible: 10)
    end

    before do
      view_context
    end

    it "renders with title, points, and due date" do
      render partial: "courses/recent_event", object: @peer_review, locals: { is_hidden: false }

      expect(response).not_to be_nil
      expect(response.body).to include(@peer_review.title)
      expect(response.body).to include("10 points")
      expect(response.body).to include("icon-peer-review")
    end

    it "renders correctly when @current_user_submissions is populated" do
      submission = @peer_review.submit_homework(@teacher, { submission_type: "online_text_entry", body: "my review" })
      assign(:current_user_submissions, [submission])

      render partial: "courses/recent_event", object: @peer_review, locals: { is_hidden: false }

      expect(response.body).to include(@peer_review.title)
      expect(response.body).to include("10 points")
    end

    it "includes peer_review_count in title when count > 0" do
      parent = @course.assignments.create!(
        title: "Counted Assignment",
        points_possible: 20,
        peer_reviews: true,
        peer_review_count: 2,
        submission_types: "online_text_entry",
        due_at: 1.day.from_now
      )
      peer_review = peer_review_model(parent_assignment: parent, due_at: 2.days.from_now, points_possible: 10)

      render partial: "courses/recent_event", object: peer_review, locals: { is_hidden: false }

      expect(response.body).to include("Counted Assignment Peer Review (2)")
    end

    it "shows Multiple Due Dates for teacher with section overrides" do
      @student = student_in_course(course: @course, active_all: true).user
      section = @course.course_sections.create!(name: "Section B")
      student_in_section(section, user: @student)

      section_due_at = 4.days.from_now
      create_section_override_for_assignment(@parent_assignment, course_section: section, due_at: section_due_at)
      PeerReview::SectionOverrideCreatorService.call(
        peer_review_sub_assignment: @peer_review,
        override: { set_id: section.id, due_at: section_due_at }
      )

      assign(:current_user, @teacher)

      render partial: "courses/recent_event", object: @peer_review, locals: { is_hidden: false }

      expect(response.body).to include("Multiple Due Dates")
    end

    it "shows overridden due date for student" do
      @student = student_in_course(course: @course, active_all: true).user
      different_due_at = 4.days.from_now
      create_adhoc_override_for_assignment(@parent_assignment, @student, due_at: different_due_at)
      PeerReview::AdhocOverrideCreatorService.call(
        peer_review_sub_assignment: @peer_review,
        override: { student_ids: [@student.id], due_at: different_due_at }
      )

      assign(:current_user, @student)

      render partial: "courses/recent_event", object: @peer_review, locals: { is_hidden: false }

      expect(response.body).to include(view.datetime_string(different_due_at))
    end
  end

  context "assignment muting" do
    before do
      course_with_student
      view_context
      @quiz = @course.quizzes.create!
      @quiz.generate_quiz_data
      @quiz.workflow_state = "available"
      @quiz.published_at = Time.zone.now
      @quiz.save

      @quiz_submission = @quiz.generate_submission(@user)
      Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission

      @submission = @quiz_submission.submission
      allow_any_instance_of(Submission).to receive(:grade).and_return("1234567890")
    end

    it "shows the grade for a non-muted assignment" do
      render partial: "courses/recent_event",
             object: @quiz.assignment,
             locals: { is_hidden: false, submissions: [@submission] }
      expect(response.body).to match(/1,234,567,890/)
    end

    it "does not show the grade for a muted assignment" do
      @quiz.assignment.mute!
      render partial: "courses/recent_event",
             object: @quiz.assignment,
             locals: { is_hidden: false, submissions: [@submission] }
      expect(response.body).not_to match(/1,234,567,890/)
    end
  end
end

# Sidebar content
