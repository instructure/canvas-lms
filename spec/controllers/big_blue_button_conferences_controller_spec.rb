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

describe ConferencesController do
  before :once do
    # these specs need an enabled web conference plugin
    @plugin = PluginSetting.create!(name: "big_blue_button")
    @plugin.update_attribute(:settings, { domain: "bigbluebutton.test", secret: "secret", recording_enabled: true })
    course_with_teacher(active_all: true, user: user_with_pseudonym(active_all: true))
    @inactive_student = course_with_user("StudentEnrollment", course: @course, enrollment_state: "invited").user
    student_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
  end

  before do
    allow(BigBlueButtonConference).to receive_messages(send_request: { running: false }, get_auth_token: "abc123")
  end

  describe "GET 'recording'" do
    it "requires authorization" do
      @conference = @course.web_conferences.create!(conference_type: "BigBlueButton", duration: 60, user: @teacher)
      get "recording", params: { course_id: @course.id, conference_id: @conference.id, recording_id: "abc123-xyz" }
      assert_unauthorized
    end
  end

  describe "DELETE 'recording'" do
    it "requires authorization" do
      @conference = @course.web_conferences.create!(conference_type: "BigBlueButton", duration: 60, user: @teacher)
      delete "recording", params: { course_id: @course.id, conference_id: @conference.id, recording_id: "abc123-xyz" }
      assert_unauthorized
    end
  end
end
