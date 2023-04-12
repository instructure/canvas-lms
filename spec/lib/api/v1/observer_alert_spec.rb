# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../../../spec_helper"

class ObserverAlertApiHarness
  include Api::V1::ObserverAlert
  include ApplicationHelper

  def course_assignment_url(context_id, assignment)
    "/courses/#{context_id}/assignments/#{assignment.id}"
  end

  def course_discussion_topic_url(context_id, announcement)
    "/courses/#{context_id}/announcements/#{announcement.id}"
  end

  def course_url(course)
    "/courses/#{course.id}"
  end
end

describe "Api::V1::ObserverAlert" do
  subject(:api) { ObserverAlertApiHarness.new }

  describe "#observer_alert_json" do
    let(:user) { user_with_pseudonym }
    let(:session) { user_session(user) }

    it "returns json" do
      alert = observer_alert_model(observer: user)
      json = api.observer_alert_json(alert, user, session)
      expect(json["title"]).to eq("value for type")
      expect(json["alert_type"]).to eq("course_announcement")
      expect(json["workflow_state"]).to eq("unread")
      expect(json["user_id"]).to eq @student.id
      expect(json["observer_id"]).to eq @observer.id
      expect(json["observer_alert_threshold_id"]).to eq @observer_alert_threshold.id
      expect(json["action_date"]).to eq alert.action_date.in_time_zone
    end

    context "returns a correct html_url" do
      before :once do
        @course = course_model
        @course.offer!
      end

      it "for discussion_topic" do
        ann = Announcement.create!(context: @course, message: "Danger! Danger! Will Robinson")
        alert = observer_alert_model(observer: user, course: @course, active_all: true, alert_type: "course_announcement", context: ann)
        json = api.observer_alert_json(alert, user, session)
        expect(json["html_url"]).to eq api.course_discussion_topic_url(@course.id, ann)
      end

      it "for assignment" do
        asg = assignment_model(course: @course)
        alert = observer_alert_model(observer: user, course: @course, active_all: true, alert_type: "assignment_grade_high", context: asg)
        json = api.observer_alert_json(alert, user, session)
        expect(json["html_url"]).to eq api.course_assignment_url(@course.id, asg)
      end

      it "for course" do
        alert = observer_alert_model(observer: user, course: @course, active_all: true, alert_type: "course_grade_high", context: @course)
        json = api.observer_alert_json(alert, user, session)
        expect(json["html_url"]).to eq api.course_url(@course)
      end

      it "for assignment_missing" do
        submission = submission_model(course: @course)
        alert = observer_alert_model(student: @student, observer: user, course: @course, active_all: true, alert_type: "assignment_missing", context: submission)
        json = api.observer_alert_json(alert, user, session)
        expect(json["html_url"]).to eq api.course_assignment_url(@course.id, submission.assignment)
      end
    end

    context "returns a correct locked_for_user" do
      before :once do
        @course = course_model
        @course.offer!
      end

      it "for assignment" do
        asg = assignment_model(course: @course)
        alert = observer_alert_model(observer: user, course: @course, active_all: true, alert_type: "assignment_grade_high", context: asg)
        json = api.observer_alert_json(alert, user, session)
        expect(json["locked_for_user"]).to be false
      end

      it "for course" do
        alert = observer_alert_model(observer: user, course: @course, active_all: true, alert_type: "course_grade_high", context: @course)
        json = api.observer_alert_json(alert, user, session)
        expect(json["locked_for_user"]).to be false
      end

      it "for invisible course" do
        alert = observer_alert_model(student: @student, observer: user, course: @course, active_all: true, alert_type: "course_grade_high", context: @course)

        @course.destroy
        json = api.observer_alert_json(alert, user, session)
        expect(json["locked_for_user"]).to be true
      end

      it "for deleted assignment" do
        assignment = assignment_model(context: @course)
        alert = observer_alert_model(student: @student, observer: user, course: @course, active_all: true, alert_type: "assignment_grade_low", threshold: 70, context: assignment)

        assignment.destroy!
        json = api.observer_alert_json(alert, user, session)
        expect(json["locked_for_user"]).to be true
      end
    end
  end
end
