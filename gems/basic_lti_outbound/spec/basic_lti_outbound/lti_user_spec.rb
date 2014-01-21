#
# Copyright (C) 2011 Instructure, Inc.
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

require "spec_helper"

describe BasicLtiOutbound::LTIUser do
  it_behaves_like "an LTI context"

  it_behaves_like "it has an attribute setter and getter for", :avatar_url
  it_behaves_like "it has an attribute setter and getter for", :email
  it_behaves_like "it has an attribute setter and getter for", :first_name
  it_behaves_like "it has an attribute setter and getter for", :last_name
  it_behaves_like "it has an attribute setter and getter for", :name
  it_behaves_like "it has an attribute setter and getter for", :login_id
  it_behaves_like "it has an attribute setter and getter for", :current_enrollments
  it_behaves_like "it has an attribute setter and getter for", :concluded_enrollments
  it_behaves_like "it has an attribute setter and getter for", :sis_user_id

  it_behaves_like "it provides variable mapping", ".login_id", :login_id
  it_behaves_like "it provides variable mapping", ".enrollment_state", :enrollment_state
  it_behaves_like "it provides variable mapping", ".concluded_roles", :concluded_roles
  it_behaves_like "it provides variable mapping", ".full", :full_name
  it_behaves_like "it provides variable mapping", ".family", :family_name
  it_behaves_like "it provides variable mapping", ".given", :given_name
  it_behaves_like "it provides variable mapping", ".timezone", :timezone

  let(:teacher_role_active) do
    BasicLtiOutbound::LTIRole.new.tap do |role|
      role.type = BasicLtiOutbound::LTIRole::INSTRUCTOR
      role.state = :active
    end
  end

  let(:teacher_role_inactive) do
    BasicLtiOutbound::LTIRole.new.tap do |role|
      role.type = BasicLtiOutbound::LTIRole::INSTRUCTOR
      role.state = :inactive
    end
  end

  let(:learner_role_active) do
    BasicLtiOutbound::LTIRole.new.tap do |role|
      role.type = BasicLtiOutbound::LTIRole::LEARNER
      role.state = :active
    end
  end

  let(:learner_role_inactive) do
    BasicLtiOutbound::LTIRole.new.tap do |role|
      role.type = BasicLtiOutbound::LTIRole::LEARNER
      role.state = :inactive
    end
  end

  describe "#current_role_types" do
    it "provides a string representation of current roles" do
      subject.tap do |user|
        user.current_enrollments = [teacher_role_active, learner_role_active]
      end

      expect(subject.current_role_types).to eq("#{BasicLtiOutbound::LTIRole::INSTRUCTOR},#{BasicLtiOutbound::LTIRole::LEARNER}")
    end

    it "defaults if no roles exist" do
      expect(subject.current_role_types).to eq(BasicLtiOutbound::LTIRole::NONE)
    end
  end

  describe "#concluded_role_types" do
    it "provides a string representation of concluded roles" do
      subject.tap do |user|
        user.concluded_enrollments = [teacher_role_active, learner_role_active]
      end

      expect(subject.concluded_role_types).to eq("#{BasicLtiOutbound::LTIRole::INSTRUCTOR},#{BasicLtiOutbound::LTIRole::LEARNER}")
    end

    it "defaults if no roles exist" do
      expect(subject.concluded_role_types).to eq(BasicLtiOutbound::LTIRole::NONE)
    end
  end

  describe "#enrollment_state" do
    it "returns 'active' if any current_enrollments are active" do
      subject.current_enrollments = [teacher_role_inactive, learner_role_active]

      expect(subject.enrollment_state).to eq BasicLtiOutbound::LTIUser::ACTIVE_STATE
    end

    it "returns 'inactive' if no current_enrollments are active" do
      subject.current_enrollments = [teacher_role_inactive, learner_role_inactive]

      expect(subject.enrollment_state).to eq BasicLtiOutbound::LTIUser::INACTIVE_STATE
    end
  end

  describe "constants" do
    it "provides enrollment state constants" do
      expect(BasicLtiOutbound::LTIUser::ACTIVE_STATE).to eq "active"
      expect(BasicLtiOutbound::LTIUser::INACTIVE_STATE).to eq "inactive"
    end
  end
  
  describe "#learner?" do
    it "returns false when current enrollments includes learner role" do
      subject.current_enrollments = [teacher_role_active, learner_role_active]

      expect(subject.learner?).to eq true
    end

    it "returns false when current enrollments do not include learner role" do
      subject.current_enrollments = [teacher_role_active]

      expect(subject.learner?).to eq false
    end
  end
end