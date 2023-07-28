# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe BrokenLinkHelper, type: :controller do
  include BrokenLinkHelper

  before :once do
    course_model
    student_in_course(course: @course)
    @current_user = @student
    assignment_model(course: @course, description: "<a href='/test_error'>bad link</a>")
  end

  it "returns false if no referrer" do
    allow(request).to receive(:referer).and_return nil
    expect(send_broken_content!).to be false
  end

  it "returns false if no course found" do
    allow(request).to receive(:referer).and_return "/hi"
    expect(send_broken_content!).to be false
  end

  it "returns false if no object with a body found" do
    allow(request).to receive(:referer).and_return "/courses/#{@course.id}/assignments"
    expect(send_broken_content!).to be false
  end

  it "returns false if the location is not found in the referrer body" do
    allow(request).to receive_messages(referer: "/courses/#{@course.id}/assignments/#{@assignment.id}", path: "/bad_link")
    @assignment.update(description: "stuff")
    expect(send_broken_content!).to be false
  end

  it "returns true for bad links in assignments with local 404 errors" do
    allow(request).to receive_messages(referer: "/courses/#{@course.id}/assignments/#{@assignment.id}", path: "/test_error")
    expect(send_broken_content!).to be true
  end

  it "returns true for bad links in quizzes" do
    quiz_model(course: @course, description: "<a href='/test_error'>bad link</a>")
    allow(request).to receive_messages(referer: "/courses/#{@course.id}/quizzes/#{@quiz.id}", path: "/test_error")
    expect(send_broken_content!).to be true
  end

  it "returns true for bad links in discussion topics" do
    discussion_topic_model(context: @course, message: "<a href='/test_error'>bad link</a>")
    allow(request).to receive_messages(referer: "/courses/#{@course.id}/discussion_topics/#{@topic.id}", path: "/test_error")
    expect(send_broken_content!).to be true
  end

  it "returns false for bad links in discussion topic entries" do
    discussion_topic_model(context: @course, message: "<a href='/good_page'>bad link</a>")
    @topic.reply_from(user: @student, html: "<a href='/test_error'>bad link</a>")
    allow(request).to receive_messages(referer: "/courses/#{@course.id}/discussion_topics/#{@topic.id}", path: "/test_error")
    expect(send_broken_content!).to be false
  end

  it "returns true for bad links in wiki pages" do
    wiki_page_model(context: @course, body: "<a href='/test_error'>bad link</a>")
    allow(request).to receive_messages(referer: "/courses/#{@course.id}/pages/#{@page.url}", path: "/test_error")
    expect(send_broken_content!).to be true
  end

  it "works with wiki pages set to the front page" do
    wiki_page_model(context: @course, body: "<a href='/test_error'>bad link</a>")
    @page.set_as_front_page!
    @course.update_attribute(:default_view, "wiki")
    allow(request).to receive_messages(referer: "/courses/#{@course.id}", path: "/test_error")
    expect(send_broken_content!).to be true
  end

  it "returns true for unpublished content" do
    linked_assignment = @assignment
    assignment_model(course: @course).update(workflow_state: "unpublished")
    linked_assignment.update(description: "<a href='/courses/#{@course.id}/assignments/#{@assignment.id}'>Unpublished Assignment</a>")
    allow(request).to receive_messages(referer: "/courses/#{@course.id}/assignments/#{linked_assignment.id}", path: "/courses/#{@course.id}/assignments/#{@assignment.id}")
    expect(send_broken_content!).to be true
  end

  context "#error_type" do
    it "returns :missing_item if the link doesn't point to course content" do
      expect(error_type(@course, "/test_error")).to eq :missing_item
    end

    it "returns :missing_item if the link doesn't match a Canvas route" do
      expect(error_type(@course, "/courses/#{@course.id}/quizes/1")).to eq :missing_item
    end

    it "returns :course_mismatch if the link comes from a different course" do
      assignment_model(course: @course)
      course_model
      expect(error_type(@course, "/courses/#{@assignment.context_id}/assignments/#{@assignment.id}")).to eq :course_mismatch
    end

    it "returns :unpublished_item for unpublished content" do
      @assignment.update(workflow_state: "unpublished")
      expect(error_type(@course, "/courses/#{@course.id}/assignments/#{@assignment.id}")).to eq :unpublished_item

      quiz_model(course: @course).update(workflow_state: "created")
      expect(error_type(@course, "/courses/#{@course.id}/quizzes/#{@quiz.id}")).to eq :unpublished_item

      attachment_model(context: @course).update(locked: true)
      expect(error_type(@course, "/courses/#{@course.id}/files/#{@attachment.id}/download")).to eq :unpublished_item
    end

    it "returns :deleted for deleted content" do
      @assignment.update(workflow_state: "deleted")
      expect(error_type(@course, "/courses/#{@course.id}/assignments/#{@assignment.id}")).to eq :deleted

      quiz_model(course: @course).update(workflow_state: "deleted")
      expect(error_type(@course, "/courses/#{@course.id}/quizzes/#{@quiz.id}")).to eq :deleted

      attachment_model(context: @course).update(file_state: "deleted")
      expect(error_type(@course, "/courses/#{@course.id}/files/#{@attachment.id}/download")).to eq :deleted
    end

    it "returns :inaccessible for group links the user doesn't have access to" do
      group_category(context: @course)
      group(group_category: @group_category, context: @course)
      wiki_page_model(context: @group)
      response.status = 401
      expect(error_type(@course, "/groups/#{@group.id}/pages/#{@page.url}")).to eq :inaccessible
      response.status = 403
      expect(error_type(@course, "/groups/#{@group.id}/pages/#{@page.url}")).to eq :inaccessible
    end

    it "returns :missing_item when the user got a 404 and the URL is valid in Canvas" do
      group_category(context: @course)
      group(group_category: @group_category, context: @course)
      wiki_page_model(context: @group)
      response.status = 404
      expect(error_type(@course, "/groups/#{@group.id}/pages/#{@page.url}")).to eq :missing_item
    end

    it "returns :missing_item when the user got to a route that doesn't exist in Canvas" do
      expect(error_type(@course, "/yo")).to eq :missing_item
    end
  end
end
