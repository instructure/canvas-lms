# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "messages_helper"

describe "content_link_error" do
  before :once do
    @course = course_model
    @course2 = course_model
    unpublished_assignment = assignment_model(course: @course)
    @assignment = assignment_model(course: @course, description: "<a href='/courses/#{@course.id}/offline_web_exports'>Offline web exports</a>")
    @quiz = quiz_model(course: @course, description: "<a href='/courses/#{@course2.id}/assignments'>Wrong course</a>")
    @dt = discussion_topic_model(course: @course, message:
      "<a href='/courses/#{@course.id}/assignments/#{unpublished_assignment.id}'>Unpublished assignment</a>")
    @page = wiki_page_model(course: @course)
  end

  let(:asset) { @assignment }
  let(:notification_name) { :content_link_error }

  context "with a quiz" do
    let(:asset) { @quiz }

    include_examples "a message"
  end

  context "with a discussion topic" do
    let(:asset) { @dt }

    include_examples "a message"
  end

  context "with a wiki page" do
    let(:asset) { @page }

    include_examples "a message"
  end
end
