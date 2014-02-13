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

describe LtiOutbound::LTIUser do
  it_behaves_like 'an LTI context'

  it_behaves_like 'it has a proc attribute setter and getter for', :avatar_url
  it_behaves_like 'it has a proc attribute setter and getter for', :email
  it_behaves_like 'it has a proc attribute setter and getter for', :first_name
  it_behaves_like 'it has a proc attribute setter and getter for', :last_name
  it_behaves_like 'it has a proc attribute setter and getter for', :login_id
  it_behaves_like 'it has a proc attribute setter and getter for', :current_roles
  it_behaves_like 'it has a proc attribute setter and getter for', :concluded_roles
  it_behaves_like 'it has a proc attribute setter and getter for', :currently_active_in_course

  it_behaves_like 'it provides variable mapping', '$Canvas.user.id', :id
  it_behaves_like 'it provides variable mapping', '$Canvas.user.loginId', :login_id
  it_behaves_like 'it provides variable mapping', '$Canvas.user.sisSourceId', :sis_source_id
  it_behaves_like 'it provides variable mapping', '$Canvas.enrollment.enrollmentState', :enrollment_state
  it_behaves_like 'it provides variable mapping', '$Canvas.membership.concludedRoles', :concluded_roles
  it_behaves_like 'it provides variable mapping', '$Person.name.full', :name
  it_behaves_like 'it provides variable mapping', '$Person.name.family', :last_name
  it_behaves_like 'it provides variable mapping', '$Person.name.given', :first_name
  it_behaves_like 'it provides variable mapping', '$Person.address.timezone', :timezone

  let(:teacher_role) { LtiOutbound::LTIRole::INSTRUCTOR }
  let(:learner_role) { LtiOutbound::LTIRole::LEARNER }

  describe '#current_role_types' do
    it 'provides a string representation of current roles' do
      subject.tap do |user|
        user.current_roles = [teacher_role, learner_role]
      end

      expect(subject.current_role_types).to eq("#{LtiOutbound::LTIRole::INSTRUCTOR},#{LtiOutbound::LTIRole::LEARNER}")
    end

    it 'defaults to NONE if no roles exist' do
      expect(subject.current_role_types).to eq(LtiOutbound::LTIRole::NONE)
    end

    it 'defaults to NONE if roles are empty' do
      subject.current_roles = []

      expect(subject.current_role_types).to eq(LtiOutbound::LTIRole::NONE)
    end
  end

  describe '#concluded_role_types' do
    it 'provides a string representation of concluded roles' do
      subject.tap do |user|
        user.concluded_roles = [teacher_role, learner_role]
      end

      expect(subject.concluded_role_types).to eq("#{LtiOutbound::LTIRole::INSTRUCTOR},#{LtiOutbound::LTIRole::LEARNER}")
    end

    it 'defaults if no roles exist' do
      expect(subject.concluded_role_types).to eq(LtiOutbound::LTIRole::NONE)
    end

    it 'defaults to NONE if roles are empty' do
      subject.concluded_roles = []

      expect(subject.current_role_types).to eq(LtiOutbound::LTIRole::NONE)
    end
  end

  describe 'constants' do
    it 'provides role state constants' do
      expect(LtiOutbound::LTIUser::ACTIVE_STATE).to eq 'active'
      expect(LtiOutbound::LTIUser::INACTIVE_STATE).to eq 'inactive'
    end
  end
  
  describe '#learner?' do
    it 'returns false when current roles includes learner role' do
      subject.current_roles = [teacher_role, learner_role]

      expect(subject.learner?).to eq true
    end

    it 'returns false when current roles do not include learner role' do
      subject.current_roles = [teacher_role]

      expect(subject.learner?).to eq false
    end
  end

  describe '#enrollment_state' do
    it "returns active if currently_active_in_course is true" do
      subject.currently_active_in_course = true
      expect(subject.enrollment_state).to eq LtiOutbound::LTIUser::ACTIVE_STATE
    end

    it "returns inactive if currently_active_in_course is false" do
      subject.currently_active_in_course = false
      expect(subject.enrollment_state).to eq LtiOutbound::LTIUser::INACTIVE_STATE
    end

    it "returns nil if currently_active_in_course is nil" do
      subject.currently_active_in_course = nil
      expect(subject.enrollment_state).to eq nil
    end
  end
end