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

require_relative '../api_spec_helper'

describe ObserverAlertsApiController, type: :request do
  include Api
  include Api::V1::ObserverAlert

  context '#alerts_by_student' do
    before :once do
      @course = course_model
      @assignment = assignment_model(context: @course)

      observer_alert_model(course: @course, alert_type: 'assignment_grade_high', context: @assignment)
      @oat = @observer_alert_threshold

      observer_alert_model(course: @course, observer: @observer, observee: @observee, uol: @observation_link,
        alert_type: 'assignment_grade_low', context: @assignment)
      observer_alert_model(course: @course, observer: @observer, observee: @observee, uol: @observation_link,
        alert_type: 'course_grade_high', context: @course)

      @path = "/api/v1/users/#{@observer.id}/observer_alerts/#{@observee.id}"
      @params = {user_id: @observer.to_param, student_id: @observee.to_param,
        controller: 'observer_alerts_api', action: 'alerts_by_student', format: 'json'}
    end

    it 'returns correct attributes' do
      json = api_call_as_user(@observer, :get, @path, @params)

      selected = json.select { |alert| alert['alert_type'] == 'assignment_grade_high'}
      expect(selected.length).to eq 1

      alert = selected.first

      expect(alert['title']).to eq('value for type')
      expect(alert['alert_type']).to eq('assignment_grade_high')
      expect(alert['workflow_state']).to eq('active')
      expect(alert['html_url']).to eq course_assignment_url(@course, @assignment)
      expect(alert['user_observation_link_id']).to eq @observation_link.id
      expect(alert['observer_alert_threshold_id']).to eq @oat.id
    end

    it 'returns all alerts for student' do
      json = api_call_as_user(@observer, :get, @path, @params)
      expect(json.length).to eq 3
    end

    it 'doesnt return alerts for other students' do
      user = user_model
      uol = UserObservationLink.create(observer_id: @observer.id, user_id: user)
      asg = assignment_model(context: @course)
      observer_alert_model(uol: uol, alert_type: 'assignment_grade_high', context: asg)
      json = api_call_as_user(@observer, :get, @path, @params)
      expect(json.length).to eq 3
    end

    it 'errors without valid user_observation_link' do
      user = user_model
      path = "/api/v1/users/#{@observer.id}/observer_alerts/#{user.id}"
      params = {user_id: @observer.to_param, student_id: user.to_param,
        controller: 'observer_alerts_api', action: 'alerts_by_student', format: 'json'}

      api_call_as_user(@observer, :get, path, params)
      expect(response.code).to eq "401"
    end
  end

  describe 'alerts_count' do
    before :once do
      @course = course_model
      @assignment = assignment_model(context: @course)

      observer_alert_model(course: @course, alert_type: 'assignment_grade_high', context: @assignment, workflow_state: 'unread')
      @observee_student = @observee
      observer_alert_model(course: @course, alert_type: 'assignment_grade_high', context: @assignment, workflow_state: 'unread', observer: @observer)
      observer_alert_model(course: @course, alert_type: 'assignment_grade_low', context: @assignment, workflow_state: 'read', observer: @observer)
    end

    it 'only returns the number of unread alerts for the user' do
      path = "/api/v1/users/self/observer_alerts/unread_count"
      params = {user_id: 'self', controller: 'observer_alerts_api', action: 'alerts_count', format: 'json'}
      json = api_call_as_user(@observer, :get, path, params)
      expect(json['unread_count']).to eq 2
    end

    it 'will only return the unread count for the specific student id provided' do
      path = "/api/v1/users/self/observer_alerts/unread_count?student_id=#{@observee_student.id}"
      params = {user_id: 'self', student_id: @observee_student.to_param, controller: 'observer_alerts_api',
                action: 'alerts_count', format: 'json'}

      json = api_call_as_user(@observer, :get, path, params)
      expect(json['unread_count']).to eq 1
    end
  end

end