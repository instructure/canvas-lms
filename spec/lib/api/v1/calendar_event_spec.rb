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

  def api_user_content(description, context)
    "api_user_content(#{description}, #{context.id}"
  end

  def api_conference_json(conference, user, _)
    "api_conference_json(#{conference.type}, #{user.id})"
  end

  def api_v1_calendar_event_url(event)
    "api_v1_calendar_event_url(#{event.id})"
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
end
