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

  describe ".wiki_page_updated" do
    before(:each) do
      course_with_teacher
      @page = @course.wiki.wiki_pages.create(:title => "old title", :body => "old body")
    end

    it "should not set old_title or old_body if they don't change" do
      @page.save

      LiveEvents.expects(:post_event).with('wiki_page_updated', {
        wiki_page_id: @page.global_id,
        title: "old title",
        body: "old body"
      })

      Canvas::LiveEvents.wiki_page_updated(@page)
    end

    it "should set old_title if the title changed" do
      @page.title = "new title"
      @page.save

      LiveEvents.expects(:post_event).with('wiki_page_updated', {
        wiki_page_id: @page.global_id,
        title: "new title",
        old_title: "old title",
        body: "old body"
      })

      Canvas::LiveEvents.wiki_page_updated(@page)
    end

    it "should set old_body if the body changed" do
      @page.body = "new body"
      @page.save

      LiveEvents.expects(:post_event).with('wiki_page_updated', {
        wiki_page_id: @page.global_id,
        title: "old title",
        body: "new body",
        old_body: "old body"
      })

      Canvas::LiveEvents.wiki_page_updated(@page)
    end
  end

  describe ".grade_changed" do
    it "should set the grader to nil for an autograded quiz" do
      quiz_with_graded_submission([])

      LiveEvents.expects(:post_event).with('grade_change', {
        submission_id: @quiz_submission.submission.global_id,
        grade: @quiz_submission.submission.grade,
        old_grade: 0,
        grader_id: nil,
        student_id: @quiz_submission.user.global_id
      })

      Canvas::LiveEvents.grade_changed(@quiz_submission.submission, 0)
    end

    it "should set the grader when a teacher grades an assignment" do
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      LiveEvents.expects(:post_event).with('grade_change', {
        submission_id: submission.global_id,
        grade: 10,
        old_grade: 0,
        grader_id: @teacher.global_id,
        student_id: @student.global_id
      })

      submission.grader = @teacher
      submission.grade = 10
      Canvas::LiveEvents.grade_changed(submission, 0)
    end
  end

  describe ".asset_access" do
    it "should trigger a live event without an asset subtype" do
      course

      LiveEvents.expects(:post_event).with('asset_accessed', {
        asset_type: 'course',
        asset_id: @course.global_id,
        asset_subtype: nil,
        category: 'category',
        role: 'role',
        level: 'participation'
      }).once

      Canvas::LiveEvents.asset_access(@course, 'category', 'role', 'participation')
    end

    it "should trigger a live event with an asset subtype" do
      course

      LiveEvents.expects(:post_event).with('asset_accessed', {
        asset_type: 'course',
        asset_id: @course.global_id,
        asset_subtype: 'assignments',
        category: 'category',
        role: 'role',
        level: 'participation'
      }).once

      Canvas::LiveEvents.asset_access([ "assignments", @course ], 'category', 'role', 'participation')
    end
  end
end
