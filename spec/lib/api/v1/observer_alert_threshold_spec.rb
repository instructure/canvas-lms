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

require_relative '../../../spec_helper.rb'

class ObserverAlertThresholdApiHarness
  include Api::V1::ObserverAlertThreshold

  def value_to_boolean(value)
    Canvas::Plugin.value_to_boolean(value)
  end

  def session
    Object.new
  end
end

describe "Api::V1::ObserverAlertThreshold" do
  subject(:api) { ObserverAlertThresholdApiHarness.new }

  let(:observer_alert_threshold) { observer_alert_threshold_model(active_all: true) }

  describe "#observer_alert_threshold_json" do
    let(:user) { user_model }
    let(:session) { Object.new }

    it "returns json" do
      json = api.observer_alert_threshold_json(observer_alert_threshold, user, session)
      expect(json['alert_type']).to eq('course_announcement')
      expect(json['workflow_state']).to eq('active')
      expect(json['user_id']).to eq @student.id
      expect(json['observer_id']).to eq @observer.id
    end
  end
end
