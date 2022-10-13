# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/k5_dashboard_page"
require_relative "../pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"
require_relative "../../helpers/shared_examples_common"

shared_examples_for "k5 homeroom announcements" do
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include SharedExamplesCommon

  it "shows navigation buttons and no recent announcements text" do
    announcement_heading1 = "K5 Do this"
    announcement_content1 = "So happy to see all of you."
    announcement1 = new_announcement(@homeroom_course, announcement_heading1, announcement_content1)
    announcement1.update!(posted_at: 15.days.ago)

    get "/"
    wait_for_ajaximations

    keep_trying_for_attempt_times(attempts: 5, sleep_interval: 0.5) do
      expect(no_recent_announcements).to be_displayed
    end

    keep_trying_for_attempt_times(attempts: 5, sleep_interval: 0.5) do
      click_previous_announcement_button(0)
      expect(announcement_title(announcement_heading1)).to be_displayed
      expect(announcement_content_text(announcement_content1)).to be_displayed
    end
  end

  context "k5 single homeroom" do
    let(:current_announcement_title) { "CURRENT ANNOUNCEMENT" }
    let(:stale_announcement_title) { "STALE ANNOUNCEMENT" }
    let(:current_announcement_content) { "CURRENT CONTENT" }
    let(:stale_announcement_content) { "STALE CONTENT" }

    before :once do
      @announcement1 =
        new_announcement(@homeroom_course, current_announcement_title, current_announcement_content)
      @announcement2 =
        new_announcement(@homeroom_course, stale_announcement_title, stale_announcement_content)
      @announcement2.update(posted_at: 20.days.ago)
    end

    it "presents latest homeroom announcements" do
      get "/"

      expect(homeroom_course_title(@course_name)).to be_displayed
      expect(announcement_title(current_announcement_title)).to be_displayed
      expect(announcement_content_text(current_announcement_content)).to be_displayed
    end

    it "shows previous and next buttons when there are multiple non-stale announcements" do
      get "/"

      expect(previous_announcement_button[0]).to be_displayed
      expect(next_announcement_button[0]).to be_displayed
      expect(element_value_for_attr(next_announcement_button[0], "cursor")).to eq("not-allowed")
    end

    it "navigates among stale announcements" do
      announcement_heading = "Happy Monday!"
      announcement_content = "Get to work"
      another_old_announcement =
        new_announcement(@homeroom_course, announcement_heading, announcement_content)
      another_old_announcement.update!(posted_at: 90.days.ago)

      get "/"

      click_previous_announcement_button(0)
      click_previous_announcement_button(0)

      expect(announcement_title(announcement_heading)).to be_displayed
      expect(announcement_content_text(announcement_content)).to be_displayed
      expect(element_value_for_attr(next_announcement_button[0], "cursor")).to eq("pointer")

      click_next_announcement_button(0)

      expect(announcement_title(stale_announcement_title)).to be_displayed
      expect(announcement_content_text(stale_announcement_content)).to be_displayed
    end
  end

  context "announcement attachments" do
    before :once do
      attachment_model(uploaded_data: fixture_file_upload("example.pdf", "application/pdf"))
      @homeroom_course.announcements.create!(
        title: "Welcome to class",
        message: "Hello!",
        attachment: @attachment
      )
    end

    it "shows download button next to homeroom announcement attachment", custom_timeout: 30 do
      get "/"
      wait_for(method: nil, timeout: 20) { f("span.instructure_file_holder").displayed? }
      expect(f("a.file_download_btn")).to be_displayed
    end

    it "opens preview overlay when clicking on homeroom announcement attachment" do
      get "/"
      f("a.preview_in_overlay").click
      expect(f("iframe.ef-file-preview-frame")).to be_displayed
    end
  end
end

shared_examples_for "k5 homeroom announcements with multiple homerooms" do |context|
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include SharedExamplesCommon

  let(:second_homeroom_course_name) { "Second Homeroom" }
  let(:homeroom1_current_announcement_title) { "HR1 CURRENT ANNOUNCEMENT" }
  let(:homeroom1_stale_announcement_title) { "HR1 STALE ANNOUNCEMENT" }
  let(:homeroom2_current_announcement_title) { "HR2 CURRENT ANNOUNCEMENT" }
  let(:homeroom2_stale_announcement_title) { "HR2 STALE ANNOUNCEMENT" }

  before :once do
    case context
    when :student
      @our_student = @student
      course_with_student(
        active_all: true,
        user: @our_student,
        course_name: second_homeroom_course_name
      )
    when :teacher
      course_with_teacher(
        active_course: 1,
        active_enrollment: 1,
        user: @homeroom_teacher,
        course_name: second_homeroom_course_name
      )
    end
    @course.update!(homeroom_course: true)

    new_announcement(@homeroom_course, homeroom1_current_announcement_title, "Let's get to work!")
    hr1_stale_announcement =
      new_announcement(@homeroom_course, homeroom1_stale_announcement_title, "Let's get to work!")
    new_announcement(@course, homeroom2_current_announcement_title, "Let's get to work!")
    hr2_stale_announcement =
      new_announcement(@course, homeroom2_stale_announcement_title, "Let's get to work!")
    hr1_stale_announcement.update!(posted_at: 20.days.ago)
    hr2_stale_announcement.update!(posted_at: 20.days.ago)
  end

  before do
    case context
    when :student
      user_session @our_student
    when :teacher
      user_session @homeroom_teacher
    end
  end

  it "shows two different homeroom course announcements two homerooms" do
    get "/"

    expect(homeroom_course_title(@course_name)).to be_displayed
    expect(announcement_title(homeroom1_current_announcement_title)).to be_displayed
    expect(homeroom_course_title(second_homeroom_course_name)).to be_displayed
    expect(announcement_title(homeroom2_current_announcement_title)).to be_displayed
  end

  it "provides navigation buttons for both homerooms when there are old announcements" do
    get "/"

    expect(previous_announcement_button[0]).to be_displayed
    expect(next_announcement_button[0]).to be_displayed
    expect(element_value_for_attr(next_announcement_button[0], "cursor")).to eq("not-allowed")

    expect(previous_announcement_button[1]).to be_displayed
    expect(next_announcement_button[1]).to be_displayed
    expect(element_value_for_attr(next_announcement_button[1], "cursor")).to eq("not-allowed")
  end

  it "shows previous announcements when previous button clicked" do
    get "/"

    keep_trying_for_attempt_times(attempts: 10, sleep_interval: 0.5) do
      expect(announcement_title(homeroom1_current_announcement_title)).to be_displayed
    end

    keep_trying_for_attempt_times(attempts: 5, sleep_interval: 0.5) do
      click_previous_announcement_button(0)
      click_previous_announcement_button(1)
      expect(announcement_title(homeroom1_stale_announcement_title)).to be_displayed
      expect(announcement_title(homeroom2_stale_announcement_title)).to be_displayed
    end

    keep_trying_for_attempt_times(attempts: 5, sleep_interval: 0.5) do
      click_next_announcement_button(0)
      click_next_announcement_button(1)
      expect(announcement_title(homeroom1_current_announcement_title)).to be_displayed
      expect(announcement_title(homeroom2_current_announcement_title)).to be_displayed
    end
  end
end

shared_examples_for "K5 Subject Home Tab" do
  it "does not display old announcements on the Home tab" do
    announcement_heading = "Do science"
    announcement = new_announcement(@subject_course, announcement_heading, "it is fun!")

    announcement.posted_at = 15.days.ago
    announcement.save!

    get "/courses/#{@subject_course.id}"

    expect(announcement_title_exists?(announcement_heading)).to be_falsey
  end

  context "multiple subject announcements" do
    let(:subject_announcement1_title) { "Happy Monday!" }
    let(:subject_announcement1_content) { "We got this!" }
    let(:subject_announcement2_title) { "Happy Monday!" }
    let(:subject_announcement2_content) { "We got this!" }

    before :once do
      @announcement1 =
        new_announcement(
          @subject_course,
          subject_announcement1_title,
          subject_announcement1_content
        )
      @announcement2 =
        new_announcement(
          @subject_course,
          subject_announcement2_title,
          subject_announcement2_content
        )
      @announcement2.update(posted_at: 20.days.ago)
    end

    it "displays the latest announcement on the Home tab" do
      get "/courses/#{@subject_course.id}"

      expect(course_dashboard_title).to include_text(@subject_course_title)
      expect(announcement_title(subject_announcement1_title)).to be_displayed
      expect(announcement_content_text(subject_announcement2_title)).to be_displayed
    end

    it "opens up the announcement when announcement title is clicked" do
      get "/courses/#{@subject_course.id}"

      click_announcement_title(subject_announcement1_title)
      wait_for_ajaximations

      expect(driver.current_url).to include(
        "/courses/#{@subject_course.id}/discussion_topics/#{@announcement1.id}"
      )
    end

    it "shows the previous and next buttons when there are multiple announcements" do
      get "/courses/#{@subject_course.id}"

      expect(previous_announcement_button[0]).to be_displayed
      expect(next_announcement_button[0]).to be_displayed
      expect(element_value_for_attr(next_announcement_button[0], "cursor")).to eq("not-allowed")
    end

    it "navigates among current and stale announcements" do
      announcement_heading = "Happy Monday!"
      announcement_content = "Get to work"
      another_old_announcement =
        new_announcement(@subject_course, announcement_heading, announcement_content)
      another_old_announcement.update!(posted_at: 90.days.ago)

      get "/courses/#{@subject_course.id}"

      click_previous_announcement_button(0)
      click_previous_announcement_button(0)

      expect(announcement_title(announcement_heading)).to be_displayed
      expect(announcement_content_text(announcement_content)).to be_displayed
      expect(element_value_for_attr(next_announcement_button[0], "cursor")).to eq("pointer")

      click_next_announcement_button(0)

      expect(announcement_title(subject_announcement2_title)).to be_displayed
      expect(announcement_content_text(subject_announcement2_content)).to be_displayed
    end
  end
end
