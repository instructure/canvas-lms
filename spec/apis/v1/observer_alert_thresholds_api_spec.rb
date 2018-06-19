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

describe ObserverAlertThresholdsApiController, type: :request do
  include Api
  include Api::V1::ObserverAlertThreshold

  context '#index' do
    before :once do
      observer_alert_threshold_model(active_all: true, alert_type: 'missing_assignment')
      @path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds?student_id=#{@observee.id}"
      @params = {user_id: @observer.to_param, student_id: @observee.to_param,
        controller: 'observer_alert_thresholds_api', action: 'index', format: 'json'}
    end

    describe 'with student_id' do
      it 'returns the thresholds' do
        json = api_call_as_user(@observer, :get, @path, @params)
        expect(json.length).to eq 1
        expect(json[0]['user_observation_link_id']).to eq @observation_link.id
        expect(json[0]['alert_type']).to eq 'missing_assignment'
      end

      it 'only returns active thresholds' do
        to_destroy = @observation_link.observer_alert_thresholds.create(alert_type: 'assignment_grade_low')
        to_destroy.destroy!

        json = api_call_as_user(@observer, :get, @path, @params)
        expect(json.length).to eq 1

        thresholds = @observation_link.observer_alert_thresholds.reload
        expect(thresholds.count).to eq 2
      end

      it 'errors without proper user_observation_link' do
        user = user_model
        path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds?student_id=#{user.id}"
        params = {user_id: @observer.to_param, student_id: user.to_param,
          controller: 'observer_alert_thresholds_api', action: 'index', format: 'json'}

        api_call_as_user(@observer, :get, path, params)
        expect(response.code).to eq "401"
      end
    end

    describe 'without student_id' do
      it 'returns the thresholds' do
        link = UserObservationLink.create(observer_id: @observer, user_id: user_model)
        link.observer_alert_thresholds.create(alert_type: 'assignment_grade_high')

        path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds"
        params = {user_id: @observer.to_param, controller: 'observer_alert_thresholds_api',
          action: 'index', format: 'json'}

        json = api_call_as_user(@observer, :get, path, params)
        expect(json.length).to eq 2
      end

      it 'errors without proper user_observation_link' do
        user = user_model
        path = "/api/v1/users/#{user.id}/observer_alert_thresholds"
        params = {user_id: user.to_param, controller: 'observer_alert_thresholds_api',
          action: 'index', format: 'json'}

        api_call_as_user(user, :get, path, params)
        expect(response.code).to eq "401"
      end
    end
  end

  context '#show' do
    before :once do
      observer_alert_threshold_model(active_all: true, alert_type: 'missing_assignment')
      @path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      @params = {user_id: @observer.to_param, observer_alert_threshold_id: @observer_alert_threshold.to_param,
        controller: 'observer_alert_thresholds_api', action: 'show', format: 'json'}
    end

    it 'returns the threshold' do
      json = api_call_as_user(@observer, :get, @path, @params)
      expect(json['id']).to eq @observer_alert_threshold.id
      expect(json['user_observation_link_id']).to eq @observation_link.id
      expect(json['alert_type']).to eq 'missing_assignment'
    end

    it 'errors without proper user_observation_link' do
      user = user_model
      path = "/api/v1/users/#{user.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      params = {user_id: user.to_param, observer_alert_threshold_id: @observer_alert_threshold.to_param,
        controller: 'observer_alert_thresholds_api', action: 'show', format: 'json'}

      api_call_as_user(user, :get, path, params)
      expect(response.code).to eq "401"
    end
  end

  context '#create' do
    before :once do
      @observer = user_model
      @observee = user_model
      @uol = UserObservationLink.create(observer_id: @observer, user_id: @observee)
      @path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds"
    end

    it 'creates the threshold' do
      create_params = {alert_type: 'assignment_grade_high', threshold: "88"}
      params = {user_id: @observer.to_param, student_id: @uol.user_id, observer_alert_threshold: create_params,
        controller: 'observer_alert_thresholds_api', action: 'create', format: 'json'}
      json = api_call_as_user(@observer, :post, @path, params)
      expect(json['alert_type']).to eq 'assignment_grade_high'
      expect(json['user_observation_link_id']).to eq @uol.id
      expect(json['threshold']).to eq "88"
    end

    it 'errors with bad student_id' do
      create_params = {alert_type: 'assignment_grade_high', threshold: "88"}
      params = {user_id: @observer.to_param, student_id: @uol.user_id + 100, observer_alert_threshold: create_params,
        controller: 'observer_alert_thresholds_api', action: 'create', format: 'json'}
      api_call_as_user(@observer, :post, @path, params)
      expect(response.code).to eq "401"
    end

    it 'errors if user_observation_link doesnt belong to user' do
      user = user_model
      path = "/api/v1/users/#{user.id}/observer_alert_thresholds"
      create_params = {alert_type: 'assignment_grade_high', threshold: "88"}
      params = {user_id: user.to_param, student_id: @uol.user_id, observer_alert_threshold: create_params,
        controller: 'observer_alert_thresholds_api', action: 'create', format: 'json'}
      api_call_as_user(user, :post, path, params)
      expect(response.code).to eq "401"
    end

    it 'errors without required params' do
      create_params = {threshold: "88"}
      params = {user_id: @observer.to_param, student_id: @uol.user_id, observer_alert_threshold: create_params,
        controller: 'observer_alert_thresholds_api', action: 'create', format: 'json'}
      api_call_as_user(@observer, :post, @path, params)
      expect(response.code).to eq "400"
    end

    it 'ignores improper params' do
      create_params = {something_sneaky: 'sneaky!', alert_type: 'assignment_grade_high', threshold: "88"}
      params = {user_id: @observer.to_param, student_id: @uol.user_id, observer_alert_threshold: create_params,
        controller: 'observer_alert_thresholds_api', action: 'create', format: 'json'}
      json = api_call_as_user(@observer, :post, @path, params)
      expect(response.code).to eq "200"
      expect(json['something_sneaky']).to eq nil
    end
  end

  context '#update' do
    before :once do
      observer_alert_threshold_model(active_all: true, alert_type: 'assignment_grade_low', threshold: "88")
      @path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      @params = {user_id: @observer.to_param, observer_alert_threshold_id: @observer_alert_threshold.to_param,
        controller: 'observer_alert_thresholds_api', action: 'update', format: 'json'}
    end

    it 'updates the threshold' do
      update_params = {threshold: "50", alert_type: "assignment_missing",
        user_observation_link_id: @observation_link.id + 100}
      params = @params.merge({observer_alert_threshold: update_params})
      json = api_call_as_user(@observer, :put, @path, params)
      expect(json['alert_type']).to eq 'assignment_grade_low'
      expect(json['threshold']).to eq "50"
      expect(json['user_observation_link_id']).to eq @observation_link.id
    end

    it 'errors without proper user_observation_link' do
      user = user_model
      path = "/api/v1/users/#{user.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      params = @params.merge({user_id: user.to_param, observer_alert_threshold: {threshold: "50"}})

      api_call_as_user(user, :put, path, params)
      expect(response.code).to eq "401"
    end
  end

  context '#destroy' do
    before :once do
      observer_alert_threshold_model(active_all: true, alert_type: 'assignment_grade_low', threshold: "88")
      @path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      @params = {user_id: @observer.to_param, observer_alert_threshold_id: @observer_alert_threshold.to_param,
        controller: 'observer_alert_thresholds_api', action: 'destroy', format: 'json'}
    end

    it 'destroys the threshold' do
      json = api_call_as_user(@observer, :delete, @path, @params)
      expect(json['id']).to eq @observer_alert_threshold.id

      thresholds = @observation_link.observer_alert_thresholds.active.reload
      expect(thresholds.count).to eq 0
    end

    it 'errors without proper user_observation_link' do
      user = user_model
      path = "/api/v1/users/#{user.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      params = @params.merge({user_id: user.to_param})

      api_call_as_user(user, :delete, path, params)
      expect(response.code).to eq "401"
    end
  end
end