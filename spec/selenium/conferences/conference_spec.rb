# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_relative "../helpers/conferences_common"
require_relative "../helpers/public_courses_context"

describe "Web conferences" do
  include_context "in-process server selenium tests"
  include ConferencesCommon
  include WebMock::API

  before(:once) do
    initialize_wimba_conference_plugin
    course_with_teacher(name: "Teacher Bob", active_all: true)
    course_with_ta(name: "TA Alice", course: @course, active_all: true)
    4.times do |i|
      course_with_student(name: "Student_#{i + 1}", course: @course, active_all: true)
    end
  end

  before do
    user_session(@teacher)
  end

  after do
    accept_alert if alert_present?
    close_extra_windows
  end

  it "disables unchangeable properties when conference has begun" do
    conf = create_wimba_conference
    conf.started_at = 1.hour.ago
    conf.end_at = 1.day.from_now
    conf.save!

    get conferences_index_page
    fj("li.conference a:contains('Settings')").click
    fj("a:contains('Edit')").click
    expect(f("span[data-testid='duration-input'] input")).to be_disabled
    expect(f("input[value='no_time_limit']")).to be_disabled
  end

  it "validates name length" do
    initial_conference_count = WebConference.count
    get conferences_index_page
    stub_request(:get, /wimba\.instructure\.com/)
    name_255_chars = "Y3298V7EQwLC8chKnXTz5IFARakIP0k2Yk0nLQ7owgidY6zDQnh9nCmH8z033TnJ1ssFwYtCkKwyhB7HkUN9ZF3u2s1shsj4vYqUlsEQmPljTGFBtO43pCh1QquQUnM2yCsiS5nnCRefjTK7jMwAiOXTZeyFvPk3tLzPAmOwf1Od6vtOB5nfXFSPVYyxSNcl85ySG8SlBoOULqF1IZV0BwE4TLthJV8Ab1h7xW0CbjHaJLMTQtnWK6ntTLxSNi4"
    error_message = "Name must not exceed 255 characters"
    f("button[title='New Conference']").click
    f("input[placeholder='Conference Name']").clear
    f("input[placeholder='Conference Name']").send_keys name_255_chars
    f("input[placeholder='Conference Name']").send_keys "a" # 256th char
    expect(fj("span:contains('#{error_message}')")).to be_present
    expect(f("button[data-testid='submit-button']")).not_to be_enabled

    # bring it back down to 255 chars
    f("input[placeholder='Conference Name']").send_keys :backspace
    expect(f("body")).not_to contain_jqcss("span:contains('#{error_message}')")
    expect(f("button[data-testid='submit-button']")).to be_enabled

    f("button[data-testid='submit-button']").click
    wait_for_ajaximations
    expect(WebConference.count).to be > initial_conference_count
  end

  it "validates duration length" do
    initial_conference_count = WebConference.count
    get conferences_index_page
    stub_request(:get, /wimba\.instructure\.com/)
    number_larger_than_8_digits = 999_999_990
    error_message = "Duration must be less than or equal to 99,999,999 minutes"
    f("button[title='New Conference']").click
    f("span[data-testid='duration-input'] input").clear
    f("span[data-testid='duration-input'] input").send_keys number_larger_than_8_digits
    expect(fj("span:contains('#{error_message}')")).to be_present
    expect(f("button[data-testid='submit-button']")).not_to be_enabled

    # bring it back down to 8 digits
    f("span[data-testid='duration-input'] input").send_keys :backspace
    expect(f("body")).not_to contain_jqcss("span:contains('#{error_message}')")
    expect(f("button[data-testid='submit-button']")).to be_enabled

    f("button[data-testid='submit-button']").click
    wait_for_ajaximations
    expect(WebConference.count).to be > initial_conference_count
  end

  it "invites specific course members" do
    get conferences_index_page
    stub_request(:get, /wimba\.instructure\.com/)
    f("button[title='New Conference']").click
    fj("label:contains('Invite all course members')").click
    f("[data-testid='address-input']").click
    wait_for_ajaximations
    f("[data-testid='user-#{@student.id}']").click
    fj("button:contains('Create')").click
    wait_for_ajaximations
    expect(WebConference.last.invitees.pluck(:id)).to eq [@student.id]
  end

  it "invites course members async" do
    Setting.set("max_invitees_sync_size", 5)

    get conferences_index_page
    stub_request(:get, /wimba\.instructure\.com/)
    f("button[title='New Conference']").click
    fj("button:contains('Create')").click
    wait_for_ajaximations
    run_jobs
    expect(WebConference.last.invitees.count).to eq 7
  end

  it "can exclude observers on creation" do
    my_observer = user_factory(name: "Cogsworth", active_all: true)
    @course.enroll_user(my_observer, "ObserverEnrollment", { associated_user_id: @student.id })
    get conferences_index_page
    stub_request(:get, /wimba\.instructure\.com/)
    f("button[title='New Conference']").click
    fj("label:contains('Remove all course observer members')").click
    fj("button:contains('Create')").click
    wait_for_ajaximations
    my_conf = WimbaConference.last
    expect(my_conf.invitees.pluck(:id)).to include(@ta.id)
    expect(my_conf.invitees.pluck(:id)).not_to include(my_observer.id)
  end
end
