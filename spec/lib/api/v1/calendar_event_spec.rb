# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe Api::V1::CalendarEvent do
  include Api::V1::CalendarEvent

  before(:once) do
    %w[big_blue_button wimba].each do |name|
      plugin = PluginSetting.create!(name:)
      plugin.update_attribute(:settings, { key: "value" })
    end
  end

  let_once(:course) { course_model }

  def conference(context:, user: @user, type: "BigBlueButton")
    WebConference.create!(context:, user:, conference_type: type)
  end

  # Splat signature avoids ArgumentError since the real api_user_content
  # (lib/api.rb) accepts multiple positional and keyword arguments.
  def api_user_content(description, context, *_args, **_kwargs)
    "api_user_content(#{description}, #{context.id})"
  end

  def api_conference_json(conference, user, _)
    "api_conference_json(#{conference.type}, #{user.id})"
  end

  def api_v1_calendar_event_url(event)
    event_id = event.respond_to?(:id) ? event.id : event
    "api_v1_calendar_event_url(#{event_id})"
  end

  def calendar_url_for(event, _)
    "calendar_url_for(#{event.id})"
  end

  it "includes web conference in json" do
    event = course.calendar_events.create! title: "Foo", web_conference: conference(context: course)

    json = event_json(event, @user, @session, { include: ["web_conference"] })

    expect(json["web_conference"]).to be_present
  end

  it "excludes web conference in json if plugin is disabled" do
    event = course.calendar_events.create! title: "Foo", web_conference: conference(context: course)

    ps = PluginSetting.where("name = 'big_blue_button'").first
    ps.disabled = true
    ps.save!

    json = event_json(event, @user, @session, { include: ["web_conference"] })
    expect(json["web_conference"]).not_to be_present
  end

  it "does not include the CourseSection name if already present on the event" do
    section = course.course_sections.create!(name: "Section 1")
    event = section.calendar_events.create!(title: "Test")
    json = event_json(event, @user, @session, {})
    expect(json["title"]).to eq("Test (#{section.name})")
    event.update(title: "Test (#{section.name})")
    json = event_json(event, @user, @session, {})
    expect(json["title"]).to eq("Test (#{section.name})")
  end

  describe "assignment_event_json peer review sub assignment" do
    include Rails.application.routes.url_helpers

    def default_url_options
      { host: "localhost" }
    end

    let(:assignment) do
      course.assignments.create!(
        title: "Test Assignment",
        peer_reviews: true,
        submission_types: "online_text_entry",
        due_at: 1.week.from_now
      )
    end

    let(:base_assignment_hash) { { "html_url" => "http://localhost/test" } }

    before do
      allow(self).to receive(:assignment_json).and_return(base_assignment_hash.dup)
    end

    context "when peer_review_allocation_and_grading is enabled" do
      before do
        course.enable_feature!(:peer_review_allocation_and_grading)
      end

      it "includes peer_review_sub_assignment_enabled as true when peer review sub assignment exists" do
        peer_review_model(parent_assignment: assignment)
        assignment.reload

        json = assignment_event_json(assignment, @user, @session)
        expect(json["assignment"]["peer_review_sub_assignment_enabled"]).to be true
      end

      it "includes peer_review_sub_assignment_enabled as false when peer review sub assignment does not exist" do
        json = assignment_event_json(assignment, @user, @session)
        expect(json["assignment"]["peer_review_sub_assignment_enabled"]).to be false
      end

      it "includes peer_review_sub_assignment_enabled on the assignment payload when an override is applied" do
        peer_review_model(parent_assignment: assignment)
        override = assignment_override_model(assignment:)
        overridden = AssignmentOverrideApplicator.assignment_with_overrides(assignment, [override])
        allow(self).to receive(:assignment_override_json).and_return({ "id" => override.id })

        json = assignment_event_json(overridden, @user, @session)

        expect(json["assignment_overrides"]).to be_present
        expect(json["assignment"]["peer_review_sub_assignment_enabled"]).to be true
      end
    end

    context "when peer_review_allocation_and_grading is disabled" do
      it "does not include peer_review_sub_assignment_enabled" do
        json = assignment_event_json(assignment, @user, @session)
        expect(json["assignment"]).not_to have_key("peer_review_sub_assignment_enabled")
      end

      it "does not include peer_review_sub_assignment_enabled even when a peer review sub assignment exists" do
        peer_review_model(parent_assignment: assignment)
        course.disable_feature!(:peer_review_allocation_and_grading)
        assignment.reload

        json = assignment_event_json(assignment, @user, @session)
        expect(json["assignment"]).not_to have_key("peer_review_sub_assignment_enabled")
      end
    end
  end
end
