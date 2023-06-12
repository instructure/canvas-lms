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

require_relative "../api_spec_helper"

describe ObserverAlertThresholdsApiController, type: :request do
  include Api
  include Api::V1::ObserverAlertThreshold

  describe "#index" do
    before :once do
      observer_alert_threshold_model(alert_type: "assignment_missing")
      @path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds?student_id=#{@student.id}"
      @params = { user_id: @observer.to_param,
                  student_id: @student.to_param,
                  controller: "observer_alert_thresholds_api",
                  action: "index",
                  format: "json" }
    end

    context "with student_id" do
      it "returns the thresholds" do
        json = api_call_as_user(@observer, :get, @path, @params)
        expect(json.length).to eq 1
        expect(json[0]["user_id"]).to eq @student.id
        expect(json[0]["observer_id"]).to eq @observer.id
        expect(json[0]["alert_type"]).to eq "assignment_missing"
      end

      it "only returns active thresholds" do
        to_destroy = observer_alert_threshold_model(observer: @observer,
                                                    student: @student,
                                                    alert_type: "assignment_grade_low",
                                                    threshold: 50)
        to_destroy.destroy!

        json = api_call_as_user(@observer, :get, @path, @params)
        expect(json.length).to eq 1

        count = ObserverAlertThreshold.where(observer: @observer, student: @student).count
        expect(count).to eq 2
      end

      it "returns an empty array if there arent any thresholds" do
        observer = user_model
        student = user_model
        add_linked_observer(student, observer)
        path = "/api/v1/users/#{observer.id}/observer_alert_thresholds?student_id=#{student.id}"
        params = { user_id: observer.to_param,
                   student_id: student.to_param,
                   controller: "observer_alert_thresholds_api",
                   action: "index",
                   format: "json" }

        json = api_call_as_user(observer, :get, path, params)
        expect(json.length).to eq 0
      end

      it "returns an empty array if users are no longer linked" do
        observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
        observer_alert_threshold_model(observer:,
                                       student: @student,
                                       alert_type: "course_grade_high",
                                       threshold: 90)
        observer.enrollments.active.map(&:destroy)
        @observation_link.destroy
        path = "/api/v1/users/#{observer.id}/observer_alert_thresholds?student_id=#{@student.id}"
        params = { user_id: observer.to_param,
                   student_id: @student.to_param,
                   controller: "observer_alert_thresholds_api",
                   action: "index",
                   format: "json" }

        json = api_call_as_user(observer, :get, path, params)
        expect(json.length).to eq 0
      end
    end

    context "without student_id" do
      it "returns the thresholds" do
        observer_alert_threshold_model(observer: @observer,
                                       student: @student,
                                       alert_type: "assignment_grade_high",
                                       threshold: 90)

        path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds"
        params = { user_id: @observer.to_param,
                   controller: "observer_alert_thresholds_api",
                   action: "index",
                   format: "json" }

        json = api_call_as_user(@observer, :get, path, params)
        expect(json.length).to eq 2
      end

      it "returns an empty array if there arent any thresholds" do
        observer = user_model
        student = user_model
        add_linked_observer(student, observer)
        path = "/api/v1/users/#{observer.id}/observer_alert_thresholds"
        params = { user_id: observer.to_param, controller: "observer_alert_thresholds_api", action: "index", format: "json" }

        json = api_call_as_user(observer, :get, path, params)
        expect(json.length).to eq 0
      end

      it "returns an empty array if users are no longer linked" do
        observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
        observer_alert_threshold_model(observer:,
                                       student: @student,
                                       alert_type: "course_grade_high",
                                       threshold: 90)
        observer.enrollments.active.map(&:destroy)
        @observation_link.destroy
        path = "/api/v1/users/#{observer.id}/observer_alert_thresholds"
        params = { user_id: observer.to_param, controller: "observer_alert_thresholds_api", action: "index", format: "json" }

        json = api_call_as_user(observer, :get, path, params)
        expect(json.length).to eq 0
      end
    end
  end

  describe "#show" do
    before :once do
      observer_alert_threshold_model(alert_type: "assignment_missing")
      @path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      @params = { user_id: @observer.to_param,
                  observer_alert_threshold_id: @observer_alert_threshold.to_param,
                  controller: "observer_alert_thresholds_api",
                  action: "show",
                  format: "json" }
    end

    it "returns the threshold" do
      json = api_call_as_user(@observer, :get, @path, @params)
      expect(json["id"]).to eq @observer_alert_threshold.id
      expect(json["user_id"]).to eq @student.id
      expect(json["observer_id"]).to eq @observer.id
      expect(json["alert_type"]).to eq "assignment_missing"
    end

    it "errors if users are not linked" do
      user = user_model
      path = "/api/v1/users/#{user.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      params = { user_id: user.to_param,
                 observer_alert_threshold_id: @observer_alert_threshold.to_param,
                 controller: "observer_alert_thresholds_api",
                 action: "show",
                 format: "json" }

      api_call_as_user(user, :get, path, params)
      expect(response).to have_http_status :unauthorized
    end
  end

  describe "#create" do
    before :once do
      @observer = user_model
      @student = user_model
      add_linked_observer(@student, @observer)
      @path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds"
    end

    it "creates the threshold" do
      create_params = { alert_type: "assignment_grade_high", threshold: "88", user_id: @student.to_param }
      params = { user_id: @observer.to_param,
                 observer_alert_threshold: create_params,
                 controller: "observer_alert_thresholds_api",
                 action: "create",
                 format: "json" }
      json = api_call_as_user(@observer, :post, @path, params)
      expect(json["alert_type"]).to eq "assignment_grade_high"
      expect(json["user_id"]).to eq @student.id
      expect(json["observer_id"]).to eq @observer.id
      expect(json["threshold"]).to eq "88"
    end

    it "errors with bad user_id" do
      create_params = { alert_type: "assignment_grade_high", threshold: "88", observer_id: @observer.to_param, user_id: @student.id + 100 }
      params = { user_id: @observer.to_param,
                 observer_alert_threshold: create_params,
                 controller: "observer_alert_thresholds_api",
                 action: "create",
                 format: "json" }
      api_call_as_user(@observer, :post, @path, params)
      expect(response).to have_http_status :bad_request
    end

    it "errors if users are not linked" do
      user = user_model
      path = "/api/v1/users/#{user.id}/observer_alert_thresholds"
      create_params = { alert_type: "assignment_grade_high", threshold: "88", observer_id: user.to_param, user_id: @student.to_param }
      params = { user_id: user.to_param,
                 observer_alert_threshold: create_params,
                 controller: "observer_alert_thresholds_api",
                 action: "create",
                 format: "json" }
      api_call_as_user(user, :post, path, params)
      expect(response).to have_http_status :bad_request
    end

    it "errors without required params" do
      create_params = { threshold: "88", observer_id: @observer.to_param, user_id: @student.to_param }
      params = { user_id: @observer.to_param,
                 observer_alert_threshold: create_params,
                 controller: "observer_alert_thresholds_api",
                 action: "create",
                 format: "json" }
      api_call_as_user(@observer, :post, @path, params)
      expect(response).to have_http_status :bad_request
    end

    it "ignores improper params" do
      create_params = { something_sneaky: "sneaky!",
                        alert_type: "assignment_grade_high",
                        threshold: "88",
                        observer_id: @observer.to_param,
                        user_id: @student.to_param }
      params = { user_id: @observer.to_param,
                 observer_alert_threshold: create_params,
                 controller: "observer_alert_thresholds_api",
                 action: "create",
                 format: "json" }
      json = api_call_as_user(@observer, :post, @path, params)
      expect(response).to have_http_status :ok
      expect(json["something_sneaky"]).to be_nil
    end

    it "updates if threshold already exists" do
      observer_alert_threshold_model(observer: @observer, student: @student, alert_type: "assignment_grade_low", threshold: "50")
      create_params = { alert_type: "assignment_grade_low", threshold: "65", observer_id: @observer.to_param, user_id: @student.to_param }
      params = { user_id: @observer.to_param,
                 observer_alert_threshold: create_params,
                 controller: "observer_alert_thresholds_api",
                 action: "create",
                 format: "json" }
      json = api_call_as_user(@observer, :post, @path, params)
      expect(json["id"]).to eq @observer_alert_threshold.id
      expect(json["threshold"]).to eq "65"
      expect(ObserverAlertThreshold.active.where(observer: @observer, student: @student, alert_type: "assignment_grade_low").count).to eq 1
    end

    it "updates a deleted threshold of that alert_type" do
      observer_alert_threshold_model(alert_type: "assignment_grade_high", threshold: "90", observer: @observer, student: @student)
      @observer_alert_threshold.destroy

      create_params = { alert_type: "assignment_grade_high", threshold: "85", observer_id: @observer.to_param, user_id: @student.to_param }
      params = { user_id: @observer.to_param,
                 observer_alert_threshold: create_params,
                 controller: "observer_alert_thresholds_api",
                 action: "create",
                 format: "json" }
      json = api_call_as_user(@observer, :post, @path, params)
      expect(json["id"]).to eq @observer_alert_threshold.id
      expect(json["threshold"]).to eq "85"
    end
  end

  describe "#update" do
    before :once do
      observer_alert_threshold_model(alert_type: "assignment_grade_low", threshold: "88")
      @path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      @params = { user_id: @observer.to_param,
                  observer_alert_threshold_id: @observer_alert_threshold.to_param,
                  controller: "observer_alert_thresholds_api",
                  action: "update",
                  format: "json" }
    end

    it "updates the threshold" do
      update_params = { threshold: "50", alert_type: "assignment_missing" }
      params = @params.merge(update_params)
      json = api_call_as_user(@observer, :put, @path, params)
      expect(json["alert_type"]).to eq "assignment_grade_low"
      expect(json["threshold"]).to eq "50"
      expect(json["user_id"]).to eq @student.id
      expect(json["observer_id"]).to eq @observer.id
    end

    it "errors if users are not linked" do
      user = user_model
      path = "/api/v1/users/#{user.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      params = @params.merge({ user_id: user.to_param, threshold: "50" })

      api_call_as_user(user, :put, path, params)
      expect(response).to have_http_status :unauthorized
    end
  end

  describe "#destroy" do
    before :once do
      observer_alert_threshold_model(alert_type: "assignment_grade_low", threshold: "88")
      @path = "/api/v1/users/#{@observer.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      @params = { user_id: @observer.to_param,
                  observer_alert_threshold_id: @observer_alert_threshold.to_param,
                  controller: "observer_alert_thresholds_api",
                  action: "destroy",
                  format: "json" }
    end

    it "destroys the threshold" do
      json = api_call_as_user(@observer, :delete, @path, @params)
      expect(json["id"]).to eq @observer_alert_threshold.id

      count = ObserverAlertThreshold.active.where(observer: @observer, student: @student).count
      expect(count).to eq 0
    end

    it "errors if users are not linked" do
      user = user_model
      path = "/api/v1/users/#{user.id}/observer_alert_thresholds/#{@observer_alert_threshold.id}"
      params = @params.merge({ user_id: user.to_param })

      api_call_as_user(user, :delete, path, params)
      expect(response).to have_http_status :unauthorized
    end
  end
end
