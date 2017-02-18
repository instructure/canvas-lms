#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Canvas::LiveEvents do
  # The only methods tested in here are ones that have any sort of logic happening.

  def expect_event(event_name, event_body, event_context = nil)
    expect(LiveEvents).to receive(:post_event).with(event_name, event_body, anything, event_context)
  end

  describe ".wiki_page_updated" do
    before(:each) do
      course_with_teacher
      @page = @course.wiki.wiki_pages.create(:title => "old title", :body => "old body")
    end

    def wiki_page_updated
      Canvas::LiveEvents.wiki_page_updated(@page, @page.title_changed? ? @page.title_was : nil, @page.body_changed? ? @page.body_was : nil)
    end

    it "should not set old_title or old_body if they don't change" do
      expect_event('wiki_page_updated', {
        wiki_page_id: @page.global_id.to_s,
        title: "old title",
        body: "old body"
      })

      wiki_page_updated
    end

    it "should set old_title if the title changed" do
      @page.title = "new title"

      expect_event('wiki_page_updated', {
        wiki_page_id: @page.global_id.to_s,
        title: "new title",
        old_title: "old title",
        body: "old body"
      })

      wiki_page_updated
    end

    it "should set old_body if the body changed" do
      @page.body = "new body"

      expect_event('wiki_page_updated', {
        wiki_page_id: @page.global_id.to_s,
        title: "old title",
        body: "new body",
        old_body: "old body"
      })

      wiki_page_updated
    end
  end

  describe ".grade_changed" do
    let(:course_context) do
      hash_including(
        root_account_id: @course.root_account.global_id,
        root_account_lti_guid: @course.root_account.lti_guid,
        context_id: @course.global_id,
        context_type: 'Course'
      )
    end

    it "should set the grader to nil for an autograded quiz" do
      quiz_with_graded_submission([])

      expect_event('grade_change', hash_including(
        submission_id: @quiz_submission.submission.global_id.to_s,
        assignment_id: @quiz_submission.submission.global_assignment_id.to_s,
        grader_id: nil,
        student_id: @quiz_submission.user.global_id.to_s,
        user_id: @quiz_submission.user.global_id.to_s
      ), course_context)

      Canvas::LiveEvents.grade_changed(@quiz_submission.submission, @quiz_submission.submission.versions.current.model)
    end

    it "should set the grader when a teacher grades an assignment" do
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      expect_event('grade_change', hash_including(
        submission_id: submission.global_id.to_s,
        assignment_id: submission.global_assignment_id.to_s,
        grader_id: @teacher.global_id.to_s,
        student_id: @student.global_id.to_s,
        user_id: @student.global_id.to_s
      ), course_context)

      submission.grader = @teacher
      submission.grade = '10'
      submission.score = 10
      Canvas::LiveEvents.grade_changed(submission, submission.versions.current.model)
    end

    it "should include the user_id and assignment_id" do
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      expect_event('grade_change',
        hash_including(
          assignment_id: submission.global_assignment_id.to_s,
          user_id: @student.global_id.to_s
        ), course_context)
      Canvas::LiveEvents.grade_changed(submission, 0)
    end

    it "should include previous score attributes" do
      course_with_student_submissions submission_points: true
      submission = @course.assignments.first.submissions.first

      submission.score = 9000
      expect_event('grade_change',
        hash_including(
          score: 9000,
          old_score: 5
        ), course_context)
      Canvas::LiveEvents.grade_changed(submission, submission.versions.current.model)
    end

    it "should include previous points_possible attributes" do
      course_with_student_submissions
      assignment = @course.assignments.first
      assignment.points_possible = 5
      assignment.save!
      submission = assignment.submissions.first

      submission.assignment.points_possible = 99

      expect_event('grade_change',
        hash_including(
          points_possible: 99,
          old_points_possible: 5
        ), course_context)
      Canvas::LiveEvents.grade_changed(submission, submission, assignment.versions.current.model)
    end

    it "includes course context even when global course context unset" do
      allow(LiveEvents).to receive(:get_context).and_return({
        root_account_id: nil,
        root_account_lti_guid: nil,
        context_id: nil,
        context_type: nil,
        foo: 'bar'
      })
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      expect_event('grade_change', anything, course_context)
      Canvas::LiveEvents.grade_changed(submission)
    end

    it "includes existing context when global course context overridden" do
      allow(LiveEvents).to receive(:get_context).and_return({ foo: 'bar' })
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      expect_event('grade_change', anything, hash_including({ foo: 'bar' }))
      Canvas::LiveEvents.grade_changed(submission)
    end

    context "grading_complete" do
      before do
        course_with_student_submissions
      end

      let(:submission) { @course.assignments.first.submissions.first }

      it "is false when submission is not graded" do
        expect_event('grade_change', hash_including(
          grading_complete: false
        ), course_context)
        Canvas::LiveEvents.grade_changed(submission)
      end

      it "is true when submission is fully graded" do
        submission.score = 0
        submission.workflow_state = 'graded'

        expect_event('grade_change', hash_including(
          grading_complete: true
        ), course_context)
        Canvas::LiveEvents.grade_changed(submission)
      end

      it "is false when submission is partially graded" do
        submission.score = 0
        submission.workflow_state = 'pending_review'

        expect_event('grade_change', hash_including(
          grading_complete: false
        ), course_context)
        Canvas::LiveEvents.grade_changed(submission)
      end
    end

    context "muted" do
      before do
        course_with_student_submissions
      end

      let(:submission) { @course.assignments.first.submissions.first }

      it "is true when assignment is muted" do
        submission.assignment.mute!
        expect_event('grade_change', hash_including(
          muted: true
        ), course_context)
        Canvas::LiveEvents.grade_changed(submission)
      end
    end
  end

  describe ".submission_updated" do
    it "should include the user_id and assignment_id" do
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      expect_event('submission_updated',
        hash_including(
          user_id: @student.global_id.to_s,
          assignment_id: submission.global_assignment_id.to_s
        ))
      Canvas::LiveEvents.submission_updated(submission)
    end
  end

  describe ".asset_access" do
    it "should trigger a live event without an asset subtype" do
      course_factory

      expect_event('asset_accessed', {
        asset_type: 'course',
        asset_id: @course.global_id.to_s,
        asset_subtype: nil,
        category: 'category',
        role: 'role',
        level: 'participation'
      }).once

      Canvas::LiveEvents.asset_access(@course, 'category', 'role', 'participation')
    end

    it "should trigger a live event with an asset subtype" do
      course_factory

      expect_event('asset_accessed', {
        asset_type: 'course',
        asset_id: @course.global_id.to_s,
        asset_subtype: 'assignments',
        category: 'category',
        role: 'role',
        level: 'participation'
      }).once

      Canvas::LiveEvents.asset_access([ "assignments", @course ], 'category', 'role', 'participation')
    end
  end

  describe '.assignment_updated' do
    it 'triggers a live event with assignment details' do
      course_with_student_submissions
      assignment = @course.assignments.first

      expect_event('assignment_updated',
        hash_including({
          assignment_id: assignment.global_id.to_s,
          context_id: @course.global_id.to_s,
          context_type: 'Course',
          workflow_state: assignment.workflow_state,
          title: assignment.title,
          description: assignment.description,
          due_at: assignment.due_at,
          unlock_at: assignment.unlock_at,
          lock_at: assignment.lock_at,
          points_possible: assignment.points_possible
        })
      ).once

      Canvas::LiveEvents.assignment_updated(assignment)
    end
  end
end
