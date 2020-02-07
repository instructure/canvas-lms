#
# Copyright (C) 2020 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe NotificationPreferenceOverridesController, type: :request do
  before :once do
    teacher_in_course(user: user_with_pseudonym(active_all: true), active_course: true, active_enrollment: true)
    @course.root_account.enable_feature!(:mute_notifications_by_course)
    @user.communication_channels.create!(path: 'two@example.com', path_type: 'email') { |cc| cc.workflow_state = 'active' }
  end

  let(:prefix){ "/api/v1/users/self/courses/#{@course.id}/notifications_enabled" }
  let(:params){ { course_id: @course.to_param, controller: 'notification_preference_overrides', format: 'json' } }

  describe "enabled_for_context" do
    it "should show status for context" do
      np = NotificationPolicyOverride.create!(communication_channel: @cc, context: @course)
      json = api_call(:get, prefix, params.merge(action: 'enabled_for_context'))
      expect(json['enabled']).to be_truthy
      np.workflow_state = 'disabled'
      np.save!
      json = api_call(:get, prefix, params.merge(action: 'enabled_for_context'))
      expect(json['enabled']).to be_falsey
    end

    it 'should default to enabled when there is no override' do
      json = api_call(:get, prefix, params.merge(action: 'enabled_for_context'))
      expect(json['enabled']).to be_truthy
    end
  end

  describe 'enable' do
    let(:prefix){ "/api/v1/users/self/courses/#{@course.id}/enable_notifications" }

    it "should create override when record does not exist" do
      json = api_call(:put, prefix + "?enable=true", params.merge(action: 'enable', enable: true))
      expect(json['enabled']).to be_truthy
    end

    it 'should update when a record already exists' do
      np = NotificationPolicyOverride.create!(communication_channel: @cc, context: @course)
      json = api_call(:put, prefix + "?enable=false", params.merge(action: 'enable', enable: false))
      expect(json['enabled']).to be_falsey
      expect(np.reload.workflow_state).to eq 'disabled'
      expect(np.updated_at).to_not equal np.created_at
    end
  end
end
