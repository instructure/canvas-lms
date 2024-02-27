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

require_relative "../common"
require_relative "../helpers/assignments_common"

describe "assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  def click_away_accept_alert
    f("#section-tabs .home").click
    driver.switch_to.alert.accept # doing this step and the step above to avoid the alert from failing other selenium specs
  end

  def update_assignment_attributes(assignment, attribute, values, click_submit_link = true)
    assignment.update(attribute => values)
    get "/courses/#{@course.id}/assignments/#{assignment.id}"
    f(".submit_assignment_link").click if click_submit_link
  end

  context "as a student" do
    before do
      course_with_student_logged_in
    end

    before do
      @due_date = Time.now.utc + 2.days
      @assignment = @course.assignments.create!(title: "default assignment", name: "default assignment", due_at: @due_date)
    end

    it "validates an assignment created with the type of discussion" do
      @assignment.update(submission_types: "discussion_topic")

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(driver.current_url).to match %r{/courses/\d+/discussion_topics/\d+}
      expect(f("h1.discussion-title")).to include_text(@assignment.title)
    end

    it "validates an assignment created with the type of not graded" do
      @assignment.update(submission_types: "not_graded")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(f("#content")).not_to contain_css(".submit_assignment_link")
    end

    it "validates on paper submission assignment type" do
      update_assignment_attributes(@assignment, :submission_types, "on_paper", false)
      expect(f("#content")).not_to contain_css(".submit_assignment_link")
    end

    it "validates no submission assignment type" do
      update_assignment_attributes(@assignment, :submission_types, nil, false)
      expect(f("#content")).not_to contain_css(".submit_assignment_link")
    end

    it "validates that website url submissions are allowed" do
      update_assignment_attributes(@assignment, :submission_types, "online_url")
      expect(f("#submission_url")).to be_displayed
    end

    it "validates that text entry submissions are allowed" do
      update_assignment_attributes(@assignment, :submission_types, "online_text_entry")
      expect(f(".submit_online_text_entry_option")).to be_displayed
    end

    it "allows an assignment with all 3 online submission types" do
      update_assignment_attributes(@assignment, :submission_types, "online_text_entry, online_url, online_upload")
      expect(f(".submit_online_text_entry_option")).to be_displayed
      expect(f(".submit_online_url_option")).to be_displayed
      expect(f(".submit_online_upload_option")).to be_displayed
    end

    it "validates an assignment created with the type of external tool", priority: "1" do
      allow(BasicLTI::Sourcedid).to receive(:encryption_secret) { "encryption-secret-5T14NjaTbcYjc4" }
      allow(BasicLTI::Sourcedid).to receive(:signing_secret) { "signing-secret-vp04BNqApwdwUYPUI" }
      t1 = factory_with_protected_attributes(@course.context_external_tools, url: "http://www.example.com/", shared_secret: "test123", consumer_key: "test123", name: "tool 1")
      external_tool_assignment = assignment_model(course: @course, title: "test2", submission_types: "external_tool")
      external_tool_assignment.create_external_tool_tag(url: t1.url)
      external_tool_assignment.external_tool_tag.update_attribute(:content_type, "ContextExternalTool")
      get "/courses/#{@course.id}/assignments/#{external_tool_assignment.id}"

      expect(f("[id^=tool_content_]")).to be_displayed
    end
  end
end
