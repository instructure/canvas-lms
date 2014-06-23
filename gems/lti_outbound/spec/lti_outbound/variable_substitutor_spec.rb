#
# Copyright (C) 2014 Instructure, Inc.
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

require 'spec_helper'

describe LtiOutbound::VariableSubstitutor do
  let(:course) { LtiOutbound::LTICourse.new }
  subject { LtiOutbound::VariableSubstitutor.new(context: course) }

  describe "#substitute" do


    it "returns the value" do
      course.id = 1
      data_hash = {'canvas_course_id' => '$Canvas.course.id'}

      expect(subject.substitute!(data_hash)['canvas_course_id']).to eq 1
    end

    it "leaves the value unchanged for unkown keys" do
      data_hash = {'canvas_course_id' => '$Invalid.key'}
      expect(subject.substitute!(data_hash)['canvas_course_id']).to eq '$Invalid.key'
    end

    it "leaves the value unchanged for missing models" do
      data_hash = {'canvas_course_id' => '$Canvas.account.id'}
      expect(subject.substitute!(data_hash)['canvas_course_id']).to eq '$Canvas.account.id'
    end

    describe 'variable_substitutions' do
      let(:account) { double('account', id: 'account_id', name: 'account_name', sis_source_id: 'account_sis_source_id') }
      let(:assignment) { double('assignment', id: 'assignment_id', title: 'assignment_title', points_possible: 'assignment_points_possible') }
      let(:consumer_instance) { double('consumer_instance', id: 'consumer_instance_id', sis_source_id: 'consumer_instance_sis_source_id', domain: 'consumer_instance_domain') }
      let(:course) do
        course =  LtiOutbound::LTICourse.new
        course.id = 'course_id'
        course.sis_source_id =  'course_sis_source_id'
        course
      end
      let(:user) do
        double('user',
               id: 'user_id',
               sis_source_id: 'user_sis_source_id',
               login_id: 'user_login_id',
               enrollment_state: 'user_enrollment_state',
               concluded_role_types: 'user_concluded_role_types',
               last_name: 'user_last_name',
               name: 'user_name',
               first_name: 'user_first_name',
               timezone: 'user_time_zone'
        )
      end

      subject do
        LtiOutbound::VariableSubstitutor.new(
          account: account,
          assignment: assignment,
          consumer_instance: consumer_instance,
          context: course,
          user: user
        )
      end

      it 'substitute variables for all substitutions' do
        data_hash = {
          account_id: '$Canvas.account.id',
          account_name: '$Canvas.account.name',
          account_sis_source_id: '$Canvas.account.sisSourceId',
          assignment_id: '$Canvas.assignment.id',
          assignment_title: '$Canvas.assignment.title',
          assignment_points_possible: '$Canvas.assignment.pointsPossible',
          consumer_instance_id: '$Canvas.root_account.id',
          consumer_instance_sis_source_id: '$Canvas.root_account.sisSourceId',
          consumer_instance_domain: '$Canvas.api.domain',
          course_id: '$Canvas.course.id',
          course_sis_source_id: '$Canvas.course.sisSourceId',
          user_id: '$Canvas.user.id',
          user_sis_source_id: '$Canvas.user.sisSourceId',
          user_login_id: '$Canvas.user.loginId',
          user_enrollment_state: '$Canvas.enrollment.enrollmentState',
          user_concluded_role_types: '$Canvas.membership.concludedRoles',
          user_last_name: '$Person.name.family',
          user_name: '$Person.name.full',
          user_first_name: '$Person.name.given',
          user_time_zone: '$Person.address.timezone'
        }

        subject.substitute!(data_hash)
        data_hash.each{|k, v| expect(v).to eq k.to_s}
      end

    end

  end
end