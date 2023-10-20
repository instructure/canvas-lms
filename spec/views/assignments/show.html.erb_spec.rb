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

require_relative "../../lti2_spec_helper"
require_relative "../views_helper"

describe "assignments/show" do
  let(:eula_url) { "https://www.test.com/eula" }

  it "renders" do
    course_with_teacher(active_all: true)
    view_context(@course, @user)
    g = @course.assignment_groups.create!(name: "some group")
    a = @course.assignments.create!(title: "some assignment")
    a.assignment_group_id = g.id
    a.save!
    assign(:assignment, a)
    assign(:assignment_groups, [g])
    assign(:current_user_rubrics, [])
    allow(view).to receive(:show_moderation_link).and_return(true)
    render "assignments/show"
    expect(response).not_to be_nil # have_tag()
    # for an assignment with no content
    expect(rendered).to include "No additional details were added for this assignment."
    expect(response).not_to have_tag(".assignment_header")
  end

  context "future locked assignments" do
    it "renders locked future assignments" do
      course_with_student(active_all: true)
      view_context(@course, @user)
      g = @course.assignment_groups.create!(name: "some group")
      a = @course.assignments.create!(title: "some assignment")
      a.assignment_group_id = g.id
      a.save!
      a.lock_at = 1.week.from_now
      a.due_at = 3.weeks.from_now
      a.unlock_at = 2.weeks.from_now
      assign(:assignment, a)
      assign(:assignment_groups, [g])
      assign(:current_user_rubrics, [])
      locked = a.locked_for?(@user, check_policies: true, deep_check_if_needed: true)
      assign(:show_locked_page, locked)
      allow(view).to receive_messages(show_moderation_link: true)

      render "assignments/show"

      expect(response).not_to be_nil # have_tag()
      expect(response).to have_tag(".assignment_header")
    end
  end

  it "renders webcam wrapper" do
    course_with_student(active_all: true)
    view_context(@course, @student)
    g = @course.assignment_groups.create!(name: "some group")
    a = @course.assignments.create!(title: "some assignment", submission_types: "online_upload")
    a.assignment_group_id = g.id
    a.save!
    assign(:assignment, a.overridden_for(@student))
    assign(:assignment_groups, [g])
    assign(:current_user_rubrics, [])
    assign(:external_tools, [])
    allow(view).to receive_messages(show_moderation_link: true, show_confetti: false)
    allow(view).to receive(:eula_url) { eula_url }
    render "assignments/show"
    expect(response).to have_tag(".attachment_wrapper")
  end

  describe "moderation page link" do
    before do
      course_with_teacher(active_all: true)
      view_context(@course, @user)
      g = @course.assignment_groups.create!(name: "Homework")
      a = @course.assignments.create!(title: "Introduce Yourself")
      a.assignment_group_id = g.id
      a.save!
      assign(:assignment, a)
      assign(:assignment_groups, [g])
      assign(:current_user_rubrics, [])
    end

    it "is rendered when 'show_moderation_link' is true" do
      allow(view).to receive(:show_moderation_link).and_return(true)
      render "assignments/show"
      expect(rendered).to include "moderated_grading_button"
    end

    it "is not rendered when 'show_moderation_link' is false" do
      allow(view).to receive(:show_moderation_link).and_return(false)
      render "assignments/show"
      expect(rendered).not_to include "moderated_grading_button"
    end
  end

  context "plagiarism platform" do
    include_context "lti2_spec_helper"

    let(:eula_service) do
      {
        "endpoint" => eula_url,
        "action" => ["GET"],
        "@id" => "http://www.test.com/lti/v2/services#vnd.Canvas.Eula",
        "@type" => "RestService"
      }
    end

    before do
      allow_any_instance_of(Assignment).to receive(:multiple_due_dates?) { true }
      allow(view).to receive(:eula_url) { eula_url }
      allow(view).to receive(:show_confetti).and_return(false)
    end

    it "renders the eula url if present" do
      tool_proxy.raw_data["tool_profile"]["service_offered"] << eula_service
      tool_proxy.resources << resource_handler
      tool_proxy.save!

      course_with_student(active_all: true)
      view_context(@course, @student)

      a = @course.assignments.create!(title: "some assignment", submission_types: "online_upload")
      allow(a).to receive(:tool_settings_tool) { message_handler }
      assign(:assignment, a)
      assign(:current_user_rubrics, [])
      assign(:external_tools, [])

      render "assignments/show"
      expect(rendered).to include "<a href='https://www.test.com/eula'>End-User License Agreement.</a>"
    end
  end

  context "confetti" do
    before do
      course_with_student(active_all: true)
      view_context(@course, @user)
      a = @course.assignments.create!(title: "Introduce Yourself")
      a.save!
      assign(:assignment, a.overridden_for(@user))
    end

    it "is rendered when 'show_confetti' is true" do
      allow(view).to receive_messages(show_confetti: true, show_moderation_link: false)
      render "assignments/show"
      expect(response).to render_template partial: "_confetti"
    end
  end
end
